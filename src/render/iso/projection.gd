extends RefCounted
class_name IsoProjection

# RENDER-side isometric projection spine (decision 008, "Render-side projection
# spine, sim untouched"). This module is pure math: it converts between the
# sim's square logical grid and the isometric SCREEN space the render layer
# draws in. It has zero dependency on any sim node, and no projection symbol or
# screen coordinate ever enters src/sim/ (decision 007 + 008: all iso math is
# render-side, the sim stays square-grid and projection-ignorant).
#
# ---------------------------------------------------------------------------
# FROZEN CONTRACT (consumed by the camera slice, agy-worker, and the art slice,
# codex-worker). These signatures and coordinate conventions are frozen for
# this round so the dependent slices implement against a stable surface. Do not
# change a signature here without re-freezing with the consuming slice.
# ---------------------------------------------------------------------------
#
# COORDINATE SPACES
#   - CELL space: the sim's logical grid. A cell is (column x, row y). Cell
#     coordinates may be fractional (a continuous position inside the grid),
#     e.g. the center of cell (3, 4) is Vector2(3.5, 4.5). This is exactly the
#     space TownLayout / NavGrid speak, divided out of world pixels by
#     TILE_SIZE.
#   - WORLD-PIXEL space (square): the authoritative physics space the
#     CharacterBody2D and the StaticBody2D colliders live in, unchanged from
#     round 004. One cell is TILE_SIZE (128) px on a side. Decision 008 Q-B
#     keeps movement and collision here; the render layer only PROJECTS this
#     space for display and only inverts the projection at the input boundary.
#   - SCREEN space (isometric): the 2D pixel space the render layer draws in.
#     Cell (0,0)'s center-origin projects near the origin; +x cell steps go
#     down-right, +y cell steps go down-left, giving the 2:1 diamond look.
#
# DIAMOND GEOMETRY
#   A cell renders as a 2:1 isometric diamond TILE_W wide by TILE_H tall. A
#   single grid-axis step (one cell along +x or +y) therefore moves the screen
#   point by (HALF_W, HALF_H); this is why the most common motion (a road step
#   along a grid axis) projects to a screen angle of atan2(HALF_H, HALF_W) ~=
#   27deg, the fact that drove the 8-facing decision (decision 008 point 1).

const TownLayoutScript := preload("res://src/sim/town_layout.gd")

# World-pixel size of one cell (square physics space). Mirrors
# TownLayout.TILE_SIZE so the two never drift.
const TILE_SIZE: int = TownLayoutScript.TILE_SIZE

# Isometric diamond dimensions in screen pixels. 2:1 (TILE_H == TILE_W / 2) is
# the classic iso ratio and the one decision 008's facing math assumes.
const TILE_W: float = 128.0
const TILE_H: float = 64.0
const HALF_W: float = TILE_W / 2.0
const HALF_H: float = TILE_H / 2.0

# Returned by facing_octant() when motion is below the deadzone: the caller
# should hold the last facing and show a neutral (idle) frame (decision 008
# point 1, "freeze on a neutral frame at rest").
const FACING_NEUTRAL: int = -1

# Screen-pixels-per-frame below which motion is treated as "at rest" for facing
# selection. Small enough that a real walking step always clears it.
const FACING_DEADZONE: float = 0.001


# CELL -> SCREEN. Accepts fractional cells (a cell center is cell + (0.5, 0.5)).
# This is the projection every world object is drawn through.
static func cell_to_screen(cell: Vector2) -> Vector2:
	return Vector2(
		(cell.x - cell.y) * HALF_W,
		(cell.x + cell.y) * HALF_H
	)


# WORLD-PIXEL (square physics space) -> SCREEN. Continuous: this is how the
# player's authoritative square-space position becomes its iso draw position
# (the "display proxy" of decision 008 Q-B). It is cell_to_screen() of the
# fractional cell the world pixel falls in.
static func world_to_screen(world_px: Vector2) -> Vector2:
	return cell_to_screen(world_px / float(TILE_SIZE))


# SCREEN -> CELL (integer). The inverse projection, used ONLY at the input
# boundary (a mouse click in screen space -> the grid cell to route to). Floors
# to the containing integer cell, matching NavGrid.world_to_cell's convention.
static func screen_to_cell(screen: Vector2) -> Vector2i:
	# Invert cell_to_screen:
	#   sx / HALF_W = cx - cy
	#   sy / HALF_H = cx + cy
	# so cx = (sx/HALF_W + sy/HALF_H) / 2, cy = (sy/HALF_H - sx/HALF_W) / 2.
	var a := screen.x / HALF_W
	var b := screen.y / HALF_H
	var cx := (a + b) / 2.0
	var cy := (b - a) / 2.0
	return Vector2i(floori(cx), floori(cy))


# SCREEN -> WORLD-PIXEL (continuous, square physics space). The fractional
# counterpart of screen_to_cell(), for callers that need the sub-cell landing
# point rather than the containing cell.
static func screen_to_world(screen: Vector2) -> Vector2:
	var a := screen.x / HALF_W
	var b := screen.y / HALF_H
	return Vector2((a + b) / 2.0, (b - a) / 2.0) * float(TILE_SIZE)


# Screen-space AABB the camera must not show outside of (consumed by agy's
# rig). It is the bounding rectangle of the FOUR PROJECTED DIAMOND CORNERS of
# the walkable grid, grown by sprite headroom. This is decision 008 point 3 and
# the critique's camera-bounds catch verbatim: under iso the walkable diamond
# does NOT inscribe the axis-aligned rect that _layout.pixel_size() describes,
# so bounds MUST come from the projected corners, never from the square
# pixel_size.
#
#   grid_size: the walkable grid dimensions in CELLS (Vector2i(width, height)).
#   headroom:  screen-pixel margins to grow the raw corner AABB by. headroom.x
#              grows left and right; headroom.y grows top and bottom. Callers
#              should set headroom.y to at least the tallest sprite's height
#              above its ground contact (so a tall building at the back edge is
#              not clipped) plus the deepest cast shadow below contact.
#
# Returns a Rect2 in SCREEN space.
static func projected_bounds(grid_size: Vector2i, headroom: Vector2 = Vector2.ZERO) -> Rect2:
	var w := float(grid_size.x)
	var h := float(grid_size.y)
	# The four outer grid corners (grid lines, not cell centers).
	var corners := [
		cell_to_screen(Vector2(0.0, 0.0)),
		cell_to_screen(Vector2(w, 0.0)),
		cell_to_screen(Vector2(0.0, h)),
		cell_to_screen(Vector2(w, h)),
	]
	var min_x: float = corners[0].x
	var max_x: float = corners[0].x
	var min_y: float = corners[0].y
	var max_y: float = corners[0].y
	for c in corners:
		min_x = minf(min_x, c.x)
		max_x = maxf(max_x, c.x)
		min_y = minf(min_y, c.y)
		max_y = maxf(max_y, c.y)
	var rect := Rect2(min_x, min_y, max_x - min_x, max_y - min_y)
	return rect.grow_individual(headroom.x, headroom.y, headroom.x, headroom.y)


# 8-FACING SELECTION (decision 008 point 1, "blind code committed before any
# final generation"). Quantizes a SCREEN-space motion vector to one of eight
# fixed 45deg sectors, returning an immutable facing id, or FACING_NEUTRAL when
# motion is below the deadzone.
#
# Callers derive screen_motion by projecting the sim-space motion into screen
# space first (e.g. world_to_screen(pos) - world_to_screen(prev_pos)), NOT from
# the raw square-space velocity, so the facing matches what the eye sees on the
# iso diamond.
#
# FACING IDS (frozen row order for the generated 8-facing walk sheet; screen
# space is y-DOWN, so positive y is toward the bottom of the screen / "south"):
#   0 = E   (+x)
#   1 = SE  (down-right)
#   2 = S   (+y, toward camera)
#   3 = SW  (down-left)
#   4 = W   (-x)
#   5 = NW  (up-left)
#   6 = N   (-y, away from camera)
#   7 = NE  (up-right)
# Boundary convention: sectors are centered on each id direction and span
# +/- 22.5deg; a motion landing exactly on a 22.5deg boundary rounds to the
# neighbouring sector away from zero (GDScript round() half-away-from-zero).
static func facing_octant(screen_motion: Vector2) -> int:
	if screen_motion.length_squared() < FACING_DEADZONE * FACING_DEADZONE:
		return FACING_NEUTRAL
	var sector := int(round(screen_motion.angle() / (PI / 4.0)))
	return posmod(sector, 8)


# --- Footprint-aware depth sorting (decision 008 point 2) ----------------
#
# The world-object layer is drawn back-to-front by DEPTH KEY. The key is the
# projected screen Y of an object's ground CONTACT point, plus a small stable
# per-placement offset that breaks the frequent exact ties (every cell on one
# iso anti-diagonal projects to the SAME screen Y) deterministically, so tree
# order never decides depth. A larger key draws in FRONT (nearer the camera).

# Deterministic sub-pixel tie key in [0.0, 0.5) derived from a stable placement
# id. Pure function of the id string: no RNG, no time, no iteration order
# (constitution: determinism). Magnitude stays well under the minimum non-zero
# gap between distinct contact rows (HALF_H == 32 px), so it only ever orders
# genuine ties, never reorders objects at distinct depths.
static func stable_offset(placement_id: String) -> float:
	return float(hash(placement_id) % 1000) / 2000.0


# Depth key for a world object whose ground contact is at cell-space point
# contact_cell (fractional cells allowed; e.g. an actor's feet at
# world_px / TILE_SIZE, or a building's front-edge center). Larger draws front.
static func depth_key(contact_cell: Vector2, placement_id: String) -> float:
	return cell_to_screen(contact_cell).y + stable_offset(placement_id)


# The ground-contact cell-space point for a building footprint: the center of
# its FRONT (max screen-Y) edge, one full footprint-height below the top-left
# origin cell. A multi-cell building is anchored here for BOTH its draw
# position and its depth key, so an actor whose own contact projects in FRONT
# of this line (a strictly larger depth key) draws over the building and an
# actor behind it is occluded. This is the footprint-aware occlusion contract:
# it is exact for an actor in front of or behind the footprint, and defers to
# the stable tie key for an actor level with the front edge. (Perfect per-cell
# occlusion for an actor tucked alongside a tall multi-cell building is out of
# scope this round; the contract is tested with the actor at every footprint
# edge in test/active_path/test_iso_projection.gd.)
#
# This is also the MANIFEST/ANCHOR CONTRACT frozen for codex's generated iso
# building sprites: a building sprite's ground-contact line must be authored to
# sit at this projected point, drawn upward from it.
static func building_contact_cell(origin_cell: Vector2i, footprint: Vector2i) -> Vector2:
	return Vector2(
		float(origin_cell.x) + float(footprint.x) / 2.0,
		float(origin_cell.y) + float(footprint.y)
	)
