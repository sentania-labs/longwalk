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
const GroundShader := preload("res://src/render/town/ground.gdshader")

const ASSET_DIR := "res://assets/village/"
const MANIFEST_PATH := "res://assets/village/manifest.json"

# Continuous-ground assets (decision 010, PLATE fallback). The two painterly
# PLATES (sampled ONCE across the district, not tiled per cell) and the CPU-baked
# warp field are sampled by ground.gdshader in cell space; the shadow decal
# grounds each object. These are static res:// resources loaded through
# ResourceLoader (export-safe, proven by the export gate's added assertions).
# codex owns the real pixels; integration swaps them over the provisional plates.
const GRASS_PLATE_PATH := "res://assets/village/ground_grass_plate.png"
const DIRT_PLATE_PATH := "res://assets/village/ground_dirt_plate.png"
const WARP_PATH := "res://assets/village/ground_warp.png"
const SHADOW_DECAL_PATH := "res://assets/village/shadow_decal.png"

# Lane mask resolution: K texels per cell (K > 1) so a 16x14 source does not
# read as a fuzzy wide band under bilinear filtering (decision 010 step 3). The
# per-cell PATH/GRASS value is duplicated across its K texels, so the grass/dirt
# ramp lands in the last texel (1/K cell) instead of spreading a full cell.
const MASK_TEXELS_PER_CELL := 4

# Ground shader tuning. plate_repeat is how many times the painterly plate spans
# the district: 1.0 samples it exactly once (no tiling, no repeat structure, the
# point of the plate fallback). warp_amp is capped at 0.2 cell and core_frac is
# the unwarped solid-dirt fraction of every PATH cell (decision 010 step 5).
const GROUND_PLATE_REPEAT := 1.0
const GROUND_WARP_AMP := 0.18
const GROUND_CORE_FRAC := 0.5

# Contact-shadow layer (decision 010 step 7, agy defect #3). Soft darkening
# ellipses tight to each object's ground anchor, above the ground and below the
# depth-sorted objects. Contact darkening only, NOT a general cast-shadow order.
const SHADOW_WIDTH_FRAC := 0.62
const SHADOW_ALPHA := 0.28

# A distinct z-band the foreground crown is lifted into so it always draws over
# every depth-sorted world object. The world band is 1..N (N is the world-object
# count, a couple dozen at most); the crown band starts well above any plausible
# N while staying under Godot's CANVAS_ITEM_Z_MAX (4096), which set_z_index
# hard-asserts against.
const CROWN_Z_BASE := 4000

@onready var _ground_layer: Node2D = $GroundLayer
@onready var _shadow_layer: Node2D = $ShadowLayer
@onready var _world: Node2D = $World

var _layout: TownLayoutScript
var _camera_rig: CameraRigScript
# Per-object manifest records keyed by kit-id: {png, kind, anchor_px, native_px}.
var _manifest: Dictionary = {}


func _ready() -> void:
	_layout = TownLayoutScript.build_inn_green_district()
	_manifest = load_manifest()
	_build_ground()
	_build_shadows()
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


# Load a full res:// resource path (a swatch, the warp field, the shadow decal)
# through ResourceLoader, the export-safe path. Returns null if it does not
# resolve from the bundle, which the export gate's added assertions catch.
static func _load_res(path: String) -> Resource:
	if not ResourceLoader.exists(path):
		return null
	return ResourceLoader.load(path)


# ONE continuous shader-quad ground plane (decision 010). This replaces the old
# per-cell flat `Polygon2D` diamonds (the checkerboard tell agy QA flagged) with
# a single MeshInstance2D spanning the whole district's projected diamond. The
# mesh's UV array is set to the CELL corners of its vertices, so the fragment
# shader receives fractional CELL space by affine interpolation, with no
# per-frame screen->iso inversion. ground.gdshader paints the grass/dirt PLATES
# sampled once across the district and blends them by the render-derived lane mask.
func _build_ground() -> void:
	var geo := ground_quad_geometry(_layout.width, _layout.height)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = geo["verts"]
	arrays[Mesh.ARRAY_TEX_UV] = geo["uvs"]
	arrays[Mesh.ARRAY_INDEX] = geo["indices"]
	var mesh := ArrayMesh.new()
	# ARRAY_FLAG_USE_2D_VERTICES: the vertex array is Vector2 screen positions, so
	# the mesh renders flat in canvas space and the UV attribute passes straight
	# through to the shader unmodified (no texture-size normalization to fight).
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, Mesh.ARRAY_FLAG_USE_2D_VERTICES)

	var ground := MeshInstance2D.new()
	ground.mesh = mesh
	ground.material = _build_ground_material()
	_ground_layer.add_child(ground)


# The ground quad's geometry: the four projected outer grid corners as screen
# vertices, their CELL coordinates as UVs, and two triangles sharing the (0,0)->
# (w,h) diagonal. Because Iso.cell_to_screen is a linear map, the image of the
# axis-aligned cell rectangle is a parallelogram and UV interpolation is globally
# affine, so both triangles agree exactly across the shared diagonal (proven by
# test/active_path/test_ground_uv_spike.gd, the mandated coordinate spike). Kept
# static so the spike exercises the real construction, not a copy.
static func ground_quad_geometry(width: int, height: int) -> Dictionary:
	var w := float(width)
	var h := float(height)
	var verts := PackedVector2Array([
		Iso.cell_to_screen(Vector2(0.0, 0.0)),
		Iso.cell_to_screen(Vector2(w, 0.0)),
		Iso.cell_to_screen(Vector2(w, h)),
		Iso.cell_to_screen(Vector2(0.0, h)),
	])
	var uvs := PackedVector2Array([
		Vector2(0.0, 0.0),
		Vector2(w, 0.0),
		Vector2(w, h),
		Vector2(0.0, h),
	])
	var indices := PackedInt32Array([0, 1, 2, 0, 2, 3])
	return {"verts": verts, "uvs": uvs, "indices": indices}


# Build the ground ShaderMaterial: wire the two plates, the CPU-baked warp field,
# the runtime-derived lane mask, and the tuning uniforms. A plate that fails to
# resolve leaves that sampler unset (the shader still runs); the export gate is
# the load-bearing proof the real assets ship.
func _build_ground_material() -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = GroundShader
	mat.set_shader_parameter("grass_tex", _load_res(GRASS_PLATE_PATH))
	mat.set_shader_parameter("dirt_tex", _load_res(DIRT_PLATE_PATH))
	mat.set_shader_parameter("warp_tex", _load_res(WARP_PATH))
	mat.set_shader_parameter("lane_mask", _build_lane_mask())
	mat.set_shader_parameter("grid_size", Vector2(_layout.width, _layout.height))
	mat.set_shader_parameter("plate_repeat", GROUND_PLATE_REPEAT)
	mat.set_shader_parameter("warp_amp", GROUND_WARP_AMP)
	mat.set_shader_parameter("core_frac", GROUND_CORE_FRAC)
	return mat


# Derive the R8 lane mask from the sim `ground` grid (read-only; town_layout.gd
# stays texture-ignorant and viewport-free, decision 010). PATH -> 1, GRASS -> 0,
# rasterized at MASK_TEXELS_PER_CELL (K > 1) texels/cell BEFORE the shader warp.
# This is the same render-reads-sim category as the old color lookup, just into a
# texture instead of a per-diamond Color; no screen coordinate or wander offset
# ever crosses back into the sim. The mask is a derived in-memory resource and
# needs no static manifest entry.
func _build_lane_mask() -> ImageTexture:
	var kw := _layout.width * MASK_TEXELS_PER_CELL
	var kh := _layout.height * MASK_TEXELS_PER_CELL
	var img := Image.create(kw, kh, false, Image.FORMAT_R8)
	for ty in range(kh):
		var cy: int = ty / MASK_TEXELS_PER_CELL
		for tx in range(kw):
			var cx: int = tx / MASK_TEXELS_PER_CELL
			var is_path: bool = _layout.ground[cy][cx] == TownLayoutScript.GroundTile.PATH
			img.set_pixel(tx, ty, Color(1.0, 0.0, 0.0) if is_path else Color(0.0, 0.0, 0.0))
	return ImageTexture.create_from_image(img)


# Contact-shadow layer (decision 010 step 7, agy defect #3): a soft darkening
# ellipse tight to each object's ground anchor, drawn above the ground quad and
# below the depth-sorted world objects (the ShadowLayer sits between GroundLayer
# and World in the scene). Contact darkening only: this is NOT a general
# cast-shadow ordering solution, and it does not duplicate shadows baked into
# source sprites. The crown (overhanging foliage, no ground contact) casts none.
func _build_shadows() -> void:
	var decal := _load_res(SHADOW_DECAL_PATH) as Texture2D
	if decal == null:
		push_warning("village shadow decal did not resolve: %s" % SHADOW_DECAL_PATH)
		return
	var tex_size := decal.get_size()
	for placement in _layout.placements:
		if placement.kind == "crown":
			continue
		var fw := float(placement.footprint.x)
		var fh := float(placement.footprint.y)
		# Pool the shadow under the footprint's projected center.
		var center_cell := Vector2(float(placement.cell.x) + fw / 2.0, float(placement.cell.y) + fh / 2.0)
		var proj_w := (fw + fh) * Iso.HALF_W
		var target_w := proj_w * SHADOW_WIDTH_FRAC
		# Iso-foreshortened: the ground ellipse is half as tall as it is wide.
		var target_h := target_w * 0.5

		var sprite := Sprite2D.new()
		sprite.texture = decal
		sprite.centered = true
		sprite.position = Iso.cell_to_screen(center_cell)
		sprite.scale = Vector2(target_w / float(tex_size.x), target_h / float(tex_size.y))
		sprite.modulate = Color(0.0, 0.0, 0.0, SHADOW_ALPHA)
		_shadow_layer.add_child(sprite)


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
