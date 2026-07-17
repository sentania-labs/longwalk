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

const SPEED := 220.0
const TILE_SIZE := TownLayoutScript.TILE_SIZE

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

const ZOOM_LEVELS: Array[float] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
var _zoom_index := 2


func set_appearance(appearance_variant: String) -> void:
	# get_node() rather than an @onready var: set_appearance() is meant to be
	# callable right after instantiate(), including from a headless test that
	# never adds the node to a live SceneTree (see test/active_path/), and
	# @onready resolution only fires on tree entry.
	var sprite: Sprite2D = get_node("Sprite2D")
	var path := "res://tools/art/out/processed/player_character_%s.png" % appearance_variant
	sprite.texture = load(path)


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


func _physics_process(_delta: float) -> void:
	if _waypoints.is_empty():
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var target: Vector2 = _waypoints[0]
	if position.distance_to(target) <= WAYPOINT_REACHED_RADIUS:
		_waypoints.remove_at(0)
		if _waypoints.is_empty():
			clear_path()
			move_and_slide()
			path_finished.emit()
			return
		target = _waypoints[0]

	velocity = position.direction_to(target) * SPEED
	move_and_slide()
	_handle_stall()


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


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("zoom_in"):
		_set_zoom_index(_zoom_index + 1)
		var viewport := get_viewport()
		if viewport:
			viewport.set_input_as_handled()
	elif event.is_action_pressed("zoom_out"):
		_set_zoom_index(_zoom_index - 1)
		var viewport := get_viewport()
		if viewport:
			viewport.set_input_as_handled()


func _set_zoom_index(new_index: int) -> void:
	_zoom_index = clampi(new_index, 0, ZOOM_LEVELS.size() - 1)
	var camera: Camera2D = get_node_or_null("Camera2D")
	if camera:
		var z: float = ZOOM_LEVELS[_zoom_index]
		camera.zoom = Vector2(z, z)
