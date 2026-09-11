extends SceneTree
var link: Node
var age := 0.0
var slot := 0
var mode := "client"
var issued := false
var sent := 0.0
var maximum := 0
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--slot="): slot=arg.trim_prefix("--slot=").to_int()
		if arg.begins_with("--mode="): mode=arg.trim_prefix("--mode=")
	var main := Node.new()
	main.name = "Main"
	root.add_child(main)
	link = load("res://src/net/world_link.gd").new()
	link.name = "Network"
	main.add_child(link)
	link.notice.connect(func(message):
		if mode == "configure" and message == "Settings saved": print("LOAD CONFIGURED"); quit()
		if message.contains("mismatch") or message.contains("capacity") or message.contains("limit reached"): push_error(message); quit(1)
	)
	var token := FileAccess.get_file_as_string("/tmp/shared06-slice3-profile/owner.credential") if mode != "client" else Crypto.new().generate_random_bytes(32).hex_encode()
	link.connect_client("127.0.0.1",token,17779)
func _process(delta: float) -> bool:
	age += delta
	if age>50: push_error("Load client timed out"); quit(1); return false
	if not link or not link.connected or not link.snapshot.has("actors"): return false
	maximum = maxi(maximum,link.snapshot.actors.size())
	if mode == "configure":
		if not issued: link.command("settings",{"max_players":16,"save_interval":5,"day_minutes":144}); issued=true
		return false
	if mode == "probe":
		if not link.snapshot.get("metrics",{}).is_empty():
			print("SERVER METRICS: ",JSON.stringify(link.snapshot.metrics))
			quit()
		return false
	if age>35:
		if maximum<12: push_error("Expected concurrent travelers, saw "+str(maximum)); quit(1)
		else: print("LOAD CLIENT PASSED: peak concurrent travelers ",maximum); quit()
		return false
	if age-sent>8:
		link.command("move",{"target":[0 if int(age/8)%2==0 else 8,12+slot*3],"run":true,"prefer":true})
		sent=age
	return false
