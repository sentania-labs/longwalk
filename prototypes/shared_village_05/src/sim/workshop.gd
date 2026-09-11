extends RefCounted
const ENTRY = Vector3(-102,0,-74)
const POINTS = {"wood":Vector3(-5,0,2),"tool":Vector3(5,0,-3),"bench":Vector3(-5,0,-3),"trade":Vector3(0,0,-3),"exit":Vector3(0,0,5)}
const ITEMS = {"wood":"Oak wood","axe":"Wood axe","bread":"Travel bread","potion":"Healing potion","ring":"Copper ring"}

static func ensure(person: Dictionary) -> void:
	if person.has("inventory"): return
	person.area = "outside"
	person.inventory = {"wood":0,"axe":0,"bread":2,"potion":1,"ring":0}
	person.equipment = {"hand":"","finger":""}
	person.discovered = ["body","feet"]
	person.hotbar = ["bread","potion","",""]
	person.health = 100.0
	person.stamina = 100.0
	person.quest = {"wood":false,"tool":false,"prepared":false,"complete":false}
	person.coins = 0
	person.woodcraft = 0

static func valid(person: Dictionary) -> bool:
	if not person.has("inventory"): return true # 04 records upgrade on load.
	if person.get("area") not in ["outside","workshop"]: return false
	if not person.inventory is Dictionary or not person.get("equipment") is Dictionary or not person.get("quest") is Dictionary: return false
	for key in ITEMS:
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
			person.quest.prepared = true
		"trade":
			if person.quest.complete: return "The carpenter has already paid you for this work."
			if not person.quest.prepared or person.inventory.wood < 6: return "Prepare your six wood at the bench first."
			person.inventory.wood -= 6
			person.inventory.ring += 1
			person.coins += 5
			person.woodcraft += 1
			person.quest.complete = true
			if "finger" not in person.discovered: person.discovered.append("finger")
			_ready_item(person,"ring")
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
