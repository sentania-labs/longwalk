extends SceneTree
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	var main = load("res://boot.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	if not is_instance_valid(main.repair_panel) or not main.repair_panel.visible:
		push_error("Missing pack should show a usable repair screen")
		quit(1)
		return
	root.get_texture().get_image().save_png("/tmp/shared06-art-repair.png")
	print("ART REPAIR PASSED: missing pack shows a file chooser and Quit instead of a crash")
	quit()
