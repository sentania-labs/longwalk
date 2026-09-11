extends SceneTree
var main: Node
var age := 0.0
func _initialize() -> void: _run.call_deferred()
func _process(delta: float) -> bool:
	age+=delta
	if age>100: push_error("Moth render timed out"); quit(1)
	return false
func _run() -> void:
	main = load("res://boot.tscn").instantiate()
	root.add_child(main)
	main.scene._set_follow(false)
	main.scene.focus = Vector3(-4,1,70)
	main.scene.focus_target = main.scene.focus
	main.scene.zoom_slider.value = 9
	main.scene._update_camera()
	print("MOTH SCENE READY")
	await process_frame
	main.link.connect_client("127.0.0.1",FileAccess.get_file_as_string("/tmp/shared06-slice3-profile/owner.credential"),17779)
	while main.link.snapshot.is_empty(): await process_frame
	print("MOTH CLIENT CONNECTED")
	main.link.command("clock",{"minutes":1200})
	await create_timer(0.2).timeout
	main.link.command("workshop",{"op":"rename","name":"Rowan"})
	await create_timer(0.2).timeout
	main.link.command("move",{"target":[-4,72],"run":true,"prefer":true})
	while Vector2(main.link.snapshot.person.position[0],main.link.snapshot.person.position[2]).distance_to(Vector2(-4,72))>0.2: await process_frame
	main.link.command("village",{"op":"observe_moths"})
	while "lantern_moths" not in main.link.snapshot.person.observations: await process_frame
	main.scene._set_follow(false)
	main.scene.focus_target = Vector3(-4,1,70)
	main.scene.zoom_slider.value = 9
	main.hud._open("Skills")
	await create_timer(3).timeout
	if not main.scene.moth_root.visible or main.scene.moths.size()<6: push_error("No rendered colony"); quit(1); return
	root.get_texture().get_image().save_png("/tmp/shared06-moths-night.png")
	print("MOTH RENDER PASSED: server-owned colony, nighttime, named traveler, proximity discovery and skill panel")
	quit()
