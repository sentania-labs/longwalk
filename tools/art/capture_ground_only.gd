extends SceneTree

# Fast UNOBSTRUCTED ground-only capture for decision-012 tuning (claude render
# slice). Stands up the village scene, HIDES the shadow + world layers so only
# the ground quad renders (Gate 3's "free of building/shadow occlusion"), and
# captures at 1x, 0.5x, 2x plus a sub-pixel-panned 0.5x pair for the shimmer
# gate. The dirt-detail amplitude is overridden live from the DIRT_AMP env var
# so a tuning sweep does not require re-editing + re-importing the shader each
# step. Dev tool under tools/art/, never packed into the game asset path.
#
# Needs a real GL context (xvfb-run), same as the export gate; --headless uses
# the dummy driver and would capture nothing.

const VillageScene := preload("res://scenes/village.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var out_dir := OS.get_environment("GROUND_CAPTURE_DIR")
	if out_dir.is_empty():
		push_error("GROUND_CAPTURE_DIR not set")
		quit(1)
		return
	var amp_env := OS.get_environment("DIRT_AMP")
	var core_env := OS.get_environment("DIRT_CORE_AMP")
	var edge_env := OS.get_environment("DIRT_EDGE_AMP")

	var village = VillageScene.instantiate()
	root.add_child(village)
	current_scene = village
	await process_frame
	await process_frame

	# Hide everything but the ground so the crops are pure ground plane.
	for child in village.get_children():
		if child.name != "GroundLayer":
			if child is CanvasItem:
				child.visible = false

	# Live amplitude override for the sweep.
	var ground_layer = village.get_node("GroundLayer")
	var mesh = ground_layer.get_child(0)
	var mat: ShaderMaterial = mesh.material
	if not amp_env.is_empty():
		mat.set_shader_parameter("detail_shoulder_amp", float(amp_env))
	if not core_env.is_empty():
		mat.set_shader_parameter("detail_core_amp", float(core_env))
	if not edge_env.is_empty():
		mat.set_shader_parameter("edge_break_amp", float(edge_env))
	var used_amp: float = mat.get_shader_parameter("detail_shoulder_amp")
	print("detail_shoulder_amp = %.3f" % used_amp)

	var rig = village.camera_rig()
	rig.make_current()
	var base_pos: Vector2 = rig.position

	for z in [0.5, 1.0, 2.0]:
		rig.set_zoom_for_capture(z)
		rig.position = base_pos
		await process_frame
		await RenderingServer.frame_post_draw
		var img := root.get_texture().get_image()
		img.save_png(out_dir.path_join("ground-%sx.png" % z))
		print("wrote ground-%sx.png" % z)

	# Shimmer pan: 0.5x, shifted by half a screen pixel. A crawling
	# high-frequency band changes value between the two sub-pixel phases.
	rig.set_zoom_for_capture(0.5)
	rig.position = base_pos
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out_dir.path_join("ground-0.5x-panA.png"))
	rig.position = base_pos + Vector2(1.0, 0.0)  # 1 world px = 0.5 screen px at 0.5x
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out_dir.path_join("ground-0.5x-panB.png"))
	print("wrote shimmer pan pair")
	quit(0)
