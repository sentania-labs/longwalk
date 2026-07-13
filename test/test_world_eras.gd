extends SceneTree

# Hydrological era test (issue #4).
#
# Invocation (headless, wired into tools/run_tests.sh and CI):
#   godot --headless --script res://test/test_world_eras.gd
#
# Each seed derives a hydrological era (ice_age, temperate, warm) that sets a
# per-seed sea level and polar cap depth, and on ice-age worlds exposes former
# seabed biomes and remnant hypersaline seas. This test asserts:
#
#   Per fixed seed:
#   1. The JSON summary names the era, and the reported sea level and cap rows
#      sit inside the documented range for that era.
#   2. The load-bearing margins hold: the deepest possible ocean bias keeps
#      guaranteed ocean below the era sea level, and the cap ice elevation
#      stays above the era sea level (the cap is solid in every era).
#   3. Era mechanics show up in the map: an ice-age world exposes seabed
#      biomes (marsh, salt flat, basin), a non-ice-age world has none of them
#      and no hypersaline seas.
#
#   Across a seed sweep:
#   4. All three eras actually occur, so the selector is not degenerate.
#
# Exit code 0 means pass, non-zero means fail.

const MacroMap := preload("res://src/macro_map.gd")

# Documented era ranges (see the world-eras section in src/macro_map.gd).
# name: [sea_min, sea_max, cap_min, cap_max]
const ERA_RANGES := {
	"ice_age": [0.435, 0.465, 18, 25],
	"temperate": [0.49, 0.51, 10, 14],
	"warm": [0.52, 0.545, 5, 8],
}

# Fixed seeds (the committed example set) plus a sweep for era coverage.
const SEEDS := [1, 7, 12, 42]
const SWEEP_SIZE := 40


func _initialize() -> void:
	var failures := 0
	var eras_seen := {}

	for seed_value in SEEDS:
		failures += _check_seed(seed_value, eras_seen)

	# 4. Era coverage across a wider sweep (cheap: no map generation, the era
	# comes straight from the constructor).
	for seed_value in range(1, SWEEP_SIZE + 1):
		var generator := MacroMap.new(seed_value)
		eras_seen[generator.era()["name"]] = true
	var all_seen := eras_seen.has("ice_age") and eras_seen.has("temperate") and eras_seen.has("warm")
	if all_seen:
		print("\n[PASS] all three eras occur across seeds 1..%d" % SWEEP_SIZE)
	else:
		print("\n[FAIL] era selector looks degenerate across seeds 1..%d (%s)" % [SWEEP_SIZE, str(eras_seen.keys())])
		failures += 1

	if failures == 0:
		print("\nAll world era checks passed.")
		quit(0)
	else:
		print("\n%d world era check(s) FAILED." % failures)
		quit(1)


func _check_seed(seed_value: int, eras_seen: Dictionary) -> int:
	var generator := MacroMap.new(seed_value)
	var summary: Dictionary = generator.generate()["summary"]
	var failures := 0

	var era_name: String = summary["era"]
	var sea: float = summary["sea_level"]
	var cap_rows: int = summary["polar_cap_rows"]
	eras_seen[era_name] = true

	print("[seed %d] era=%s sea_level=%f cap_rows=%d" % [seed_value, era_name, sea, cap_rows])

	# 1. Era name is one we document, and sea level and cap rows are in range.
	if not ERA_RANGES.has(era_name):
		print("  [FAIL] unknown era name '%s' in summary" % era_name)
		return failures + 1
	var r: Array = ERA_RANGES[era_name]
	if sea >= float(r[0]) and sea <= float(r[1]):
		print("  [PASS] sea level %f inside the %s range [%f, %f]" % [sea, era_name, float(r[0]), float(r[1])])
	else:
		print("  [FAIL] sea level %f outside the %s range [%f, %f]" % [sea, era_name, float(r[0]), float(r[1])])
		failures += 1
	if cap_rows >= int(r[2]) and cap_rows <= int(r[3]):
		print("  [PASS] cap rows %d inside the %s range [%d, %d]" % [cap_rows, era_name, int(r[2]), int(r[3])])
	else:
		print("  [FAIL] cap rows %d outside the %s range [%d, %d]" % [cap_rows, era_name, int(r[2]), int(r[3])])
		failures += 1
	# The summary value is rounded to 6 decimals for stable JSON, so compare
	# with that tolerance.
	if absf(float(summary["sea_level"]) - generator.sea_level) < 0.000001 and era_name == generator.era()["name"]:
		print("  [PASS] summary era fields match the generator state")
	else:
		print("  [FAIL] summary era fields do not match the generator state")
		failures += 1

	# 2. Load-bearing margins for every era.
	if 1.0 + MacroMap.CONTINENT_OCEAN_BIAS < generator.sea_level:
		print("  [PASS] guaranteed-ocean bias stays below this era's sea level")
	else:
		print("  [FAIL] ocean bias %f cannot guarantee ocean below sea level %f" % [MacroMap.CONTINENT_OCEAN_BIAS, generator.sea_level])
		failures += 1
	if MacroMap.POLAR_ICE_ELEVATION > generator.sea_level:
		print("  [PASS] polar ice elevation stays above this era's sea level")
	else:
		print("  [FAIL] polar ice elevation %f is not above sea level %f" % [MacroMap.POLAR_ICE_ELEVATION, generator.sea_level])
		failures += 1

	# 3. Era mechanics in the biome distribution.
	var dist: Dictionary = summary["biome_distribution_of_land"]
	var seabed_fraction: float = float(dist.get(MacroMap.BIOME_MARSH, 0.0)) \
		+ float(dist.get(MacroMap.BIOME_SALT_FLAT, 0.0)) \
		+ float(dist.get(MacroMap.BIOME_BASIN, 0.0))
	var hypersaline: int = summary["hypersaline_tiles"]
	if era_name == "ice_age":
		if seabed_fraction > 0.0:
			print("  [PASS] ice-age world exposes seabed biomes (%f of land)" % seabed_fraction)
		else:
			print("  [FAIL] ice-age world has no exposed seabed biomes")
			failures += 1
	else:
		if seabed_fraction == 0.0 and hypersaline == 0:
			print("  [PASS] non-ice-age world has no exposed seabed and no hypersaline seas")
		else:
			print("  [FAIL] non-ice-age world reports seabed %f / hypersaline %d" % [seabed_fraction, hypersaline])
			failures += 1

	return failures
