extends SceneTree
var link: Node
var age := 0.0
var slot := 0
var duration := 3600.0
var test_port := 17782
var directory := "/tmp/shared06-sustained-profiles"
var configure := false
var token := ""
var next_retry := 0.0
var next_move := 0.0
var maximum := 0
var joins := 0
var ident := ""
var initial_inventory := {}
var peak_action := 0.0
var peak_tick := 0.0
var max_packet := 0
var max_practice := 0.0
var last_report := -1
var maximum_fauna := 0
var errors := 0
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--slot="): slot=arg.trim_prefix("--slot=").to_int()
		if arg.begins_with("--duration="): duration=arg.trim_prefix("--duration=").to_float()
		if arg.begins_with("--test-port="): test_port=arg.trim_prefix("--test-port=").to_int()
		if arg.begins_with("--test-dir="): directory=arg.trim_prefix("--test-dir=")
		if arg == "--configure": configure=true
	DirAccess.make_dir_recursive_absolute(directory)
	var credential := directory.path_join("slot-%02d.credential" % slot)
	if FileAccess.file_exists(credential): token=FileAccess.get_file_as_string(credential)
	else:
		token=Crypto.new().generate_random_bytes(32).hex_encode()
		var file := FileAccess.open(credential,FileAccess.WRITE)
		file.store_string(token)
		file.close()
	var main := Node.new()
	main.name = "Main"
	root.add_child(main)
	link = load("res://src/net/world_link.gd").new()
	link.name = "Network"
	main.add_child(link)
	link.joined.connect(func(value,_owner):
		if ident != "" and ident != value: push_error("Traveler identity changed after reconnect"); quit(1)
		ident=value
		joins+=1
		if configure: link.command("settings",{"max_players":16,"save_interval":5,"day_minutes":12})
	)
	link.notice.connect(func(message):
		if configure and message == "Settings saved": print("SUSTAINED WORLD CONFIGURED: sixteen clients, twelve-minute days"); quit()
		if message.contains("mismatch") or message.contains("capacity") or message.contains("limit reached") or message.begins_with("Storage error:"):
			push_error(message); quit(1)
	)
	link.connect_client("127.0.0.1",token,test_port)
func _process(delta: float) -> bool:
	age += delta
	if not link: return false
	if configure:
		if age>20: push_error("Sustained setup timed out"); quit(1)
		return false
	if not link.connected and not link.connecting and age>=next_retry:
		link.connect_client("127.0.0.1",token,test_port)
		next_retry=age+3
	if age>duration:
		if maximum!=16 or max_practice<=0 or initial_inventory.is_empty(): push_error("Sustained test did not exercise sixteen moving travelers"); quit(1); return false
		print("SUSTAINED CLIENT PASSED: slot=",slot," seconds=",int(age)," peak_clients=",maximum," joins=",joins," peak_action_ms=",peak_action," peak_tick_ms=",peak_tick," max_motion_bytes=",max_packet," max_fauna=",maximum_fauna," inventory_retained=true")
		quit()
		return false
	if not link.connected or link.snapshot.is_empty(): return false
	var snapshot: Dictionary = link.snapshot
	maximum = maxi(maximum,snapshot.actors.size())
	if initial_inventory.is_empty(): initial_inventory=snapshot.person.inventory.duplicate()
	if snapshot.person.inventory != initial_inventory: push_error("Movement changed carried goods"); quit(1); return false
	max_practice=maxf(max_practice,snapshot.person.practice.running)
	var metrics: Dictionary = snapshot.get("metrics",{})
	peak_action=maxf(peak_action,metrics.get("action_peak_ms",0))
	peak_tick=maxf(peak_tick,metrics.get("tick_peak_ms",0))
	max_packet=maxi(max_packet,metrics.get("motion_bytes",0))
	maximum_fauna=maxi(maximum_fauna,metrics.get("fauna",0))
	if slot==0 and int(age/60)!=last_report:
		last_report=int(age/60)
		print("SUSTAINED minute=",last_report," clients=",snapshot.actors.size()," peak_action_ms=",peak_action," peak_tick_ms=",peak_tick," max_motion_bytes=",max_packet," fauna=",metrics.get("fauna",0))
	if age>=next_move:
		var turn := int(age/15)%4
		var points := [[-300,-300],[300,300],[-400,300],[400,-300]]
		var target: Array = points[(turn+slot)%4].duplicate()
		target[1]+=slot*2
		link.command("move",{"target":target,"run":true,"prefer":slot%3!=0})
		next_move=age+15+slot*0.15
	return false
