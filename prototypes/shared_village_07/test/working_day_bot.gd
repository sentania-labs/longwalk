extends SceneTree
var link: Node
var age := 0.0
var step := 0
var issued := false
var target := Vector2.ZERO
var tasks := [
	["move",{"target":[0,-2],"run":false,"prefer":false}],
	["village",{"op":"order"}],
	["move",{"target":[0,4],"run":false,"prefer":false}],
	["workshop",{"op":"exit"}],
	["move",{"target":[-87,-59],"run":true,"prefer":true}],
	["village",{"op":"gather","pile":"west"}],
	["move",{"target":[-49,34],"run":true,"prefer":true}],
	["village",{"op":"gather","pile":"orchard"}],
	["move",{"target":[-102,-74],"run":true,"prefer":true}],
	["workshop",{"op":"enter"}],
	["move",{"target":[-5,-2],"run":false,"prefer":false}],
	["village",{"op":"prepare_order"}],
	["move",{"target":[0,-2],"run":false,"prefer":false}],
	["village",{"op":"deliver_order"}],
	["move",{"target":[0,4],"run":false,"prefer":false}],
	["workshop",{"op":"exit"}],
	["move",{"target":[4,6],"run":true,"prefer":true}],
	["village",{"op":"buy_bread"}]
]
var starting_coins := -1
var starting_bread := -1
var starting_workcraft := -1
var directory := "/tmp/shared06-packaged-profile"
var test_port := 17779
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--test-dir="): directory=arg.trim_prefix("--test-dir=")
		if arg.begins_with("--test-port="): test_port=arg.trim_prefix("--test-port=").to_int()
	var main := Node.new()
	main.name = "Main"
	root.add_child(main)
	link = load("res://src/net/world_link.gd").new()
	link.name = "Network"
	main.add_child(link)
	link.notice.connect(func(message):
		if message.begins_with("Saved:") and issued and tasks[step][0] != "move":
			print("STEP ",step,": ",message)
			step += 1
			issued = false
		elif message not in ["Connecting...","Connected","Server accepted movement"]:
			push_error(message)
			quit(1)
	)
	link.connect_client("127.0.0.1",FileAccess.get_file_as_string(directory.path_join("owner.credential")),test_port)
func _process(delta: float) -> bool:
	age += delta
	if age>600: push_error("Working day timed out at step "+str(step)); quit(1); return false
	if not link or not link.connected or link.snapshot.is_empty(): return false
	var p: Dictionary = link.snapshot.get("person",{})
	if p.is_empty(): return false
	if starting_coins<0: starting_coins=int(p.coins); starting_bread=int(p.inventory.bread); starting_workcraft=int(p.woodcraft)
	if step>=tasks.size():
		# The reliable receipt can precede the next state packet.
		if p.coins!=starting_coins+2 or p.inventory.bread!=starting_bread+1: return false
		if p.woodcraft != starting_workcraft+1 or p.order or p.inventory.prepared != 0 or p.practice.running<=100:
			push_error("Working day reward or practice mismatch"); quit(1); return false
		print("WORKING DAY NETWORK PASSED: repeat order, outdoor gathering, preparation, delivery, provisioner bread, earned Running practice")
		quit()
		return false
	if not issued:
		link.command(tasks[step][0],tasks[step][1])
		issued = true
	elif tasks[step][0] == "move":
		var point: Array = tasks[step][1].target
		if Vector2(p.position[0],p.position[2]).distance_to(Vector2(point[0],point[1]))<0.1: step+=1; issued=false
	return false
