extends SceneTree

# Landmass isolation test for the macro planet map generator (see issue #1).
#
# Invocation (headless, wired into tools/run_tests.sh and CI):
#   godot --headless --script res://test/test_landmass.gd
#
# The continent-mask layer is supposed to break the old single blobby
# landmass into several distinct, isolated continents separated by ocean.
# This test regenerates a few seeds and asserts, for the default parameters:
#
#   1. At least MIN_SIGNIFICANT_LANDMASSES land connected components each of at
#      least LANDMASS_MIN_SIZE tiles exist (distinct landmasses above a minimum
#      size). Multiple components means they are separated by non-land, i.e.
#      ocean, so the continents are genuinely isolated.
#   2. Every reported significant landmass is actually at or above the minimum
#      size (guards the metric itself).
#   3. No single landmass dominates: the largest landmass is below
#      MAX_LARGEST_FRACTION of total land, so we are not back to one big blob.
#   4. There is a healthy amount of ocean (land_fraction well below 0.5), which
#      is the deep ocean the mask guarantees between continents.
#
# Exit code 0 means pass, non-zero means fail. This test does not re-check
# byte-for-byte determinism; that stays in test/test_determinism.gd.

const MacroMap := preload("res://src/macro_map.gd")

# Seeds exercised. These match the committed example maps so the test and the
# examples/ artifacts stay in agreement.
const SEEDS := [1, 7, 42]

# A seed must yield at least this many distinct significant landmasses.
const MIN_SIGNIFICANT_LANDMASSES := 3
# No single landmass may exceed this fraction of total land.
const MAX_LARGEST_FRACTION := 0.6
# Land must stay below this fraction of the map (the rest is guaranteed ocean).
const MAX_LAND_FRACTION := 0.5


func _initialize() -> void:
	var failures := 0

	for seed_value in SEEDS:
		failures += _check_seed(seed_value)

	if failures == 0:
		print("\nAll landmass isolation checks passed.")
		quit(0)
	else:
		print("\n%d landmass isolation check(s) FAILED." % failures)
		quit(1)


func _check_seed(seed_value: int) -> int:
	var generator := MacroMap.new(seed_value)
	var summary: Dictionary = generator.generate()["summary"]

	var failures := 0

	var significant_count: int = summary["significant_landmass_count"]
	var min_size: int = summary["significant_landmass_min_size"]
	var sizes: Array = summary["landmass_sizes"]
	var largest_fraction: float = summary["largest_landmass_fraction"]
	var land_fraction: float = summary["land_fraction"]

	print("[seed %d] significant_landmasses=%d sizes=%s largest_fraction=%f land_fraction=%f" % [
		seed_value, significant_count, str(sizes), largest_fraction, land_fraction,
	])

	# 1. Enough distinct isolated landmasses.
	if significant_count >= MIN_SIGNIFICANT_LANDMASSES:
		print("  [PASS] at least %d significant landmasses" % MIN_SIGNIFICANT_LANDMASSES)
	else:
		print("  [FAIL] only %d significant landmasses (need >= %d)" % [significant_count, MIN_SIGNIFICANT_LANDMASSES])
		failures += 1

	# 2. The reported list agrees with the count and the minimum size.
	if sizes.size() == significant_count:
		print("  [PASS] reported size list length matches significant count")
	else:
		print("  [FAIL] size list length %d != significant count %d" % [sizes.size(), significant_count])
		failures += 1

	var all_above_min := true
	for s in sizes:
		if int(s) < min_size:
			all_above_min = false
	if all_above_min:
		print("  [PASS] every significant landmass is >= %d tiles" % min_size)
	else:
		print("  [FAIL] a reported significant landmass is below %d tiles" % min_size)
		failures += 1

	# 3. No single blob dominates.
	if largest_fraction < MAX_LARGEST_FRACTION:
		print("  [PASS] largest landmass is %f of land (< %f)" % [largest_fraction, MAX_LARGEST_FRACTION])
	else:
		print("  [FAIL] largest landmass is %f of land (>= %f, too blobby)" % [largest_fraction, MAX_LARGEST_FRACTION])
		failures += 1

	# 4. Plenty of ocean between continents.
	if land_fraction < MAX_LAND_FRACTION:
		print("  [PASS] land_fraction %f leaves deep ocean between continents" % land_fraction)
	else:
		print("  [FAIL] land_fraction %f too high, ocean gaps not guaranteed" % land_fraction)
		failures += 1

	return failures
