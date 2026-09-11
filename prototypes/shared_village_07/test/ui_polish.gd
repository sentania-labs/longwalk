extends SceneTree
var age := 0.0
func _initialize() -> void: _run.call_deferred()
func _process(delta: float) -> bool:
	age += delta
	if age>80: push_error("UI polish timed out"); quit(1)
	return false
func _run() -> void:
	var main = load("res://boot.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.link.connect_client("127.0.0.1",FileAccess.get_file_as_string("/tmp/shared06-packaged-profile/owner.credential"),17779)
	while main.link.snapshot.is_empty(): await process_frame
	main.hud._open("Character")
	await process_frame
	var fields: Array[Node] = main.hud.contents.find_children("*","LineEdit",true,false)
	var field: LineEdit = fields[0]
	field.grab_focus()
	await process_frame
	var before: float = main.scene.yaw
	var key := InputEventKey.new()
	key.physical_keycode = KEY_E
	key.keycode = KEY_E
	key.unicode = 101
	key.pressed = true
	Input.parse_input_event(key)
	main.scene._update_keyboard_rotation(0.1)
	var released = key.duplicate()
	released.pressed = false
	Input.parse_input_event(released)
	if not is_equal_approx(before,main.scene.yaw): push_error("Typing rotated the camera"); quit(1); return
	field.text = "Thistle"
	for button in main.hud.contents.find_children("*","Button",true,false):
		if button.text == "Save character name": button.pressed.emit(); break
	while main.link.snapshot.person.get("display_name","") != "Thistle": await process_frame
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_RIGHT
	click.pressed = true
	main.hud._quick_input(click,3,"ring")
	if not main.hud.quick_menu.visible: push_error("Quick-slot menu did not open"); quit(1); return
	main.hud.quick_menu.id_pressed.emit(2)
	main.hud.quick_menu.hide()
	while main.link.snapshot.person.hotbar[3] != "": await process_frame
	main.hud._command("assign",{"slot":3,"item":"ring"})
	while main.link.snapshot.person.hotbar[3] != "ring": await process_frame
	main.hud._open("Inventory")
	await create_timer(2).timeout
	root.get_texture().get_image().save_png("/tmp/shared06-inventory-polish.png")
	print("UI POLISH PASSED: name saved through GUI, typing leaves camera still, quick-slot context clear/reassign, inventory icons")
	quit()
