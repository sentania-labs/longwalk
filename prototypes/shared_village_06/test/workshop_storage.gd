extends SceneTree
const STORE = preload("res://src/sim/world_store.gd")
const WORK = preload("res://src/sim/workshop.gd")
func _initialize() -> void:
	var store = STORE.new()
	var state: Dictionary = store.initialize("/tmp/workshop-store-"+str(Time.get_ticks_usec()),FileAccess.get_sha256("res://world/baseline.json"))
	var id := "a".repeat(64)
	state.schema = 1
	state.players[id] = {"position":[3,0,9]}
	state.owner = id
	state.cut = true
	assert(store.save(state),store.error)
	var before: Array = state.players[id].position.duplicate()
	var reloaded: Dictionary = store.read_record(store.records("state-").back())
	WORK.ensure(reloaded.players[id])
	reloaded.schema = 2
	assert(Vector3(reloaded.players[id].position[0],reloaded.players[id].position[1],reloaded.players[id].position[2]) == Vector3(before[0],before[1],before[2]) and reloaded.cut and reloaded.owner == id)
	assert(store.save(reloaded))
	reloaded.players[id].inventory.ring = 1
	reloaded.players[id].discovered.append("finger")
	reloaded.players[id].equipment.finger = "ring"
	assert(store.save(reloaded))
	var backup: String = store.backup(reloaded)
	assert(store.read_record(backup).players[id].equipment.finger == "ring")
	print("WORKSHOP STORAGE PASSED: 04 migration preserves position/owner/tree; new equipment round-trips through saves/backups")
	quit()
