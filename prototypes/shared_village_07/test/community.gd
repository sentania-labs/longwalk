extends SceneTree
const WORLD = preload("res://src/sim/shared_world.gd")
const STORE = preload("res://src/sim/world_store.gd")
const WORK = preload("res://src/sim/workshop.gd")
func _initialize() -> void:
	var store := STORE.new()
	var state: Dictionary = store.initialize("/tmp/shared06-community-"+str(Time.get_ticks_usec()),FileAccess.get_sha256("res://world/baseline.json"))
	var world := WORLD.new()
	world.initialize(JSON.parse_string(FileAccess.get_file_as_string("res://world/baseline.json")),state)
	for key in world.COMMUNITY.PLACES:
		assert(not world.nav.is_point_solid(world.cell(world.COMMUNITY.PLACES[key])),"Citizen destination blocked: "+key)
	for key in world.COMMUNITY.PILES:
		assert(not world.nav.is_point_solid(world.cell(world.COMMUNITY.PILES[key])),"Woodfall unreachable: "+key)
	var id := "a".repeat(64)
	var person := {"position":[0,0,9]}
	WORK.ensure(person)
	state.players[id] = person
	state.owner = id
	state.clock = 900.0
	for i in range(2000): world.tick(0.1)
	assert(world.COMMUNITY.position(state).distance_to(world.COMMUNITY.PLACES.market)<0.1,"Provisioner reaches market")
	assert(not state.citizen.moving)
	person.position = [4,0,6]
	assert(world.village_action(id,"buy_bread",{}) != "")
	person.coins = 5
	assert(world.village_action(id,"buy_bread",{}) == "" and person.coins == 4 and person.inventory.bread == 3)
	person.equipment.hand = "axe"
	person.inventory.axe = 1
	person.discovered.append("hand")
	person.position = [-87,0,-60]
	assert(world.village_action(id,"gather",{"pile":"west"}) == "" and person.inventory.wood == 3)
	assert(world.village_action(id,"gather",{"pile":"west"}) != "")
	var deadline: float = state.gathering.west
	state.paused = true
	world.tick(10)
	assert(state.gathering.west == deadline and state.elapsed<deadline)
	state.paused = false
	state.elapsed = deadline
	assert(world.village_action(id,"gather",{"pile":"west"}) == "" and person.inventory.wood == 6)
	person.quest.complete = true
	person.area = "workshop"
	person.position = [0,0,-2]
	assert(world.village_action(id,"order",{}) == "")
	assert(world.village_action(id,"order",{}) != "")
	person.position = [-5,0,-2]
	assert(world.village_action(id,"prepare_order",{}) == "")
	person.position = [0,0,-2]
	assert(world.village_action(id,"deliver_order",{}) == "" and person.coins == 7 and person.inventory.prepared == 0)
	assert(world.village_action(id,"deliver_order",{}) != "")
	assert(store.save(state),store.error)
	var reloaded: Dictionary = store.read_record(store.records("state-").back())
	assert(reloaded.gathering.west == state.gathering.west and reloaded.players[id].coins == 7)
	state.clock = 400.0
	for i in range(4000): world.tick(0.1)
	assert(world.COMMUNITY.position(state).distance_to(world.COMMUNITY.PLACES.farm)<0.1,"Provisioner reaches farm")
	state.clock = 1300.0
	for i in range(4000): world.tick(0.1)
	assert(world.COMMUNITY.position(state).distance_to(world.COMMUNITY.PLACES.home)<0.1,"Provisioner reaches home")
	print("COMMUNITY PASSED: authored routes to market/farm/home, trade, shared depletion, timed recovery, pause, repeat order, duplicate prevention, persistence")
	quit()
