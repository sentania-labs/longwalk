extends SceneTree
func _initialize() -> void:
	var work = load("res://src/sim/workshop.gd")
	var person := {"position":[0,0,0]}
	work.ensure(person)
	assert(work.apply(person,"rename",{"name":"Grumpy Farmer"}) == "")
	assert(person.display_name == "Grumpy Farmer" and work.valid(person))
	assert(work.apply(person,"rename",{"name":""}) != "")
	assert(work.apply(person,"rename",{"name":" ",}) != "")
	assert(work.apply(person,"rename",{"name":"a".repeat(25)}) != "")
	assert(work.apply(person,"rename",{"name":"<b>bad</b>"}) != "")
	assert(work.apply(person,"rename",{"name":"Élodie"}) == "")
	print("CHARACTER NAME PASSED: saved display name, Unicode, empty/oversized/markup rejected")
	quit()
