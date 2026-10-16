extends SceneTree
# Run from an exported executable, including after Windows signing.
# Rendering is exercised separately with a real renderer in the CI build job.
func _initialize() -> void:
	_run.call_deferred()

func _require(condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
		quit(1)
	return condition

func _run() -> void:
	if not _require(not OS.has_feature("editor"), "Run this check from an exported client"): return
	var loader = load("res://asset_loader.gd")
	if not _require(loader != null, "Embedded asset loader missing"): return
	var manifest: Dictionary = loader.manifest()
	if not _require(manifest.get("protocol", "") == "shared-village-07", "Embedded client manifest missing"): return
	var art_path := OS.get_executable_path().get_base_dir().path_join(str(manifest.get("art_file", "")))
	var error: String = loader.mount(art_path)
	if not _require(error.is_empty(), error): return
	if not _require(ResourceLoader.exists("res://assets/barn.glb"), "Mounted art resources missing"): return
	if not _require(load("res://boot.tscn") is PackedScene, "Embedded client entry scene missing"): return
	if not _require(load("res://village.gd") is GDScript, "Embedded village script missing"): return
	var baseline = JSON.parse_string(FileAccess.get_file_as_string("res://world/baseline.json"))
	if not _require(baseline is Dictionary and not baseline.is_empty(), "Embedded world baseline missing"): return
	print("EXPORTED CLIENT CHECK PASSED: embedded client, manifest, baseline and verified external art")
	quit(0)
