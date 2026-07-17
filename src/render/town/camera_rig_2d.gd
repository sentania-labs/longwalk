extends Camera2D
class_name CameraRig2D

const IsoProjection = preload("res://src/render/iso/projection.gd")

enum State { FOLLOW, DRAG }

var _state := State.FOLLOW
var _player: CharacterBody2D
var _layout

var _zoom_levels: Array[float] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
var _zoom_index := 2
var _target_zoom := 1.0

var _projected_bounds := Rect2()

# Panning
var _pan_active := false
var _pan_start_mouse_pos := Vector2.ZERO
const DRAG_THRESHOLD := 5.0 # screen pixels

# Cursor-preserving zoom
var _zoom_center_screen := Vector2.ZERO

func setup(player: CharacterBody2D, layout) -> void:
	_player = player
	_layout = layout
	if _layout != null:
		var grid_size = Vector2i(_layout.width, _layout.height)
		# A reasonable headroom to cover sprites/shadows
		var headroom = Vector2(300, 400)
		_projected_bounds = IsoProjection.projected_bounds(grid_size, headroom)
	
	_recompute_zoom_levels()
	
	if _player != null:
		position = IsoProjection.world_to_screen(_player.position)

func _recompute_zoom_levels() -> void:
	if _layout == null:
		return

	var vp_w: float = ProjectSettings.get_setting("display/window/size/viewport_width")
	var vp_h: float = ProjectSettings.get_setting("display/window/size/viewport_height")
	
	# Minimum zoom to fit the projected bounds in the viewport
	var min_zoom_x := vp_w / _projected_bounds.size.x
	var min_zoom_y := vp_h / _projected_bounds.size.y
	var min_zoom := maxf(min_zoom_x, min_zoom_y)

	var new_levels: Array[float] = [min_zoom]
	for z in [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]:
		if z > min_zoom:
			new_levels.append(z)

	var current_zoom := _zoom_levels[_zoom_index]
	_zoom_levels = new_levels

	_zoom_index = 0
	for i in range(_zoom_levels.size()):
		if _zoom_levels[i] <= current_zoom:
			_zoom_index = i
		else:
			break

	_target_zoom = _zoom_levels[_zoom_index]

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("zoom_in") or event.is_action_pressed("zoom_out"):
		var factor = 1 if event.is_action_pressed("zoom_in") else -1
		_set_zoom_index(_zoom_index + factor)
		var vp := get_viewport()
		if vp:
			# Use the current mouse position in the viewport as the center for zoom
			_zoom_center_screen = vp.get_mouse_position()
			vp.set_input_as_handled()
	elif event.is_action_pressed("pan_drag"):
		_pan_active = true
		if event is InputEventMouse:
			_pan_start_mouse_pos = event.position
		else:
			var vp = get_viewport()
			if vp:
				_pan_start_mouse_pos = vp.get_mouse_position()
		var vp := get_viewport()
		if vp:
			vp.set_input_as_handled()
	elif event.is_action_released("pan_drag"):
		_pan_active = false
		var vp := get_viewport()
		if vp:
			vp.set_input_as_handled()
	elif event.is_action_pressed("center_on_player"):
		_state = State.FOLLOW
		var vp := get_viewport()
		if vp:
			vp.set_input_as_handled()
			
	if _pan_active and event is InputEventMouseMotion:
		if _state != State.DRAG:
			if event.position.distance_to(_pan_start_mouse_pos) > DRAG_THRESHOLD:
				_state = State.DRAG
		
		if _state == State.DRAG:
			# Pan the camera by the relative motion divided by zoom
			position -= event.relative / zoom
			position = _clamp_to_limits(position)
			var vp := get_viewport()
			if vp:
				vp.set_input_as_handled()

func _set_zoom_index(new_index: int) -> void:
	_zoom_index = clampi(new_index, 0, _zoom_levels.size() - 1)
	_target_zoom = _zoom_levels[_zoom_index]

func _clamp_to_limits(pos: Vector2) -> Vector2:
	if _projected_bounds.size == Vector2.ZERO:
		return pos
		
	var vp_w: float = ProjectSettings.get_setting("display/window/size/viewport_width")
	var vp_h: float = ProjectSettings.get_setting("display/window/size/viewport_height")
	var vp_size = Vector2(vp_w, vp_h) / zoom
	var half_size = vp_size / 2.0
	
	var limit_left = _projected_bounds.position.x
	var limit_top = _projected_bounds.position.y
	var limit_right = _projected_bounds.end.x
	var limit_bottom = _projected_bounds.end.y
	
	var clamped_x = clampf(pos.x, limit_left + half_size.x, limit_right - half_size.x)
	var clamped_y = clampf(pos.y, limit_top + half_size.y, limit_bottom - half_size.y)
	
	if limit_right - limit_left < vp_size.x:
		clamped_x = limit_left + (limit_right - limit_left) / 2.0
	if limit_bottom - limit_top < vp_size.y:
		clamped_y = limit_top + (limit_bottom - limit_top) / 2.0
		
	return Vector2(clamped_x, clamped_y)

func _process(delta: float) -> void:
	if not is_equal_approx(zoom.x, _target_zoom):
		var old_z: float = zoom.x
		var new_z: float = lerpf(zoom.x, _target_zoom, 1.0 - exp(-15.0 * delta))
		if abs(new_z - _target_zoom) < 0.001:
			new_z = _target_zoom
			
		# Cursor-preserving zoom logic
		if _zoom_center_screen != Vector2.ZERO:
			var vp_size = get_viewport_rect().size
			var screen_center_offset = _zoom_center_screen - vp_size / 2.0
			var shift = screen_center_offset * (1.0 / old_z - 1.0 / new_z)
			
			if _state == State.DRAG:
				position += shift
				position = _clamp_to_limits(position)
		
		zoom = Vector2(new_z, new_z)
		
		# Clear _zoom_center_screen when zoom completes
		if new_z == _target_zoom:
			_zoom_center_screen = Vector2.ZERO

	if _state == State.FOLLOW and _player != null:
		position = IsoProjection.world_to_screen(_player.position)
		position = _clamp_to_limits(position)
