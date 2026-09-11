extends SceneTree
const WORLD = preload("res://src/sim/shared_world.gd")
const STORE = preload("res://src/sim/world_store.gd")
const FAUNA = preload("res://src/sim/lantern_moths.gd")
func _initialize() -> void:
	var store := STORE.new()
	var state: Dictionary = store.initialize("/tmp/moth-check-"+str(Time.get_ticks_usec()),FileAccess.get_sha256("res://world/baseline.json"))
	var world := WORLD.new()
	world.initialize(JSON.parse_string(FileAccess.get_file_as_string("res://world/baseline.json")),state)
	for habitat in FAUNA.HABITATS: assert(not world.nav.is_point_solid(world.cell(habitat)),"Meadow habitat must be reachable")
	state.clock = 1200.0
	var nectar_before: Array = state.fauna.nectar.duplicate()
	for i in range(2400): world.tick(0.1)
	assert(state.fauna.births>0 and state.fauna.agents.size()<=FAUNA.CAPACITY)
	assert(state.fauna.nectar != nectar_before)
	assert(FAUNA.valid(state))
	var paused: Dictionary = state.fauna.duplicate(true)
	state.paused = true
	for i in range(20): world.tick(0.1)
	assert(state.fauna == paused)
	state.paused = false
	assert(store.save(state))
	var restored: Dictionary = store.read_record(store.records("state-").back())
	assert(JSON.stringify(restored.fauna) == JSON.stringify(state.fauna))
	state.clock = 700.0
	for i in range(200): world.tick(0.1)
	assert(not FAUNA.public_state(state).active)
	for agent in state.fauna.agents: assert(agent.position[1]<0.3)
	state.fauna.agents[0].age = FAUNA.LIFESPAN-0.001
	for i in range(4): world.tick(0.1)
	assert(state.fauna.deaths == 1)
	var id := "a".repeat(64)
	state.players[id] = {"position":[-4,0,70]}
	world.WORK.ensure(state.players[id])
	state.clock = 1200.0
	assert(world.village_action(id,"observe_moths",{}) == "")
	assert(world.village_action(id,"observe_moths",{}) != "")
	assert(state.players[id].practice.observation == 100)
	print("LANTERN MOTHS PASSED: authored habitat, feeding, births, capacity, roosting, aging, pause, persistence, one-time observation")
	quit()
