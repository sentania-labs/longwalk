extends SceneTree
func _initialize() -> void:
	var world = load("res://src/sim/shared_world.gd").new()
	world.initialize(JSON.parse_string(FileAccess.get_file_as_string("res://world/baseline.json")),{"players":{"a":{"position":[0,0,9]}},"paused":false,"cut":true})
	world.active = ["a"]
	for target in [[-300,-300],[300,300],[-400,300],[400,-300],[-102,-74]]:
		for prefer in [true,false]:
			var before := Time.get_ticks_usec()
			var message: String = world.move("a",target,true,prefer)
			print("PATH BUDGET: target=",target," prefer=",prefer," milliseconds=",snappedf((Time.get_ticks_usec()-before)/1000.0,0.1)," accepted=",message=="")
			world.stop("a")
	quit()
