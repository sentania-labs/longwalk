extends RefCounted

# Immutable, numbered snapshots form a small append-only state journal.
# Only a complete validated record becomes an acknowledged revision.
var directory: String
var baseline: String
var generation := 0
var error := ""

func initialize(path: String, version: String) -> Dictionary:
	directory = path
	baseline = version
	if DirAccess.make_dir_recursive_absolute(directory) != OK:
		error = "Cannot create world data directory"
		return {}
	var names := records("state-")
	if names.is_empty(): return {"schema":2,"baseline":baseline,"revision":0,"players":{},"owner":"","cut":false,"config":{"save_interval":5.0,"max_players":4},"paused":false}
	var name: String = names.back()
	generation = name.trim_prefix("state-").trim_suffix(".json").to_int()
	return read_record(name)

func records(prefix: String) -> Array[String]:
	var result: Array[String] = []
	for name in DirAccess.get_files_at(directory):
		if name.begins_with(prefix) and name.ends_with(".json"): result.append(name)
	result.sort()
	return result

func read_record(name: String) -> Dictionary:
	if name.get_file() != name:
		error = "Invalid record name"
		return {}
	var envelope = JSON.parse_string(FileAccess.get_file_as_string(directory.path_join(name)))
	if not envelope is Dictionary or not envelope.get("payload") is String or not envelope.get("checksum") is String:
		error = "Invalid save envelope: " + name
		return {}
	if envelope.payload.sha256_text() != envelope.checksum:
		error = "Save checksum mismatch: " + name
		return {}
	var state = JSON.parse_string(envelope.payload)
	if not valid_state(state):
		error = "Invalid or incompatible world record: " + name
		return {}
	return state

func valid_state(state: Variant) -> bool:
	if not state is Dictionary: return false
	if (state.get("schema") != 1 and state.get("schema") != 2) or state.get("baseline") != baseline: return false
	if state.has("clock") and (not state.clock is float and not state.clock is int or not is_finite(float(state.clock)) or state.clock<0 or state.clock>=1440): return false
	if not state.get("players") is Dictionary or not state.get("config") is Dictionary or not state.get("cut") is bool: return false
	if not state.get("owner") is String or not state.get("paused") is bool: return false
	if not state.get("revision") is float and not state.get("revision") is int: return false
	var cfg: Dictionary = state.config
	if not cfg.get("save_interval") is float and not cfg.get("save_interval") is int: return false
	if float(cfg.save_interval)<1 or float(cfg.save_interval)>60: return false
	if not cfg.get("max_players") is float and not cfg.get("max_players") is int: return false
	if int(cfg.max_players)<2 or int(cfg.max_players)>16: return false
	for ident in state.players:
		var person = state.players[ident]
		if not ident is String or ident.length()!=64 or not person is Dictionary: return false
		if not person.get("position") is Array or person.position.size()!=3: return false
		for v in person.position:
			if (not v is float and not v is int) or not is_finite(float(v)): return false
		if state.schema == 2 and not person.has("inventory"): return false
		if not preload("res://src/sim/workshop.gd").valid(person): return false
		if absf(person.position[0])>511 or absf(person.position[2])>511 or absf(person.position[1])>5: return false
	return true

func write_record(name: String, state: Dictionary) -> bool:
	error = ""
	if FileAccess.file_exists(directory.path_join(name)):
		error = "Refusing to replace an existing world record"
		return false
	if not valid_state(state):
		error = "Refusing to write invalid world state"
		return false
	var payload := JSON.stringify(state)
	var temporary := directory.path_join(name + ".pending")
	var file := FileAccess.open(temporary,FileAccess.WRITE)
	if file == null:
		error = "Cannot open world storage for writing"
		return false
	file.store_string(JSON.stringify({"payload":payload,"checksum":payload.sha256_text()}))
	file.flush()
	var result := file.get_error()
	file.close()
	if result != OK:
		error = "World storage write failed"
		return false
	# Validate bytes read back before atomically publishing the new record.
	var verify = read_record(name + ".pending")
	if verify.is_empty(): return false
	if DirAccess.rename_absolute(temporary,directory.path_join(name)) != OK:
		error = "World storage publish failed"
		return false
	return true

func save(state: Dictionary) -> bool:
	var next := generation + 1
	if not write_record("state-%012d.json" % next,state): return false
	generation = next
	return true

func backup(state: Dictionary) -> String:
	var suffix := Crypto.new().generate_random_bytes(6).hex_encode()
	var name := "backup-%012d-%s.json" % [generation,suffix]
	return name if write_record(name,state) else ""
