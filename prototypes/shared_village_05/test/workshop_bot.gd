extends Node
var link: Node
var scenario := "workshop"
var directory := "/tmp/shared05-profiles"
var age := 0.0
var step := 0
var issued := false
var token := ""
var hold_complete := false
var tasks := [
	["move",{"target":[-102,-74],"run":true,"prefer":true}],
	["workshop",{"op":"enter"}],
	["move",{"target":[-5,3],"run":true,"prefer":false}],
	["workshop",{"op":"wood"}],
	["move",{"target":[5,-2],"run":true,"prefer":false}],
	["workshop",{"op":"tool"}],
	["workshop",{"op":"use","item":"axe"}],
	["move",{"target":[-5,-2],"run":true,"prefer":false}],
	["workshop",{"op":"bench"}],
	["move",{"target":[0,-2],"run":true,"prefer":false}],
	["workshop",{"op":"trade"}],
	["workshop",{"op":"use","item":"ring"}]
]
func _ready() -> void:
	if scenario == "finish_workshop": tasks = [["move",{"target":[2,-2],"run":false,"prefer":false}],["workshop",{"op":"trade"}],["workshop",{"op":"use","item":"ring"}]]
	if scenario == "exit_workshop": tasks = [["move",{"target":[0,4],"run":false,"prefer":false}],["workshop",{"op":"exit"}]]
	for arg in OS.get_cmdline_user_args():
		if arg == "--hold-complete": hold_complete = true
		if arg.begins_with("--test-dir="): directory=arg.trim_prefix("--test-dir=")
	DirAccess.make_dir_recursive_absolute(directory)
	var path := directory.path_join("owner.credential")
	if FileAccess.file_exists(path): token=FileAccess.get_file_as_string(path)
	else:
		token=Crypto.new().generate_random_bytes(32).hex_encode()
		var file := FileAccess.open(path,FileAccess.WRITE)
		file.store_string(token)
		file.close()
	link.notice.connect(func(message):
		if message.begins_with("Saved:") and issued and tasks[step][0]=="workshop": step+=1; issued=false
		if message.begins_with("No ") or message.begins_with("That ") or message.begins_with("Move closer"):
			push_error("BOT ACTION REJECTED: "+message)
	)
	link.connect_client("127.0.0.1",token,17779)
func _process(delta: float) -> void:
	age += delta
	if age > 240:
		push_error("Workshop bot timed out at step "+str(step))
		get_tree().quit(1)
		return
	if not link.connected or link.snapshot.is_empty(): return
	var person: Dictionary = link.snapshot.get("person",{})
	if person.is_empty(): return
	if scenario == "reconnect_workshop":
		if person.quest.complete and person.inventory.ring == 1 and person.coins == 5 and person.equipment.finger == "ring" and person.area == "workshop":
			print("WORKSHOP RECONNECT PASSED: inventory, equipment, discovered finger, reward, interior and progress retained")
			get_tree().quit()
		else:
			push_error("Workshop reconnect state lost")
			get_tree().quit(1)
		return
	if step >= tasks.size():
		if hold_complete and age < 180: return
		assert(person.quest.complete and person.coins == 5 and person.inventory.ring == 1 and "finger" in person.discovered)
		print("PACKAGED EXIT PASSED: returned outside with inventory and equipment intact" if scenario == "exit_workshop" else "PACKAGED WORKSHOP PASSED: walked to door, entered, collected, equipped, prepared, exchanged and equipped discovered ring")
		get_tree().quit()
		return
	if not issued:
		link.command(tasks[step][0],tasks[step][1])
		issued=true
	elif tasks[step][0] == "move":
		var target: Array = tasks[step][1].target
		if Vector2(person.position[0],person.position[2]).distance_to(Vector2(target[0],target[1])) < 0.1:
			step+=1
			issued=false
