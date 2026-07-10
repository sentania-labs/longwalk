extends SceneTree

# Headless CLI entry point for the macro planet map generator.
#
# Invocation (see README.md and ARCHITECTURE.md):
#   godot --headless --script res://src/generate_map.gd -- --seed=<N> --out=<path-prefix>
#
# The `--` separates Godot's own arguments from the script arguments. Anything
# after `--` is passed through to this script via OS.get_cmdline_user_args().
#
# --seed=<N>   integer world seed (required, defaults to 0 if omitted)
# --out=<p>    output path prefix. The generator writes <p>.png and <p>.json.
#              Defaults to "res://examples/map" if omitted.
#
# Determinism: two runs with the same seed produce byte-identical .png and
# .json. See test/test_determinism.gd for the automated assertion.

const MacroMap := preload("res://src/macro_map.gd")


func _initialize() -> void:
	var args := _parse_args(OS.get_cmdline_user_args())

	var seed_value := int(args.get("seed", "0"))
	var out_prefix: String = args.get("out", "res://examples/map")

	print("[generate_map] seed=%d out=%s" % [seed_value, out_prefix])

	var generator := MacroMap.new(seed_value)
	var result := generator.generate()
	var image: Image = result["image"]
	var summary: Dictionary = result["summary"]

	var png_path := out_prefix + ".png"
	var json_path := out_prefix + ".json"

	_ensure_dir(png_path)

	var png_err := image.save_png(png_path)
	if png_err != OK:
		push_error("Failed to save PNG to %s (error %d)" % [png_path, png_err])
		quit(1)
		return

	# Pretty-print with a fixed 2-space indent so the JSON is stable and
	# human-readable. Keys are inserted in canonical order by the generator.
	var json_text := JSON.stringify(summary, "  ") + "\n"
	var f := FileAccess.open(json_path, FileAccess.WRITE)
	if f == null:
		push_error("Failed to open %s for writing" % json_path)
		quit(1)
		return
	f.store_string(json_text)
	f.close()

	# East-west wrap sanity check: sample the elevation noise at the far west
	# and far east columns. Because x is wrapped onto a cylinder, column 0 and
	# column width-1 are neighbors, so their elevations must be very close.
	# This is logged so headless runs and CI show the seam is continuous.
	var wrap_delta := _max_wrap_delta(generator)
	print("[generate_map] east-west wrap max |elevation delta| between x=0 and x=width-1: %f" % wrap_delta)
	if wrap_delta > 0.05:
		push_warning("East-west wrap discontinuity larger than expected: %f" % wrap_delta)

	print("[generate_map] wrote %s" % png_path)
	print("[generate_map] wrote %s" % json_path)
	print("[generate_map] land_fraction=%s" % str(summary["land_fraction"]))

	quit(0)


# Compute the maximum absolute elevation difference between the west edge
# (x=0) and the east edge (x=width-1) across all rows. Small values confirm
# the noise is seamless across the wrap.
func _max_wrap_delta(generator: MacroMap) -> float:
	var worst := 0.0
	for py in range(generator.height):
		var west: float = generator.elevation_at(0, py)
		var east: float = generator.elevation_at(generator.width - 1, py)
		worst = maxf(worst, absf(west - east))
	return worst


func _parse_args(raw: PackedStringArray) -> Dictionary:
	var parsed := {}
	for arg in raw:
		if arg.begins_with("--") and arg.contains("="):
			var trimmed := arg.substr(2)
			var eq := trimmed.find("=")
			var key := trimmed.substr(0, eq)
			var value := trimmed.substr(eq + 1)
			parsed[key] = value
	return parsed


func _ensure_dir(path: String) -> void:
	var dir := path.get_base_dir()
	if dir == "":
		return
	var abs_dir := ProjectSettings.globalize_path(dir)
	DirAccess.make_dir_recursive_absolute(abs_dir)
