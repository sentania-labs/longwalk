extends SceneTree
var age := 0.0
var message := ""
func _initialize() -> void: _run.call_deferred()
func _process(delta: float) -> bool:
	age += delta
	if age>30: push_error("Frozen recovery timed out: "+message); quit(1)
	return false
func _run() -> void:
	var main := Node.new()
	main.name = "Main"
	root.add_child(main)
	var link = load("res://src/net/world_link.gd").new()
	link.name = "Network"
	main.add_child(link)
	link.notice.connect(func(value): message=value)
	link.connect_client("127.0.0.1",FileAccess.get_file_as_string("/tmp/shared06-packaged-profile/owner.credential"),17781)
	while message != "Owner-only recovery mode": await process_frame
	if link.connected: push_error("Non-owner entered recovery world"); quit(1); return
	link.disconnect_client("")
	link.connect_client("127.0.0.1",FileAccess.get_file_as_string("/tmp/shared06-slice3-profile/owner.credential"),17781)
	while link.snapshot.is_empty(): await process_frame
	if not link.is_owner or not link.snapshot.paused or link.snapshot.error == "": push_error("Recovery mode was not visible to owner"); quit(1); return
	var original: Dictionary = link.snapshot.person.duplicate(true)
	link.command("village",{"op":"gather","pile":"south"})
	while not message.begins_with("Storage error:"): await process_frame
	link.command("restore",{"name":"backup-000000000936-fixture.json"})
	while link.snapshot.error != "": await process_frame
	if not link.snapshot.paused or link.snapshot.person.inventory != original.inventory or link.snapshot.person.equipment != original.equipment: push_error("Recovery changed player goods or resumed silently"); quit(1); return
	link.command("pause")
	while link.snapshot.paused: await process_frame
	print("FROZEN RECOVERY PASSED: non-owner rejected, owner sees storage failure, actions frozen, backup restore preserves goods and remains paused, resume succeeds")
	quit()
