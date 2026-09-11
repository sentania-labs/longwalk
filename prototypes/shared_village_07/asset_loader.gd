extends RefCounted
const SETTINGS = "user://art-location.cfg"
static func manifest() -> Dictionary:
	var value = JSON.parse_string(FileAccess.get_file_as_string("res://release_manifest.json"))
	return value if value is Dictionary else {}

static func selected_path() -> String:
	var settings := ConfigFile.new()
	settings.load(SETTINGS)
	var fallback := OS.get_executable_path().get_base_dir().path_join(manifest().get("art_file","Longwalk-Art-01.pck"))
	var saved = settings.get_value("art",manifest().get("art_sha256","unknown"),fallback)
	return saved if saved is String else fallback

static func validate(path: String) -> String:
	var expected := manifest()
	if expected.get("art_sha256","").length()!=64: return "This client is missing its art manifest. Extract the complete client package again."
	if not FileAccess.file_exists(path): return "The art pack could not be found. Keep Longwalk-Art-01.pck beside the EXE, or locate your existing copy below."
	if FileAccess.get_sha256(path) != expected.art_sha256: return "This art pack does not match the client. Choose the matching pack from the same release."
	return ""

static func mount(path: String) -> String:
	var error := validate(path)
	if error != "": return error
	# Art cannot replace bootstrap scripts or settings already in the client pack.
	if not ProjectSettings.load_resource_pack(path,false): return "The verified art pack could not be opened. Extract a fresh copy."
	return ""

static func remember(path: String) -> bool:
	var settings := ConfigFile.new()
	settings.load(SETTINGS)
	settings.set_value("art",manifest().get("art_sha256","unknown"),path)
	return settings.save(SETTINGS) == OK
