extends SceneTree
const WORLD = preload("res://src/sim/shared_world.gd")
const WORK = preload("res://src/sim/workshop.gd")
func _initialize() -> void:
	var world := WORLD.new()
	var person := {"position":[0,0,0]}
	WORK.ensure(person)
	world.initialize({"footprints":[]},{"schema":3,"players":{"runner":person},"paused":false,"cut":true})
	world.active = ["runner"]
	world.routes.runner = [Vector3(20,0,0)]
	world.running.runner = true
	for i in range(10): world.tick(0.1)
	assert(absf(person.practice.running-4.5)<0.001)
	assert(absf(person.stamina-98)<0.001)
	world.stop("runner")
	var practice: float = person.practice.running
	for i in range(10): world.tick(0.1)
	assert(person.practice.running == practice)
	person.practice.running = 400
	assert(WORK.SKILLS.level(person,"running") == 2)
	assert(WORK.SKILLS.run_speed(person)>4.5 and WORK.SKILLS.run_cost(person)<2)
	person.stamina = 0.01
	world.routes.runner = [Vector3(20,0,0)]
	world.running.runner = true
	world.tick(0.1)
	assert(not world.running.runner and person.stamina == 0)
	var exhausted_practice: float = person.practice.running
	world.tick(0.1)
	assert(not world.running.runner and person.practice.running == exhausted_practice and person.stamina>0)
	person.area = "workshop"
	person.position = [-5,0,2]
	assert(WORK.apply(person,"observe",{"subject":"wood_grain"}) == "")
	assert(WORK.apply(person,"observe",{"subject":"wood_grain"}) != "")
	assert(person.practice.observation == 100)
	# A 05 player midway through the commission keeps the prepared material.
	var old := {"position":[0,0,0]}
	WORK.ensure(old)
	old.inventory.erase("prepared")
	old.erase("practice")
	old.quest.prepared = true
	old.inventory.wood = 6
	WORK.ensure(old)
	assert(old.inventory.wood == 0 and old.inventory.prepared == 6 and WORK.valid(old))
	print("SKILLS PASSED: actual running distance, no idle practice, speed/efficiency, one-time discovery, prepared-wood migration, exhaustion stays walking")
	quit()
