extends SceneTree

const StarterTownScene = preload("res://scenes/starter_town.tscn")

func _initialize() -> void:
	var failures := 0

	var town = StarterTownScene.instantiate()
	town._ready() # Force ready to build layout

	var canvas_modulate: CanvasModulate = null
	for child in town.get_children():
		if child is CanvasModulate:
			canvas_modulate = child
			break

	failures += _check(canvas_modulate != null, "Starter town has CanvasModulate")

	# Find a chimney smoke instance
	var smoke: CPUParticles2D = null
	var world = town.get_node("World")
	for child in world.get_children():
		if child is Sprite2D and child.has_meta("sprite_key") and child.get_meta("sprite_key") == "cottage_facade":
			for subchild in child.get_children():
				if subchild is CPUParticles2D and subchild.name == "ChimneySmoke":
					smoke = subchild
					break
			if smoke:
				break

	failures += _check(smoke != null, "Found ChimneySmoke on cottage facade")

	var grade_color: Color = canvas_modulate.color
	var smoke_modulate: Color = smoke.modulate

	print("\nCanvasModulate grade: ", grade_color)
	print("Smoke modulate: ", smoke_modulate)

	# Ensure the smoke texture is a GradientTexture2D
	var grad_tex = smoke.texture as GradientTexture2D
	failures += _check(grad_tex != null, "Smoke texture is GradientTexture2D")

	if grad_tex:
		var gradient = grad_tex.gradient
		failures += _check(gradient.colors.size() == 3, "Smoke gradient has 3 stops")

		# Expected authored hues from the instruction
		var expected_hues = [197.1, 190.0, 200.0]

		for i in range(gradient.colors.size()):
			var authored_color: Color = gradient.colors[i]
			var authored_hue = authored_color.h * 360.0
			var effective_color = authored_color * smoke_modulate * grade_color
			var effective_hue = effective_color.h * 360.0

			print("Stop %d (t=%.2f): authored hue = %.1f deg, effective hue = %.1f deg" % [i, gradient.offsets[i], authored_hue, effective_hue])

			# Verify effective hue is within 1 degree of authored hue (cool grey, not warm brown)
			failures += _check(abs(effective_hue - expected_hues[i]) < 1.0, "Stop %d effective hue remains cool" % i)

	town.free()

	if failures == 0:
		print("\nAll smoke grade checks passed.")
		quit(0)
	else:
		print("\n%d smoke grade check(s) FAILED." % failures)
		quit(1)

func _check(condition: bool, description: String) -> int:
	if condition:
		print("PASS: %s" % description)
		return 0
	push_error("FAIL: %s" % description)
	return 1
