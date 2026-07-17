extends Camera2D
class_name CameraRig2D

enum State { FOLLOW, FOCUSED }

var _state := State.FOLLOW
var _focus_point := Vector2.ZERO
var _player: CharacterBody2D
var _layout

var _zoom_levels: Array[float] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
var _zoom_index := 2
var _target_zoom := 1.0

func setup(player: CharacterBody2D, layout) -> void:
	_player = player
	_layout = layout
	_recompute_zoom_levels()
	if _layout != null:
		var pixel_size = _layout.pixel_size()
		limit_left = 0
		limit_top = 0
		limit_right = int(pixel_size.x)
		limit_bottom = int(pixel_size.y)
	
	if _player != null:
		position = _player.position

func _recompute_zoom_levels() -> void:
	if _layout == null:
		return

	var vp_w: float = ProjectSettings.get_setting("display/window/size/viewport_width")
	var vp_h: float = ProjectSettings.get_setting("display/window/size/viewport_height")
	var town_size: Vector2 = _layout.pixel_size()

	var min_zoom_x := vp_w / town_size.x
	var min_zoom_y := vp_h / town_size.y
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
	if event.is_action_pressed("zoom_in"):
		_set_zoom_index(_zoom_index + 1)
		var vp := get_viewport()
		if vp:
			vp.set_input_as_handled()
	elif event.is_action_pressed("zoom_out"):
		_set_zoom_index(_zoom_index - 1)
		var vp := get_viewport()
		if vp:
			vp.set_input_as_handled()
	elif event.is_action_pressed("focus_view"):
		_state = State.FOCUSED
		var world_pos = get_global_mouse_position()
		_focus_point = _clamp_to_limits(world_pos)
		var vp := get_viewport()
		if vp:
			vp.set_input_as_handled()
	elif event.is_action_pressed("center_on_player"):
		_state = State.FOLLOW
		var vp := get_viewport()
		if vp:
			vp.set_input_as_handled()

func _set_zoom_index(new_index: int) -> void:
	_zoom_index = clampi(new_index, 0, _zoom_levels.size() - 1)
	_target_zoom = _zoom_levels[_zoom_index]

func _clamp_to_limits(pos: Vector2) -> Vector2:
	var vp_w: float = ProjectSettings.get_setting("display/window/size/viewport_width")
	var vp_h: float = ProjectSettings.get_setting("display/window/size/viewport_height")
	var vp_size = Vector2(vp_w, vp_h) / zoom
	var half_size = vp_size / 2.0
	var clamped_x = clampf(pos.x, limit_left + half_size.x, limit_right - half_size.x)
	var clamped_y = clampf(pos.y, limit_top + half_size.y, limit_bottom - half_size.y)
	
	if limit_right - limit_left < vp_size.x:
		clamped_x = limit_left + (limit_right - limit_left) / 2.0
	if limit_bottom - limit_top < vp_size.y:
		clamped_y = limit_top + (limit_bottom - limit_top) / 2.0
		
	return Vector2(clamped_x, clamped_y)

func _process(delta: float) -> void:
	if not is_equal_approx(zoom.x, _target_zoom):
		var new_z: float = lerpf(zoom.x, _target_zoom, 1.0 - exp(-15.0 * delta))
		if abs(new_z - _target_zoom) < 0.001:
			new_z = _target_zoom
		zoom = Vector2(new_z, new_z)
		if _state == State.FOCUSED:
			_focus_point = _clamp_to_limits(_focus_point)

	if _state == State.FOLLOW and _player != null:
		position = _player.position
	elif _state == State.FOCUSED:
		position = position.lerp(_focus_point, 1.0 - exp(-10.0 * delta))
