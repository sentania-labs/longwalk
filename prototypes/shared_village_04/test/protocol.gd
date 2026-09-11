extends SceneTree
var age := 0.0
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var main := Node.new()
	main.name = "Main"
	root.add_child(main)
	var link = load("res://src/net/world_link.gd").new()
	link.name = "Network"
	main.add_child(link)
	for connection in link.multiplayer.connected_to_server.get_connections():
		link.multiplayer.connected_to_server.disconnect(connection.callable)
	link.multiplayer.connected_to_server.connect(func(): link.hello.rpc_id(1,link.version,"0".repeat(64)))
	link.notice.connect(func(message):
		if message.begins_with("Version mismatch:"):
			assert(not link.connected)
			print("PROTOCOL PASSED: baseline-only 03 client rejected with upgrade message before registration")
			quit()
	)
	link.connect_client("127.0.0.1","0".repeat(64),17778)
func _process(delta: float) -> bool:
	age += delta
	if age > 8:
		push_error("Protocol rejection timed out")
		quit(1)
	return false
