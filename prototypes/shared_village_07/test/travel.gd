extends SceneTree
const LAND = preload("res://src/sim/landscape.gd")
const GRID = preload("res://src/sim/travel_grid.gd")
var failures := 0
func check(value: bool, message: String) -> void:
	if not value:
		push_error(message)
		failures += 1
func id(p: Vector2) -> Vector2i: return Vector2i(p.round()) + Vector2i(512,512)
func pos(p: Vector2i) -> Vector2: return Vector2(p - Vector2i(512,512))
func _initialize() -> void:
	var grid := GRID.new()
	var empty: Array[Rect2] = []
	grid.prepare(empty)
	for road in LAND.ROADS:
		var a := Vector2(road.x,road.y)
		var b := Vector2(road.z,road.w)
		for i in range(ceili(a.distance_to(b)) + 1):
			var p := a.lerp(b,float(i)/maxf(1,ceili(a.distance_to(b))))
			for field in LAND.FARMS:
				check(not field.grow(-0.1).has_point(p),"Road crosses planted field at %s" % p)
	for i in range(LAND.FARMS.size()):
		var gate: Vector2 = LAND.GATES[i]
		var center: Vector2 = LAND.FARMS[i].get_center()
		check(not grid.is_point_solid(id(gate)),"Gate blocked: %s" % i)
		var outside := gate + (gate-center).normalized()*6
		var route := grid.get_id_path(id(outside),id(center))
		check(not route.is_empty(),"Worker cannot enter field %s" % i)
		var used_gate := false
		for step in route:
			if pos(step).distance_to(gate)<3: used_gate = true
		check(used_gate,"Worker missed field gate %s" % i)
	for barrier in LAND.field_barriers():
		check(grid.is_point_solid(id(barrier.get_center())),"Fence center is walkable")
	var start := id(Vector2(0,165))
	var finish := id(Vector2(60,245))
	grid.prefer_paths = true
	var normal := grid.get_id_path(start,finish)
	grid.prefer_paths = false
	var direct := grid.get_id_path(start,finish)
	check(not normal.is_empty() and not direct.is_empty(),"Comparison routes exist")
	check(normal.size() > direct.size(),"Direct route should take a deliberate shortcut")
	var road_steps := 0
	for step in normal:
		if LAND.road_distance(pos(step))<2: road_steps += 1
	check(float(road_steps)/normal.size()>0.8,"Default traveler should prefer the road")
	for preferred in [true,false]:
		grid.prefer_paths = preferred
		for z in LAND.BRIDGES:
			var x := LAND.river_x(z)
			var crossing := grid.get_id_path(id(Vector2(x-20,z)),id(Vector2(x+20,z)))
			check(not crossing.is_empty(),"Bridge unreachable")
			for step in crossing:
				check(not LAND.water(pos(step)) or LAND.crossing(pos(step)),"Route entered open water")
	if failures == 0: print("TRAVEL CHECKS PASSED: field access, solid fences, road preference, deliberate shortcuts, bridge crossings")
	quit(1 if failures else 0)
