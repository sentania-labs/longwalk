extends RefCounted
# Fictional meadow fauna. Habitats are authored; no placement RNG is involved.
const HABITATS = [Vector3(-4,0,70),Vector3(7,0,77),Vector3(18,0,69)]
const CAPACITY = 12
const ADULT_AGE = 120.0
const LIFESPAN = 4320.0 # Three world days; day-length settings preserve the lifecycle.
var accumulator := 0.0

static func ensure(data: Dictionary) -> void:
	if data.has("fauna"): return
	data.fauna = {"agents":[],"nectar":[30.0,30.0,30.0],"next_id":6,"births":0,"deaths":0}
	for i in range(6):
		var p: Vector3 = HABITATS[i%3]+Vector3(-0.4 if i<3 else 0.4,1,0)
		data.fauna.agents.append({"id":i,"position":[p.x,p.y,p.z],"energy":60.0,"age":180.0,"cooldown":0.0})

static func nocturnal(clock: float) -> bool:
	return clock>=1080 or clock<360

static func point(agent: Dictionary) -> Vector3:
	return Vector3(agent.position[0],agent.position[1],agent.position[2])

func tick(data: Dictionary, delta: float) -> void:
	accumulator += delta
	if accumulator<0.25: return
	var dt := accumulator
	accumulator = 0
	var day_length: float = data.get("config",{}).get("day_minutes",144)
	var age_step := dt*24/day_length
	var feeding_step := dt*144/day_length
	var fauna: Dictionary = data.fauna
	var night := nocturnal(data.get("clock",900))
	for i in range(3): fauna.nectar[i] = minf(30,float(fauna.nectar[i])+feeding_step*0.15)
	var alive: Array = []
	for agent in fauna.agents:
		agent.age += age_step
		agent.cooldown = maxf(0,agent.cooldown-age_step)
		agent.energy = maxf(0,agent.energy-feeding_step*(0.02 if night else 0.001))
		if agent.age>=LIFESPAN or agent.energy<=0:
			fauna.deaths += 1
			continue
		var home: int = int(agent.id)%3
		var position := point(agent)
		var target: Vector3 = HABITATS[home]+Vector3(0,0.25,0)
		if night:
			var phase := float(data.get("elapsed",0))*0.35+float(agent.id)*1.7
			target = HABITATS[home]+Vector3(sin(phase)*2,1.0+sin(phase*0.7)*0.3,cos(phase)*2)
			if agent.energy>=85 and agent.age>=ADULT_AGE and agent.cooldown<=0 and fauna.agents.size()<CAPACITY:
				var mate_distance := INF
				for mate in fauna.agents:
					if mate.id == agent.id or mate.energy<80 or mate.age<ADULT_AGE or mate.cooldown>0: continue
					var distance := position.distance_to(point(mate))
					if distance<mate_distance:
						mate_distance = distance
						target = position.lerp(point(mate),0.5)
			if agent.energy<85:
				target = HABITATS[home]+Vector3(0,1,0)
				if position.distance_to(target)<1.2 and fauna.nectar[home]>0:
					var sip := minf(feeding_step,float(fauna.nectar[home]))
					fauna.nectar[home] -= sip
					agent.energy = minf(100,agent.energy+sip*4)
		position = position.move_toward(target,dt*0.9)
		agent.position = [position.x,position.y,position.z]
		alive.append(agent)
	fauna.agents = alive
	if not night: return
	# A pair must be fed, mature and close. Crowding stops births, not movement.
	var children := []
	for i in range(alive.size()):
		if alive.size()+children.size()>=CAPACITY: break
		var a: Dictionary = alive[i]
		if a.energy<80 or a.age<ADULT_AGE or a.cooldown>0: continue
		for j in range(i+1,alive.size()):
			var b: Dictionary = alive[j]
			if b.energy<80 or b.age<ADULT_AGE or b.cooldown>0 or point(a).distance_to(point(b))>2: continue
			var birthplace := point(a).lerp(point(b),0.5)
			children.append({"id":fauna.next_id,"position":[birthplace.x,birthplace.y,birthplace.z],"energy":40.0,"age":0.0,"cooldown":240.0})
			fauna.next_id += 1
			fauna.births += 1
			a.energy -= 30
			b.energy -= 30
			a.cooldown = 240.0
			b.cooldown = 240.0
			break
	fauna.agents.append_array(children)

static func public_state(data: Dictionary) -> Dictionary:
	var agents := []
	for agent in data.fauna.agents: agents.append({"id":int(agent.id),"position":agent.position.duplicate()})
	return {"active":nocturnal(data.get("clock",900)),"agents":agents,"births":data.fauna.births,"deaths":data.fauna.deaths}

static func valid(data: Dictionary) -> bool:
	if not data.has("fauna"): return true
	var fauna = data.fauna
	if not fauna is Dictionary or not fauna.get("agents") is Array or fauna.agents.size()>CAPACITY: return false
	if not fauna.get("nectar") is Array or fauna.nectar.size()!=3: return false
	for value in fauna.nectar:
		if not number(value) or value<0 or value>30: return false
	for key in ["next_id","births","deaths"]:
		if not number(fauna.get(key)) or fauna[key]<0 or fauna[key]>1000000000 or fauna[key]!=int(fauna[key]): return false
	var ids := []
	for agent in fauna.agents:
		if not agent is Dictionary or not number(agent.get("id")) or agent.id<0 or agent.id>=fauna.next_id or agent.id!=int(agent.id) or agent.id in ids: return false
		ids.append(agent.id)
		for key in ["age","energy","cooldown"]:
			if not number(agent.get(key)) or agent[key]<0 or agent[key]>LIFESPAN: return false
		if agent.energy>100: return false
		if not agent.get("position") is Array or agent.position.size()!=3: return false
		for value in agent.position:
			if not number(value) or absf(float(value))>511: return false
		if agent.position[1]<0 or agent.position[1]>5: return false
	return true

static func number(value: Variant) -> bool:
	return (value is float or value is int) and is_finite(float(value))
