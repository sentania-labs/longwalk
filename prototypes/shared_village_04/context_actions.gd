extends RefCounted

static func choices(kind: String, cut: bool, nearby: bool, can_move: bool) -> Array:
	var actions := [{"id":"walk","label":"Walk here","enabled":can_move},{"id":"run","label":"Run here","enabled":can_move},{"id":"inspect","label":"Inspect","enabled":true}]
	if kind == "square_oak":
		actions[0].label = "Walk to square oak"
		actions[1].label = "Run to square oak"
		if cut: actions.append({"id":"harvest","label":"Already harvested","enabled":false})
		else: actions.append({"id":"harvest","label":"Harvest square oak" if nearby else "Harvest (move closer first)","enabled":nearby and can_move})
	return actions
