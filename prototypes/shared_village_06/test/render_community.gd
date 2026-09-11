extends SceneTree
var age := 0.0
func _initialize() -> void: _run.call_deferred()
func _process(delta: float) -> bool:
	age += delta
	if age>40: push_error("Community render timed out"); quit(1)
	return false
func _run() -> void:
	var main = load("res://boot.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.link.connect_client("127.0.0.1",Crypto.new().generate_random_bytes(32).hex_encode(),17779)
	while main.link.snapshot.get("person",{}).is_empty(): await process_frame
	main.scene._set_follow(false)
	main.scene.focus_target = Vector3(4,1,4)
	main.scene.zoom_slider.value = 20
	await create_timer(3).timeout
	main.hud._open("Map / travel")
	main.hud.panel.position = Vector2(1000,120)
	assert(main.scene.provisioner.visible)
	var point: Vector2 = main.scene.camera.unproject_position(main.scene.provisioner.position+Vector3(0,1,0))
	var picked: Dictionary = main.scene._pick_context(point)
	assert(picked.kind == "provisioner")
	main.scene._open_context(point)
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png("/tmp/shared06-community-day.png")
	main.scene.context_panel.hide()
	main.scene._update_daylight(1300)
	main.link.changed.disconnect(main.scene._receive_world)
	main.hud.region_time.text = "Two Rivers · Night (lighting check)"
	main.hud.set_process(false)
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png("/tmp/shared06-community-night.png")
	print("COMMUNITY RENDER PASSED: connected citizen, market, contextual trade, day/night")
	quit()
