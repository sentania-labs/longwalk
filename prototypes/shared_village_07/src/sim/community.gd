extends RefCounted
const WORK = preload("res://src/sim/workshop.gd")
const PLACES = {"home":Vector3(-35,0,-18),"farm":Vector3(-98,0,-70),"market":Vector3(4,0,4)}
const PILES = {"west":Vector3(-87,0,-60),"orchard":Vector3(-49,0,33),"south":Vector3(21,0,43)}
const REGROW_SECONDS = 180.0
var route: Array[Vector3] = []
var goal := ""
var retry := 0.0

static func ensure(state: Dictionary) -> void:
	if state.has("config") and not state.config.has("day_minutes"): state.config.day_minutes = 144.0
	if not state.has("elapsed"): state.elapsed = 0.0
	if not state.has("citizen"): state.citizen = {"position":[-35,0,-18],"activity":"home","moving":false}
	if not state.has("gathering"):
		state.gathering = {}
		for key in PILES: state.gathering[key] = 0.0
	for person in state.players.values():
		if not person.has("order"): person.order = false

static func valid(state: Dictionary) -> bool:
	if not state.has("citizen"): return true
	if not state.citizen is Dictionary or not state.citizen.get("position") is Array or state.citizen.position.size()!=3: return false
	for value in state.citizen.position:
		if not _number(value) or absf(float(value))>511: return false
	if state.citizen.get("activity") not in PLACES or not state.citizen.get("moving") is bool: return false
	if not _number(state.get("elapsed")) or state.elapsed<0: return false
	if not state.get("gathering") is Dictionary: return false
	for key in PILES:
		if not _number(state.gathering.get(key)) or state.gathering[key]<0: return false
	return true

static func _number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))

static func position(state: Dictionary) -> Vector3:
	var p: Array = state.citizen.position
	return Vector3(p[0],p[1],p[2])

static func schedule(clock: float) -> String:
	return "home" if clock<360 or clock>=1200 else "farm" if clock<660 else "market"

func tick(world: RefCounted, delta: float) -> void:
	var data: Dictionary = world.data
	data.elapsed += delta
	var next := schedule(data.get("clock",900))
	retry = maxf(0,retry-delta)
	var p := position(data)
	var destination: Vector3 = PLACES[next]
	if next != goal or (route.is_empty() and p.distance_to(destination)>0.1 and retry<=0):
		goal = next
		route.clear()
		world.nav.prefer_paths = true
		var blockers: Array[Vector2i] = []
		for ident in world.active:
			if world.data.players[ident].area != "outside": continue
			var center: Vector2i = world.cell(world.position(ident))
			for offset in [Vector2i.ZERO,Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
				var cell: Vector2i = center+offset
				if cell != world.cell(p) and world.nav.is_in_boundsv(cell) and not world.nav.is_point_solid(cell):
					world.nav.set_point_solid(cell,true)
					blockers.append(cell)
		var path: Array[Vector2i] = []
		if not world.nav.is_point_solid(world.cell(destination)): path = world.nav.get_id_path(world.cell(p),world.cell(destination))
		for cell in blockers: world.nav.set_point_solid(cell,false)
		if path.size()>1: path.pop_front()
		for cell in path:
			var point := Vector3(cell.x-512,0,cell.y-512)
			point.y = world.ground(point)
			route.append(point)
		retry = 1
	data.citizen.activity = next
	data.citizen.moving = false
	var budget := 1.5*delta
	while not route.is_empty() and budget>0:
		var distance := p.distance_to(route[0])
		if distance<0.001: route.pop_front(); continue
		var step := minf(distance,budget)
		var candidate := p.move_toward(route[0],step)
		var blocked := false
		for ident in world.active:
			if data.players[ident].area != "outside": continue
			var other: Vector3 = world.position(ident)
			if candidate.distance_to(other)<0.9 and candidate.distance_to(other)<=p.distance_to(other): blocked=true; break
		if blocked:
			route.clear()
			break
		p = candidate
		data.citizen.moving = true
		budget -= step
		if step>=distance: route.pop_front()
	data.citizen.position = [p.x,p.y,p.z]

static func apply(world: RefCounted, ident: String, op: String, args: Dictionary) -> String:
	var person: Dictionary = world.data.players[ident]
	var p: Vector3 = world.position(ident)
	match op:
		"observe_moths":
			if person.area != "outside" or not world.FAUNA.nocturnal(world.data.get("clock",900)): return "Lantern moths emerge around sunset. Look in the south meadow at night."
			var nearby := false
			for agent in world.data.fauna.agents:
				if p.distance_to(world.FAUNA.point(agent))<4: nearby=true; break
			if not nearby: return "Move closer to a lantern moth in the south meadow."
			if "lantern_moths" in person.observations: return "You already discovered Watching the Small Hours."
			person.observations.append("lantern_moths")
			person.practice.observation += 100
		"gather":
			var pile = args.get("pile","")
			if not pile is String or pile not in PILES: return "Choose a woodfall pile."
			if person.area != "outside" or p.distance_to(PILES[pile])>3: return "Walk closer to the woodfall pile."
			if person.equipment.hand != "axe": return "Equip your axe to trim the fallen branches."
			if world.data.gathering[pile]>world.data.elapsed: return "These branches were gathered. The pile needs time to recover."
			if person.inventory.wood>9996: return "Your pack cannot hold more wood."
			person.inventory.wood += 3
			world.data.gathering[pile] = world.data.elapsed+REGROW_SECONDS
		"order":
			if person.area != "workshop" or p.distance_to(WORK.POINTS.trade)>2.4: return "Talk to the carpenter inside the workshop."
			if not person.quest.complete: return "Finish the first commission before taking another order."
			if person.order: return "Your next order is already open: six prepared wood for three coins."
			person.order = true
		"prepare_order":
			if person.area != "workshop" or p.distance_to(WORK.POINTS.bench)>2.4: return "Use the workshop bench."
			if not person.order or person.inventory.wood<6 or person.equipment.hand!="axe": return "Accept an order, carry six raw wood and equip your axe."
			if person.inventory.prepared>9993: return "Your pack cannot hold more prepared wood."
			person.inventory.wood -= 6
			person.inventory.prepared += 6
		"deliver_order":
			if person.area != "workshop" or p.distance_to(WORK.POINTS.trade)>2.4: return "Return to the carpenter."
			if not person.order or person.inventory.prepared<6: return "Bring six prepared wood for your open order."
			person.inventory.prepared -= 6
			person.coins += 3
			person.woodcraft += 1
			person.practice.woodcraft += 100
			person.order = false
		"buy_bread":
			if person.area != "outside" or p.distance_to(position(world.data))>3: return "Walk closer to the village provisioner."
			if world.data.citizen.activity != "market" or world.data.citizen.moving or position(world.data).distance_to(PLACES.market)>0.25: return "The provisioner sells bread when settled at the market, from late morning until night."
			if person.coins<1: return "Bread costs one coin. Complete work to earn some."
			if person.inventory.bread>=9999: return "Your pack cannot hold more bread."
			person.coins -= 1
			person.inventory.bread += 1
		_: return "Unknown village action."
	world.data.revision += 1
	return ""

static func receipt(op: String) -> String:
	return {"observe_moths":"Discovered: Watching the Small Hours. Observation practice +100. Lantern moths feed on the meadow dew after sunset.","gather":"Gathered three oak wood. The shared pile will recover in three minutes of running world time.","order":"Accepted: six prepared wood for three coins and Woodcraft practice. Gather fallen branches outside.","prepare_order":"Prepared six oak wood for your order.","deliver_order":"Delivered six prepared wood. Received three coins and Woodcraft practice.","buy_bread":"Bought one travel bread for one coin."}.get(op,"Village action saved.")
