extends SceneTree
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	var main = load("res://boot.tscn").instantiate()
	root.add_child(main)
	await process_frame
	if not is_instance_valid(main.repair_panel): push_error("Expected repair screen"); quit(1); return
	main._accept_art_file("/tmp/shared06-bad-art.pck")
	if is_instance_valid(main.scene) or not main.art_message.text.contains("does not match"): push_error("Wrong pack was not rejected"); quit(1); return
	main._accept_art_file("/home/scott/codex/longwalk/prototypes/shared_village_06/build/Longwalk-Art-01.pck")
	await process_frame
	await process_frame
	if not is_instance_valid(main.scene) or is_instance_valid(main.repair_panel): push_error("Matching pack did not recover startup"); quit(1); return
	root.get_texture().get_image().save_png("/tmp/shared06-art-recovered.png")
	print("ART RECOVERY PASSED: mismatched pack rejected; selecting verified external pack starts village")
	quit()
