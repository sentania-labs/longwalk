extends SceneTree

# Render-side R-channel consumption test for the baked footprint interaction
# field (decision 016 D2). The bake deterministically encodes the building-apron
# coverage in the field's R channel (docs/art/village-seam-bake.md: "R is
# building-apron coverage"); the worn-apron seam in ground.gdshader must consume
# that authored coverage, not re-derive the whole apron from G/B and leave R
# dead. codex's render review BLOCKED the first cut for exactly this: the shader
# read fp.g and fp.b only, and no test guarded render-side R consumption.
#
# This is that guard. It reads the ShaderMaterial the RENDER layer actually binds
# (not a copy of the file) and asserts, structurally, that the apron coverage is
# sourced from the footprint field's R channel and that the R-derived coverage
# feeds the apron mix. A regression that drops fp.r and rebuilds the ring purely
# from G/B (the reverted defect) fails here.
#
# Invocation (run by tools/run_tests.sh):
#   godot --headless --script res://test/active_path/test_footprint_apron_r.gd

const VillageScene := preload("res://scenes/village.tscn")


func _initialize() -> void:
	var failures := 0

	var village = VillageScene.instantiate()
	root.add_child(village)
	village._ready()

	var material := _ground_material(village)
	failures += _check(material != null, "ground MeshInstance2D has a ShaderMaterial")
	if material == null:
		village.free()
		_finish(failures)
		return

	failures += _check(material.get_shader_parameter("footprint_field") != null,
		"material binds footprint_field")

	var shader := material.shader
	failures += _check(shader != null, "ground material carries a Shader")
	if shader == null:
		village.free()
		_finish(failures)
		return

	# Strip comments so a token in a `// ... fp.r ...` note cannot masquerade as
	# real consumption. The regression we guard against is the IMPLEMENTATION
	# ignoring R, not the prose.
	var code := _strip_comments(shader.code)

	# The footprint field is sampled into a local (fp).
	var fp_var := _footprint_sample_var(code)
	failures += _check(fp_var != "", "shader samples footprint_field into a local var")

	if fp_var != "":
		var r_token := "%s.r" % fp_var
		var g_token := "%s.g" % fp_var
		var b_token := "%s.b" % fp_var
		# R must be consumed by the implementation, not just G/B (the exact defect
		# codex blocked: the ring was derived from G with R never read).
		failures += _check(code.contains(r_token),
			"apron implementation reads the footprint field R channel (%s)" % r_token)
		# The contract keeps G (edge falloff) and B (door threshold) in play too.
		failures += _check(code.contains(g_token),
			"apron still consumes G edge-distance (%s)" % g_token)
		failures += _check(code.contains(b_token),
			"apron still consumes B door-threshold (%s)" % b_token)

		# Structural chain: R -> apron coverage -> apron_cov. Assert the R read
		# reaches the apron_cov mix weight, so a cosmetic mention of fp.r that does
		# not actually feed coverage would not pass.
		failures += _check(_r_feeds_apron_cov(code, r_token),
			"the R-derived coverage feeds apron_cov (R is not dead)")

	village.free()
	_finish(failures)


# Return the local variable name the footprint field is sampled into, e.g. "fp"
# from `vec4 fp = texture(footprint_field, mask_uv);`. "" if not found.
func _footprint_sample_var(code: String) -> String:
	for raw_line in code.split("\n"):
		var line := raw_line.strip_edges()
		if line.contains("footprint_field") and line.contains("texture(") and line.contains("="):
			# form: <type> <name> = texture(footprint_field, ...);
			var lhs := line.get_slice("=", 0).strip_edges()
			var parts := lhs.split(" ", false)
			if parts.size() >= 2:
				return parts[parts.size() - 1]
	return ""


# Prove the R read is wired into the apron_cov coverage, not merely present. We
# walk the assignment chain: the var assigned from <fp>.r, then any var whose RHS
# uses it, until we reach a line that assigns apron_cov from an R-tainted term.
func _r_feeds_apron_cov(code: String, r_token: String) -> bool:
	var tainted := {}
	tainted[r_token] = true
	for raw_line in code.split("\n"):
		var line := raw_line.strip_edges()
		if not line.contains("=") or line.begins_with("//"):
			continue
		var lhs := line.get_slice("=", 0).strip_edges()
		var rhs := line.substr(line.find("=") + 1)
		var name := lhs
		var parts := lhs.split(" ", false)
		if parts.size() >= 2:
			name = parts[parts.size() - 1]
		var rhs_is_tainted := false
		for token in tainted.keys():
			if rhs.contains(token):
				rhs_is_tainted = true
				break
		if not rhs_is_tainted:
			continue
		if name == "apron_cov" or lhs == "apron_cov":
			return true
		tainted[name] = true
	return false


func _strip_comments(code: String) -> String:
	var out := ""
	for raw_line in code.split("\n"):
		var idx := raw_line.find("//")
		if idx >= 0:
			out += raw_line.substr(0, idx) + "\n"
		else:
			out += raw_line + "\n"
	return out


func _ground_material(village) -> ShaderMaterial:
	var ground_layer: Node = village.get_node("GroundLayer")
	for child in ground_layer.get_children():
		if child is MeshInstance2D:
			return child.material as ShaderMaterial
	return null


func _finish(failures: int) -> void:
	if failures == 0:
		print("\nAll footprint-apron R-consumption checks passed.")
		quit(0)
	else:
		print("\n%d footprint-apron R-consumption check(s) FAILED." % failures)
		quit(1)


func _check(condition: bool, label: String) -> int:
	if condition:
		print("[PASS] %s" % label)
		return 0
	print("[FAIL] %s" % label)
	return 1
