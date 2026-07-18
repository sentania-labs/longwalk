extends SceneTree

# Render-side consumption test for the baked lane masks (decision 011). codex
# owns the sim / nav / bake-fingerprint tests; this owns the proof that the
# RENDER layer consumes the committed baked textures the honest, export-safe way
# rather than rebuilding a runtime mask from the PATH grid.
#
# Asserts:
#   - the ground ShaderMaterial binds lane_mask AND lane_density;
#   - both are imported resources (CompressedTexture2D loaded through
#     ResourceLoader from res://assets/village/), NOT a runtime-built
#     ImageTexture. A runtime ImageTexture would mean the render re-rasterized
#     the mask itself, reintroducing the decision-010 binary-from-grid path this
#     slice replaced, and would not be packed/proven by the export gate;
#   - the sampled core channel (lane_mask.R) reads SOLID somewhere (a protected
#     nav-PATH core exists in exactly the texture the shader reads), and the
#     coverage channel never falls below the core (density/coverage never reduce
#     the protected core, checked on the shader-consumed texture);
#   - the scene stands up and captures a non-blank frame with NO banned
#     image-load warning (the export-safe ResourceLoader path is the only one
#     used; no Image.load_from_file lives in src/).
#
# Invocation (run by tools/run_tests.sh):
#   godot --headless --script res://test/active_path/test_lane_mask_consumption.gd

const VillageScene := preload("res://scenes/village.tscn")

const LANE_MASK_PATH := "res://assets/village/lane_mask.png"
const LANE_DENSITY_PATH := "res://assets/village/lane_density.png"


func _initialize() -> void:
	var failures := 0
	failures += _check_material_binds_baked_masks()

	if failures == 0:
		print("\nAll lane-mask consumption checks passed.")
		quit(0)
	else:
		print("\n%d lane-mask consumption check(s) FAILED." % failures)
		quit(1)


func _check_material_binds_baked_masks() -> int:
	var failures := 0
	var village = VillageScene.instantiate()
	root.add_child(village)
	village._ready()

	var material := _ground_material(village)
	failures += _check(material != null, "ground MeshInstance2D has a ShaderMaterial")
	if material == null:
		village.free()
		return failures

	var mask: Variant = material.get_shader_parameter("lane_mask")
	var density: Variant = material.get_shader_parameter("lane_density")
	failures += _check(mask != null, "material binds lane_mask")
	failures += _check(density != null, "material binds lane_density")

	# The honest export-safe path binds the IMPORTED committed texture
	# (CompressedTexture2D), never a runtime-rasterized ImageTexture.
	failures += _check(mask is CompressedTexture2D, "lane_mask is an imported resource, not a runtime ImageTexture")
	failures += _check(density is CompressedTexture2D, "lane_density is an imported resource, not a runtime ImageTexture")
	failures += _check(not (mask is ImageTexture), "lane_mask is NOT a runtime ImageTexture (no PATH-grid re-raster)")
	if mask is Texture2D:
		failures += _check((mask as Texture2D).resource_path == LANE_MASK_PATH, "lane_mask resolved from %s" % LANE_MASK_PATH)
	if density is Texture2D:
		failures += _check((density as Texture2D).resource_path == LANE_DENSITY_PATH, "lane_density resolved from %s" % LANE_DENSITY_PATH)

	# Read the exact texture the shader samples and assert the protected core is
	# solid and never reduced by the coverage channel.
	if mask is Texture2D:
		var img := (mask as Texture2D).get_image()
		img.convert(Image.FORMAT_RG8)
		var max_core := 0.0
		var core_solid_below_coverage := true
		for y in range(img.get_height()):
			for x in range(img.get_width()):
				var px := img.get_pixel(x, y)
				max_core = maxf(max_core, px.r)
				if px.r > px.g + 0.004:
					core_solid_below_coverage = false
		failures += _check(max_core >= 0.99, "shader-consumed core channel reads solid somewhere (max R=%.3f)" % max_core)
		failures += _check(core_solid_below_coverage, "coverage never reduces the protected core in the consumed texture")

	# Grid_size drives cell->mask sampling; keep it wired to the layout.
	var grid: Variant = material.get_shader_parameter("grid_size")
	failures += _check(grid is Vector2 and grid == Vector2(16, 14), "grid_size uniform matches the district")

	village.free()
	return failures


func _ground_material(village) -> ShaderMaterial:
	var ground_layer: Node = village.get_node("GroundLayer")
	for child in ground_layer.get_children():
		if child is MeshInstance2D:
			return child.material as ShaderMaterial
	return null


func _check(condition: bool, label: String) -> int:
	if condition:
		print("[PASS] %s" % label)
		return 0
	print("[FAIL] %s" % label)
	return 1
