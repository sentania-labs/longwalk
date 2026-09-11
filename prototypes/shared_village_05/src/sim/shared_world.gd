extends RefCounted
const WORK = preload("res://src/sim/workshop.gd")
const GRID = preload("res://src/sim/travel_grid.gd")
const PROFILE = preload("res://src/sim/bridge_profile.gd")
const LAND = preload("res://src/sim/landscape.gd")
var nav := GRID.new()
var interior := room_grid()
var data: Dictionary
var routes := {}
var running := {}
# Only connected travelers occupy the shared simulation.
var active: Array = []
var destinations := {}
var preferences := {}
var retry_after := {}
const CLEARANCE := 0.85
var resource := Vector3(-12,0,27)

func initialize(baseline: Dictionary, state: Dictionary) -> void:
	data = state
	data.schema = 2
	for person in data.players.values(): WORK.ensure(person)
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
	if data.players[ident].get("area","outside") == "workshop" and (absf(destination[0])>7 or absf(destination[1])>5): return "That point is outside the workshop."
	var target := cell(Vector3(destination[0],0,destination[1]))
	var grid = grid_for(ident)
	if grid.is_point_solid(target): return "That destination is blocked"
	destinations[ident] = target
	preferences[ident] = prefer
	running[ident] = run
	if not _plan(ident):
		stop(ident)
		return "No clear route around the other travelers"
	return ""

func _plan(ident: String) -> bool:
	var grid = grid_for(ident)
	var start := cell(position(ident))
	var temporarily_blocked: Array[Vector2i] = []
	for other in active:
		if other == ident or not data.players.has(other) or data.players[other].get("area","outside") != data.players[ident].get("area","outside"): continue
		var occupied := position(other)
		var center := cell(occupied)
		for x in range(center.x-2,center.x+3):
			for y in range(center.y-2,center.y+3):
				var id := Vector2i(x,y)
				var point := Vector2(x-512,y-512)
				if id != start and point.distance_to(Vector2(occupied.x,occupied.z)) < 1.35 and grid.is_in_boundsv(id) and not grid.is_point_solid(id):
					grid.set_point_solid(id,true)
					temporarily_blocked.append(id)
	if grid == nav: grid.prefer_paths = preferences.get(ident,true)
	var target: Vector2i = destinations[ident]
	var path: Array[Vector2i] = []
	if not grid.is_point_solid(target): path = grid.get_id_path(start,target)
	for id in temporarily_blocked: grid.set_point_solid(id,false)
	if path.is_empty(): return false
	if path.size() > 1: path.pop_front()
	var points: Array[Vector3] = []
	for id in path:
		var point := Vector3(id.x-512,0,id.y-512)
		point.y = ground(point) if data.players[ident].get("area","outside") == "outside" else 0
		points.append(point)
	routes[ident] = points
	return true

func _can_step(ident: String, from: Vector3, to: Vector3) -> bool:
	var a := Vector2(from.x,from.z)
	var b := Vector2(to.x,to.z)
	for other in active:
		if other == ident or not data.players.has(other) or data.players[other].get("area","outside") != data.players[ident].get("area","outside"): continue
		var p := position(other)
		var obstacle := Vector2(p.x,p.z)
		# Older saves can contain overlap. Permit separating movement only.
		if a.distance_to(obstacle) < CLEARANCE and b.distance_to(obstacle) > a.distance_to(obstacle): continue
		var closest := Geometry2D.get_closest_point_to_segment(obstacle,a,b)
		if closest.distance_to(obstacle) < CLEARANCE: return false
	return true

func stop(ident: String) -> void:
	routes.erase(ident)
	running.erase(ident)
	destinations.erase(ident)
	preferences.erase(ident)
	retry_after.erase(ident)

func tick(delta: float) -> void:
	if data.paused: return
	data.clock = fposmod(float(data.get("clock",900)) + delta/6,1440)
	var ordered := routes.keys()
	ordered.sort()
	for ident in ordered:
		retry_after[ident] = maxf(0,float(retry_after.get(ident,0))-delta)
		var route: Array = routes[ident]
		var p := position(ident)
		var person: Dictionary = data.players[ident]
		var sprint: bool = running.get(ident,false) and person.get("stamina",100)>0
		var budget := (4.5 if sprint else 1.8)*delta
		person.stamina = clampf(person.get("stamina",100) + (-2.0 if sprint else 0.5)*delta,0,100)
		while not route.is_empty() and budget>0:
			var difference: Vector3 = route[0]-p
			var distance := difference.length()
			if distance<0.001:
				route.pop_front()
				continue
			var amount := minf(distance,budget)
			var next := p + difference/distance*amount
			if not _can_step(ident,p,next):
				data.players[ident].position = [p.x,p.y,p.z]
				if retry_after[ident] <= 0:
					_plan(ident)
					retry_after[ident] = 0.5
				break
			p = next
			budget -= amount
			if amount>=distance: route.pop_front()
		data.players[ident].position = [p.x,p.y,p.z]
		if route.is_empty(): stop(ident)

func harvest(ident: String) -> String:
	if data.paused: return "World is paused"
	if data.players[ident].get("area","outside") != "outside": return "The square oak is outside."
	if data.cut: return "The square oak is already harvested"
	if position(ident).distance_to(resource)>3.5: return "Walk within 3.5m of the marked square oak first"
	data.cut = true
	data.revision += 1
	apply_resource()
	return ""

static func room_grid() -> AStarGrid2D:
	var grid := AStarGrid2D.new()
	grid.region = Rect2i(505,507,15,11)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	for p in [Vector2i(-5,-3),Vector2i(5,-3),Vector2i(0,-3),Vector2i(-5,2)]: grid.set_point_solid(p+Vector2i(512,512),true)
	return grid

func grid_for(ident: String) -> AStarGrid2D:
	return interior if data.players[ident].get("area","outside") == "workshop" else nav

func workshop(ident: String, action: String, args: Dictionary) -> String:
	if data.paused: return "World is paused."
	var message := WORK.apply(data.players[ident],action,args)
	if message == "":
		if action in ["enter","exit"]:
			stop(ident)
			var base := position(ident)
			for offset in [0,-2,2,-4,4,-6,6]:
				var candidate := base+Vector3(offset,0,0)
				if not grid_for(ident).is_in_boundsv(cell(candidate)) or grid_for(ident).is_point_solid(cell(candidate)): continue
				var clear := true
				for other in active:
					if other != ident and data.players[other].get("area","outside") == data.players[ident].area and position(other).distance_to(candidate)<1: clear=false
				if clear:
					data.players[ident].position = [candidate.x,candidate.y,candidate.z]
					return ""
			return "The doorway is occupied. Try again when it clears."
		data.revision += 1
	return message
