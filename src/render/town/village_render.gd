extends Node2D

# RENDER-side assembly of the inn-green village district (decision 009). This is
# the no-PC / no-NPC free-cam counterpart to starter_town.gd: it reads the
# SIM-side authored district (src/sim/town_layout.gd build_inn_green_district())
# and draws it through the frozen isometric projection spine
# (src/render/iso/projection.gd), with a free ("disincorporated") camera and no
# player, no click-to-move, no name label, no player collider.
#
# ASSET STORY (decision 009 items 2, 3, the mandatory carry-forward finding).
# Every world-object sprite is loaded from res://assets/village/, driven by
# res://assets/village/manifest.json, through ResourceLoader. That path is
# export-VISIBLE (not a .gdignore'd tools/ tree), so a stock packaged build
# ships the real art instead of silently substituting engine defaults. The
# manifest is joined to the sim placement by `id`; the manifest owns the
# texture, the ground-contact anchor pixel, and the native size. No texture path
# or screen coordinate lives in src/sim/.
#
# DEPTH (decision 008 depth_key contract, decision 009 item 9 crown). World
# objects are ranked back-to-front by IsoProjection.depth_key over their
# projected ground-contact point, with a stable per-instance tie key. The
# `crown` kind (the tree's overhanging foreground foliage) sorts ABOVE every
# world object regardless of its contact Y, so it always draws over the scene.

const TownLayoutScript := preload("res://src/sim/town_layout.gd")
const Iso := preload("res://src/render/iso/projection.gd")
const CameraRigScript := preload("res://src/render/town/camera_rig_2d.gd")

const ASSET_DIR := "res://assets/village/"
const MANIFEST_PATH := "res://assets/village/manifest.json"

const GROUND_COLORS := {
	TownLayoutScript.GroundTile.GRASS: Color(0.36, 0.54, 0.29),
	TownLayoutScript.GroundTile.PATH: Color(0.70, 0.62, 0.45),
}

# A distinct z-band the foreground crown is lifted into so it always draws over
# every depth-sorted world object. The world band is 1..N (N is the world-object
# count, a couple dozen at most); the crown band starts well above any plausible
# N while staying under Godot's CANVAS_ITEM_Z_MAX (4096), which set_z_index
# hard-asserts against.
const CROWN_Z_BASE := 4000

@onready var _ground_layer: Node2D = $GroundLayer
@onready var _world: Node2D = $World

var _layout: TownLayoutScript
var _camera_rig: CameraRigScript
# Per-object manifest records keyed by kit-id: {png, kind, anchor_px, native_px}.
var _manifest: Dictionary = {}


func _ready() -> void:
	_layout = TownLayoutScript.build_inn_green_district()
	_manifest = load_manifest()
	_build_ground()
	_build_objects()
	_build_camera_rig()

	var grade := CanvasModulate.new()
	grade.color = Color(1.0, 0.95, 0.88)
	add_child(grade)


# Parse res://assets/village/manifest.json into a kit-id -> record dictionary.
# Uses FileAccess on a res:// JSON (packed by the stock export's all_resources
# filter, proven by the export gate). This is NOT the banned image-loading path:
# it reads a text manifest, never FileAccess.get_file_as_image / Image.load of a
# game texture. Every texture goes through ResourceLoader (see _load_texture).
static func load_manifest() -> Dictionary:
	var out: Dictionary = {}
	var file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if file == null:
		push_error("village manifest missing: %s" % MANIFEST_PATH)
		return out
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY or not parsed.has("objects"):
		push_error("village manifest malformed: %s" % MANIFEST_PATH)
		return out
	for obj in parsed["objects"]:
		out[obj["id"]] = obj
	return out


# Load a village texture through ResourceLoader (the export-safe path). Returns
# null if the asset does not resolve from the bundle, which is exactly the
# silent-default-art failure the export gate asserts against.
static func _load_texture(png: String) -> Texture2D:
	var path := ASSET_DIR + png
	if not ResourceLoader.exists(path):
		return null
	return ResourceLoader.load(path) as Texture2D


# Flat-color diamond base layer (grass / lane). Decision 009 item 1 allows a
# painted ground base; codex's authored iso ground tiles drop onto the same
# per-cell anchor later. Every VERTICAL / interactable element is a discrete
# manifest-driven sprite built in _build_objects().
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


# Build one sprite per district placement, joined to the manifest by id. The
# sprite's manifest anchor_px is placed on the projected ground-contact point
# (the same anchor contract _build_buildings uses in starter_town.gd, expressed
# in per-pixel manifest terms). World objects are depth-sorted; crowns are
# lifted into a separate foreground band.
func _build_objects() -> void:
	var world_sorts: Array = []
	var crown_sprites: Array = []

	for i in range(_layout.placements.size()):
		var placement = _layout.placements[i]
		var record: Variant = _manifest.get(placement.id)
		if record == null:
			# No manifest entry for this kit-id: skip drawing it, the export gate
			# reports the missing asset. Rendering continues so a partial manifest
			# still produces a scene to inspect.
			push_warning("no manifest record for placement id '%s'" % placement.id)
			continue

		var texture := _load_texture(record["png"])
		if texture == null:
			push_warning("village texture did not resolve: %s" % record["png"])
			continue

		var contact_cell := Iso.building_contact_cell(placement.cell, placement.footprint)
		var contact_screen := Iso.cell_to_screen(contact_cell)

		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.centered = false
		# Place the manifest anchor pixel on the projected ground-contact point:
		# with centered=false the texture's top-left draws at position + offset,
		# so offset = -anchor puts anchor_px exactly at contact_screen.
		var anchor: Array = record["anchor_px"]
		sprite.position = contact_screen
		sprite.offset = Vector2(-float(anchor[0]), -float(anchor[1]))
		sprite.set_meta("kit_id", placement.id)
		_world.add_child(sprite)

		if placement.kind == "crown":
			crown_sprites.append(sprite)
		else:
			# Per-instance depth id: a repeated kit-id (fence_section) still gets a
			# unique, deterministic tie key from the placement index.
			var sort_id := "%s#%d" % [placement.id, i]
			world_sorts.append({
				"key": Iso.depth_key(contact_cell, sort_id),
				"node": sprite,
			})

	world_sorts.sort_custom(func(a, b): return a.key < b.key)
	for i in range(world_sorts.size()):
		world_sorts[i].node.z_index = 1 + i

	# Foreground crown band: always above every world object (decision 009 item
	# 9). Ordered among themselves by contact for stable layering.
	for i in range(crown_sprites.size()):
		crown_sprites[i].z_index = CROWN_Z_BASE + i


func _build_camera_rig() -> void:
	_camera_rig = CameraRigScript.new()
	_camera_rig.name = "CameraRig2D"
	_world.add_child(_camera_rig)
	_camera_rig.setup_free(_layout)


# Accessor for the export/capture gate (decision 009 items 2, 9). Not used in
# interactive play.
func camera_rig() -> CameraRigScript:
	return _camera_rig
