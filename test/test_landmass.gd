extends SceneTree

# Landmass isolation and archetype test for the macro planet map generator.
#
# Invocation (headless, wired into tools/run_tests.sh and CI):
#   godot --headless --script res://test/test_landmass.gd
#
# The continent-mask layer breaks the old single blobby landmass into distinct,
# ocean-separated continents. Each continent is now a GROUP of overlapping lobes
# that merge into one irregular landmass; the isolation guarantee applies between
# groups. How much land a world has, how many continents, and how their sizes
# spread is itself derived from the seed (the world "archetype", see
# MacroMapGenerator._build_archetype): most seeds are CONTINENTAL (one near
# supercontinent plus mid and small continents and scattered islands, roughly a
# quarter to two fifths land), with an OCEANIC water-world tail and a
# CONTINENT_HEAVY dry tail. This variety is a feature, so this test does NOT
# assert one fixed universal land fraction. Instead, for each seed it reads that
# seed's own derived archetype and asserts:
#
#   1. Land fraction falls inside the seed's archetype land band.
#   2. There are at least the archetype's minimum significant landmasses (land
#      connected components at or above LANDMASS_MIN_SIZE tiles). Multiple
#      components means they are separated by ocean, so continents are isolated.
#   3. Every reported significant landmass is actually at or above the minimum
#      size, and the reported list length matches the count (guards the metric).
#   4. Size hierarchy: for archetypes with a dominant continent (continental and
#      continent_heavy set a non-zero archetype min_largest_fraction), the largest
#      landmass holds at least that share of all land, so the world reads as one
#      dominant mass plus smaller ones, not N equal-size blobs. Oceanic sets the
#      floor to 0.0, which disables the check (a water world has no dominant mass).
#
# Two invariants are hard and hold for EVERY seed regardless of archetype:
#
#   A. Isolation: the smallest ocean band between any two placed continents of
#      DIFFERENT groups (min_center_extent_gap) stays at or above twice the
#      domain-warp amplitude, so the warp can never close a gap and make two
#      distinct landmasses (or an archipelago and a continent) touch. Lobes within
#      one group are meant to merge and are not separated.
#   B. Determinism (byte-identical PNG/JSON per seed) is covered separately in
#      test/test_determinism.gd and is not re-checked here.
#
# Exit code 0 means pass, non-zero means fail.

const MacroMap := preload("res://src/macro_map.gd")

# Seeds exercised. These match the committed example maps so the test and the
# examples/ artifacts stay in agreement. They deliberately span archetypes:
# seed 1 is continent_heavy (a dry world), seeds 7 and 12 are the typical
# continental case (a near-supercontinent plus mid, small and island masses),
# and seed 42 is an oceanic water world.
const SEEDS := [1, 7, 12, 42]


func _initialize() -> void:
	var failures := 0

	for seed_value in SEEDS:
		failures += _check_seed(seed_value)

	if failures == 0:
		print("\nAll landmass isolation and archetype checks passed.")
		quit(0)
	else:
		print("\n%d landmass/archetype check(s) FAILED." % failures)
		quit(1)


func _check_seed(seed_value: int) -> int:
	var generator := MacroMap.new(seed_value)
	var summary: Dictionary = generator.generate()["summary"]

	# The expected bounds come from the SAME archetype-derivation the generator
	# uses, so the test asserts against this seed's own derived world, not one
	# universal expectation.
	var arch: Dictionary = generator.archetype()
	var band_min: float = float(arch["land_band_min"])
	var band_max: float = float(arch["land_band_max"])
	var min_significant: int = int(arch["min_significant"])
	var min_largest_fraction: float = float(arch["min_largest_fraction"])

	var failures := 0

	var significant_count: int = summary["significant_landmass_count"]
	var min_size: int = summary["significant_landmass_min_size"]
	var sizes: Array = summary["landmass_sizes"]
	var land_fraction: float = summary["land_fraction"]
	var largest_fraction: float = summary["largest_landmass_fraction"]
	var gap: float = generator.min_center_extent_gap()

	print("[seed %d] archetype=%s land_fraction=%f band=[%f,%f] significant=%d (need >= %d) largest_frac=%f (need >= %f) sizes=%s gap=%f" % [
		seed_value, arch["name"], land_fraction, band_min, band_max,
		significant_count, min_significant, largest_fraction, min_largest_fraction, str(sizes), gap,
	])

	# 1. Land fraction inside this seed's archetype band.
	if land_fraction >= band_min and land_fraction <= band_max:
		print("  [PASS] land_fraction %f within archetype band [%f, %f]" % [land_fraction, band_min, band_max])
	else:
		print("  [FAIL] land_fraction %f outside archetype band [%f, %f]" % [land_fraction, band_min, band_max])
		failures += 1

	# 2. Enough distinct isolated landmasses for this archetype.
	if significant_count >= min_significant:
		print("  [PASS] at least %d significant landmasses" % min_significant)
	else:
		print("  [FAIL] only %d significant landmasses (need >= %d)" % [significant_count, min_significant])
		failures += 1

	# 3. The reported list agrees with the count and the minimum size.
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

	# 4. Size hierarchy: for archetypes with a dominant continent, the largest
	# landmass must hold at least the archetype's min_largest_fraction of all land.
	# A 0.0 floor (oceanic) disables the check.
	if min_largest_fraction <= 0.0:
		print("  [PASS] size-hierarchy floor not asserted for this archetype")
	elif largest_fraction >= min_largest_fraction:
		print("  [PASS] largest landmass fraction %f dominates (>= %f)" % [largest_fraction, min_largest_fraction])
	else:
		print("  [FAIL] largest landmass fraction %f below dominance floor %f" % [largest_fraction, min_largest_fraction])
		failures += 1

	# A. Hard isolation invariant for every seed: the smallest ocean band between
	# any two continents clears twice the warp amplitude, so distinct landmasses
	# can never touch. A gap < 0 means fewer than two continents were placed
	# (nothing to separate), which trivially satisfies isolation.
	var min_gap := 2.0 * MacroMap.CONTINENT_WARP_AMP
	if gap < 0.0 or gap >= min_gap:
		print("  [PASS] continent isolation gap %f clears the warp margin %f" % [gap, min_gap])
	else:
		print("  [FAIL] continent isolation gap %f below warp margin %f (landmasses could touch)" % [gap, min_gap])
		failures += 1

	return failures
