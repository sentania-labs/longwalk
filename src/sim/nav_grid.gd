extends RefCounted
class_name NavGrid

# NavGrid is the SIM-side navigation for the hand-authored starter town: a
# deterministic 8-connected A* over TownLayout's walkable cells. It has zero
# dependency on Viewport, Camera, physics, or any UI node and runs headless
# (see CLAUDE.md, "Simulation/rendering separation"). The render layer
# (src/render/town/player_controller_2d.gd) asks for a route and then does its
# own steering and collision; it never writes back into this file's results.
#
# Determinism (CLAUDE.md, "Determinism"): find_path() is a pure function of
# (layout, from, to). There is no RNG here and no accumulator that depends on
# iteration order:
#
#   - The open set is a plain Array searched with an explicit total order
#     (lower f, then lower y * width + x). It is never a Dictionary keyed walk,
#     so no result depends on hash iteration order.
#   - The octile heuristic is consistent for this cost pair, so a cell is
#     closed at most once and no reopening rule can reorder the search.
#   - Every cost is a sum of ORTHOGONAL_COST and DIAGONAL_COST, so repeated
#     calls with equal input produce byte-identical output.
#
# The grid is 18x14 (252 cells), so the linear open-set scan below is chosen
# for being obviously order-independent rather than for asymptotics. A binary
# heap would need its own tie-break rule to stay deterministic and would buy
# nothing at this size.

# Uniform step costs. Diagonals cost sqrt(2) so a diagonal route is never
# cheaper than the orthogonal route it replaces.
const ORTHOGONAL_COST := 1.0
const DIAGONAL_COST := 1.4142135623730951

# Fixed neighbour order: orthogonals first, then diagonals, each group in
# row-major order. Pop order is a total order regardless of this list, so this
# only fixes the order equal-cost parents are considered in.
const NEIGHBOR_OFFSETS: Array[Vector2i] = [
	Vector2i(0, -1),
	Vector2i(-1, 0),
	Vector2i(1, 0),
	Vector2i(0, 1),
	Vector2i(-1, -1),
	Vector2i(1, -1),
	Vector2i(-1, 1),
	Vector2i(1, 1),
]

# Returned by nearest_walkable() when a layout has no walkable cell at all.
const NO_CELL := Vector2i(-1, -1)


# The fixed total order every tie in this file breaks on: row-major cell index.
static func cell_index(layout: TownLayout, cell: Vector2i) -> int:
	return cell.y * layout.width + cell.x


# Octile distance: the exact cost of the cheapest unobstructed 8-connected
# route, which makes it both admissible and consistent for the costs above.
static func octile_distance(from: Vector2i, to: Vector2i) -> float:
	var dx := absi(to.x - from.x)
	var dy := absi(to.y - from.y)
	return ORTHOGONAL_COST * float(dx + dy) \
			+ (DIAGONAL_COST - 2.0 * ORTHOGONAL_COST) * float(mini(dx, dy))


# Whether a single step from `from` to the adjacent cell `to` is legal.
#
# Corner-cutting is forbidden: a diagonal step requires BOTH shared orthogonal
# neighbours to be walkable. Without this the route would slip through the
# zero-width seam where two diagonally adjacent buildings touch, which the
# render layer's colliders (solid rects meeting at that corner) will not let
# the body follow. See "Agreement with collision, by construction" in
# src/render/town/player_controller_2d.gd.
static func can_step(layout: TownLayout, from: Vector2i, to: Vector2i) -> bool:
	if not layout.is_cell_walkable(to):
		return false
	var delta := to - from
	if delta == Vector2i.ZERO:
		return false
	if absi(delta.x) > 1 or absi(delta.y) > 1:
		return false
	if delta.x != 0 and delta.y != 0:
		if not layout.is_cell_walkable(Vector2i(from.x + delta.x, from.y)):
			return false
		if not layout.is_cell_walkable(Vector2i(from.x, from.y + delta.y)):
			return false
	return true


# The cheapest 8-connected route from `from` to `to`, inclusive of both ends.
#
# Returns an empty array when either endpoint is unwalkable or no route exists,
# and a single-element array when `from == to`. Callers that may hold an
# arbitrary click should pass it through nearest_walkable() first.
static func find_path(layout: TownLayout, from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var no_path: Array[Vector2i] = []
	if not layout.is_cell_walkable(from) or not layout.is_cell_walkable(to):
		return no_path
	if from == to:
		var single: Array[Vector2i] = [from]
		return single

	var start_index := cell_index(layout, from)
	# index -> cost so far / index -> estimated total / index -> previous cell.
	var g_score := {start_index: 0.0}
	var f_score := {start_index: octile_distance(from, to)}
	# Keyed by cell rather than index: _reconstruct walks the chain without a
	# layout in scope, so it cannot recompute an index.
	var came_from := {}
	var closed := {}
	var open: Array[Vector2i] = [from]

	while not open.is_empty():
		var best_slot := 0
		for slot in range(1, open.size()):
			var candidate_f: float = f_score[cell_index(layout, open[slot])]
			var best_f: float = f_score[cell_index(layout, open[best_slot])]
			# Lower f, then lower cell index. A total order, so the pop
			# sequence is fully determined by the input.
			if candidate_f < best_f or (candidate_f == best_f \
					and cell_index(layout, open[slot]) < cell_index(layout, open[best_slot])):
				best_slot = slot

		var current: Vector2i = open[best_slot]
		if current == to:
			return _reconstruct(came_from, current)
		open.remove_at(best_slot)
		var current_index := cell_index(layout, current)
		closed[current_index] = true

		for offset in NEIGHBOR_OFFSETS:
			var neighbor: Vector2i = current + offset
			if not can_step(layout, current, neighbor):
				continue
			var neighbor_index := cell_index(layout, neighbor)
			if closed.has(neighbor_index):
				continue
			var step_cost := DIAGONAL_COST if offset.x != 0 and offset.y != 0 else ORTHOGONAL_COST
			var tentative: float = float(g_score[current_index]) + step_cost
			if g_score.has(neighbor_index) and tentative >= float(g_score[neighbor_index]):
				continue
			g_score[neighbor_index] = tentative
			f_score[neighbor_index] = tentative + octile_distance(neighbor, to)
			came_from[neighbor] = current
			if not open.has(neighbor):
				open.append(neighbor)

	return no_path


static func _reconstruct(came_from: Dictionary, tail: Vector2i) -> Array[Vector2i]:
	# came_from is only ever read by key lookup along one chain, never
	# iterated, so its hash order cannot reach the output.
	var reversed: Array[Vector2i] = [tail]
	var cursor := tail
	while came_from.has(cursor):
		cursor = came_from[cursor]
		reversed.append(cursor)
	reversed.reverse()
	return reversed


# The nearest walkable cell to `cell`, for turning an arbitrary click (a
# cottage roof, a point past the town edge) into a reachable destination.
#
# The search contract, stated explicitly rather than left to fall out of the
# implementation:
#
#   - OUT OF BOUNDS: `cell` is first clamped componentwise into
#     [0, width-1] x [0, height-1]. A click past the town edge therefore
#     searches from the edge cell nearest it, never from off-map.
#   - SEARCH REGION: bounded. Chebyshev rings of radius r = 1, 2, ... around
#     the clamped origin, and r never exceeds max(width, height), which after
#     clamping is enough to reach every cell in the layout.
#   - DISTANCE METRIC: Euclidean distance from the clamped origin. Note this
#     is NOT the ring metric: ring r+1 can still hold a strictly nearer cell
#     than one already found at ring r (at r=3, a hit at (3,3) is 4.24 away
#     while (0,4) on the next ring is 4.00). The scan therefore keeps
#     expanding until the ring radius exceeds the best distance found, rather
#     than returning on the first ring that contains any hit.
#   - TIE-BREAK: equal Euclidean distance resolves on lower cell index
#     (y * width + x), the same total order find_path() breaks ties on. Since
#     each ring is scanned row-major and ties resolve on index rather than on
#     visit order, the result does not depend on the scan order.
#
# Returns NO_CELL only if the layout has no walkable cell anywhere.
static func nearest_walkable(layout: TownLayout, cell: Vector2i) -> Vector2i:
	var origin := Vector2i(
		clampi(cell.x, 0, layout.width - 1),
		clampi(cell.y, 0, layout.height - 1)
	)
	if layout.is_cell_walkable(origin):
		return origin

	var best := NO_CELL
	var best_distance := INF
	var max_radius := maxi(layout.width, layout.height)
	var radius := 1
	while radius <= max_radius:
		# Every cell on ring r is at least r away, so once the best hit is
		# nearer than the ring itself, no later ring can beat it.
		if best_distance < INF and float(radius) > best_distance:
			break
		for y in range(origin.y - radius, origin.y + radius + 1):
			for x in range(origin.x - radius, origin.x + radius + 1):
				if maxi(absi(x - origin.x), absi(y - origin.y)) != radius:
					continue
				var candidate := Vector2i(x, y)
				if not layout.is_cell_walkable(candidate):
					continue
				var distance := Vector2(candidate - origin).length()
				if distance < best_distance or (distance == best_distance \
						and cell_index(layout, candidate) < cell_index(layout, best)):
					best_distance = distance
					best = candidate
		radius += 1
	return best
