extends SceneTree
var age := 0.0
func _initialize() -> void: _run.call_deferred()
func _process(delta: float) -> bool:
	age += delta
	if age>90: push_error("Launcher check timed out"); quit(1)
	return false
func _run() -> void:
	var main = load("res://boot.tscn").instantiate()
	root.add_child(main)
	await create_timer(2).timeout
	if not main.launch_panel.visible: push_error("Missing join screen"); quit(1); return
	root.get_texture().get_image().save_png("/tmp/shared06-launcher.png")
	for button in main.launch_panel.find_children("*","Button",true,false):
		if button.text == "Connection settings": button.pressed.emit(); break
	if main.launch_panel.visible or not main.connection_panel.visible: push_error("Connection settings did not open"); quit(1); return
	main.connection_panel.hide()
	main.address.text = "127.0.0.1"
	main.port.value = 17779
	main.credentials[main.profiles[main.profile.selected]] = FileAccess.get_file_as_string("/tmp/shared06-packaged-profile/owner.credential")
	main.launch_panel.show()
	for button in main.launch_panel.find_children("*","Button",true,false):
		if button.text == "Join village": button.pressed.emit(); break
	while main.link.snapshot.is_empty(): await process_frame
	if main.launch_panel.visible: push_error("Join screen remained over the world"); quit(1); return
	main.hud._open("Character")
	await create_timer(1).timeout
	root.get_texture().get_image().save_png("/tmp/shared06-launcher-joined.png")
	print("LAUNCHER PASSED: visible destination/build, settings, Join button, accepted connection dismisses launcher")
	quit()
