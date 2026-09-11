extends SceneTree
const WORK = preload("res://src/sim/workshop.gd")
func _initialize() -> void:
	var p := {"position":[0,0,9]}
	WORK.ensure(p)
	assert(WORK.valid(p))
	assert(WORK.apply(p,"enter",{}) != "")
	p.position = [-102,0,-74]
	assert(WORK.apply(p,"enter",{}) == "")
	p.position = [-5,0,2]
	assert(WORK.apply(p,"wood",{}) == "")
	assert(WORK.apply(p,"wood",{}) != "" and p.inventory.wood == 6)
	p.position = [5,0,-3]
	assert(WORK.apply(p,"tool",{}) == "")
	assert("hand" in p.discovered)
	assert(WORK.apply(p,"use",{"item":"axe"}) == "")
	p.position = [-5,0,-3]
	assert(WORK.apply(p,"bench",{}) == "")
	p.position = [0,0,-3]
	assert(WORK.apply(p,"trade",{}) == "")
	assert(WORK.apply(p,"trade",{}) != "")
	assert(p.coins == 5 and p.inventory.wood == 0 and p.inventory.ring == 1 and "finger" in p.discovered)
	assert(WORK.apply(p,"use",{"item":"ring"}) == "" and p.equipment.finger == "ring")
	assert(WORK.apply(p,"use",{"item":"potion"}) != "" and p.inventory.potion == 1)
	p.stamina = 40
	assert(WORK.apply(p,"use",{"item":"bread"}) == "" and p.stamina == 65 and p.inventory.bread == 1)
	assert(WORK.valid(p))
	p.position = [0,0,5]
	assert(WORK.apply(p,"exit",{}) == "" and p.area == "outside")
	var invalid := p.duplicate(true)
	invalid.inventory.ring = -1
	assert(not WORK.valid(invalid))
	print("WORKSHOP PASSED: discovery, enter/exit, item use, equip, commission, duplicate prevention, validation")
	quit()
