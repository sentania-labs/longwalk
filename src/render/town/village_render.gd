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
const ShadowShader := preload("res://src/render/town/shadow.gdshader")
const FloraBaseShader := preload("res://src/render/town/flora_base.gdshader")

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
# at the same anchored position. They carry the shadow shape in ALPHA (RGB is 0).
#
# Second-iteration D1 (agy QA: the masks read as HARD, too-dark painted polygons).
# We no longer draw them as flat pure-black Sprite2Ds. Each shadow sprite carries
# shadow.gdshader, which FEATHERS the mask's hard alpha edge into the ground and
# tints it a dark desaturated earth-brown (SHADOW_COLOR) instead of 0,0,0, so the
# pool reads as cast light-occlusion on soil, not a pasted black shape. CONTACT is
# the tight dark core hugging the base (small feather); CAST is the wider short
# grounding pool (feathers more). Strengths are lowered toward the spike's soft
# shadow value.
const CONTACT_STRENGTH := 0.55
const CAST_STRENGTH := 0.30
# Feather (texel spread of the Gaussian in shadow.gdshader). The wider cast pool
# grades over a broader band than the tight contact core (rubric D1: cast feathers
# more than contact).
const CONTACT_FEATHER_PX := 1.2
const CAST_FEATHER_PX := 2.8
# Dark desaturated earth-brown the shadows grade toward (never pure black), so
# they read as light-occlusion on soil at the spike's value, not painted polygons.
const SHADOW_COLOR := Color(0.09, 0.07, 0.05)
# Sign cast tell (agy QA D1): a hanging sign should not throw a hard directional
# ground polygon. We SUPPRESS the standalone sign's cast entirely and keep only a
# softened contact, per the rubric ("a small, soft contact is fine; the hard
# directional polygon is the defect").
const SIGN_CAST_STRENGTH := 0.0
const BASE_VEGETATION_SEED := 17017
# Balanced kit table (decision 017 tuning, gap 2 repetition): the two bushes and
# the two flower clusters carry equal weight so no single silhouette (the round
# bush_a, the tall flower_cluster_b) recurs at every clump; rocks stay sparse as
# accents. Selection is `(_mix_candidate >> 8) % size`, uniform over the index,
# so listed count == weight.
const BASE_VEGETATION_KITS := ["bush_a", "bush_b", "bush_b", "flower_cluster_a", "flower_cluster_b", "flower_cluster_a", "rock_a", "bush_a", "flower_cluster_b", "rock_b"]
# Wider scale spread (gap 2): five steps instead of three so adjacent clumps
# differ in size as well as kit; kept in the weed band, not diorama scale.
const BASE_VEGETATION_SCALES := [0.42, 0.50, 0.56, 0.64, 0.72]
const FLORA_BASE_COLOR := Color(0.24, 0.22, 0.09)

# Per-kit tonal grade (decision 016 D4). TONAL_STRENGTH damps the move from each
# sprite's measured midtone toward its manifest target midtone (0 = no grade,
# 1 = land exactly on target); kept below 1 so the grade closes the tonal
# disparity into one scene key without fully recoloring an object. Each channel
# multiplier is clamped to [TONAL_MUL_LO, TONAL_MUL_HI] so no single kit is
# pushed to an extreme even where its source midtone is far from target.
const TONAL_STRENGTH := 0.50
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
# Shadow-lift / de-contrast (decision 016 D4, second iteration). agy QA: the
# buildings read dark AND contrasty (near-black slate roofs and heavy timbers)
# while the ground is a brighter key, so structures look pasted on. A uniform
# tonal multiply cannot lift the dark roofs without blowing the bright plaster on
# the same sprite, so object.gdshader ALSO lifts only the SHADOW band toward a
# warm scene-key tint. These are the per-BUCKET lift amounts (0 = disabled):
# structures (buildings, wood props, stone) lift; flora and flowers do NOT (their
# dark floor is owned by the tonal clamp, and lifting foliage shadows would grey
# it). The lift is strongest on buildings, whose roofs are the worst offender.
const SHADOW_LIFT_BUILDING := 0.13
const SHADOW_LIFT_WOOD := 0.08
const SHADOW_LIFT_STONE := 0.06
# Highlight ceiling / anti-wash (decision 016 D1 iter3). The per-kit tonal grade is
# a proportional MULTIPLY, so it brightens the light end of a sprite hardest. On
# the smithy the already-light foreground props under the awning (the pale
# grindstone, lit workbench top, light stone footings) sit in the mid-to-light
# band below the manifest highlight_guard, so the warm grade pushed them from ~155
# luminance into a glaring pale ~185 patch that read as a blown light polygon on
# the ground (agy QA #003 D1, orchestrator-confirmed regression from the D4 grade).
# object.gdshader soft-compresses GRADED luminance above this ceiling back toward
# it (hue preserved), capping the wash while leaving everything below the ceiling,
# so the D4 shadow-lift on the dark slate roofs and timbers is fully preserved
# (their luminance is well under the ceiling). Applied to the STRUCTURE buckets
# that carry the multiply wash (same set as the shadow-lift); flora/flowers pass
# 1.0 (disabled) so their vivid highlights are untouched. 0.66 * 255 ~= 168 caps
# the awning props at the surrounding-ground key band instead of 2x above it.
const GRADE_CEILING_STRUCTURE := 0.66
const GRADE_CEILING_SOFT := 0.12
# Ground key-warming (decision 016 D4, second iteration). agy QA: the buildings
# read dark/contrasty against a flatter, brighter yellow-green ground, so the two
# do not share one lighting key. Alongside the stronger per-kit object grade
# (which lifts the buildings toward the warm scene-key target), we nudge the
# ground layer a touch warmer/less-cold-green (drop blue, ease green) so its key
# meets the buildings' instead of sitting apart. This is a bounded per-layer
# modulate, NOT the global village CanvasModulate (the fixed final grade) and NOT
# a plate-pixel edit (codex owns the plates).
const GROUND_KEY_MODULATE := Color(1.0, 0.985, 0.93)

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
var _render_instances: Array = []


func _ready() -> void:
	_layout = TownLayoutScript.build_inn_green_district()
	_manifest = load_manifest()
	_seam_policy = load_seam_policy()
	_render_instances = _build_render_instances()
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
	# Warm the ground key a touch toward the buildings' (decision 016 D4). A
	# per-layer modulate, applied on the ground MeshInstance2D so it grades only the
	# terrain, not the shadows or objects on their own layers.
	ground.self_modulate = GROUND_KEY_MODULATE
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
	for instance in _render_instances:
		if instance.kind == "crown":
			continue
		var record: Variant = _manifest.get(instance.kit_id)
		if record == null or not shadows.has(instance.kit_id):
			# No manifest anchor or no baked seam for this kit: skip its shadow.
			# crown_foliage legitimately has no seam record (decision 016).
			continue
		var seam: Dictionary = shadows[instance.kit_id]
		var contact_cell: Vector2 = instance.contact
		var contact_screen := Iso.cell_to_screen(contact_cell)
		var anchor: Array = record["anchor_px"]
		var scale: float = instance.scale
		var offset := Vector2(-float(anchor[0]), -float(anchor[1]))
		# The standalone sign throws a hard directional cast polygon (agy QA D1); we
		# suppress its cast and keep only the softened contact. Every other object
		# gets both, cast first (the wider, lighter grounding pool), then contact on
		# top (the tight dark core), so the anchor deepens, not the far cast edge.
		var cast_strength := SIGN_CAST_STRENGTH if instance.kind == "sign" else CAST_STRENGTH
		if instance.kind in ["tree", "bush", "flower"]:
			_add_flora_base(seam.get("contact", ""), contact_screen, offset, scale, instance.kind)
		_add_seam_sprite(seam.get("cast", ""), contact_screen, offset, scale, cast_strength, CAST_FEATHER_PX)
		_add_seam_sprite(seam.get("contact", ""), contact_screen, offset, scale, CONTACT_STRENGTH, CONTACT_FEATHER_PX)


# Draw one baked seam mask (contact or cast) as a FEATHERED, earth-brown,
# alpha-shaped grounding pool on the ShadowLayer (decision 016 D1, second
# iteration). The mask is a full-sprite-sized RGBA whose alpha carries the shadow
# shape; shadow.gdshader blurs that alpha into the ground (feather_px wider for
# the cast) and tints it SHADOW_COLOR at `strength`, so the pool grounds the
# object without the hard black polygon the first cut showed. strength <= 0 skips
# the sprite entirely (the suppressed sign cast). A path that does not resolve is
# skipped (the export gate asserts the declared seam masks ship).
func _add_seam_sprite(png_rel: String, position: Vector2, offset: Vector2, scale: float, strength: float, feather_px: float) -> void:
	if png_rel == "" or strength <= 0.0:
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
	sprite.scale = Vector2(scale, scale)
	var mat := ShaderMaterial.new()
	mat.shader = ShadowShader
	mat.set_shader_parameter("shadow_color", Vector3(SHADOW_COLOR.r, SHADOW_COLOR.g, SHADOW_COLOR.b))
	mat.set_shader_parameter("feather_px", feather_px)
	mat.set_shader_parameter("strength", strength)
	# Whole-layer fade hook (replaces the shadow shader's old MODULATE.a, invalid in
	# Godot 4.3). No caller fades the grounding-shadow layer today, so this is the
	# no-fade identity; it is the explicit seam for a future layer fade.
	mat.set_shader_parameter("layer_fade", 1.0)
	sprite.material = mat
	_shadow_layer.add_child(sprite)


func _add_flora_base(png_rel: String, position: Vector2, offset: Vector2, scale: float, kind: String) -> void:
	var tex := _load_res(ASSET_DIR + png_rel) as Texture2D
	if tex == null:
		return
	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.centered = false
	sprite.position = position
	sprite.offset = offset
	sprite.scale = Vector2(scale, scale)
	var mat := ShaderMaterial.new()
	mat.shader = FloraBaseShader
	mat.set_shader_parameter("base_color", FLORA_BASE_COLOR)
	mat.set_shader_parameter("radius_px", 1.4 if kind == "flower" else 2.4)
	mat.set_shader_parameter("strength", 0.18 if kind == "flower" else 0.24)
	sprite.material = mat
	_shadow_layer.add_child(sprite)


# Build one sprite per district placement, joined to the manifest by id. The
# sprite's manifest anchor_px is placed on the projected ground-contact point
# (the same anchor contract _build_buildings uses in starter_town.gd, expressed
# in per-pixel manifest terms). World objects are depth-sorted; crowns are
# lifted into a separate foreground band.
func _build_objects() -> void:
	var world_sorts: Array = []
	var crown_sprites: Array = []

	for instance in _render_instances:
		var record: Variant = _manifest.get(instance.kit_id)
		if record == null:
			# No manifest entry for this kit-id: skip drawing it, the export gate
			# reports the missing asset. Rendering continues so a partial manifest
			# still produces a scene to inspect.
			push_warning("no manifest record for placement id '%s'" % instance.kit_id)
			continue

		var texture := _load_texture(record["png"])
		if texture == null:
			push_warning("village texture did not resolve: %s" % record["png"])
			continue

		var contact_cell: Vector2 = instance.contact
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
		sprite.scale = Vector2(instance.scale, instance.scale)
		# Deterministic horizontal-flip variation for derived vegetation (decision
		# 017 tuning, gap 2): flip_h mirrors the texture within its unchanged rect,
		# so the ground-contact anchor column moves to (native_width - anchor_x);
		# re-seat offset.x there to keep the base pinned to contact_screen.
		if instance.get("flip", false):
			sprite.flip_h = true
			var native: Array = record.get("native_px", [float(anchor[0]) * 2.0, float(anchor[1])])
			sprite.offset.x = float(anchor[0]) - float(native[0])
		sprite.set_meta("kit_id", instance.kit_id)
		sprite.set_meta("derived_base_vegetation", instance.derived)
		# Per-kit tonal coherence grade (decision 016 D4). A bounded, guarded
		# nudge toward the manifest scene-key target; the CanvasModulate stays the
		# fixed final grade. No target -> no material (ungraded), which keeps the
		# scene rendering if the contract is partial.
		var tonal := _build_tonal_material(texture, instance.kit_id, instance.kind)
		if tonal != null:
			sprite.material = tonal
		_world.add_child(sprite)

		if instance.kind == "crown":
			crown_sprites.append(sprite)
		else:
			# Per-instance depth id: a repeated kit-id (fence_section) still gets a
			# unique, deterministic tie key from the placement index.
			world_sorts.append({
				"key": Iso.depth_key(contact_cell, instance.sort_id),
				"node": sprite,
			})

	world_sorts.sort_custom(func(a, b): return a.key < b.key)
	for i in range(world_sorts.size()):
		world_sorts[i].node.z_index = 1 + i

	# Foreground crown band: always above every world object (decision 009 item
	# 9). Ordered among themselves by contact for stable layering.
	for i in range(crown_sprites.size()):
		crown_sprites[i].z_index = CROWN_Z_BASE + i


func _build_render_instances() -> Array:
	var out: Array = []
	for i in range(_layout.placements.size()):
		var p = _layout.placements[i]
		out.append({"kit_id": p.id, "kind": p.kind, "contact": Iso.building_contact_cell(p.cell, p.footprint),
			"scale": 1.0, "flip": false, "sort_id": "%s#%d" % [p.id, i], "derived": false})
	for derived in derive_base_vegetation(_layout.placements, _seam_policy):
		out.append({"kit_id": derived.kit_id, "kind": derived.kind, "contact": derived.contact,
			"scale": derived.scale, "flip": derived.flip, "sort_id": derived.sort_id, "derived": true})
	return out


# Pure render-side placement. Candidate coordinates are canonical quarter-cell
# integers, so selection never depends on building or candidate visit order.
static func derive_base_vegetation(placements: Array, seam_policy: Dictionary) -> Array:
	var out: Array = []
	var doors: Dictionary = seam_policy.get("doors", {})
	for p in placements:
		if p.kind not in ["building_anchor", "building", "cottage", "tree"]:
			continue
		# A tree has no stone foundation to hug: veg on its rear/far perimeter reads
		# as loose scatter on open grass (gap 1). Restrict it to a single tight
		# front-base clump (facing corners only), matching the spike's trunk-base
		# planting instead of a full perimeter ring.
		var is_tree: bool = p.kind == "tree"
		var candidates := _perimeter_candidates(p.cell, p.footprint)
		for candidate in candidates:
			var q: Vector2i = candidate.q
			var contact := Vector2(q) / 4.0
			if _inside_door_exclusion(p, contact, doors):
				continue
			if _overlaps_hard_object(contact, placements):
				continue
			var facing: bool = candidate.edge in ["south", "east"]
			if is_tree and (not facing or not candidate.corner):
				continue
			var mixed := _mix_candidate(BASE_VEGETATION_SEED, q)
			# Density profile (decision 017 tuning). Only the camera-facing edges
			# (south/east) carry the derived planting: those are the visible stone
			# foundation the veg hugs and creeps up. The rear (north/west) has no
			# visible wall, so anything placed there floats in the open lanes
			# between buildings (gap 1) rather than reading as foundation planting;
			# it is cut entirely (decision 017 item 4: no density behind the
			# building). On the facing edges, corners carry dense mixed clumps
			# toward the spike (gap 3) and mid-edges stay a controlled fill.
			var keep_limit: int = 0
			if facing:
				keep_limit = 92 if candidate.corner else 30
			# Force-keep the mandatory anchor only on a facing edge, so every
			# building still gets its two front foundation corners (the >=2-anchor
			# invariant) without a rear anchor stranded on open grass.
			var force_keep: bool = candidate.mandatory and facing
			if not force_keep and mixed % 100 >= keep_limit:
				continue
			var kit: String = BASE_VEGETATION_KITS[(mixed >> 8) % BASE_VEGETATION_KITS.size()]
			var kind := "flower" if kit.begins_with("flower") else ("bush" if kit.begins_with("bush") else "rock")
			out.append({"building": p.id, "kit_id": kit, "kind": kind, "contact": contact,
				"candidate_q": q, "mandatory": candidate.mandatory,
				"scale": BASE_VEGETATION_SCALES[(mixed >> 16) % BASE_VEGETATION_SCALES.size()],
				"flip": ((mixed >> 24) & 1) == 1,
				"sort_id": "derived:%d:%d:%s" % [q.x, q.y, kit]})
	out.sort_custom(func(a, b): return a.sort_id < b.sort_id)
	return out


static func _perimeter_candidates(cell: Vector2i, footprint: Vector2i) -> Array:
	# Hug the foundation: candidates sit ON the footprint boundary (offset 0), not
	# a quarter-cell outside it, so clumps creep UP the stone base instead of
	# sitting in front of it on open ground (decision 017 tuning, gap 1). The
	# perimeter is walked at quarter-cell resolution (step 1) so corner clumps can
	# pack tightly with distinct coordinates; the keep profile in
	# derive_base_vegetation thins the mid-edges back out.
	var x0 := cell.x * 4
	var y0 := cell.y * 4
	var x1 := (cell.x + footprint.x) * 4
	var y1 := (cell.y + footprint.y) * 4
	var out: Array = []
	for x in range(x0, x1 + 1):
		var cx: bool = x <= x0 + 1 or x >= x1 - 1
		out.append({"q": Vector2i(x, y0), "edge": "north", "mandatory": x == x0 or x == x1, "corner": cx})
		out.append({"q": Vector2i(x, y1), "edge": "south", "mandatory": x == x0 or x == x1, "corner": cx})
	for y in range(y0 + 1, y1):
		var cy: bool = y <= y0 + 1 or y >= y1 - 1
		out.append({"q": Vector2i(x0, y), "edge": "west", "mandatory": false, "corner": cy})
		out.append({"q": Vector2i(x1, y), "edge": "east", "mandatory": false, "corner": cy})
	return out


static func _inside_door_exclusion(p, contact: Vector2, doors: Dictionary) -> bool:
	if not doors.has(p.id):
		return false
	var uv: Array = doors[p.id].get("footprint_uv", [0.5, 1.0])
	var door := Vector2(p.cell) + Vector2(float(uv[0]) * p.footprint.x, float(uv[1]) * p.footprint.y)
	return contact.distance_to(door) < 0.65


static func _overlaps_hard_object(contact: Vector2, placements: Array) -> bool:
	for p in placements:
		if p.kind not in ["fence", "sign"]:
			continue
		var hard_contact := Iso.building_contact_cell(p.cell, p.footprint)
		if contact.distance_to(hard_contact) < 0.55:
			return true
	return false


static func _mix_candidate(seed: int, q: Vector2i) -> int:
	var value := seed ^ (q.x * 0x45d9f3b) ^ (q.y * 0x119de1f3)
	value = (value ^ (value >> 16)) * 0x45d9f3b
	value = (value ^ (value >> 16)) * 0x45d9f3b
	return absi(value ^ (value >> 16))


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
	# Per-item modulate (replaces the object shader's old MODULATE built-in, invalid
	# in Godot 4.3). Objects carry no per-sprite tint today, so this is white
	# (identity); it is the explicit seam a caller uses to tint or fade one sprite
	# without disturbing the tonal grade, applied exactly once so the texture is
	# never squared.
	mat.set_shader_parameter("item_modulate", Color(1.0, 1.0, 1.0, 1.0))
	mat.set_shader_parameter("tonal_mul", mul)
	mat.set_shader_parameter("highlight_guard", clampf(highlight_guard_255 / 255.0, 0.0, 1.0))
	mat.set_shader_parameter("guard_softness", GUARD_SOFTNESS)
	# saturation_guard is optional (flowers only); >= 1.0 disables the guard.
	var sat_guard := float(target.get("saturation_guard", 255))
	mat.set_shader_parameter("saturation_guard", clampf(sat_guard / 255.0, 0.0, 1.5) if sat_guard < 255 else 1.5)
	# Shadow-lift (decision 016 D4): lift only structures' shadow band toward the
	# warm key. Flora/flowers pass 0 so their dark floor stays owned by the clamp.
	mat.set_shader_parameter("shadow_lift", _shadow_lift_for(kind))
	# Highlight ceiling (decision 016 D1 iter3): cap the graded highlights on the
	# structure buckets so the multiply grade cannot wash their light props into a
	# blown pale patch. Flora/flowers pass 1.0 (disabled) to keep vivid highlights.
	mat.set_shader_parameter("grade_ceiling", _grade_ceiling_for(kind))
	mat.set_shader_parameter("grade_ceiling_soft", GRADE_CEILING_SOFT)
	return mat


# Per-bucket shadow-lift amount (decision 016 D4). Structures (buildings, wood
# props, stone) lift their dark roofs/timbers into the shared key; flora, flowers,
# and the crown do NOT (0), so foliage shadows are not greyed and the flora floor
# stays owned by the tonal clamp.
static func _shadow_lift_for(kind: String) -> float:
	match kind:
		"building_anchor", "building", "cottage":
			return SHADOW_LIFT_BUILDING
		"fence", "sign":
			return SHADOW_LIFT_WOOD
		"rock":
			return SHADOW_LIFT_STONE
		_:
			return 0.0


# Per-bucket highlight ceiling (decision 016 D1 iter3). The structure buckets that
# carry the proportional tonal-multiply wash (buildings, wood props, stone) cap
# their graded highlights so the grade cannot blow their light props into a pale
# patch; flora, flowers, and the crown return 1.0 (disabled) so their vivid
# highlights are untouched. Mirrors the structure set in _shadow_lift_for.
static func _grade_ceiling_for(kind: String) -> float:
	match kind:
		"building_anchor", "building", "cottage", "fence", "sign", "rock":
			return GRADE_CEILING_STRUCTURE
		_:
			return 1.0


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
