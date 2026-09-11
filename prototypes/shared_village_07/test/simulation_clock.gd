extends SceneTree
func _initialize() -> void:
	var link = load("res://src/net/world_link.gd").new()
	link.world = load("res://src/sim/shared_world.gd").new()
	link.world.initialize({"footprints":[]},{"players":{},"paused":false,"cut":true,"clock":0.0,"config":{"day_minutes":12.0}})
	link._advance_simulation(0.75)
	assert(absf(link.world.data.elapsed-0.5)<0.00001 and absf(link.simulation_accumulator-0.25)<0.00001)
	link._advance_simulation(0.05)
	assert(absf(link.world.data.elapsed-0.8)<0.00001 and absf(link.world.data.clock-1.6)<0.00001)
	link.world.data.paused=true
	link._advance_simulation(100)
	assert(absf(link.world.data.elapsed-0.8)<0.00001 and link.simulation_accumulator==0)
	link.world.data.paused=false
	link._advance_simulation(0.05)
	assert(absf(link.world.data.elapsed-0.85)<0.00001)
	link.free()
	print("SIMULATION CLOCK PASSED: bounded catch-up after a delayed frame, fixed movement steps, pause discards backlog")
	quit()
