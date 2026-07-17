extends SceneTree

# Headless tests for the SIM-side navigation grid (src/sim/nav_grid.gd) and
# the invariants that let the render layer's colliders agree with it by
# construction rather than by runtime exception (decision record
# docs/decisions/003-village-feel.md).
#
# No display server, no physics, no scene tree: NavGrid is a pure function of
# (layout, from, to), and these tests exercise it as one.
#
# Invocation (run by tools/run_tests.sh):
#   godot --headless --script res://test/active_path/test_nav_grid.gd

const TownLayoutScript := preload("res://src/sim/town_layout.gd")
const NavGridScript := preload("res://src/sim/nav_grid.gd")
const PlayerScene := preload("res://scenes/player.tscn")

const STREET_Y := 7


func _initialize() -> void:
	var failures := 0

	failures += _check_straight_street_path()
	failures += _check_path_around_cottage()
	failures += _check_no_corner_cutting()
	failures += _check_nearest_walkable_on_roof()
	failures += _check_nearest_walkable_out_of_bounds()
	failures += _check_nearest_walkable_tie_break()
	failures += _check_path_to_self()
	failures += _check_determinism()
	failures += _check_unreachable_and_unwalkable_endpoints()
	failures += _check_nav_collision_agreement()

	if failures == 0:
		print("\nAll nav grid checks passed.")
		quit(0)
	else:
		print("\n%d nav grid check(s) FAILED." % failures)
		quit(1)


# A route down the open main street is the straight one: every step orthogonal
# east, no detour, length exactly the cell count.
func _check_straight_street_path() -> int:
	var failures := 0
	var layout: TownLayoutScript = TownLayoutScript.build_starter_town()
	var from := Vector2i(1, STREET_Y)
	var to := Vector2i(6, STREET_Y)
	var path := NavGridScript.find_path(layout, from, to)

	failures += _check(path.size() == 6, "straight street path has one cell per step (%d)" % path.size())
	if path.size() != 6:
		return failures
	failures += _check(path[0] == from and path[path.size() - 1] == to, "street path includes both endpoints")

	var stays_on_street := true
	for i in range(path.size()):
		if path[i] != Vector2i(1 + i, STREET_Y):
			stays_on_street = false
	failures += _check(stays_on_street, "street path runs straight down the street without detouring")
	return failures


# cottage_a occupies cells (2,3)..(3,4). A route from one side of it to the
# other must go around it and never step onto it.
func _check_path_around_cottage() -> int:
	var failures := 0
	var layout: TownLayoutScript = TownLayoutScript.build_starter_town()
	var from := Vector2i(1, 3)
	var to := Vector2i(4, 3)
	var path := NavGridScript.find_path(layout, from, to)

	failures += _check(not path.is_empty(), "a route around cottage_a exists")
	if path.is_empty():
		return failures

	var avoids_building := true
	for cell in path:
		if layout.is_cell_blocked_by_building(cell):
			avoids_building = false
	failures += _check(avoids_building, "route around cottage_a never enters the building footprint")

	# Straight through would be 4 cells; going around must cost more.
	failures += _check(path.size() > 4, "route around cottage_a is longer than the blocked straight line (%d)" % path.size())

	var steps_are_adjacent := true
	for i in range(path.size() - 1):
		if not NavGridScript.can_step(layout, path[i], path[i + 1]):
			steps_are_adjacent = false
	failures += _check(steps_are_adjacent, "every step of the cottage_a route is a legal single step")
	return failures


# The corner-cutting rule, on a purpose-built layout rather than the starter
# town: two buildings touching only at a corner must not be squeezed between.
func _check_no_corner_cutting() -> int:
	var failures := 0
	var layout := _build_diagonal_pinch_layout()

	# Buildings at (1,1) and (2,2). The (1,2)->(2,1) diagonal would slip
	# through the seam where their corners meet.
	failures += _check(not NavGridScript.can_step(layout, Vector2i(1, 2), Vector2i(2, 1)), "diagonal step through a building-corner seam is refused")
	failures += _check(not NavGridScript.can_step(layout, Vector2i(2, 1), Vector2i(1, 2)), "the same seam is refused from the other side")

	# A diagonal with both orthogonal neighbours clear stays legal, so the rule
	# above is not just refusing all diagonals.
	failures += _check(NavGridScript.can_step(layout, Vector2i(3, 3), Vector2i(4, 4)), "an unobstructed diagonal step is allowed")

	var path := NavGridScript.find_path(layout, Vector2i(1, 2), Vector2i(2, 1))
	failures += _check(not path.is_empty(), "a route between the pinched cells exists the long way around")
	if not path.is_empty():
		failures += _check(path.size() > 2, "route between pinched cells does not cut the corner (%d cells)" % path.size())
		var no_cut := true
		for i in range(path.size() - 1):
			if not NavGridScript.can_step(layout, path[i], path[i + 1]):
				no_cut = false
		failures += _check(no_cut, "every step of the pinched route is legal")
	return failures


# Clicking a cottage roof resolves to a walkable cell next to it, not onto it.
func _check_nearest_walkable_on_roof() -> int:
	var failures := 0
	var layout: TownLayoutScript = TownLayoutScript.build_starter_town()
	var roof := Vector2i(2, 3)
	failures += _check(not layout.is_cell_walkable(roof), "the test roof cell is actually blocked")

	var resolved := NavGridScript.nearest_walkable(layout, roof)
	failures += _check(resolved != NavGridScript.NO_CELL, "a roof click resolves to some cell")
	failures += _check(layout.is_cell_walkable(resolved), "a roof click resolves to a walkable cell")
	# cottage_a is 2x2 from (2,3), so the nearest walkable cell is one step off
	# its footprint: Chebyshev distance 1 from the clicked corner.
	failures += _check(maxi(absi(resolved.x - roof.x), absi(resolved.y - roof.y)) == 1, "roof click resolves to an adjacent cell, not a distant one")

	var path := NavGridScript.find_path(layout, Vector2i(1, STREET_Y), resolved)
	failures += _check(not path.is_empty(), "the resolved roof-click cell is reachable from the street")
	return failures


# Out-of-bounds clicks clamp into bounds rather than returning NO_CELL or
# searching from off-map.
func _check_nearest_walkable_out_of_bounds() -> int:
	var failures := 0
	var layout: TownLayoutScript = TownLayoutScript.build_starter_town()

	var far_cases := {
		"past the west edge": Vector2i(-50, STREET_Y),
		"past the east edge": Vector2i(layout.width + 50, STREET_Y),
		"past the north edge": Vector2i(5, -50),
		"past the south edge": Vector2i(5, layout.height + 50),
		"past a corner": Vector2i(-99, -99),
	}
	for label in far_cases:
		var resolved := NavGridScript.nearest_walkable(layout, far_cases[label])
		failures += _check(resolved != NavGridScript.NO_CELL and layout.is_cell_walkable(resolved), "click %s resolves to a walkable in-bounds cell" % label)

	# Clamping, specifically: a click far west of a walkable edge cell resolves
	# to that edge cell itself, not to something the search wandered to.
	var west := NavGridScript.nearest_walkable(layout, Vector2i(-50, STREET_Y))
	failures += _check(west == Vector2i(0, STREET_Y), "a far-west click clamps to the west edge cell of the street (%s)" % west)
	return failures


# The tie-break codex asked for: when candidates are equidistant, the lower
# cell index (y * width + x) wins, and it does so regardless of scan order.
func _check_nearest_walkable_tie_break() -> int:
	var failures := 0

	# A single blocked cell at (2,2) in an otherwise open 5x5 field. Its eight
	# neighbours are all walkable; the four orthogonals are all exactly 1.0
	# away, so the tie must resolve on index. Lowest index among (2,1), (1,2),
	# (3,2), (2,3) is (2,1): index 1 * 5 + 2 = 7.
	var layout := _build_open_layout(5, 5, [_plot("pillar", Vector2i(2, 2), Vector2i(1, 1))])
	var resolved := NavGridScript.nearest_walkable(layout, Vector2i(2, 2))
	failures += _check(resolved == Vector2i(2, 1), "equal-distance candidates resolve to the lowest cell index (%s)" % resolved)

	# Same layout, asked twice: the tie-break is stable, not scan-order luck.
	failures += _check(NavGridScript.nearest_walkable(layout, Vector2i(2, 2)) == resolved, "the equal-distance tie-break is stable across calls")

	# A 2x1 block: cells (1,1) and (2,1) blocked in a 5x5 field. Clicking (1,1)
	# has three orthogonal neighbours at distance 1.0: (1,0), (0,1), (1,2).
	# Lowest index is (1,0): 0 * 5 + 1 = 1.
	var wide := _build_open_layout(5, 5, [_plot("wide", Vector2i(1, 1), Vector2i(2, 1))])
	var wide_resolved := NavGridScript.nearest_walkable(wide, Vector2i(1, 1))
	failures += _check(wide_resolved == Vector2i(1, 0), "tie-break on a wider block picks the lowest-index neighbour (%s)" % wide_resolved)

	# The metric is Euclidean, not Chebyshev: with the whole ring at radius 1
	# blocked, a cell at (2,0) (distance 2.0) must beat a diagonal at (0,0)
	# (distance 2.83), even though both are on Chebyshev ring 2.
	var ring := _build_open_layout(5, 5, [_plot("ring", Vector2i(1, 1), Vector2i(3, 3))])
	var ring_resolved := NavGridScript.nearest_walkable(ring, Vector2i(2, 2))
	failures += _check(ring_resolved == Vector2i(2, 0), "the search uses Euclidean distance, preferring an orthogonal over a diagonal on the same ring (%s)" % ring_resolved)

	# An already-walkable cell resolves to itself.
	failures += _check(NavGridScript.nearest_walkable(ring, Vector2i(0, 0)) == Vector2i(0, 0), "a walkable cell resolves to itself")
	return failures


func _check_path_to_self() -> int:
	var failures := 0
	var layout: TownLayoutScript = TownLayoutScript.build_starter_town()
	var cell := Vector2i(5, STREET_Y)
	var path := NavGridScript.find_path(layout, cell, cell)
	failures += _check(path.size() == 1, "path to self is a single element (%d)" % path.size())
	if path.size() == 1:
		failures += _check(path[0] == cell, "path to self is the cell itself")
	return failures


# CLAUDE.md's determinism rule, applied to routing: identical input must give
# byte-identical output, across repeated calls and across fresh layouts.
func _check_determinism() -> int:
	var failures := 0
	var layout_a: TownLayoutScript = TownLayoutScript.build_starter_town()
	var layout_b: TownLayoutScript = TownLayoutScript.build_starter_town()

	# Corner to corner, so the route crosses the town and passes several
	# buildings: the most tie-rich route the starter town offers.
	var from := Vector2i(0, 0)
	var to := Vector2i(17, 13)

	var first := NavGridScript.find_path(layout_a, from, to)
	failures += _check(not first.is_empty(), "the cross-town route exists")
	if first.is_empty():
		return failures

	var repeat_matches := true
	for _i in range(8):
		var again := NavGridScript.find_path(layout_a, from, to)
		if again != first:
			repeat_matches = false
	failures += _check(repeat_matches, "repeated find_path calls on one layout are byte-identical")

	var fresh := NavGridScript.find_path(layout_b, from, to)
	failures += _check(fresh == first, "find_path on a freshly built identical layout is byte-identical")

	# Order independence: routing something else in between must not perturb
	# the result, i.e. no state accumulates across calls.
	NavGridScript.find_path(layout_a, Vector2i(1, STREET_Y), Vector2i(9, 2))
	NavGridScript.nearest_walkable(layout_a, Vector2i(2, 3))
	var after_other_work := NavGridScript.find_path(layout_a, from, to)
	failures += _check(after_other_work == first, "find_path is unaffected by unrelated calls in between")
	return failures


func _check_unreachable_and_unwalkable_endpoints() -> int:
	var failures := 0
	var layout: TownLayoutScript = TownLayoutScript.build_starter_town()

	failures += _check(NavGridScript.find_path(layout, Vector2i(1, STREET_Y), Vector2i(2, 3)).is_empty(), "a route to a blocked cell is refused")
	failures += _check(NavGridScript.find_path(layout, Vector2i(2, 3), Vector2i(1, STREET_Y)).is_empty(), "a route from a blocked cell is refused")
	failures += _check(NavGridScript.find_path(layout, Vector2i(1, STREET_Y), Vector2i(99, 99)).is_empty(), "a route to an out-of-bounds cell is refused")

	# A walled-off pocket: reachable cells route, sealed ones do not.
	var sealed := _build_open_layout(5, 5, [
		_plot("wall_v", Vector2i(3, 0), Vector2i(1, 5)),
	])
	failures += _check(NavGridScript.find_path(sealed, Vector2i(0, 0), Vector2i(4, 4)).is_empty(), "a route across a full-height wall is refused")
	failures += _check(not NavGridScript.find_path(sealed, Vector2i(0, 0), Vector2i(2, 4)).is_empty(), "a route within the open side of the wall exists")
	return failures


# Decision 003 sustains agy-worker's constraint: "The collision and nav must
# agree by construction, not by runtime exception." These are the three
# construction facts the argument in player_controller_2d.gd rests on. If a
# later change breaks one, this fails rather than shipping a player that wedges
# on invisible bounds.
func _check_nav_collision_agreement() -> int:
	var failures := 0
	var layout: TownLayoutScript = TownLayoutScript.build_starter_town()

	# 1. The player collider fits a walkable cell with room to spare, so a body
	#    centred on a cell centre never overlaps a neighbouring blocked cell.
	var player := PlayerScene.instantiate()
	var shape_node: CollisionShape2D = player.get_node("CollisionShape2D")
	var rect := shape_node.shape as RectangleShape2D
	failures += _check(rect != null, "player collider is a RectangleShape2D")
	if rect != null:
		var half_extent: float = maxf(rect.size.x, rect.size.y) / 2.0
		var half_tile := float(TownLayoutScript.TILE_SIZE) / 2.0
		failures += _check(half_extent < half_tile, "player collider half-extent (%.1f) is inside a half-tile (%.1f), so a cell-centred body has clearance" % [half_extent, half_tile])
		# The collider is offset from the body origin (feet); the offset must
		# not push it out of the cell either.
		var reach: float = maxf(
			absf(shape_node.position.x) + rect.size.x / 2.0,
			absf(shape_node.position.y) + rect.size.y / 2.0
		)
		failures += _check(reach < half_tile, "player collider stays inside its cell once its offset is applied (%.1f < %.1f)" % [reach, half_tile])
	player.free()

	# 2. Every building collider the render layer builds is exactly the
	#    footprint the nav grid blocks. starter_town.gd sizes the rect
	#    footprint * TILE_SIZE, so this asserts the footprints are whole cells
	#    (no fractional cell a collider could cover but the grid could not).
	var footprints_are_whole_cells := true
	for building in layout.buildings:
		if building.footprint.x <= 0 or building.footprint.y <= 0:
			footprints_are_whole_cells = false
	failures += _check(footprints_are_whole_cells, "every building footprint is a whole number of cells")

	# 3. The blocked set and the walkable set are exact complements within
	#    bounds: no cell is both, none is neither.
	var complements := true
	for y in range(layout.height):
		for x in range(layout.width):
			var cell := Vector2i(x, y)
			if layout.is_cell_walkable(cell) == layout.is_cell_blocked_by_building(cell):
				complements = false
	failures += _check(complements, "walkable and building-blocked are exact complements in bounds")

	# Every cell a route can use is walkable, and the reachable set is fully
	# connected from the spawn: no click resolves to a pocket the player cannot
	# reach, which is what would strand a route at runtime.
	var spawn := Vector2i(int(layout.width / 2.0), STREET_Y)
	var unreachable := 0
	for y in range(layout.height):
		for x in range(layout.width):
			var cell := Vector2i(x, y)
			if not layout.is_cell_walkable(cell):
				continue
			if NavGridScript.find_path(layout, spawn, cell).is_empty():
				unreachable += 1
	failures += _check(unreachable == 0, "every walkable cell is reachable from the spawn (%d stranded)" % unreachable)
	return failures


func _plot(id: String, cell: Vector2i, footprint: Vector2i) -> TownLayoutScript.BuildingPlacement:
	# Semantic kind only. Decision 003: sprite_key does not go on new sim data;
	# BuildingPlacement.sprite_key is pre-existing debt, so these fixtures pass
	# it empty rather than deepening the pattern.
	return TownLayoutScript.BuildingPlacement.new(id, cell, footprint, "")


# A purpose-built open field with hand-placed blockers, for the invariants that
# the starter town's own geometry does not happen to exercise.
func _build_open_layout(width: int, height: int, plots: Array) -> TownLayoutScript:
	var ground: Array = []
	for y in range(height):
		var row: Array = []
		for x in range(width):
			row.append(TownLayoutScript.GroundTile.GRASS)
		ground.append(row)
	var buildings: Array[TownLayoutScript.BuildingPlacement] = []
	for plot in plots:
		buildings.append(plot)
	return TownLayoutScript.new(width, height, ground, buildings)


# Two 1x1 buildings meeting only at a corner:
#
#     . . . . .
#     . # . . .      # at (1,1) and (2,2)
#     . . # . .      the (1,2)->(2,1) diagonal is the seam
#     . . . . .
#     . . . . .
func _build_diagonal_pinch_layout() -> TownLayoutScript:
	return _build_open_layout(6, 6, [
		_plot("pinch_a", Vector2i(1, 1), Vector2i(1, 1)),
		_plot("pinch_b", Vector2i(2, 2), Vector2i(1, 1)),
	])


func _check(condition: bool, label: String) -> int:
	if condition:
		print("[PASS] %s" % label)
		return 0
	print("[FAIL] %s" % label)
	return 1
