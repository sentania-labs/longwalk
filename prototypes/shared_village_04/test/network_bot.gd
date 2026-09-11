extends Node
var link: Node
var scenario := ""
var age := 0.0
var phase := 0
var ident := ""
var baseline_generation := 0
var backup := ""
var before_position := Vector3.ZERO
var credential := ""
var saw_other := false
var test_dir := ""
var done := false
var test_port := 17778

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--test-port="): test_port = int(arg.trim_prefix("--test-port="))
		if arg.begins_with("--test-dir="): test_dir = arg.trim_prefix("--test-dir=")
	if test_dir == "": fail("Missing test directory"); return
	DirAccess.make_dir_recursive_absolute(test_dir)
	var profile := "observer" if scenario in ["observer","hold","verify_restore","security"] else "owner"
	var path := test_dir.path_join(profile + ".credential")
	if FileAccess.file_exists(path): credential = FileAccess.get_file_as_string(path)
	else:
		credential = Crypto.new().generate_random_bytes(32).hex_encode()
		var file := FileAccess.open(path,FileAccess.WRITE)
		file.store_string(credential)
		file.close()
	link.joined.connect(func(value,_owner): ident = value)
	link.notice.connect(func(message):
		if message.begins_with("Backup saved: "):
			backup = message.trim_prefix("Backup saved: ")
			var file := FileAccess.open(test_dir.path_join("backup-name.txt"),FileAccess.WRITE)
			file.store_string(backup)
	)
	link.connect_client("127.0.0.1",credential,test_port)

func fail(message: String) -> void:
	if done: return
	done = true
	push_error("NETWORK TEST FAILED: " + message)
	get_tree().quit(1)
func pass_test(message: String) -> void:
	if done: return
	done = true
	print("NETWORK TEST PASSED: " + message)
	get_tree().quit()
func own_position() -> Vector3:
	for actor in link.snapshot.get("actors",[]):
		if actor.id == ident: return Vector3(actor.position[0],actor.position[1],actor.position[2])
	return Vector3.INF

func _process(delta: float) -> void:
	if done: return
	age += delta
	if age>(200 if scenario=="hold" else 80): fail("Timed out in " + scenario + " phase " + str(phase)); return
	if not link.connected or link.snapshot.is_empty(): return
	if link.snapshot.actors.size()>=2: saw_other = true
	match scenario:
		"observer":
			if phase==0:
				link.command("move",{"target":[8,12],"run":true,"prefer":true})
				phase = 1
			if age>3 and link.snapshot.cut and saw_other: pass_test("second client saw other traveler and shared harvest")
		"harvest":
			if phase==0:
				if not link.is_owner: fail("Initial traveler was not owner"); return
				if link.snapshot.cut: fail("Expected fresh uncut tree"); return
				link.command("backup")
				phase = 1
			elif phase==1 and backup!="":
				link.command("move",{"target":[-12,30],"run":true,"prefer":true})
				phase = 2
			elif phase==2 and own_position().distance_to(Vector3(-12,0,27))<3.5:
				link.command("harvest")
				phase = 3
			elif phase==3 and link.snapshot.cut and saw_other:
				pass_test("owner moved authoritatively; harvest committed; second player present")
		"reconnect":
			if not link.snapshot.cut: fail("Acknowledged harvest lost after process restart"); return
			if not link.is_owner: fail("Owner identity lost after reconnect"); return
			pass_test("same owner recovered; harvested tree survived abrupt restart")
		"restore":
			if phase==0:
				if not link.snapshot.cut: fail("Expected harvested tree before restore"); return
				link.command("pause")
				phase = 1
			elif phase==1 and link.snapshot.paused:
				backup = FileAccess.get_file_as_string(test_dir.path_join("backup-name.txt"))
				link.command("restore",{"name":backup})
				phase = 2
			elif phase==2 and not link.snapshot.cut:
				if not link.snapshot.paused: fail("Restore should keep world paused"); return
				pass_test("backup restored tree; displaced state retained; world remains paused")
		"verify_restore":
			if link.snapshot.cut: fail("Second client did not receive restored tree"); return
			if not link.snapshot.paused: fail("Restored world must stay paused"); return
			pass_test("second identity reconnected to restored world")
		"security":
			if phase==0:
				if link.is_owner: fail("Observer unexpectedly has owner permissions"); return
				baseline_generation = int(link.snapshot.saved_generation)
				link.command("pause")
				link.command("settings",{"save_interval":1,"max_players":16})
				phase = 1
			elif age>2:
				if not link.snapshot.paused or int(link.snapshot.config.max_players)!=4: fail("Non-owner changed administration state"); return
				pass_test("non-owner administration denied")
		"hold":
			if age>160: pass_test("second client held connection for rendered playtest")
