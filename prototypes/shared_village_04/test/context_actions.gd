extends SceneTree
const ACTIONS = preload("res://context_actions.gd")
func _initialize() -> void:
	assert(ACTIONS.choices("ground",false,false,true).size() == 3)
	assert(not ACTIONS.choices("square_oak",false,false,true)[3].enabled)
	assert(ACTIONS.choices("square_oak",false,true,true)[3].enabled)
	assert(ACTIONS.choices("square_oak",true,true,true)[3].label == "Already harvested")
	assert(not ACTIONS.choices("square_oak",false,true,false)[3].enabled)
	assert(not ACTIONS.choices("ground",false,false,false)[0].enabled)
	assert(ACTIONS.choices("ground",false,false,false)[2].enabled)
	print("CONTEXT ACTIONS PASSED: ground, range, harvested, offline and paused states")
	quit()
