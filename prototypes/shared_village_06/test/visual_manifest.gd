extends SceneTree
const MANIFEST = preload("res://visual_manifest.gd")
func _initialize() -> void:
	var baseline: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://world/baseline.json"))
	var visuals: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://world/visuals.json"))
	var digest := FileAccess.get_sha256("res://world/baseline.json")
	var keys := []
	for id in baseline.placements:
		var key: String = id.get_slice(":",0)
		if key not in keys: keys.append(key)
	assert(MANIFEST.validate(visuals,baseline,digest,keys) == "")
	assert(MANIFEST.validate(visuals,baseline,"different-world",keys) != "")
	var bad: Dictionary = visuals.duplicate(true)
	bad.records[0].id = "incorrect"
	assert(MANIFEST.validate(bad,baseline,digest,keys).contains("index 0"))
	bad = visuals.duplicate(true)
	bad.records.pop_back()
	assert(MANIFEST.validate(bad,baseline,digest,keys).contains("count"))
	bad = visuals.duplicate(true)
	bad.records[0].transform[0] = NAN
	assert(MANIFEST.validate(bad,baseline,digest,keys).contains("transform"))
	# Frozen matrices retain sub-millimeter precision beyond the old rounded IDs.
	var precise := false
	for record in visuals.records:
		if absf(record.transform[9]-float(record.id.get_slice(":",1))) > 0.000001: precise = true
	assert(precise)
	print("VISUAL MANIFEST PASSED: 3099 exact identities; full transforms; incompatible or corrupt records rejected")
	quit()
