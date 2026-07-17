extends SceneTree

# Tests the render-side iso projection spine (src/render/iso/projection.gd):
# the frozen cell<->screen contract, the projected camera bounds (from the four
# diamond corners, NOT the axis-aligned pixel_size rect), the 8-facing
# quantization, and the footprint-aware depth ordering with the actor placed at
# every footprint edge (decision 008 points 1-3).

const Iso := preload("res://src/render/iso/projection.gd")
const TownLayoutScript := preload("res://src/sim/town_layout.gd")


func _initialize() -> void:
	var failures := 0

	failures += _test_round_trip()
	failures += _test_axis_projection()
	failures += _test_screen_to_cell_floor()
	failures += _test_projected_bounds()
	failures += _test_facing_octant()
	failures += _test_footprint_depth_edges()
	failures += _test_stable_tie_key()

	if failures == 0:
		print("\nAll iso projection checks passed.")
		quit(0)
	else:
		print("\n%d iso projection check(s) FAILED." % failures)
		quit(1)


# cell_to_screen -> screen_to_cell round-trips to the containing cell for a
# spread of integer cells (using the cell center so floor lands back home).
func _test_round_trip() -> int:
	var failures := 0
	for cx in range(0, 18):
		for cy in range(0, 14):
			var center := Vector2(cx + 0.5, cy + 0.5)
			var screen := Iso.cell_to_screen(center)
			var back := Iso.screen_to_cell(screen)
			failures += _check(back == Vector2i(cx, cy), "round-trip cell (%d,%d)" % [cx, cy])
	return failures


# The two grid axes project to the expected diamond half-steps.
func _test_axis_projection() -> int:
	var failures := 0
	failures += _check(Iso.cell_to_screen(Vector2(0, 0)) == Vector2(0, 0), "origin projects to screen origin")
	failures += _check(Iso.cell_to_screen(Vector2(1, 0)) == Vector2(Iso.HALF_W, Iso.HALF_H), "+x step goes down-right")
	failures += _check(Iso.cell_to_screen(Vector2(0, 1)) == Vector2(-Iso.HALF_W, Iso.HALF_H), "+y step goes down-left")
	# world_to_screen of a cell-center world pixel matches cell_to_screen.
	var world := Vector2(3, 4) * Iso.TILE_SIZE + Vector2.ONE * (Iso.TILE_SIZE / 2.0)
	failures += _check(Iso.world_to_screen(world) == Iso.cell_to_screen(Vector2(3.5, 4.5)), "world_to_screen matches cell_to_screen of the fractional cell")
	return failures


# screen_to_cell floors into the containing cell even for points off the exact
# center, so a click anywhere inside a diamond resolves to that diamond's cell.
func _test_screen_to_cell_floor() -> int:
	var failures := 0
	var base := Iso.cell_to_screen(Vector2(5.5, 5.5))
	for dx in [-10.0, 0.0, 10.0]:
		for dy in [-10.0, 0.0, 10.0]:
			failures += _check(Iso.screen_to_cell(base + Vector2(dx, dy)) == Vector2i(5, 5), "click near cell (5,5) center resolves to it (off %s,%s)" % [dx, dy])
	return failures


# projected_bounds is the AABB of the four PROJECTED diamond corners, not the
# square pixel_size rect. For an 18x14 grid the leftmost point is corner
# (0,height) and the rightmost is (width,0); neither is at x=0, which an
# axis-aligned pixel_size rect would wrongly assume.
func _test_projected_bounds() -> int:
	var failures := 0
	var grid := Vector2i(18, 14)
	var bounds := Iso.projected_bounds(grid)

	var c00 := Iso.cell_to_screen(Vector2(0, 0))
	var cw0 := Iso.cell_to_screen(Vector2(grid.x, 0))
	var c0h := Iso.cell_to_screen(Vector2(0, grid.y))
	var cwh := Iso.cell_to_screen(Vector2(grid.x, grid.y))

	failures += _check(is_equal_approx(bounds.position.x, c0h.x), "left bound is the (0,height) corner")
	failures += _check(is_equal_approx(bounds.end.x, cw0.x), "right bound is the (width,0) corner")
	failures += _check(is_equal_approx(bounds.position.y, c00.y), "top bound is the (0,0) corner")
	failures += _check(is_equal_approx(bounds.end.y, cwh.y), "bottom bound is the (width,height) corner")
	# The projected span is wider than the square pixel_size would suggest along
	# x (the diamond is not inscribed by the axis-aligned rect).
	failures += _check(bounds.position.x < 0.0, "projected left extends past x=0, unlike pixel_size")

	# Headroom grows the raw AABB symmetrically on x and y.
	var grown := Iso.projected_bounds(grid, Vector2(100.0, 200.0))
	failures += _check(is_equal_approx(grown.position.x, bounds.position.x - 100.0), "headroom.x grows left")
	failures += _check(is_equal_approx(grown.end.x, bounds.end.x + 100.0), "headroom.x grows right")
	failures += _check(is_equal_approx(grown.position.y, bounds.position.y - 200.0), "headroom.y grows top")
	failures += _check(is_equal_approx(grown.end.y, bounds.end.y + 200.0), "headroom.y grows bottom")
	return failures


# The eight sectors map screen-space motion to the frozen facing ids, and
# sub-deadzone motion returns FACING_NEUTRAL.
func _test_facing_octant() -> int:
	var failures := 0
	failures += _check(Iso.facing_octant(Vector2.ZERO) == Iso.FACING_NEUTRAL, "zero motion is neutral")
	failures += _check(Iso.facing_octant(Vector2(1, 0)) == 0, "east is 0")
	failures += _check(Iso.facing_octant(Vector2(1, 1)) == 1, "south-east is 1")
	failures += _check(Iso.facing_octant(Vector2(0, 1)) == 2, "south is 2")
	failures += _check(Iso.facing_octant(Vector2(-1, 1)) == 3, "south-west is 3")
	failures += _check(Iso.facing_octant(Vector2(-1, 0)) == 4, "west is 4")
	failures += _check(Iso.facing_octant(Vector2(-1, -1)) == 5, "north-west is 5")
	failures += _check(Iso.facing_octant(Vector2(0, -1)) == 6, "north is 6")
	failures += _check(Iso.facing_octant(Vector2(1, -1)) == 7, "north-east is 7")
	# All eight ids are reachable and in range.
	var seen := {}
	for deg in range(0, 360, 5):
		var rad := deg_to_rad(float(deg))
		var id := Iso.facing_octant(Vector2(cos(rad), sin(rad)))
		failures += _check(id >= 0 and id < 8, "octant id in range at %d deg" % deg)
		seen[id] = true
	failures += _check(seen.size() == 8, "all eight facings are reachable")
	return failures


# The footprint-aware occlusion contract, exercised with the actor at every
# cell touching a building footprint. An actor whose contact projects strictly
# in front of the building's front-edge contact must sort in front (larger
# depth key); strictly behind must sort behind.
func _test_footprint_depth_edges() -> int:
	var failures := 0
	var origin := Vector2i(7, 2)
	var footprint := Vector2i(3, 2)
	var building_contact := Iso.building_contact_cell(origin, footprint)
	var building_key := Iso.depth_key(building_contact, "general_store")

	# Walk every cell in the ring around the footprint.
	for ay in range(origin.y - 1, origin.y + footprint.y + 1):
		for ax in range(origin.x - 1, origin.x + footprint.x + 1):
			var on_edge := ax == origin.x - 1 or ax == origin.x + footprint.x \
				or ay == origin.y - 1 or ay == origin.y + footprint.y
			if not on_edge:
				continue
			var actor_contact := Vector2(ax + 0.5, ay + 0.5)
			var actor_key := Iso.depth_key(actor_contact, "player")
			var actor_screen_y := Iso.cell_to_screen(actor_contact).y
			var front_screen_y := Iso.cell_to_screen(building_contact).y
			if actor_screen_y > front_screen_y + 0.5:
				failures += _check(actor_key > building_key, "actor in front of footprint at (%d,%d) draws over building" % [ax, ay])
			elif actor_screen_y < front_screen_y - 0.5:
				failures += _check(actor_key < building_key, "actor behind footprint at (%d,%d) is occluded" % [ax, ay])
	return failures


# The stable tie key is deterministic and keeps two objects on the same iso
# anti-diagonal (identical contact screen Y) in a fixed, id-decided order.
func _test_stable_tie_key() -> int:
	var failures := 0
	# Cells (5,3) and (4,4) share cx+cy == 8, so identical projected screen Y.
	var a := Vector2(5.5, 3.5)
	var b := Vector2(4.5, 4.5)
	failures += _check(is_equal_approx(Iso.cell_to_screen(a).y, Iso.cell_to_screen(b).y), "same-diagonal cells share screen Y")
	var ka1 := Iso.depth_key(a, "alpha")
	var ka2 := Iso.depth_key(a, "alpha")
	failures += _check(ka1 == ka2, "depth key is deterministic for a fixed id")
	var kb := Iso.depth_key(b, "omega")
	failures += _check(ka1 != kb, "tie key separates two same-diagonal objects")
	# Offsets stay in [0, 0.5), never large enough to cross a real 32px row gap.
	for id in ["player", "general_store", "cottage_a", "cottage_b", "flora_17"]:
		var off := Iso.stable_offset(id)
		failures += _check(off >= 0.0 and off < 0.5, "stable_offset('%s') stays sub-pixel" % id)
	return failures


func _check(condition: bool, description: String) -> int:
	if condition:
		return 0
	push_error("FAIL: %s" % description)
	print("FAIL: %s" % description)
	return 1
