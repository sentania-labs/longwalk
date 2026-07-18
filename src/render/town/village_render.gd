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
const ObjectShader := preload("res://src/render/town/object.gdshader")

const ASSET_DIR := "res://assets/village/"
const MANIFEST_PATH := "res://assets/village/manifest.json"

# Continuous-ground assets (decision 010 PLATE fallback + decision 011 baked
# lanes). The two painterly PLATES (sampled ONCE across the district, not tiled
# per cell) and the two BAKED lane textures (mask + density) are sampled by
# ground.gdshader in cell space. Object grounding is now the per-object baked
# seam masks (decision 016 D1), NOT the generic shadow_decal ellipse, which is
# RETIRED from the render (the committed shadow_decal.png asset stays in the
# manifest and is still audited by the export gate). These are static res://
# resources loaded through ResourceLoader (export-safe, proven by the export
# gate's assertions). codex owns the baked lane pixels; this slice consumes them.
const GRASS_PLATE_PATH := "res://assets/village/ground_grass_plate.png"
const DIRT_PLATE_PATH := "res://assets/village/ground_dirt_plate.png"

# Dirt DETAIL control texture (decision 012). The offline bake
# (tools/art/bake_dirt_detail.gd) turns the grass plate's luminance high-pass
# into this committed RG8 asset (R high-frequency shoulder structure, G broad
# core drift). ground.gdshader samples it once across the district to give the
# intrinsically flat dirt plate the source structure it lacks. codex owns the
# baked pixels; this slice consumes them, same export-safe ResourceLoader path.
const DIRT_DETAIL_PATH := "res://assets/village/ground_dirt_detail.png"

# Baked lane data textures (decision 011). The offline bake
# (tools/art/bake_lane_mask.gd) turns the authored sim polylines into these two
# committed assets: lane_mask (RG8: R unwarped protected core, G cosmetic
# shoulder coverage with the domain warp + junction smooth-minimum baked in) and
# lane_density (R8 low-frequency wear). The shader consumes them directly; the
# render no longer rasterizes a runtime binary mask from the PATH grid.
const LANE_MASK_PATH := "res://assets/village/lane_mask.png"
const LANE_DENSITY_PATH := "res://assets/village/lane_density.png"

# Baked footprint interaction field (decision 016 D2). RGBA8 layout-derived field
# (tools/art/bake_footprint_field.gd, codex's slice) at lane-mask resolution:
# R = building-apron coverage, G = signed distance to the nearest footprint
# (0.5 = edge), B = deterministic door-threshold wear. ground.gdshader samples it
# ONLY at its named worn-apron insertion point to grade the grass-to-foundation
# seam; the frozen lane core / plate / detail path is untouched. codex owns the
# baked pixels; this slice consumes them, same export-safe ResourceLoader path.
const FOOTPRINT_FIELD_PATH := "res://assets/village/footprint_interaction_field.png"

# Ground shader tuning. plate_repeat is how many times the painterly plate spans
# the district: 1.0 samples it exactly once (no tiling, no repeat structure, the
# point of the plate fallback).
const GROUND_PLATE_REPEAT := 1.0

# Grounding-shadow layer (decision 016 D1). The generic symmetric shadow_decal
# ellipse is RETIRED. Each object now draws its baked basal-alpha contact + SHORT
# directional cast masks (assets/village/seams/<id>_{contact,cast}.png, codex's
# slice) on a shared below-sprite ground-plane layer. The masks share their
# sprite's dimensions and frame, so they align pixel-for-pixel under the sprite
# at the same anchored position. They carry the shadow shape in ALPHA (RGB is 0);
# we draw them as flat black modulated by these bounded strengths so the pool
# grounds the object without reading as a pasted ellipse. CONTACT is the tight
# dark core hugging the base; CAST is the short light-driven grounding pool
# (one shared manifest light_vector_px, baked in).
const CONTACT_STRENGTH := 0.80
const CAST_STRENGTH := 0.42

# Per-kit tonal grade (decision 016 D4). TONAL_STRENGTH damps the move from each
# sprite's measured midtone toward its manifest target midtone (0 = no grade,
# 1 = land exactly on target); kept below 1 so the grade closes the tonal
# disparity into one scene key without fully recoloring an object. Each channel
# multiplier is clamped to [TONAL_MUL_LO, TONAL_MUL_HI] so no single kit is
# pushed to an extreme even where its source midtone is far from target.
const TONAL_STRENGTH := 0.48
# The clamp is deliberately asymmetric. Several flora targets are measured very
# dark (bush_a mid is 40,36,16), so a symmetric low bound crushed foliage toward
# black; TONAL_MUL_LO floors the darkening at 0.72 so flora reads muted, not
# black, while TONAL_MUL_HI keeps room for the building/stone warmth lift.
const TONAL_MUL_LO := 0.72
const TONAL_MUL_HI := 1.45
# Highlight/saturation guards are read per-kit from the manifest (0..255) and
# normalized to 0..1 for the shader. GUARD_SOFTNESS is the fade band below a
# guard where the grade ramps back to identity.
const GUARD_SOFTNESS := 0.12

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
# The manifest seam_policy block (decision 016 render contract): light_vector_px,
# per-kit shadow mask paths, and per-kit tonal targets. Empty if absent.
var _seam_policy: Dictionary = {}


func _ready() -> void:
	_layout = TownLayoutScript.build_inn_green_district()
	_manifest = load_manifest()
	_seam_policy = load_seam_policy()
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


# Parse the manifest's seam_policy block (decision 016 render contract). Same
# text-manifest path as load_manifest (never an image-load). Returns {} if the
# manifest is missing or carries no seam_policy, in which case the seam layer and
# tonal grade degrade to no-ops and the export gate reports the absent contract.
static func load_seam_policy() -> Dictionary:
	var file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY or not parsed.has("seam_policy"):
		return {}
	return parsed["seam_policy"]


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
# sampled once across the district and blends them by the BAKED lane mask +
# density textures (decision 011).
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


# Build the ground ShaderMaterial: wire the two painterly plates, the two BAKED
# lane data textures (decision 011: the offline-baked mask + density, loaded via
# ResourceLoader, NOT a runtime-rasterized ImageTexture), and the tuning
# uniforms. A resource that fails to resolve leaves that sampler unset (the
# shader still runs); the export gate is the load-bearing proof the real assets
# ship and load off the packed bundle.
func _build_ground_material() -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = GroundShader
	mat.set_shader_parameter("grass_tex", _load_res(GRASS_PLATE_PATH))
	mat.set_shader_parameter("dirt_tex", _load_res(DIRT_PLATE_PATH))
	mat.set_shader_parameter("lane_mask", _load_res(LANE_MASK_PATH))
	mat.set_shader_parameter("lane_density", _load_res(LANE_DENSITY_PATH))
	mat.set_shader_parameter("dirt_detail", _load_res(DIRT_DETAIL_PATH))
	mat.set_shader_parameter("footprint_field", _load_res(FOOTPRINT_FIELD_PATH))
	mat.set_shader_parameter("grid_size", Vector2(_layout.width, _layout.height))
	mat.set_shader_parameter("plate_repeat", GROUND_PLATE_REPEAT)
	return mat


# Grounding-shadow layer (decision 016 D1). RETIRES the generic symmetric
# shadow_decal ellipse (which read pasted-on) in favor of each object's baked
# basal-alpha CONTACT + SHORT directional CAST masks, drawn on the shared
# ShadowLayer that sits between GroundLayer and World, so every shadow renders
# BELOW every sprite (a per-object node at the object's own z would paint A's
# shadow across B's roof, decision 016). The masks share their sprite's
# dimensions and frame, so they anchor exactly like the object sprite
# (position = projected contact point, offset = -anchor) and land pixel-aligned
# under it. Their shadow shape lives in ALPHA; we draw them flat-black scaled by
# bounded strengths. The crown (overhanging foliage, no ground contact) and any
# kit without a seam record are skipped.
func _build_shadows() -> void:
	var shadows: Dictionary = _seam_policy.get("shadows", {})
	if shadows.is_empty():
		push_warning("village seam_policy.shadows missing; grounding shadows skipped")
		return
	for placement in _layout.placements:
		if placement.kind == "crown":
			continue
		var record: Variant = _manifest.get(placement.id)
		if record == null or not shadows.has(placement.id):
			# No manifest anchor or no baked seam for this kit: skip its shadow.
			# crown_foliage legitimately has no seam record (decision 016).
			continue
		var seam: Dictionary = shadows[placement.id]
		var contact_cell := Iso.building_contact_cell(placement.cell, placement.footprint)
		var contact_screen := Iso.cell_to_screen(contact_cell)
		var anchor: Array = record["anchor_px"]
		var offset := Vector2(-float(anchor[0]), -float(anchor[1]))
		# Cast first (the wider, lighter grounding pool), then contact on top (the
		# tight dark core), so the anchor deepens rather than the far cast edge.
		_add_seam_sprite(seam.get("cast", ""), contact_screen, offset, CAST_STRENGTH)
		_add_seam_sprite(seam.get("contact", ""), contact_screen, offset, CONTACT_STRENGTH)


# Draw one baked seam mask (contact or cast) as a flat-black, alpha-shaped
# grounding pool on the ShadowLayer. The mask is a full-sprite-sized RGBA whose
# alpha carries the shadow shape; modulating black at `strength` scales that
# alpha into the ground without introducing any color. A path that does not
# resolve is skipped (the export gate asserts the declared seam masks ship).
func _add_seam_sprite(png_rel: String, position: Vector2, offset: Vector2, strength: float) -> void:
	if png_rel == "":
		return
	var tex := _load_res(ASSET_DIR + png_rel) as Texture2D
	if tex == null:
		push_warning("village seam mask did not resolve: %s" % png_rel)
		return
	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.centered = false
	sprite.position = position
	sprite.offset = offset
	sprite.modulate = Color(0.0, 0.0, 0.0, strength)
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
		# Per-kit tonal coherence grade (decision 016 D4). A bounded, guarded
		# nudge toward the manifest scene-key target; the CanvasModulate stays the
		# fixed final grade. No target -> no material (ungraded), which keeps the
		# scene rendering if the contract is partial.
		var tonal := _build_tonal_material(texture, placement.id, placement.kind)
		if tonal != null:
			sprite.material = tonal
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


# Resolve the per-kit tonal target (decision 016 D4) for a placement from
# seam_policy.tonal_targets. flora_kits carries per-id overrides for the five
# flora sprites; the generic kind buckets cover everything else. Returns {} if no
# target applies (grade becomes a no-op).
func _resolve_tonal_target(kit_id: String, kind: String) -> Dictionary:
	var targets: Dictionary = _seam_policy.get("tonal_targets", {})
	if targets.is_empty():
		return {}
	var flora_kits: Dictionary = targets.get("flora_kits", {})
	if flora_kits.has(kit_id):
		return flora_kits[kit_id]
	var bucket := ""
	match kind:
		"building_anchor", "building", "cottage":
			bucket = "building"
		"fence", "sign":
			bucket = "wood_prop"
		"rock":
			bucket = "stone"
		"tree", "bush", "crown":
			bucket = "flora"
		"flower":
			bucket = "flower"
		_:
			bucket = ""
	if bucket != "" and targets.has(bucket):
		return targets[bucket]
	return {}


# Build the guarded tonal-grade ShaderMaterial for one object sprite (decision
# 016 D4). Measures the sprite's own midtone, computes a strength-damped,
# clamped per-channel multiply toward the manifest target midtone, and wires the
# highlight / saturation guards from the target. Returns null when no target
# applies (the sprite then renders ungraded).
func _build_tonal_material(texture: Texture2D, kit_id: String, kind: String) -> ShaderMaterial:
	var target := _resolve_tonal_target(kit_id, kind)
	if target.is_empty() or not target.has("mid_rgb"):
		return null
	var highlight_guard_255 := float(target.get("highlight_guard", 255))
	var src := _measure_mid(texture, highlight_guard_255)
	if src == Vector3.ZERO:
		return null
	var tgt_arr: Array = target["mid_rgb"]
	var tgt := Vector3(float(tgt_arr[0]), float(tgt_arr[1]), float(tgt_arr[2]))
	# Per-channel move from measured src toward target, damped by TONAL_STRENGTH
	# and clamped so no kit is pushed to an extreme.
	var mul := Vector3(
		_tonal_channel(tgt.x, src.x),
		_tonal_channel(tgt.y, src.y),
		_tonal_channel(tgt.z, src.z))

	var mat := ShaderMaterial.new()
	mat.shader = ObjectShader
	mat.set_shader_parameter("tonal_mul", mul)
	mat.set_shader_parameter("highlight_guard", clampf(highlight_guard_255 / 255.0, 0.0, 1.0))
	mat.set_shader_parameter("guard_softness", GUARD_SOFTNESS)
	# saturation_guard is optional (flowers only); >= 1.0 disables the guard.
	var sat_guard := float(target.get("saturation_guard", 255))
	mat.set_shader_parameter("saturation_guard", clampf(sat_guard / 255.0, 0.0, 1.5) if sat_guard < 255 else 1.5)
	return mat


# One channel of the tonal multiply: damp the target/src ratio toward 1.0 by
# TONAL_STRENGTH, then clamp to the bounded range.
static func _tonal_channel(target_c: float, src_c: float) -> float:
	if src_c <= 0.0:
		return 1.0
	var ratio := target_c / src_c
	var damped := 1.0 + (ratio - 1.0) * TONAL_STRENGTH
	return clampf(damped, TONAL_MUL_LO, TONAL_MUL_HI)


# Measure a sprite's midtone: the mean RGB (0..255) of its opaque, non-highlight,
# non-shadow pixels. This is the source the D4 grade moves toward the target. A
# pure function of the committed texture, so the grade is deterministic. Returns
# Vector3.ZERO if no pixels fall in the mid band (grade becomes a no-op).
static func _measure_mid(texture: Texture2D, highlight_guard_255: float) -> Vector3:
	var image := texture.get_image()
	if image == null:
		return Vector3.ZERO
	var w := image.get_width()
	var h := image.get_height()
	var hi := clampf(highlight_guard_255, 1.0, 255.0) / 255.0
	var sum := Vector3.ZERO
	var count := 0
	for y in range(h):
		for x in range(w):
			var px := image.get_pixel(x, y)
			if px.a < 0.5:
				continue
			var lum := px.r * 0.299 + px.g * 0.587 + px.b * 0.114
			if lum <= 0.098 or lum >= hi:
				continue
			sum += Vector3(px.r, px.g, px.b)
			count += 1
	if count == 0:
		return Vector3.ZERO
	return (sum / float(count)) * 255.0


func _build_camera_rig() -> void:
	_camera_rig = CameraRigScript.new()
	_camera_rig.name = "CameraRig2D"
	_world.add_child(_camera_rig)
	_camera_rig.setup_free(_layout)


# Accessor for the export/capture gate (decision 009 items 2, 9). Not used in
# interactive play.
func camera_rig() -> CameraRigScript:
	return _camera_rig
