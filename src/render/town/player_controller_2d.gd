extends CharacterBody2D
class_name PlayerController2D

# RENDER-side top-down player controller: click-to-move. The route comes from
# the sim layer (src/sim/nav_grid.gd, a pure deterministic A* over TownLayout
# cells); everything in this file is the render half of that split, namely
# turning a click into a cell, steering the body along the returned waypoints,
# and colliding via Godot's physics against the StaticBody2D colliders the
# starter-town render layer builds. No world-state or routing logic lives here,
# and nothing in src/sim/ knows this file exists.
#
# There is no WASD. Movement is click-to-move only (decision record
# docs/decisions/003-village-feel.md); the move_up/move_down/move_left/
# move_right actions came out of project.godot in the same change.
#
#
# Agreement with collision, by construction
# ----------------------------------------
# Decision 003 sustains agy-worker's objection as a constraint on this slice:
# "The collision and nav must agree by construction, not by runtime exception."
# The nav grid and the colliders agree because all three of these hold, and
# test/active_path/test_nav_grid.gd asserts each one rather than trusting this
# comment:
#
#   1. BUILDINGS. src/render/town/starter_town.gd builds each building's
#      collider as a RectangleShape2D of exactly footprint * TILE_SIZE, centred
#      on exactly that footprint. NavGrid blocks exactly the same cells
#      (TownLayout.is_cell_blocked_by_building). The collider is the footprint,
#      not an approximation of it, so there is no cell the grid calls walkable
#      that a building collider intrudes on.
#   2. BOUNDARY. The four boundary walls sit wholly outside [0, pixel_size],
#      i.e. outside cells 0..width-1 / 0..height-1, which is exactly the region
#      TownLayout.is_cell_in_bounds accepts. The wall bounds the walkable set
#      from outside it rather than overlapping its edge cells.
#   3. CLEARANCE. Waypoints are cell centres, and the player's collider is
#      36x20 (player.tscn), so its largest half-extent is 18px against a 64px
#      half-tile. A body centred on any walkable cell keeps 46px of clearance
#      to the nearest blocked cell's edge. Corner-cutting being forbidden in
#      NavGrid.can_step extends this to diagonal steps: both shared orthogonal
#      neighbours are walkable, so the swept corridor between two consecutive
#      waypoints is clear for a body of half-extent < TILE_SIZE / 2.
#
# The clearance argument is what my original proposal was missing, and it is
# why the "player wedges on invisible bounds" failure agy described does not
# arise: the disagreement it assumed (128px cells vs "exact footprints plus a
# 64px boundary") is not what starter_town.gd actually builds. The one thing
# construction cannot cover is a body that is already off-route when a route is
# requested (a spawn overlapping geometry, or a future moving obstacle such as
# an NPC, which nothing in this slice creates). _handle_stall below is the
# backstop for exactly that residual case, and it is not load-bearing for any
# geometry this town contains.

const TownLayoutScript := preload("res://src/sim/town_layout.gd")
const NavGridScript := preload("res://src/sim/nav_grid.gd")
const IsoProjection := preload("res://src/render/iso/projection.gd")
const CandidateArt := preload("res://src/render/town/candidate_art.gd")

const SPEED := 220.0
const TILE_SIZE := TownLayoutScript.TILE_SIZE
const WALK_CELL_SIZE := Vector2(160, 160)
const WALK_FRAME_SECONDS := 0.14
const WALK_FRAME_COUNT := 4

enum Facing { DOWN, UP, RIGHT, LEFT }

# Fold of IsoProjection's eight screen-space octants onto the four proxy walk
# rows we ship today (the full 8-facing atlas is Scott-gated follow-up). Indexed
# by facing_octant id (0=E,1=SE,2=S,3=SW,4=W,5=NW,6=N,7=NE). Screen space is
# y-DOWN, so S is toward the camera (DOWN) and N is away (UP); the four diagonal
# octants fold onto the horizontal rows, which read cleanly on the diamond and
# keep DOWN/UP for motion that projects straight toward or away from the camera.
const _OCTANT_TO_FACING := [
	Facing.RIGHT, # 0 E
	Facing.RIGHT, # 1 SE
	Facing.DOWN,  # 2 S
	Facing.LEFT,  # 3 SW
	Facing.LEFT,  # 4 W
	Facing.LEFT,  # 5 NW
	Facing.UP,    # 6 N
	Facing.RIGHT, # 7 NE
]

# A waypoint counts as reached inside this radius. Comfortably under the 46px
# of clearance a cell centre has, so retiring a waypoint early never steers the
# body into a blocked cell.
const WAYPOINT_REACHED_RADIUS := 8.0

# Stall backstop. If the body is asked to move but its real velocity stays
# near zero for this many consecutive physics frames, repath once from where it
# actually is; if that repath also stalls, drop the route rather than grind.
const STALL_FRAMES := 12
const STALL_SPEED_EPSILON := 4.0

signal path_finished()

var _layout: TownLayoutScript
# Remaining waypoints in world pixels, nearest first.
var _waypoints: PackedVector2Array = PackedVector2Array()
var _destination_cell := NavGridScript.NO_CELL
var _stall_frames := 0
var _repathed_since_stall := false
var _walk_atlas: Texture2D
var _walk_texture := AtlasTexture.new()
var _facing := Facing.DOWN
var _walk_frame := 0
var _walk_elapsed := 0.0

# Walk-sheet shape. Defaults describe the round-005 4-facing proxy fold; a pilot
# candidate replaces them with the true 8-facing x 6-pose sheet via
# set_candidate(). _walk_frame_count is the columns of the active sheet;
# _facing_is_octant selects whether _facing indexes the eight iso octants
# directly (candidate) or the folded four proxy rows (default, via
# _OCTANT_TO_FACING). _walk_cell_size is the atlas cell geometry the region math
# uses: the hardcoded WALK_CELL_SIZE for the default proxy, the manifest
# cell_size for a candidate.
var _walk_frame_count := WALK_FRAME_COUNT
var _facing_is_octant := false
var _walk_cell_size := WALK_CELL_SIZE



func set_appearance(appearance_variant: String) -> void:
	# get_node() rather than an @onready var: set_appearance() is meant to be
	# callable right after instantiate(), including from a headless test that
	# never adds the node to a live SceneTree (see test/active_path/), and
	# @onready resolution only fires on tree entry.
	var sprite: Sprite2D = get_node("Sprite2D")
	var path := "res://tools/art/out/processed/player_walk_%s.png" % appearance_variant
	_walk_atlas = load(path)
	_walk_texture.atlas = _walk_atlas
	sprite.texture = _walk_texture
	_apply_walk_frame()


# Drive the true 8-facing x 6-pose pilot atlas for candidate `a` or `b` instead
# of the folded 4-facing proxy. Everything about the sheet is read from the
# candidate's manifest (facing count, frame count, cell size, contact anchor)
# rather than hardcoded, and each of the eight iso octants indexes its own row
# (no proxy fold). Callable straight after instantiate(), like set_appearance().
func set_candidate(candidate_id: String) -> void:
	var manifest := CandidateArt.load_json(CandidateArt.player_manifest_path(candidate_id))
	var cell: float = float(manifest["cell_size"])
	# The atlas region geometry is driven by the manifest cell size, not the
	# hardcoded WALK_CELL_SIZE (which stays the default proxy value). _apply_walk_frame
	# reads _walk_cell_size, so storing it here is what makes the candidate path
	# genuinely manifest-driven.
	_walk_cell_size = Vector2(cell, cell)
	_walk_frame_count = int(manifest["frames_per_facing"])
	_facing_is_octant = true

	# The manifest facing order is the frozen iso octant order (E,SE,S,SW,W,NW,
	# N,NE), so an octant id already IS its atlas row; assert that rather than
	# trusting it silently.
	var facing_order: Array = manifest["facing_order"]
	assert(facing_order.size() == 8, "candidate atlas must declare 8 facings")

	_walk_atlas = CandidateArt.load_texture(CandidateArt.player_atlas_path(candidate_id))
	_walk_texture.atlas = _walk_atlas

	var sprite: Sprite2D = get_node("Sprite2D")
	sprite.texture = _walk_texture
	# Pivot on the authored contact anchor. The sprite is centered, so its region
	# center draws at the node; offsetting by (half_cell - anchor) moves the
	# anchor pixel onto the node, i.e. onto the projected feet the display sets.
	var anchor: Array = manifest["contact_anchor"]
	sprite.centered = true
	sprite.offset = Vector2(cell / 2.0 - float(anchor[0]), cell / 2.0 - float(anchor[1]))
	_apply_walk_frame()


# The render layer hands the controller the sim data it routes over. Same
# reasoning as set_appearance(): callable straight after instantiate().
func set_layout(layout: TownLayoutScript) -> void:
	_layout = layout



func has_path() -> bool:
	return not _waypoints.is_empty()


func destination_cell() -> Vector2i:
	return _destination_cell


static func cell_to_world_center(cell: Vector2i) -> Vector2:
	return Vector2(cell) * TILE_SIZE + Vector2(TILE_SIZE, TILE_SIZE) / 2.0


static func world_to_cell(world_position: Vector2) -> Vector2i:
	return Vector2i(floori(world_position.x / TILE_SIZE), floori(world_position.y / TILE_SIZE))


# Route to the cell nearest `world_position`, which may be a building roof or a
# point past the town edge; NavGrid.nearest_walkable states how those resolve.
# Returns the destination cell actually routed to, or NO_CELL if no route
# exists.
func move_to_world_position(world_position: Vector2) -> Vector2i:
	if _layout == null:
		return NavGridScript.NO_CELL
	var goal := NavGridScript.nearest_walkable(_layout, world_to_cell(world_position))
	if goal == NavGridScript.NO_CELL:
		return NavGridScript.NO_CELL
	return _route_to(goal)


func clear_path() -> void:
	_waypoints = PackedVector2Array()
	_destination_cell = NavGridScript.NO_CELL
	_stall_frames = 0
	_repathed_since_stall = false
	velocity = Vector2.ZERO


func _route_to(goal: Vector2i) -> Vector2i:
	var start := NavGridScript.nearest_walkable(_layout, world_to_cell(position))
	if start == NavGridScript.NO_CELL:
		return NavGridScript.NO_CELL
	var cells := NavGridScript.find_path(_layout, start, goal)
	if cells.is_empty():
		return NavGridScript.NO_CELL

	var points := PackedVector2Array()
	for cell in cells:
		points.append(cell_to_world_center(cell))
	# Drop the first waypoint when the body already stands on it, so a route
	# never opens by steering backwards to the centre of the current cell.
	if points.size() > 1 and position.distance_to(points[0]) <= float(TILE_SIZE) / 2.0:
		points.remove_at(0)
	_waypoints = points
	_destination_cell = goal
	_stall_frames = 0
	_repathed_since_stall = false
	return goal


func _physics_process(delta: float) -> void:
	if _waypoints.is_empty():
		velocity = Vector2.ZERO
		move_and_slide()
		_update_walk_animation(delta, false)
		return

	var target: Vector2 = _waypoints[0]
	if position.distance_to(target) <= WAYPOINT_REACHED_RADIUS:
		_waypoints.remove_at(0)
		if _waypoints.is_empty():
			clear_path()
			move_and_slide()
			_update_walk_animation(delta, false)
			path_finished.emit()
			return
		target = _waypoints[0]

	velocity = position.direction_to(target) * SPEED
	_update_facing(velocity)
	move_and_slide()
	_update_walk_animation(delta, get_real_velocity().length() > STALL_SPEED_EPSILON)
	_handle_stall()


func _update_facing(direction: Vector2) -> void:
	# The sprite is drawn through the isometric projection, so facing must be
	# chosen from the PROJECTED screen motion, not the raw square velocity: a
	# +y grid step projects down-LEFT on screen and a -y step up-RIGHT, so
	# comparing square x vs y (the round 004 code) selected DOWN/UP for motion
	# that visibly runs sideways on the diamond. IsoProjection.cell_to_screen is
	# linear with no constant term, so projecting the velocity direction yields
	# the screen-motion direction directly. facing_octant is the frozen contract
	# this was always meant to wire to (decision 008); its eight octants fold
	# onto the four proxy rows until the 8-facing atlas lands.
	var octant := IsoProjection.facing_octant(IsoProjection.cell_to_screen(direction))
	if octant == IsoProjection.FACING_NEUTRAL:
		return
	# A candidate sheet has one row per octant, so the octant is the row; the
	# proxy sheet folds the eight octants onto its four rows.
	_facing = octant if _facing_is_octant else _OCTANT_TO_FACING[octant]


func _update_walk_animation(delta: float, moving: bool) -> void:
	if not moving:
		_walk_elapsed = 0.0
		_walk_frame = 0
		_apply_walk_frame()
		return
	_walk_elapsed += delta
	while _walk_elapsed >= WALK_FRAME_SECONDS:
		_walk_elapsed -= WALK_FRAME_SECONDS
		_walk_frame = (_walk_frame + 1) % _walk_frame_count
	_apply_walk_frame()


func _apply_walk_frame() -> void:
	if _walk_atlas == null:
		return
	_walk_texture.region = Rect2(
		Vector2(_walk_frame * _walk_cell_size.x, int(_facing) * _walk_cell_size.y),
		_walk_cell_size
	)


# The residual backstop described at the top of this file, NOT the answer to
# collider/grid disagreement. get_real_velocity() is post-collision, so this
# measures what the body actually did rather than what it intended.
func _handle_stall() -> void:
	if get_real_velocity().length() > STALL_SPEED_EPSILON:
		_stall_frames = 0
		return
	_stall_frames += 1
	if _stall_frames < STALL_FRAMES:
		return
	if _repathed_since_stall:
		clear_path()
		return
	var goal := _destination_cell
	_repathed_since_stall = true
	_stall_frames = 0
	if _route_to(goal) == NavGridScript.NO_CELL:
		clear_path()
		return
	# _route_to resets the guard, so re-arm it: the next stall on this route
	# drops it rather than repathing forever.
	_repathed_since_stall = true


