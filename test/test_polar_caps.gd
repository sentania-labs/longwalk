extends SceneTree

# Polar cap band uniformity test (issue #2).
#
# Invocation (headless, wired into tools/run_tests.sh and CI):
#   godot --headless --script res://test/test_polar_caps.gd
#
# The world is sphere-traversable at the poles: crossing the north edge at
# longitude x re-enters from the north edge at longitude (x + width/2) heading
# south, mirrored at the south edge. The generator constraint that makes that
# crossing seamless is that the top and bottom polar_cap_rows() rows (a per
# seed, era-scaled depth) are uniform featureless ice: flat elevation, one
# biome, nothing to mismatch across the seam. This test asserts, per seed:
#
#   1. Cap uniformity: every cell in both cap bands has biome ice and elevation
#      exactly POLAR_ICE_ELEVATION (above sea level, so the cap is solid ice).
#   2. Polar crossing consistency: for every column x on the edge rows, the
#      cell at x and its crossing partner at (x + width/2) mod width agree on
#      elevation and biome. Given 1 this is implied, but it encodes the actual
#      traversal semantics so a future change that weakens 1 still gets caught.
#   3. Variation resumes below the band: the first row past each cap band is
#      not uniform (terrain begins there), so the cap flattening is not leaking
#      into the rest of the map.
#   4. Summary accounting: ice_tiles equals the exact band area, land ice plus
#      sea ice equals ice_tiles, and ice is excluded from land_tiles.
#
# Exit code 0 means pass, non-zero means fail.

const MacroMap := preload("res://src/macro_map.gd")

# Same seed set the landmass test uses, spanning all three archetypes.
const SEEDS := [1, 7, 12, 42]


func _initialize() -> void:
	var failures := 0

	for seed_value in SEEDS:
		failures += _check_seed(seed_value)

	if failures == 0:
		print("\nAll polar cap checks passed.")
		quit(0)
	else:
		print("\n%d polar cap check(s) FAILED." % failures)
		quit(1)


func _check_seed(seed_value: int) -> int:
	var generator := MacroMap.new(seed_value)
	var failures := 0

	var cap_rows := generator.polar_cap_rows()
	print("[seed %d] polar cap rows=%d (era %s) ice elevation=%f" % [
		seed_value, cap_rows, generator.era()["name"], MacroMap.POLAR_ICE_ELEVATION,
	])

	# 1. Cap uniformity: flat ice across both bands.
	var uniform := true
	for py in _cap_rows(generator):
		for px in range(generator.width):
			if generator.biome_for_cell(px, py) != MacroMap.BIOME_ICE:
				uniform = false
			if generator.elevation_at(px, py) != MacroMap.POLAR_ICE_ELEVATION:
				uniform = false
	if uniform:
		print("  [PASS] every cap band cell is flat featureless ice")
	else:
		print("  [FAIL] a cap band cell is not flat featureless ice")
		failures += 1

	# 2. Polar crossing consistency on the edge rows: x and (x + width/2) agree.
	var half := generator.width / 2
	var crossing_ok := true
	for edge_py in [0, generator.height - 1]:
		for px in range(generator.width):
			var partner := (px + half) % generator.width
			if generator.elevation_at(px, edge_py) != generator.elevation_at(partner, edge_py):
				crossing_ok = false
			if generator.biome_for_cell(px, edge_py) != generator.biome_for_cell(partner, edge_py):
				crossing_ok = false
	if crossing_ok:
		print("  [PASS] polar crossing partners agree on both edge rows")
	else:
		print("  [FAIL] a polar crossing partner pair mismatches on an edge row")
		failures += 1

	# 3. Terrain variation resumes immediately below each cap band.
	var north_row := cap_rows
	var south_row := generator.height - cap_rows - 1
	for row in [north_row, south_row]:
		if _row_varies(generator, row):
			print("  [PASS] row %d (first past a cap band) has terrain variation" % row)
		else:
			print("  [FAIL] row %d (first past a cap band) is uniform" % row)
			failures += 1

	# 4. Summary accounting.
	var summary: Dictionary = generator.generate()["summary"]
	var expected_ice: int = 2 * cap_rows * generator.width
	var ice_tiles: int = summary["ice_tiles"]
	var land_ice: int = summary["land_ice_tiles"]
	var sea_ice: int = summary["sea_ice_tiles"]
	print("  ice_tiles=%d (expect %d) land_ice=%d sea_ice=%d" % [ice_tiles, expected_ice, land_ice, sea_ice])
	if ice_tiles == expected_ice:
		print("  [PASS] ice_tiles equals the exact cap band area")
	else:
		print("  [FAIL] ice_tiles %d != band area %d" % [ice_tiles, expected_ice])
		failures += 1
	if land_ice + sea_ice == ice_tiles and land_ice >= 0 and sea_ice >= 0:
		print("  [PASS] land ice plus sea ice accounts for every cap cell")
	else:
		print("  [FAIL] land ice %d + sea ice %d != ice_tiles %d" % [land_ice, sea_ice, ice_tiles])
		failures += 1
	var total: int = summary["total_tiles"]
	var land: int = summary["land_tiles"]
	var ocean: int = summary["ocean_tiles"]
	var hypersaline: int = summary["hypersaline_tiles"]
	if land + ocean + hypersaline + ice_tiles == total:
		print("  [PASS] land, water and ice partition the map exactly")
	else:
		print("  [FAIL] land %d + ocean %d + hypersaline %d + ice %d != total %d" % [land, ocean, hypersaline, ice_tiles, total])
		failures += 1

	return failures


# Every row index inside the north and south cap bands.
func _cap_rows(generator: MacroMap) -> Array:
	var rows: Array = []
	for py in range(generator.polar_cap_rows()):
		rows.append(py)
		rows.append(generator.height - 1 - py)
	return rows


# True when the row has at least two distinct elevation values, i.e. it is not
# a flattened band.
func _row_varies(generator: MacroMap, py: int) -> bool:
	var first := generator.elevation_at(0, py)
	for px in range(1, generator.width):
		if generator.elevation_at(px, py) != first:
			return true
	return false
