extends RefCounted
# Practice comes from completed work and distance actually traveled, never clicks.
static func ensure(person: Dictionary) -> void:
	if not person.has("practice"):
		person.practice = {"running":0.0,"woodcraft":float(person.get("woodcraft",0))*100,"observation":0.0}
	if not person.has("observations"): person.observations = []
	if not person.has("constitution"): person.constitution = 10

static func level(person: Dictionary, skill: String) -> int:
	return mini(10,int(sqrt(float(person.get("practice",{}).get(skill,0))/100.0)))

static func stamina_max(person: Dictionary) -> float:
	return 50.0+5.0*float(person.get("constitution",10))

static func run_speed(person: Dictionary) -> float:
	return 4.5*(1+0.02*level(person,"running"))

static func run_cost(person: Dictionary) -> float:
	return 2.0*(1-0.03*level(person,"running"))

static func valid(person: Dictionary) -> bool:
	if not person.has("practice"): return true # Older saves gain practice on migration.
	if not person.practice is Dictionary: return false
	for skill in ["running","woodcraft","observation"]:
		var value = person.practice.get(skill)
		if (not value is int and not value is float) or not is_finite(float(value)) or value<0 or value>100000000: return false
	if not person.get("observations") is Array or person.observations.size()>32: return false
	for observation in person.observations:
		if observation not in ["wood_grain","bridge_joinery","old_oak","lantern_moths"]: return false
	if person.get("constitution") != 10: return false
	return true
