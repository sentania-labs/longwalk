extends SceneTree

func _initialize() -> void:
	var link = load("res://src/net/world_link.gd").new()
	root.add_child(link)
	link.serving = true
	link.store = load("res://src/sim/world_store.gd").new()
	var state: Dictionary = link.store.initialize("/tmp/shared-recovery-disconnect-" + str(Time.get_ticks_usec()),link.version)
	link.world = load("res://src/sim/shared_world.gd").new()
	link.world.data = state
	assert(link.store.save(state))
	var generation: int = link.store.generation
	link.frozen = true
	link.connections[42] = "fixture"
	link._left(42)
	assert(link.store.generation == generation, "Disconnect must not publish fallback state")
	assert(link.frozen and link.connections.is_empty())
	print("RECOVERY DISCONNECT PASSED: fallback state was not committed")
	quit()
