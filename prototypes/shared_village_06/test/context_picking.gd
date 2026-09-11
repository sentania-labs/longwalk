extends SceneTree
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	# Exercise ray ordering without constructing or rendering the village.
	root.size = Vector2i(800,500)
	var scene = load("res://village.gd").new()
	scene.camera = Camera3D.new()
	root.add_child(scene.camera)
	scene.camera.position = Vector3(0,1.5,10)
	scene.camera.current = true
	scene.provisioner = Node3D.new()
	scene.moth_root = Node3D.new()
	await process_frame
	var center: Vector2 = scene.camera.unproject_position(Vector3(0,1.5,0))
	assert(scene._pick_context(center).kind == "provisioner")
	var wall := Node3D.new()
	wall.position = Vector3(0,0,5)
	scene.pick_records.append({"node":wall,"key":"hall","bounds":AABB(Vector3(-2,0,4),Vector3(4,4,2))})
	assert(scene._pick_context(center).kind == "hall","A nearer building must occlude the citizen")
	wall.visible = false
	assert(scene._pick_context(center).kind == "provisioner","A hidden building must not intercept interaction")
	scene.camera.free()
	scene.provisioner.free()
	scene.moth_root.free()
	wall.free()
	scene.free()
	print("CONTEXT PICKING PASSED: nearest visible object wins, hidden geometry does not intercept")
	quit()
