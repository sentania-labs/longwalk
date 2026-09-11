extends SceneTree
const STORE = preload("res://src/sim/world_store.gd")
var failures := 0
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func _initialize() -> void:
	var folder := "/tmp/longwalk-store-check-" + Crypto.new().generate_random_bytes(6).hex_encode()
	var store := STORE.new()
	var baseline := FileAccess.get_sha256("res://world/baseline.json")
	var state := store.initialize(folder,baseline)
	check(not state.is_empty(),"Fresh defaults load")
	check(store.save(state),"Initial snapshot saved")
	var backup := store.backup(state)
	check(not backup.is_empty(),"Backup created")
	state.cut = true
	state.revision = 1
	check(store.save(state),"Tree change saved")
	var reload := STORE.new()
	var loaded := reload.initialize(folder,baseline)
	check(loaded.get("cut",false),"Latest saved tree state reloads")
	check(not store.read_record(backup).cut,"Backup preserves prior state")
	var file := FileAccess.open(folder.path_join("state-000000000003.json.pending"),FileAccess.WRITE)
	file.store_string("incomplete write")
	file.close()
	check(reload.initialize(folder,baseline).get("cut",false),"Unpublished partial write does not replace committed state")
	file = FileAccess.open(folder.path_join("state-000000000003.json"),FileAccess.WRITE)
	file.store_string("corrupt committed record")
	file.close()
	check(reload.initialize(folder,baseline).is_empty(),"Corrupt latest save fails closed")
	check(not reload.error.is_empty(),"Corruption produces visible error")
	var wrong := STORE.new()
	check(wrong.initialize(folder,"wrong-version").is_empty(),"Incompatible baseline is rejected")
	store.directory = "/proc/longwalk-storage-denied"
	check(not store.save(state),"Unavailable storage cannot acknowledge a save")
	if failures == 0: print("STORAGE CHECKS PASSED: checkpoints, backup, incomplete writes, corruption, version mismatch, unavailable storage")
	quit(1 if failures else 0)
