extends SceneTree
const WORLD = preload("res://src/sim/shared_world.gd")
func _initialize() -> void:
	var world := WORLD.new()
	world.initialize(JSON.parse_string(FileAccess.get_file_as_string("res://world/baseline.json")),{"schema":3,"players":{},"paused":false,"cut":false,"clock":0.0,"config":{"day_minutes":12.0}})
	var arrivals := {}
	var market_seconds := 0.0
	var slowest_usec := 0
	for step in range(14400):
		var before := Time.get_ticks_usec()
		world.tick(0.1)
		slowest_usec = maxi(slowest_usec,Time.get_ticks_usec()-before)
		var place: String = world.data.citizen.activity
		if world.COMMUNITY.position(world.data).distance_to(world.COMMUNITY.PLACES[place])<0.25:
			arrivals[place] = true
			if place == "market": market_seconds+=0.1
	assert(arrivals.size()==3,"Citizen must arrive at all three places in the shortest supported day")
	assert(market_seconds>120,"The market needs a useful trading window even with short days")
	print("DAY CYCLE PASSED: two 12-minute days, all destinations reached; market available ",snappedf(market_seconds,0.1)," seconds; max simulation tick ",slowest_usec," usec")
	quit()
