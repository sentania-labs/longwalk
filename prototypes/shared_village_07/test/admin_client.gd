extends SceneTree
var link: Node
var staff_ui: VBoxContainer
var age := 0.0
var last_command := ""
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	var main := Node.new()
	main.name="Main"
	root.add_child(main)
	link=load("res://src/net/world_link.gd").new()
	link.name="Network"
	main.add_child(link)
	staff_ui=load("res://staff_panel.gd").new()
	staff_ui.link=link
	main.add_child(staff_ui)
	if OS.get_environment("LONGWALK_TEST_MISMATCH")=="1": link.version="incompatible-baseline"
	link.notice.connect(func(message):
		if message.begins_with("Update required:"):
			assert(not link.connected)
			print("COMPATIBILITY REJECTION PASSED")
			quit()
	)
	link.changed.connect(func(state):
		var file := FileAccess.open(OS.get_environment("LONGWALK_TEST_DATA").path_join("client-state.json"),FileAccess.WRITE)
		file.store_string(JSON.stringify({"id":link.local_id,"owner":link.is_owner,"role":state.get("staff_role",""),"person":state.person}))
	)
	link.connect_client("127.0.0.1",OS.get_environment("LONGWALK_TEST_CREDENTIAL"),int(OS.get_environment("LONGWALK_UDP_LISTEN_PORT")))
func _process(delta: float) -> bool:
	age+=delta
	if age>90: quit(1)
	if not link or not link.connected: return false
	var path := OS.get_environment("LONGWALK_TEST_DATA").path_join("client-command.json")
	if FileAccess.file_exists(path):
		var text := FileAccess.get_file_as_string(path)
		if text!=last_command:
			last_command=text
			var command=JSON.parse_string(text)
			if command.action=="staff": staff_ui._send(command.arguments.operation,command.arguments.arguments)
			else: link.command(command.action,command.get("arguments",{}))
	return false
