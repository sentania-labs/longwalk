extends SceneTree

# Determinism test for the M2 sim-side layers (terrain sampler and spawn
# finder). Runs headless, the same way the macro map determinism test does.
#
# Invocation (this is run by tools/run_tests.sh after the macro map test):
#   godot --headless --script res://test/test_sim_determinism.gd
#
# It asserts:
#   - The terrain sampler returns byte-identical heights for the same (seed,
#     position) across two independently built samplers (pure function).
#   - A different seed changes the sampled heights (not a constant surface).
#   - The sampler agrees with the macro map on land vs ocean at macro-cell
#     centers (the hierarchical rule: detail refines, never contradicts).
#   - The spawn finder returns the same coastal cell for a fixed seed, that the
#     cell is land, and that it is adjacent to ocean.
# Exit code 0 means pass, non-zero means fail.

const MacroMap := preload("res://src/macro_map.gd")
const TerrainSamplerC := preload("res://src/sim/terrain_sampler.gd")
const SpawnFinderC := preload("res://src/sim/spawn_finder.gd")

const SEED_A := 424242
const SEED_B := 987654

# A fixed set of sample positions (world units) to probe.
const SAMPLE_POINTS := [
	Vector2(0.0, 0.0),
	Vector2(137.5, 902.25),
	Vector2(-58.0, 4210.0),
	Vector2(12287.0, 8191.0),
	Vector2(6144.0, 4096.0),
]


func _initialize() -> void:
	var failures := 0

	failures += _test_sampler_determinism()
	failures += _test_sampler_varies_by_seed()
	failures += _test_sampler_agrees_with_macro()
	failures += _test_detail_never_flips_coast()
	failures += _test_spawn_determinism()

	if failures == 0:
		print("\nAll sim determinism checks passed.")
		quit(0)
	else:
		print("\n%d sim determinism check(s) FAILED." % failures)
		quit(1)


func _make_sampler(seed_value: int):
	var generator := MacroMap.new(seed_value)
	return TerrainSamplerC.new(generator)


func _test_sampler_determinism() -> int:
	var s1 = _make_sampler(SEED_A)
	var s2 = _make_sampler(SEED_A)
	for p in SAMPLE_POINTS:
		var h1: float = s1.height_at(p.x, p.y)
		var h2: float = s2.height_at(p.x, p.y)
		if h1 != h2:
			print("[FAIL] sampler height differs for same seed at %s (%f vs %f)" % [p, h1, h2])
			return 1
	print("[PASS] terrain sampler is deterministic for a fixed seed")
	return 0


func _test_sampler_varies_by_seed() -> int:
	var sa = _make_sampler(SEED_A)
	var sb = _make_sampler(SEED_B)
	var any_different := false
	for p in SAMPLE_POINTS:
		if sa.height_at(p.x, p.y) != sb.height_at(p.x, p.y):
			any_different = true
			break
	if any_different:
		print("[PASS] terrain sampler varies with the seed")
		return 0
	print("[FAIL] terrain sampler produced identical heights for different seeds")
	return 1


func _test_sampler_agrees_with_macro() -> int:
	# At macro-cell centers, the bilinear base equals the authoritative macro
	# elevation, so land/ocean classification must agree with the macro map.
	var generator := MacroMap.new(SEED_A)
	var sampler = TerrainSamplerC.new(generator)
	var cell_size: float = TerrainSamplerC.MACRO_CELL_SIZE
	var mismatches := 0
	var checked := 0
	# Probe a coarse grid of macro cells.
	for py in range(0, generator.height, 17):
		for px in range(0, generator.width, 23):
			var wx := (float(px) + 0.5) * cell_size
			var wz := (float(py) + 0.5) * cell_size
			var macro_land: bool = generator.elevation_at(px, py) >= generator.sea_level
			# Compare against the bilinear base (detail excluded), which is what
			# must agree with the macro map exactly at cell centers.
			var base_land: bool = sampler.macro_elevation01(wx, wz) >= generator.sea_level
			checked += 1
			if macro_land != base_land:
				mismatches += 1
	if mismatches == 0:
		print("[PASS] sampler base agrees with macro land/ocean at cell centers (%d checked)" % checked)
		return 0
	print("[FAIL] sampler base disagreed with macro map at %d of %d cell centers" % [mismatches, checked])
	return 1


# The local-detail layer must never move the surface across sea level: at every
# position the detailed elevation must land on the same side of sea level as the
# authoritative macro base. This guards the hierarchical rule (detail refines,
# never contradicts) that spawn selection and biome lookup rely on.
func _test_detail_never_flips_coast() -> int:
	var generator := MacroMap.new(SEED_A)
	var sampler = TerrainSamplerC.new(generator)
	var cell_size: float = TerrainSamplerC.MACRO_CELL_SIZE
	var sea: float = generator.sea_level
	var flips := 0
	var checked := 0
	# Sample a fine grid (including off-center points) so near-shore cells and
	# their interiors are all exercised.
	for gy in range(0, generator.height * 2, 3):
		for gx in range(0, generator.width * 2, 5):
			var wx := float(gx) * cell_size * 0.5
			var wz := float(gy) * cell_size * 0.5
			var base_land: bool = sampler.macro_elevation01(wx, wz) >= sea
			var detailed_land: bool = sampler.elevation01_at(wx, wz) >= sea
			checked += 1
			if base_land != detailed_land:
				flips += 1
	if flips == 0:
		print("[PASS] local detail never flips land/ocean across sea level (%d points)" % checked)
		return 0
	print("[FAIL] local detail flipped land/ocean at %d of %d points" % [flips, checked])
	return 1


func _test_spawn_determinism() -> int:
	var failures := 0
	var g1 := MacroMap.new(SEED_A)
	var g2 := MacroMap.new(SEED_A)
	var spawn1: Dictionary = SpawnFinderC.new(g1).find_spawn()
	var spawn2: Dictionary = SpawnFinderC.new(g2).find_spawn()

	if spawn1["cell"] == spawn2["cell"] and spawn1["landmass_size"] == spawn2["landmass_size"]:
		print("[PASS] spawn is deterministic for a fixed seed (cell=%s, landmass=%d)" % [spawn1["cell"], spawn1["landmass_size"]])
	else:
		print("[FAIL] spawn differs across runs (%s vs %s)" % [spawn1["cell"], spawn2["cell"]])
		failures += 1

	if not spawn1["found"]:
		print("[FAIL] spawn finder found no landmass for seed %d" % SEED_A)
		return failures + 1

	var cell: Vector2i = spawn1["cell"]
	if g1.elevation_at(cell.x, cell.y) >= g1.sea_level:
		print("[PASS] spawn cell is land")
	else:
		print("[FAIL] spawn cell is not land")
		failures += 1

	# Confirm the spawn cell is coastal (adjacent to ocean).
	var coastal := false
	var offsets := [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]
	for o in offsets:
		var nx: int = ((cell.x + o.x) % g1.width + g1.width) % g1.width
		var ny: int = cell.y + o.y
		if ny < 0 or ny >= g1.height:
			continue
		if g1.elevation_at(nx, ny) < g1.sea_level:
			coastal = true
			break
	if coastal:
		print("[PASS] spawn cell is coastal (adjacent to ocean)")
	else:
		print("[FAIL] spawn cell is not coastal")
		failures += 1

	return failures
