extends SceneTree
const WORLD = preload("res://src/sim/shared_world.gd")
func _initialize() -> void:
	var world = WORLD.new()
	var baseline: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://world/baseline.json"))
	world.initialize(baseline,{"players":{"a":{"position":[-5,0,9]},"b":{"position":[0,0,9]}},"paused":false,"cut":false})
	world.active = ["a","b"]
	assert(world.move("a",[5,9],true,false) == "")
	var detoured := false
	for tick in range(240):
		world.tick(0.05)
		assert(world.position("a").distance_to(world.position("b")) >= 0.849)
		if absf(world.position("a").z-9) > 0.5: detoured = true
	assert(detoured and world.position("a").distance_to(Vector3(5,0,9)) < 0.01)
	world.data.players.a.position = [-5,0,9]
	world.data.players.b.position = [5,0,9]
	assert(world.move("a",[8,9],true,false) == "")
	assert(world.move("b",[-8,9],true,false) == "")
	for tick in range(600):
		world.tick(0.05)
		assert(world.position("a").distance_to(world.position("b")) >= 0.849)
	assert(world.position("a").distance_to(Vector3(8,0,9)) < 0.01)
	assert(world.position("b").distance_to(Vector3(-8,0,9)) < 0.01)
	# A traveler entering an already planned route is detected while moving.
	world.data.players.a.position = [-5,0,9]
	world.data.players.b.position = [0,0,15]
	assert(world.move("a",[5,9],true,false) == "")
	world.data.players.b.position = [0,0,9]
	for tick in range(400):
		world.tick(0.05)
		assert(world.position("a").distance_to(world.position("b")) >= 0.849)
	assert(world.position("a").distance_to(Vector3(5,0,9)) < 0.01)
	# Disconnected saved characters do not obstruct the shared scene.
	world.active = ["a"]
	assert(world.move("a",[0,9],true,false) == "")
	for tick in range(100): world.tick(0.05)
	assert(world.position("a").distance_to(Vector3(0,0,9)) < 0.01)
	# A one-cell corridor cannot accommodate passing. Wait, then continue.
	world.stop("a")
	world.stop("b")
	world.active = ["a","b"]
	world.data.players.a.position = [-5,0,9]
	world.data.players.b.position = [0,0,15]
	world.nav.fill_solid_region(Rect2i(502,520,21,1),true)
	world.nav.fill_solid_region(Rect2i(502,522,21,1),true)
	world.nav.set_point_solid(world.cell(Vector3(-10,0,9)),true)
	world.nav.set_point_solid(world.cell(Vector3(10,0,9)),true)
	assert(world.move("a",[5,9],true,false) == "")
	world.data.players.b.position = [0,0,9]
	for tick in range(100):
		world.tick(0.05)
		assert(world.position("a").distance_to(world.position("b")) >= 0.849)
	assert(world.position("a").x < 0)
	world.active = ["a"]
	for tick in range(200): world.tick(0.05)
	assert(world.position("a").distance_to(Vector3(5,0,9)) < 0.01)
	print("AVOIDANCE PASSED: stationary detour, opposing travelers, moving obstruction, disconnected traveler")
	quit()
