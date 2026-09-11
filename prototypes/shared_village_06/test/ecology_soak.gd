extends SceneTree
const FAUNA = preload("res://src/sim/lantern_moths.gd")
func _initialize() -> void:
	for length in [12.0,144.0,1440.0]:
		var state := {"players":{},"config":{"day_minutes":length},"clock":900.0,"elapsed":0.0}
		FAUNA.ensure(state)
		var fauna := FAUNA.new()
		var low := 12
		var high := 0
		# Equal game-time steps across day lengths; positions still use real travel time.
		var dt: float = length/144
		for step in range(259200):
			state.elapsed += dt
			state.clock = fposmod(state.clock+dt*24/length,1440)
			fauna.tick(state,dt)
			low = mini(low,state.fauna.agents.size())
			high = maxi(high,state.fauna.agents.size())
		print("SOAK RESULT: ",length," minute days, low=",low," high=",high," final=",state.fauna.agents.size()," births=",state.fauna.births," deaths=",state.fauna.deaths)
		assert(FAUNA.valid(state) and low>0 and high<=FAUNA.CAPACITY)
		assert(state.fauna.births>0 and state.fauna.deaths>0)
		print("ECOLOGY SOAK: thirty world days at ",length," minute days; population ",low,"..",high,"; births ",state.fauna.births,"; deaths ",state.fauna.deaths)
	print("ECOLOGY SOAK PASSED: bounded living population across supported day lengths")
	quit()
