extends RefCounted
const GRID = preload("res://src/sim/travel_grid.gd")
const PROFILE = preload("res://src/sim/bridge_profile.gd")
const LAND = preload("res://src/sim/landscape.gd")
var nav := GRID.new()
var data: Dictionary
var routes := {}
var running := {}
var resource := Vector3(-12,0,27)

func initialize(baseline: Dictionary, state: Dictionary) -> void:
	data = state
	var footprints: Array[Rect2] = []
	for r in baseline.footprints: footprints.append(Rect2(r[0],r[1],r[2],r[3]))
	nav.prepare(footprints)
	apply_resource()

func cell(p: Vector3) -> Vector2i: return Vector2i(roundi(p.x+512),roundi(p.z+512))
func position(ident: String) -> Vector3:
	var p: Array = data.players[ident].position
	return Vector3(p[0],p[1],p[2])
func ground(p: Vector3) -> float:
	for z in LAND.BRIDGES:
		if absf(p.z-z)<3 and absf(p.x-LAND.river_x(z))<12: return PROFILE.deck_height(p.x-LAND.river_x(z),false)
	if absf(p.x)<1.5 and absf(p.z-LAND.tributary_z(0))<6: return PROFILE.deck_height(p.z-LAND.tributary_z(0),true)
	return 0
func apply_resource() -> void:
	# This tree has the same 1.3m trunk footprint baked into the baseline.
	for x in range(-12,-11):
		for z in range(27,28): nav.set_point_solid(cell(Vector3(x,0,z)),not data.cut)

func move(ident: String, destination: Array, run: bool, prefer: bool) -> String:
	if data.paused: return "World is paused"
	if destination.size()!=2: return "Invalid destination"
	for v in destination:
		if (not v is float and not v is int) or not is_finite(float(v)) or absf(float(v))>510: return "Invalid destination"
	var target := cell(Vector3(destination[0],0,destination[1]))
	if nav.is_point_solid(target): return "That destination is blocked"
	nav.prefer_paths = prefer
	var path := nav.get_id_path(cell(position(ident)),target)
	if path.is_empty(): return "No route to that point"
	var points: Array[Vector3] = []
	for id in path:
		var p := Vector3(id.x-512,0,id.y-512)
		p.y = ground(p)
		points.append(p)
	routes[ident] = points
	running[ident] = run
	return ""

func stop(ident: String) -> void:
	routes.erase(ident)
	running.erase(ident)

func tick(delta: float) -> void:
	if data.paused: return
	for ident in routes.keys():
		var route: Array = routes[ident]
		var p := position(ident)
		var budget := (4.5 if running.get(ident,false) else 1.8)*delta
		while not route.is_empty() and budget>0:
			var difference: Vector3 = route[0]-p
			var distance := difference.length()
			if distance<0.001:
				route.pop_front()
				continue
			var amount := minf(distance,budget)
			p += difference/distance*amount
			budget -= amount
			if amount>=distance: route.pop_front()
		data.players[ident].position = [p.x,p.y,p.z]
		if route.is_empty(): stop(ident)

func harvest(ident: String) -> String:
	if data.paused: return "World is paused"
	if data.cut: return "The square oak is already harvested"
	if position(ident).distance_to(resource)>3.5: return "Walk within 3.5m of the marked square oak first"
	data.cut = true
	data.revision += 1
	apply_resource()
	return ""
