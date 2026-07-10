extends SceneTree

# Determinism test for the macro planet map generator.
#
# Invocation (headless, this is what CI runs):
#   godot --headless --script res://test/test_determinism.gd
#
# The test generates the map twice with the same seed, saves both the PNG and
# the JSON each time, and asserts the two PNGs are byte-identical and the two
# JSON files are byte-identical. It also asserts that a DIFFERENT seed produces
# a different PNG (so the test cannot pass trivially by producing a constant
# image). Exit code 0 means pass, non-zero means fail.

const MacroMap := preload("res://src/macro_map.gd")

const SEED_A := 424242
const SEED_B := 987654


func _initialize() -> void:
	var failures := 0

	var a1 := _render(SEED_A, "a1")
	var a2 := _render(SEED_A, "a2")
	var b1 := _render(SEED_B, "b1")

	# Same seed must give byte-identical PNG.
	if a1["png"] == a2["png"]:
		print("[PASS] same-seed PNG is byte-identical (%d bytes)" % a1["png"].size())
	else:
		print("[FAIL] same-seed PNG differs (%d vs %d bytes)" % [a1["png"].size(), a2["png"].size()])
		failures += 1

	# Same seed must give byte-identical JSON.
	if a1["json"] == a2["json"]:
		print("[PASS] same-seed JSON is byte-identical (%d bytes)" % a1["json"].size())
	else:
		print("[FAIL] same-seed JSON differs")
		print("  first : %s" % a1["json"].get_string_from_utf8())
		print("  second: %s" % a2["json"].get_string_from_utf8())
		failures += 1

	# A different seed must produce a different PNG (guards against a constant
	# or all-ocean output that would pass the identity check trivially).
	if a1["png"] != b1["png"]:
		print("[PASS] different seed produces a different PNG")
	else:
		print("[FAIL] different seed produced an identical PNG")
		failures += 1

	# Sanity: the map must contain some land and some ocean.
	var land_fraction: float = a1["summary"]["land_fraction"]
	if land_fraction > 0.01 and land_fraction < 0.99:
		print("[PASS] map has a mix of land and ocean (land_fraction=%f)" % land_fraction)
	else:
		print("[FAIL] degenerate map, land_fraction=%f" % land_fraction)
		failures += 1

	# East-west wrap: the west and east edges must be continuous.
	var wrap_delta := _wrap_delta(SEED_A)
	if wrap_delta < 0.05:
		print("[PASS] east-west wrap is seamless (max edge delta=%f)" % wrap_delta)
	else:
		print("[FAIL] east-west wrap seam detected (max edge delta=%f)" % wrap_delta)
		failures += 1

	if failures == 0:
		print("\nAll determinism checks passed.")
		quit(0)
	else:
		print("\n%d determinism check(s) FAILED." % failures)
		quit(1)


# Render a map for the given seed, save PNG + JSON to user:// temp files, and
# return the raw bytes of each plus the summary dictionary.
func _render(seed_value: int, tag: String) -> Dictionary:
	var generator := MacroMap.new(seed_value)
	var result := generator.generate()
	var image: Image = result["image"]
	var summary: Dictionary = result["summary"]

	var png_path := "user://det_%s.png" % tag
	var json_path := "user://det_%s.json" % tag

	image.save_png(png_path)
	var json_text := JSON.stringify(summary, "  ") + "\n"
	var jf := FileAccess.open(json_path, FileAccess.WRITE)
	jf.store_string(json_text)
	jf.close()

	return {
		"png": FileAccess.get_file_as_bytes(png_path),
		"json": FileAccess.get_file_as_bytes(json_path),
		"summary": summary,
	}


func _wrap_delta(seed_value: int) -> float:
	var generator := MacroMap.new(seed_value)
	var worst := 0.0
	for py in range(generator.height):
		var west: float = generator.elevation_at(0, py)
		var east: float = generator.elevation_at(generator.width - 1, py)
		worst = maxf(worst, absf(west - east))
	return worst
