extends SceneTree
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	var link = load("res://src/net/world_link.gd").new()
	root.add_child(link)
	link.serving = true
	link.store = load("res://src/sim/world_store.gd").new()
	var state: Dictionary = link.store.initialize("/tmp/shared06-move-queue-"+str(Time.get_ticks_usec()),link.version)
	var ident := "a".repeat(64)
	state.players[ident] = {"position":[0,0,9]}
	state.owner = ident
	link.world = load("res://src/sim/shared_world.gd").new()
	link.world.initialize(JSON.parse_string(FileAccess.get_file_as_string("res://world/baseline.json")),state)
	link.connections[0] = ident
	link.request("move",{"target":[100,100],"run":true,"prefer":true})
	link.request("move",{"target":[200,200],"run":false,"prefer":false,"ignored":"extra input"})
	assert(link.move_queue.size()==1 and link.pending_moves.size()==1)
	assert(link.pending_moves[0].target == [200,200] and not link.pending_moves[0].has("ignored"))
	link._admin("pause",{})
	assert(link.move_queue.is_empty() and link.pending_moves.is_empty())
	link._admin("pause",{})
	link.request("move",{"target":[100,100],"run":true,"prefer":true})
	link._left(0)
	assert(link.move_queue.is_empty() and link.pending_moves.is_empty() and link.world.routes.is_empty())
	print("MOVE QUEUE PASSED: latest intent coalesces, unused input discarded, pause and disconnect clear pending movement")
	quit()
