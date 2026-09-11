extends SceneTree
var link: Node
var age := 0.0
var stage := 0
var backup := ""
var original := {}
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	var main := Node.new()
	main.name = "Main"
	root.add_child(main)
	link = load("res://src/net/world_link.gd").new()
	link.name = "Network"
	main.add_child(link)
	link.notice.connect(func(message):
		if message.begins_with("Backup saved: "): backup=message.trim_prefix("Backup saved: ")
	)
	link.connect_client("127.0.0.1",FileAccess.get_file_as_string("/tmp/shared06-slice3-profile/owner.credential"),17779)
func _process(delta: float) -> bool:
	age += delta
	if age>30: push_error("Working day restore timed out at "+str(stage)); quit(1); return false
	if not link or not link.connected or link.snapshot.is_empty(): return false
	var s: Dictionary = link.snapshot
	match stage:
		0:
			link.command("pause")
			stage=1
		1:
			if not s.paused: return false
			original = s.duplicate(true)
			link.command("backup")
			stage=2
		2:
			if backup == "": return false
			link.command("clock",{"minutes":60})
			stage=3
		3:
			if s.clock!=60: return false
			link.command("restore",{"name":backup})
			stage=4
		4:
			if s.clock==60: return false
			if s.person.inventory!=original.person.inventory or s.person.practice!=original.person.practice or s.person.equipment!=original.person.equipment or s.gathering!=original.gathering or s.citizen!=original.citizen:
				push_error("New world state did not restore exactly"); quit(1); return false
			if not s.paused: push_error("Restore must remain paused"); quit(1); return false
			link.command("pause")
			stage=5
		5:
			if s.paused: return false
			print("WORKING DAY RESTORE PASSED: inventory, equipment, practice, citizen, depletion and world clock; resumed")
			quit()
	return false
