extends Node2D

# RENDER-side assembly of the starter town: reads TownLayout (SIM-side, see
# src/sim/town_layout.gd) and builds the actual ground sprites, building
# sprites/collision, boundary collision, and player. Nothing here computes
# world layout, it only draws what TownLayout already decided.

const TownLayoutScript := preload("res://src/sim/town_layout.gd")
const NavGridScript := preload("res://src/sim/nav_grid.gd")
const ClickMarkerScript := preload("res://src/render/town/click_marker.gd")
const PlayerScene := preload("res://scenes/player.tscn")
const ChimneySmokeScene := preload("res://scenes/chimney_smoke.tscn")

const GROUND_TEXTURE_PATHS := {
	TownLayoutScript.GroundTile.GRASS: "res://assets/kenney/roguelike-rpg-pack/grass.png",
	TownLayoutScript.GroundTile.PATH: "res://assets/kenney/roguelike-rpg-pack/path.png",
}

const BUILDING_TEXTURE_PATHS := {
	"building_facade": "res://assets/kenney/roguelike-rpg-pack/cottage.png",
	"cottage_facade": "res://assets/kenney/roguelike-rpg-pack/cottage.png",
}

const FLORA := [
	{"texture": "tree.png", "cell": Vector2i(8, 6), "scale": 0.5},
	{"texture": "tree.png", "cell": Vector2i(10, 6), "scale": 0.5},
	{"texture": "bush.png", "cell": Vector2i(8, 8), "scale": 0.5},
	{"texture": "bush.png", "cell": Vector2i(10, 8), "scale": 0.5},
	{"texture": "flowers.png", "cell": Vector2i(8, 7), "scale": 0.5},
	{"texture": "flowers.png", "cell": Vector2i(10, 7), "scale": 0.5},
]
const KENNEY_ASSET_ROOT := "res://assets/kenney/roguelike-rpg-pack/"

const TILE_SIZE := TownLayoutScript.TILE_SIZE
const BOUNDARY_THICKNESS := 64.0
const PLACEHOLDER_MARKER_COLOR := Color(0.9, 0.75, 0.2, 0.25)
const COTTAGE_SMOKE_OFFSET := Vector2(80.0, -230.0)

@onready var _ground_layer: Node2D = $GroundLayer
@onready var _world: Node2D = $World
@onready var _boundary: Node2D = $Boundary
@onready var _name_label: Label = $UI/NameLabel

var _layout: TownLayoutScript
var _player: CharacterBody2D
var _click_marker: ClickMarkerScript

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
	_build_flora()
	_build_boundary()
	_spawn_player()
	_build_click_marker()
	_name_label.text = character_name

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


func _build_ground() -> void:
	for y in range(_layout.height):
		for x in range(_layout.width):
			var tile: int = _layout.ground[y][x]
			var sprite := Sprite2D.new()
			sprite.texture = load(GROUND_TEXTURE_PATHS[tile])
			sprite.centered = false
			sprite.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)

			var h := hash(Vector2i(x, y))
			sprite.flip_h = (h % 2 == 0)
			sprite.flip_v = ((h / 2) % 2 == 0)

			_ground_layer.add_child(sprite)


func _build_buildings() -> void:
	for building in _layout.buildings:
		if building.is_npc_placeholder:
			_build_placeholder_marker(building)
			continue

		var footprint_px := Vector2(building.footprint.x, building.footprint.y) * TILE_SIZE
		var footprint_origin := Vector2(building.cell.x, building.cell.y) * TILE_SIZE
		var footprint_center := footprint_origin + footprint_px / 2.0

		var shadow := _create_shadow_polygon(footprint_px * 0.8)
		shadow.position = footprint_center
		_ground_layer.add_child(shadow)

		var texture: Texture2D = load(BUILDING_TEXTURE_PATHS[building.sprite_key])
		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.centered = true
		sprite.scale = Vector2(0.5, 0.5)
		# Y-sort (see _world.y_sort_enabled in starter_town.tscn) compares
		# each direct child's own `position`, not where its texture is drawn.
		# The player's sort key is its feet (the CharacterBody2D's own
		# origin, see player.tscn's Sprite2D offset). To sort consistently
		# against that, this sprite's `position` must ALSO be the footprint's
		# bottom edge, with the taller texture then drawn upward from there
		# via `offset` rather than by moving `position` itself; moving
		# `position` up by half the texture height (as an earlier version of
		# this code did) put the sort key at the sprite's vertical middle,
		# which flipped front/back ordering against the player across
		# roughly the lower half of the building's height.
		sprite.position = Vector2(footprint_center.x, footprint_origin.y + footprint_px.y)
		sprite.offset = Vector2(0, -texture.get_height() / 2.0)
		sprite.set_meta("sprite_key", building.sprite_key)
		_world.add_child(sprite)
		if building.sprite_key == "cottage_facade":
			var smoke := ChimneySmokeScene.instantiate()
			smoke.position = COTTAGE_SMOKE_OFFSET
			var canvas_grade = Color(1.0, 0.95, 0.88)
			smoke.modulate = Color(1.0 / canvas_grade.r, 1.0 / canvas_grade.g, 1.0 / canvas_grade.b)
			sprite.add_child(smoke)

		var body := StaticBody2D.new()
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = footprint_px
		shape.shape = rect
		body.add_child(shape)
		body.position = footprint_center
		_world.add_child(body)


func _build_flora() -> void:
	for placement in FLORA:
		var texture: Texture2D = load(KENNEY_ASSET_ROOT + placement.texture)
		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.centered = true
		sprite.scale = Vector2.ONE * placement.scale
		# Direct World children sort on their ground-contact position. Drawing the
		# texture upward from that point lets the traveller pass behind and in front.
		sprite.position = Vector2(placement.cell) * TILE_SIZE + Vector2(TILE_SIZE / 2.0, TILE_SIZE)
		sprite.offset = Vector2(0.0, -texture.get_height() / 2.0)
		sprite.set_meta("flora", placement.texture)
		_world.add_child(sprite)


# Click feedback lives above the ground but is not y-sorted against the player:
# it is UI-ish feedback drawn flat on the street, so it goes in _ground_layer
# rather than _world, where its own position would otherwise fight the player's
# sort key.
func _build_click_marker() -> void:
	_click_marker = ClickMarkerScript.new()
	_click_marker.name = "ClickMarker"
	_ground_layer.add_child(_click_marker)


# Click-to-move: the only movement input in the game (decision record
# docs/decisions/003-village-feel.md removed WASD). The town owns the click
# because it owns the layout and the marker; the player owns the routing and
# the steering.
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	if event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
		return
	if _player == null:
		return
	var world_position := _world.get_global_mouse_position()
	var destination: Vector2i = _player.move_to_world_position(world_position)
	if destination == NavGridScript.NO_CELL:
		return
	get_viewport().set_input_as_handled()
	if _click_marker != null:
		# Marked at the resolved cell, not the raw click: the feedback should
		# answer where the player is actually going.
		_click_marker.position = _player.cell_to_world_center(destination)
		_click_marker.ping()


func _build_placeholder_marker(building) -> void:
	var footprint_px := Vector2(building.footprint.x, building.footprint.y) * TILE_SIZE
	var footprint_origin := Vector2(building.cell.x, building.cell.y) * TILE_SIZE
	var marker := Polygon2D.new()
	marker.polygon = PackedVector2Array([
		Vector2(0, 0),
		Vector2(footprint_px.x, 0),
		Vector2(footprint_px.x, footprint_px.y),
		Vector2(0, footprint_px.y),
	])
	marker.color = PLACEHOLDER_MARKER_COLOR
	marker.position = footprint_origin
	_ground_layer.add_child(marker)


func _build_boundary() -> void:
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
	var spawn_cell := Vector2i(int(_layout.width / 2.0), 7)
	player.position = Vector2(spawn_cell.x, spawn_cell.y) * TILE_SIZE + Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)

	var shadow := _create_shadow_polygon(Vector2(28.0, 14.0))
	shadow.position = Vector2.ZERO
	player.add_child(shadow)
	player.move_child(shadow, 0)

	_world.add_child(player)
	_player = player

	var camera: Camera2D = player.get_node("Camera2D")
	var pixel_size := _layout.pixel_size()
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(pixel_size.x)
	camera.limit_bottom = int(pixel_size.y)


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
