extends RefCounted
const SKILLS = preload("res://src/sim/skills.gd")
const ENTRY = Vector3(-102,0,-74)
const POINTS = {"wood":Vector3(-5,0,2),"tool":Vector3(5,0,-3),"bench":Vector3(-5,0,-3),"trade":Vector3(0,0,-3),"exit":Vector3(0,0,5)}
const ITEMS = {"wood":"Oak wood","prepared":"Prepared oak wood","axe":"Wood axe","bread":"Travel bread","potion":"Healing potion","ring":"Copper ring"}

static func ensure(person: Dictionary) -> void:
	if not person.has("display_name"): person.display_name = "Traveler"
	if not person.has("order"): person.order = false
	if person.has("inventory"):
		if not person.inventory.has("prepared"):
			person.inventory.prepared = 0
			if person.quest.prepared and not person.quest.complete and person.inventory.wood >= 6:
				person.inventory.wood -= 6
				person.inventory.prepared += 6
		SKILLS.ensure(person)
		return
	person.area = "outside"
	person.inventory = {"wood":0,"prepared":0,"axe":0,"bread":2,"potion":1,"ring":0}
	person.equipment = {"hand":"","finger":""}
	person.discovered = ["body","feet"]
	person.hotbar = ["bread","potion","",""]
	person.health = 100.0
	person.stamina = 100.0
	person.quest = {"wood":false,"tool":false,"prepared":false,"complete":false}
	person.coins = 0
	person.woodcraft = 0
	SKILLS.ensure(person)

static func valid(person: Dictionary) -> bool:
	if not person.has("inventory"): return true # 04 records upgrade on load.
	if person.get("area") not in ["outside","workshop"]: return false
	if not person.inventory is Dictionary or not person.get("equipment") is Dictionary or not person.get("quest") is Dictionary: return false
	if person.has("order") and not person.order is bool: return false
	if person.has("display_name") and not valid_name(person.display_name): return false
	if not SKILLS.valid(person): return false
	for key in ITEMS:
		if key == "prepared" and not person.inventory.has(key): continue
		var count = person.inventory.get(key)
		if (not count is int and not count is float) or not is_finite(float(count)) or count < 0 or count > 9999 or count != int(count): return false
	for key in ["wood","tool","prepared","complete"]:
		if not person.quest.get(key) is bool: return false
	for key in ["health","stamina"]:
		var value = person.get(key)
		if (not value is int and not value is float) or not is_finite(float(value)) or value < 0 or value > 100: return false
	if not person.get("discovered") is Array or not person.get("hotbar") is Array or person.hotbar.size()!=4: return false
	for item in person.hotbar:
		if item != "" and item not in ITEMS: return false
	for slot in person.discovered:
		if slot not in ["body","feet","hand","finger"]: return false
	if person.equipment.get("hand") not in ["","axe"] or person.equipment.get("finger") not in ["","ring"]: return false
	for slot in ["hand","finger"]:
		var item: String = person.equipment[slot]
		if item != "" and (person.inventory[item] < 1 or slot not in person.discovered): return false
	for key in ["coins","woodcraft"]:
		var value = person.get(key)
		if (not value is int and not value is float) or not is_finite(float(value)) or value < 0 or value > 999999 or value != int(value): return false
	if person.area == "workshop" and (absf(person.position[0])>7 or absf(person.position[2])>5): return false
	return true

static func apply(person: Dictionary, action: String, args: Dictionary) -> String:
	ensure(person)
	var p: Array = person.position
	var pos := Vector3(p[0],p[1],p[2])
	if action == "enter":
		if person.area != "outside" or pos.distance_to(ENTRY)>3: return "Walk to the workshop door first."
		person.area = "workshop"
		person.position = [0,0,4]
		return ""
	if action in POINTS:
		if person.area != "workshop" or pos.distance_to(POINTS[action])>2.4: return "Move closer first."
	match action:
		"exit":
			person.area = "outside"
			person.position = [ENTRY.x,0,ENTRY.z]
		"wood":
			if person.quest.wood: return "You already collected your wood bundle."
			person.inventory.wood += 6
			person.quest.wood = true
		"tool":
			if person.quest.tool: return "You already collected your tool."
			person.inventory.axe += 1
			person.quest.tool = true
			if "hand" not in person.discovered: person.discovered.append("hand")
			_ready_item(person,"axe")
		"bench":
			if person.quest.prepared: return "Your wood is already prepared."
			if person.inventory.wood < 6 or person.equipment.hand != "axe": return "Carry six wood and equip your axe first."
			person.inventory.wood -= 6
			person.inventory.prepared += 6
			person.quest.prepared = true
		"trade":
			if person.quest.complete: return "The carpenter has already paid you for this work."
			if not person.quest.prepared or person.inventory.prepared < 6: return "Prepare your six wood at the bench first."
			person.inventory.prepared -= 6
			person.inventory.ring += 1
			person.coins += 5
			person.woodcraft += 1
			person.practice.woodcraft += 100
			person.quest.complete = true
			if "finger" not in person.discovered: person.discovered.append("finger")
			_ready_item(person,"ring")
		"rename":
			var chosen = args.get("name","")
			if not valid_name(chosen): return "Use a name of 1 to 24 letters, numbers, spaces, apostrophes or hyphens."
			person.display_name = chosen.strip_edges()
		"observe":
			var subject = args.get("subject","")
			if subject != "wood_grain" or person.area != "workshop" or pos.distance_to(POINTS.wood)>2.4: return "Move close to the wood bundle to study its grain."
			if subject in person.observations: return "You already noticed the grain. Look for something new elsewhere."
			person.observations.append(subject)
			person.practice.observation += 100
		"use":
			var item = args.get("item","")
			if not item is String or item not in ITEMS or person.inventory[item]<1: return "You are not carrying that item."
			match item:
				"axe", "ring":
					var slot := "hand" if item == "axe" else "finger"
					person.equipment[slot] = "" if person.equipment[slot] == item else item
				"bread":
					if person.stamina >= 100: return "Stamina is full; bread kept in your pack."
					person.inventory.bread -= 1
					person.stamina = minf(100,person.stamina+25)
				"potion":
					if person.health >= 100: return "Health is full; potion kept in your pack."
					person.inventory.potion -= 1
					person.health = minf(100,person.health+30)
				_: return "A material for the carpenter."
		"assign":
			var slot = args.get("slot")
			var item = args.get("item","")
			if not slot is int or slot<0 or slot>3 or not item is String or (item != "" and (item not in ITEMS or person.inventory[item]<1)): return "Choose an owned item and a quick slot."
			person.hotbar[slot] = item
		_: return "Unknown workshop action."
	return ""

static func _ready_item(person: Dictionary, item: String) -> void:
	var empty: int = person.hotbar.find("")
	if empty >= 0: person.hotbar[empty] = item

static func receipt(action: String, args: Dictionary) -> String:
	match action:
		"wood": return "Collected: six oak wood for your first commission."
		"tool": return "Received: one free starter axe. Yours to keep. Equip it before preparing wood."
		"bench": return "Prepared: six oak wood. Deliver them to the carpenter for five coins and a ring."
		"trade": return "Delivered: six prepared wood. Received: five coins, one copper ring and Woodcraft practice. You keep your axe."
		"observe": return "Discovered: Reading the Grain. Observation practice +100."
		"enter": return "Entered the carpenter's workshop."
		"exit": return "Returned to the West farms."
		"assign": return "Quick slot updated."
		"rename": return "Your character is now called " + str(args.get("name","")).strip_edges()+"."
		"use": return "Used / changed equipment: " + ITEMS.get(args.get("item",""),"item")
	return action.capitalize()

static func valid_name(value: Variant) -> bool:
	if not value is String or value.length()>24 or value.strip_edges().is_empty(): return false
	var allowed := RegEx.new()
	allowed.compile("^[\\p{L}\\p{N} '\u002d]+$")
	return allowed.search(value) != null
