extends Node2D

# RENDER-side assembly of the starter town: reads TownLayout (SIM-side, see
# src/sim/town_layout.gd) and builds the actual ground diamonds, building
# sprites/collision, boundary collision, and player. Nothing here computes
# world layout, it only draws what TownLayout already decided.
#
# ISOMETRIC SPINE (decision 008). The sim and physics stay in SQUARE
# world-pixel space, unchanged (decision 008 Q-B: movement and collision are
# authoritative there, move_and_slide and the footprint colliders are
# untouched). This assembler PROJECTS that square space to isometric SCREEN
# space for display only, through src/render/iso/projection.gd:
#
#   - Ground diamonds live in the non-y-sorted GroundLayer (a static base
#     layer), along with contact shadows and the click marker.
#   - The World node holds the AUTHORITATIVE physics: the player CharacterBody2D
#     (at its square position) and the StaticBody2D building colliders (at their
#     square footprints). These are unchanged from round 004. Their VISUALS are
#     projected: each building sprite is drawn at its projected ground-contact
#     anchor, and the player's own Sprite2D is drawn at the projection of the
#     body's square position each frame (the "display proxy"). Depth is a manual
#     z_index rank over projected contact Y with a stable placement-id tie key
#     (footprint-aware occlusion contract), NOT Godot's bare y_sort, which
#     cannot express the tie key or a multi-cell footprint anchor.
#
# The inverse projection is used ONLY at the input boundary (a click's screen
# point -> the grid cell to route to). No projection symbol enters src/sim/.
#
# NOTE (frozen seam for agy's camera slice): the CameraRig2D added here still
# follows the player's SQUARE-space body position, so on this branch in
# isolation the interactive camera looks at square coordinates while the world
# is drawn in iso. agy's drag-pan rework consumes the frozen projection contract
# (IsoProjection.projected_bounds / screen_to_cell) and retargets the camera to
# the projected space; that is out of this slice by decision 008's division of
# labor. The acceptance-capture tool (tools/art/capture_player_walk.gd) sets up
# its own camera in projected space so this slice's visual artifact does not
# depend on the camera rework.

const TownLayoutScript := preload("res://src/sim/town_layout.gd")
const NavGridScript := preload("res://src/sim/nav_grid.gd")
const ClickMarkerScript := preload("res://src/render/town/click_marker.gd")
const Iso := preload("res://src/render/iso/projection.gd")
const PlayerScene := preload("res://scenes/player.tscn")
const ChimneySmokeScene := preload("res://scenes/chimney_smoke.tscn")
const CameraRigScript := preload("res://src/render/town/camera_rig_2d.gd")

const GROUND_COLORS := {
	TownLayoutScript.GroundTile.GRASS: Color(0.36, 0.54, 0.29),
	TownLayoutScript.GroundTile.PATH: Color(0.70, 0.62, 0.45),
}

const BUILDING_TEXTURE_PATHS := {
	"building_facade": "res://tools/art/out/processed/building_facade.png",
	"cottage_facade": "res://tools/art/out/processed/cottage_facade.png",
}

const TILE_SIZE := TownLayoutScript.TILE_SIZE
const BOUNDARY_THICKNESS := 64.0
const PLACEHOLDER_MARKER_COLOR := Color(0.9, 0.75, 0.2, 0.25)
const COTTAGE_SMOKE_OFFSET := Vector2(80.0, -230.0)

# Player display id for the depth-sort tie key. Fixed: there is one player.
const PLAYER_SORT_ID := "player"

@onready var _ground_layer: Node2D = $GroundLayer
@onready var _world: Node2D = $World
@onready var _boundary: Node2D = $Boundary
@onready var _name_label: Label = $UI/NameLabel

var _layout: TownLayoutScript
var _player: CharacterBody2D
var _player_shadow: Polygon2D
var _click_marker: ClickMarkerScript
var _camera_rig: CameraRigScript

# Static world-object depth entries (buildings). Each is {node, id, contact}
# where contact is the projected-into-cell-space ground-contact point. The
# player is ranked alongside these each frame from its live square position.
var _building_sorts: Array = []

# Character choices from character creation. Public and settable directly
# (a headless test sets these before calling _ready()/build() rather than
# going through the GameState autoload) so this scene never hard-depends on
# tree-entry-triggered autoload resolution to be exercised. In normal play
# _ready() fills these from the GameState autoload if they were left unset.
var character_name := ""
var appearance_variant := ""


func _ready() -> void:
	if character_name.is_empty() or appearance_variant.is_empty():
		_load_from_game_state()
	_layout = TownLayoutScript.build_starter_town()
	_build_ground()
	_build_buildings()
	_build_boundary()
	_spawn_player()
	_build_camera_rig()
	_build_click_marker()
	_name_label.text = character_name
	_update_iso_display()

	var grade := CanvasModulate.new()
	grade.color = Color(1.0, 0.95, 0.88)
	add_child(grade)


func _load_from_game_state() -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null:
		character_name = "Traveler"
		appearance_variant = "moss"
		return
	character_name = game_state.character_name
	appearance_variant = game_state.appearance_variant


# Ground diamonds. Each cell projects to a 2:1 diamond built from its four
# projected grid corners; the diamonds tile without overlap, so draw order
# among them is irrelevant. Placeholder flat colors keyed by ground type stand
# in for codex's generated iso ground tiles (which will drop in against the
# same per-cell anchor); a small deterministic brightness jitter (hash of the
# cell, no RNG) keeps the field from reading dead flat.
func _build_ground() -> void:
	for y in range(_layout.height):
		for x in range(_layout.width):
			var tile: int = _layout.ground[y][x]
			var diamond := Polygon2D.new()
			diamond.polygon = PackedVector2Array([
				Iso.cell_to_screen(Vector2(x, y)),
				Iso.cell_to_screen(Vector2(x + 1, y)),
				Iso.cell_to_screen(Vector2(x + 1, y + 1)),
				Iso.cell_to_screen(Vector2(x, y + 1)),
			])
			var base: Color = GROUND_COLORS[tile]
			var jitter := (float(hash(Vector2i(x, y)) % 100) / 100.0 - 0.5) * 0.06
			diamond.color = Color(
				clampf(base.r + jitter, 0.0, 1.0),
				clampf(base.g + jitter, 0.0, 1.0),
				clampf(base.b + jitter, 0.0, 1.0)
			)
			_ground_layer.add_child(diamond)


func _build_buildings() -> void:
	for building in _layout.buildings:
		if building.is_npc_placeholder:
			_build_placeholder_marker(building)
			continue

		var contact_cell := Iso.building_contact_cell(building.cell, building.footprint)
		var contact_screen := Iso.cell_to_screen(contact_cell)

		# Contact shadow, flat on the ground under the footprint (placeholder
		# for codex's offline-derived shadow mask, decision 008 Q-C).
		var footprint_center := Vector2(building.cell) + Vector2(building.footprint) / 2.0
		var shadow := _create_shadow_polygon(Vector2(building.footprint.x * Iso.HALF_W, building.footprint.y * Iso.HALF_H) * 0.8)
		shadow.position = Iso.cell_to_screen(footprint_center)
		_ground_layer.add_child(shadow)

		# Building sprite, drawn upward from its projected ground-contact anchor.
		var texture: Texture2D = load(BUILDING_TEXTURE_PATHS[building.sprite_key])
		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.centered = true
		# position is the projected ground-contact point; offset draws the
		# taller facade upward from there so its base sits on the contact line
		# (see IsoProjection.building_contact_cell for the anchor contract that
		# codex's generated iso sprites are authored against).
		sprite.position = contact_screen
		sprite.offset = Vector2(0, -texture.get_height() / 2.0)
		sprite.set_meta("sprite_key", building.sprite_key)
		_world.add_child(sprite)
		if building.sprite_key == "cottage_facade":
			var smoke := ChimneySmokeScene.instantiate()
			smoke.position = COTTAGE_SMOKE_OFFSET

			# Compensate for the warm sunset CanvasModulate so the smoke reads as cool grey
			var canvas_grade = Color(1.0, 0.95, 0.88)
			smoke.modulate = Color(1.0 / canvas_grade.r, 1.0 / canvas_grade.g, 1.0 / canvas_grade.b)

			sprite.add_child(smoke)

		_building_sorts.append({
			"node": sprite,
			"id": building.id,
			"contact": contact_cell,
		})

		# Collision stays AUTHORITATIVE in square world-pixel space, unchanged
		# from round 004: the collider is exactly footprint * TILE_SIZE centered
		# on the square footprint. This is the geometry the nav grid agrees with
		# by construction (decision 008 Q-B; test_nav_grid pins it).
		var footprint_px := Vector2(building.footprint.x, building.footprint.y) * TILE_SIZE
		var footprint_origin := Vector2(building.cell.x, building.cell.y) * TILE_SIZE
		var square_center := footprint_origin + footprint_px / 2.0
		var body := StaticBody2D.new()
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = footprint_px
		shape.shape = rect
		body.add_child(shape)
		body.position = square_center
		_world.add_child(body)


# Click feedback lives in the ground base layer (not depth-sorted against world
# objects): it is flat-on-the-street feedback, drawn at the projected center of
# the resolved cell.
func _build_click_marker() -> void:
	_click_marker = ClickMarkerScript.new()
	_click_marker.name = "ClickMarker"
	_ground_layer.add_child(_click_marker)


# Click-to-move: the only movement input in the game (decision record
# docs/decisions/003-village-feel.md removed WASD). The click arrives in iso
# SCREEN space; the inverse projection turns it into the grid cell to route to.
# This is the ONLY place the projection is inverted (the input boundary,
# decision 008 Q-B); routing and collision then run in square space as before.
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	if event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
		return
	if _player == null:
		return
	var screen_position := _ground_layer.get_global_mouse_position()
	var cell := Iso.screen_to_cell(screen_position)
	var world_center := Vector2(cell) * TILE_SIZE + Vector2.ONE * (TILE_SIZE / 2.0)
	var destination: Vector2i = _player.move_to_world_position(world_center)
	if destination == NavGridScript.NO_CELL:
		return
	get_viewport().set_input_as_handled()
	if _click_marker != null:
		# Marked at the resolved cell, not the raw click: the feedback should
		# answer where the player is actually going.
		_click_marker.position = Iso.cell_to_screen(Vector2(destination) + Vector2(0.5, 0.5))
		_click_marker.ping()


func _build_placeholder_marker(building) -> void:
	var marker := Polygon2D.new()
	var origin: Vector2i = building.cell
	var fp: Vector2i = building.footprint
	marker.polygon = PackedVector2Array([
		Iso.cell_to_screen(Vector2(origin.x, origin.y)),
		Iso.cell_to_screen(Vector2(origin.x + fp.x, origin.y)),
		Iso.cell_to_screen(Vector2(origin.x + fp.x, origin.y + fp.y)),
		Iso.cell_to_screen(Vector2(origin.x, origin.y + fp.y)),
	])
	marker.color = PLACEHOLDER_MARKER_COLOR
	_ground_layer.add_child(marker)


func _build_boundary() -> void:
	# Boundary walls stay in SQUARE world-pixel space, unchanged: they bound the
	# authoritative physics region, not the projected display.
	var size := _layout.pixel_size()
	_add_boundary_wall(Vector2(size.x / 2.0, -BOUNDARY_THICKNESS / 2.0), Vector2(size.x, BOUNDARY_THICKNESS))
	_add_boundary_wall(Vector2(size.x / 2.0, size.y + BOUNDARY_THICKNESS / 2.0), Vector2(size.x, BOUNDARY_THICKNESS))
	_add_boundary_wall(Vector2(-BOUNDARY_THICKNESS / 2.0, size.y / 2.0), Vector2(BOUNDARY_THICKNESS, size.y))
	_add_boundary_wall(Vector2(size.x + BOUNDARY_THICKNESS / 2.0, size.y / 2.0), Vector2(BOUNDARY_THICKNESS, size.y))


func _add_boundary_wall(center: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)
	body.position = center
	_boundary.add_child(body)


func _spawn_player() -> void:
	var player := PlayerScene.instantiate()
	player.set_appearance(appearance_variant)
	player.set_layout(_layout)
	# Authoritative SQUARE-space spawn, unchanged from round 004.
	var spawn_cell := Vector2i(int(_layout.width / 2.0), 7)
	player.position = Vector2(spawn_cell.x, spawn_cell.y) * TILE_SIZE + Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)

	# The player's contact shadow lives in the ground layer (drawn under every
	# world object) and is repositioned to the projected feet each frame, rather
	# than parented to the body (which sits in square space).
	_player_shadow = _create_shadow_polygon(Vector2(Iso.HALF_W * 0.44, Iso.HALF_H * 0.44))
	_ground_layer.add_child(_player_shadow)

	_world.add_child(player)
	_player = player


func _build_camera_rig() -> void:
	_camera_rig = CameraRigScript.new()
	_camera_rig.name = "CameraRig2D"
	_world.add_child(_camera_rig)
	_camera_rig.setup(_player, _layout)


func _process(_delta: float) -> void:
	_update_iso_display()


# Projects the authoritative square-space world into iso screen space for
# display: the player's sprite is drawn at the projection of its body position,
# its shadow tracks its projected feet, and every world object's z_index is
# ranked back-to-front by projected contact Y with a stable placement-id tie
# key (decision 008 point 2). Buildings are static; only the player's rank
# moves, but a full re-rank over the handful of world objects each frame is
# trivial and keeps the ordering obviously correct.
func _update_iso_display() -> void:
	var entries: Array = []
	for entry in _building_sorts:
		entries.append({
			"key": Iso.depth_key(entry.contact, entry.id),
			"node": entry.node,
		})

	if _player != null:
		var feet_screen := Iso.world_to_screen(_player.position)
		var sprite: Sprite2D = _player.get_node("Sprite2D")
		# Draw the sprite at the projected feet while the body stays in square
		# space: sprite is local to the body, so subtract the body position.
		sprite.position = feet_screen - _player.position
		if _player_shadow != null:
			_player_shadow.position = feet_screen
		var contact_cell := _player.position / float(TILE_SIZE)
		entries.append({
			"key": Iso.depth_key(contact_cell, PLAYER_SORT_ID),
			"node": _player,
		})

	entries.sort_custom(func(a, b): return a.key < b.key)
	for i in range(entries.size()):
		entries[i].node.z_index = 1 + i


func _create_shadow_polygon(size: Vector2) -> Polygon2D:
	var shadow := Polygon2D.new()
	var points := PackedVector2Array()
	var segments := 24
	for i in range(segments):
		var angle := float(i) / segments * TAU
		points.append(Vector2(cos(angle) * size.x / 2.0, sin(angle) * size.y / 2.0))
	shadow.polygon = points
	shadow.color = Color(0, 0, 0, 0.25)
	return shadow
