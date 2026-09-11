extends RefCounted

static func validate(visuals: Variant, baseline: Dictionary, digest: String, keys: Array) -> String:
	if not visuals is Dictionary or visuals.get("schema") != 1 or visuals.get("baseline") != digest:
		return "Visual manifest does not match the server baseline"
	if not visuals.get("records") is Array or visuals.records.size() != baseline.placements.size():
		return "Visual manifest placement count mismatch"
	for i in range(visuals.records.size()):
		var record = visuals.records[i]
		if not record is Dictionary or record.get("id") != baseline.placements[i]:
			return "Visual manifest placement mismatch at index %d" % i
		if record.id.get_slice(":",0) not in keys:
			return "Unknown visual asset at index %d" % i
		if not valid_transform(record.get("transform")) or not record.get("models") is Array or record.models.is_empty():
			return "Invalid visual transform at index %d" % i
		for model in record.models:
			if not valid_transform(model): return "Invalid model transform at index %d" % i
	return ""

static func valid_transform(values: Variant) -> bool:
	if not values is Array or values.size() != 12: return false
	for value in values:
		if (not value is float and not value is int) or not is_finite(float(value)): return false
	return true
