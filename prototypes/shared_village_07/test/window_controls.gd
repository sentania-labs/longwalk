extends SceneTree
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var main = load("res://boot.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	main.launch_panel.hide()
	var hud = main.hud
	hud.person = {"position":[0,0,9]}
	preload("res://src/sim/workshop.gd").ensure(hud.person)
	hud._open("Journal")
	await process_frame
	var before: Vector2 = hud.panel.position
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	hud.title.gui_input.emit(press)
	assert(hud.window_drag.dragging)
	hud.window_drag.offset = hud.panel.get_global_mouse_position()-Vector2(300,140)
	hud.window_drag._input(InputEventMouseMotion.new())
	assert(hud.panel.position.distance_to(Vector2(300,140))<1)
	press.pressed = false
	hud.window_drag._input(press)
	assert(not hud.window_drag.dragging)
	hud._open("Inventory")
	hud._open("Journal")
	assert(hud.panel.position.distance_to(Vector2(300,140))<1)
	hud.panel.position = Vector2(10000,-10000)
	hud.window_drag._clamp()
	assert(hud.panel.position.y>=0 and hud.panel.position.x+hud.panel.size.x<=hud.panel.get_viewport_rect().size.x)
	main.connection_panel.show()
	await process_frame
	var close: Button
	for button in main.connection_panel.find_children("*","Button",true,false):
		if button.text == "×": close=button; break
	assert(close != null)
	close.pressed.emit()
	assert(not main.connection_panel.visible)
	hud._open("Journal")
	hud.panel.position = Vector2(955,130)
	main.connection_panel.show()
	main.connection_panel.position = Vector2(320,185)
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png("/tmp/shared06-windows.png")
	print("WINDOW CONTROLS PASSED: title drag, saved per-interface placement, screen clamp, visible close button")
	quit()
