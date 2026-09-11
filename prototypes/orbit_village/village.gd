extends Node3D

# Disposable presentation experiment. No shared-world simulation lives here.
const Cottage = preload("res://assets/cottage.glb")
const Walker = preload("res://assets/player_walk.glb")
const AREA := 15.0
const CELL := 0.5
var camera: Camera3D
var avatar: Node3D
var animation: AnimationPlayer
var walk_clip := ""
var yaw := 45.0
var target_yaw := 45.0
var elevation := 35.264
var focus := Vector3(0, 0.8, 0)
var dragging := false
var drag_distance := 0.0
var fixed := false
var orbit := false
var route: Array[Vector3] = []
var nav := AStarGrid2D.new()
var angle_label: Label
var status_label: Label
var lock_button: CheckButton
var orbit_button: CheckButton
var zoom_slider: HSlider
var elevation_slider: HSlider
var marker: MeshInstance3D
var footprint_rects: Array[Rect2] = []
var travel := 0.0


func _ready() -> void:
	_build_world()
	_build_navigation()
	_build_ui()
	_update_camera()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):
			_capture_study(arg.trim_prefix("--capture-dir="))


func _material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.95
	return mat


func _box(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.material_override = _material(color)
	parent.add_child(mesh)
	mesh.position = pos
	return mesh


func _build_world() -> void:
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("343f3b")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("dbe3d3")
	env.ambient_light_energy = 0.65
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment = env
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -35, 0)
	sun.light_color = Color("fff0ce")
	sun.light_energy = 0.85
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 70
	add_child(sun)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(34, 34)
	ground.mesh = plane
	var ground_material := ShaderMaterial.new()
	ground_material.shader = preload("res://ground.gdshader")
	ground_material.set_shader_parameter("grass_tex", preload("res://art/grass.png"))
	ground_material.set_shader_parameter("dirt_tex", preload("res://art/dirt.png"))
	ground.material_override = ground_material
	add_child(ground)
	_add_cottage(Vector3(-5, 0, -5), 0)
	_add_cottage(Vector3(5, 0, 5), 180)
	# These simple fence forms are spatial references, not production art.
	for x in [-8.3, -6.7, -5.1, -3.5, -1.9]:
		_box(self, Vector3(x, 0.65, -8.7), Vector3(0.14, 1.3, 0.14), Color("75654b"))
	for y in [0.45, 0.95]:
		_box(self, Vector3(-5.1, y, -8.7), Vector3(6.5, 0.1, 0.1), Color("8b7856"))
	avatar = Node3D.new()
	add_child(avatar)
	avatar.position = Vector3(-2, 0, 1)
	var model := Walker.instantiate()
	avatar.add_child(model)
	# This recovered skinned mesh has 1.53125 m mesh-space height (GLB
	# POSITION accessor). Its skeleton already applies the armature transform;
	# the static-mesh bounds walk would apply that scale a second time.
	model.scale = Vector3.ONE * (1.75 / 1.53125)
	animation = _find_animation(model)
	if animation:
		for clip in animation.get_animation_list():
			if clip != "RESET":
				walk_clip = clip
				animation.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
				animation.play(clip)
				animation.advance(0)
				animation.pause()
				break
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 22.0
	camera.far = 150
	add_child(camera)
	camera.make_current()
	marker = MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.19
	ring.outer_radius = 0.26
	ring.rings = 24
	ring.ring_segments = 8
	marker.mesh = ring
	marker.material_override = _material(Color("ead8a0"))
	marker.visible = false
	add_child(marker)


func _bounds(node: Node3D, inherited: Transform3D) -> AABB:
	var transform := inherited * node.transform
	var result := AABB()
	var found := false
	if node is MeshInstance3D:
		result = transform * node.get_aabb()
		found = true
	for child in node.get_children():
		if child is Node3D:
			var child_bounds := _bounds(child, transform)
			if child_bounds.size != Vector3.ZERO:
				result = result.merge(child_bounds) if found else child_bounds
				found = true
	return result


func _add_cottage(pos: Vector3, degrees: float) -> void:
	var holder := Node3D.new()
	add_child(holder)
	holder.position = pos
	holder.rotation_degrees.y = degrees
	var model := Cottage.instantiate()
	holder.add_child(model)
	var bounds := _bounds(model, Transform3D.IDENTITY)
	model.position.y -= bounds.position.y
	# The two views use 0/180 rotations, so their X/Z extents are identical.
	var half := Vector2(bounds.size.x, bounds.size.z) * 0.5 + Vector2.ONE * 0.35
	footprint_rects.append(Rect2(Vector2(pos.x, pos.z) - half, half * 2))


func _find_animation(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var found := _find_animation(child)
		if found:
			return found
	return null


func _build_navigation() -> void:
	nav.region = Rect2i(0, 0, 60, 60)
	nav.cell_size = Vector2.ONE * CELL
	nav.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	nav.update()
	for y in range(60):
		for x in range(60):
			var p := Vector2(x, y) * CELL - Vector2.ONE * AREA
			for rect in footprint_rects:
				if rect.has_point(p):
					nav.set_point_solid(Vector2i(x, y))


func _cell(pos: Vector3) -> Vector2i:
	return Vector2i(roundi((pos.x + AREA) / CELL), roundi((pos.z + AREA) / CELL))


func _walk_to(point: Vector3) -> bool:
	var end := _cell(point)
	if not nav.is_in_boundsv(end) or nav.is_point_solid(end):
		status_label.text = "Choose open ground beside the buildings."
		return false
	var ids := nav.get_id_path(_cell(avatar.position), end)
	if ids.is_empty():
		return false
	route.clear()
	for id in ids:
		route.append(Vector3(id.x * CELL - AREA, 0, id.y * CELL - AREA))
	marker.position = route.back() + Vector3(0, 0.05, 0)
	marker.visible = true
	status_label.text = "Walking. Try rotating while the traveler moves."
	return true


func _process(delta: float) -> void:
	if orbit and not fixed:
		target_yaw += delta * 12.0
	yaw = lerpf(yaw, target_yaw, 1.0 - exp(-delta * 12.0))
	_update_camera()
	if not route.is_empty():
		var delta_pos := route[0] - avatar.position
		if delta_pos.length() < 0.04:
			route.pop_front()
		else:
			var old_pos := avatar.position
			avatar.position = avatar.position.move_toward(route[0], 2.1 * delta)
			travel += avatar.position.distance_to(old_pos)
			avatar.rotation.y = lerp_angle(avatar.rotation.y, atan2(delta_pos.x, delta_pos.z), 1.0 - exp(-delta * 12.0))
		if animation and not animation.is_playing():
			animation.play(walk_clip)
	else:
		if animation and animation.is_playing():
			animation.pause()
		marker.visible = false
	angle_label.text = "%03d°  /  %.1f° elevation  /  %s" % [int(fposmod(yaw, 360)), elevation, "FIXED" if fixed else "ORBIT"]


func _update_camera() -> void:
	var a := deg_to_rad(yaw)
	var e := deg_to_rad(elevation)
	camera.position = focus + Vector3(sin(a) * cos(e), sin(e), cos(a) * cos(e)) * 38.0
	camera.look_at(focus)


func _input(event: InputEvent) -> void:
	# Release may happen over a control that consumes the mouse event.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed:
		if dragging and drag_distance < 6.0 and get_viewport().gui_get_hovered_control() == null:
			_rehome_at(event.position)
		dragging = false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				dragging = true
				drag_distance = 0.0
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_slider.value -= 1
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_slider.value += 1
		elif event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var origin := camera.project_ray_origin(event.position)
			var direction := camera.project_ray_normal(event.position)
			var hit = Plane(Vector3.UP, 0).intersects_ray(origin, direction)
			if hit != null:
				_walk_to(hit)
	elif event is InputEventMouseMotion and dragging:
		drag_distance += event.relative.length()
		if drag_distance >= 6.0 and not fixed:
			target_yaw -= event.relative.x * 0.3
			elevation_slider.value += event.relative.y * 0.2
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_Q: _rotate(-45)
			KEY_E: _rotate(45)
			KEY_R: _reset_view()
			KEY_SPACE: _center_traveler()
			KEY_ESCAPE: get_tree().quit()


func _rehome_at(screen_position: Vector2) -> void:
	var hit = Plane(Vector3.UP, 0).intersects_ray(
		camera.project_ray_origin(screen_position), camera.project_ray_normal(screen_position))
	if hit == null or absf(hit.x) > AREA or absf(hit.z) > AREA:
		status_label.text = "Right-click within the meadow to center the view."
		return
	focus = Vector3(hit.x, 0.8, hit.z)
	_update_camera()
	status_label.text = "View centered here. Space returns to the traveler."


func _center_traveler() -> void:
	focus = avatar.position + Vector3(0, 0.8, 0)
	_update_camera()
	status_label.text = "Centered on the traveler."


func _rotate(degrees: float) -> void:
	if not fixed:
		target_yaw += degrees


func _reset_view() -> void:
	focus = Vector3(0, 0.8, 0)
	target_yaw = 45
	zoom_slider.value = 22
	elevation_slider.value = 35.264
	orbit_button.button_pressed = false


func _label(text: String, size: int, color := Color("eee9d9")) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func _button(text: String, callback: Callable, parent: Node) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 42
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(24, 24)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.075, 0.10, 0.085, 0.93)
	style.set_corner_radius_all(12)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", style)
	layer.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	box.add_child(_label("L O N G W A L K", 25))
	box.add_child(_label("CAMERA STUDY  /  rough art", 13, Color("c4c7af")))
	box.add_child(_label("Left-click to walk · Right-click to center\nRight-drag to orbit and tilt · Scroll to zoom", 16))
	var buttons := HBoxContainer.new()
	box.add_child(buttons)
	_button("↶  45°", func(): _rotate(-45), buttons)
	_button("45°  ↷", func(): _rotate(45), buttons)
	_button("Reset view", _reset_view, buttons)
	_button("Center traveler  [Space]", _center_traveler, box)
	lock_button = CheckButton.new()
	lock_button.text = "Lock angle (compare fixed view)"
	lock_button.toggled.connect(func(value):
		fixed = value
		dragging = false
		if value:
			target_yaw = yaw
			orbit_button.button_pressed = false
	)
	box.add_child(lock_button)
	orbit_button = CheckButton.new()
	orbit_button.text = "Slow automatic orbit"
	orbit_button.toggled.connect(func(value):
		orbit = value
		if value:
			lock_button.button_pressed = false
	)
	box.add_child(orbit_button)
	box.add_child(_label("View angle: eye level to overhead", 14))
	elevation_slider = HSlider.new()
	elevation_slider.min_value = 1
	elevation_slider.max_value = 60
	elevation_slider.step = 0.001
	elevation_slider.value = elevation
	elevation_slider.value_changed.connect(func(value): elevation = value)
	box.add_child(elevation_slider)
	box.add_child(_label("Zoom", 14))
	zoom_slider = HSlider.new()
	zoom_slider.min_value = 3
	zoom_slider.max_value = 32
	zoom_slider.value = 22
	zoom_slider.value_changed.connect(func(value): camera.size = value)
	box.add_child(zoom_slider)
	angle_label = _label("", 13, Color("d9c38b"))
	box.add_child(angle_label)
	status_label = _label("Explore the front, sides, and rear.", 14)
	status_label.position = Vector2(24, 852)
	layer.add_child(status_label)
	_button("Quit", func(): get_tree().quit(), box)


func _check(condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
	return condition


func _capture_study(path: String) -> void:
	var passed := true
	DirAccess.make_dir_recursive_absolute(path)
	await get_tree().process_frame
	for angle in [45.0, 135.0, 225.0, 315.0]:
		yaw = angle
		target_yaw = angle
		await get_tree().create_timer(0.2).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(path.path_join("view-%d.png" % angle))
	# Exercise the same movement function as mouse picking, around a footprint.
	avatar.position = Vector3(-9, 0, -5)
	passed = _check(_walk_to(Vector3(-1, 0, -5)), "Destination must be reachable") and passed
	passed = _check(route.size() > 16, "Route should detour around cottage") and passed
	for point in route:
		for rect in footprint_rects:
			passed = _check(not rect.has_point(Vector2(point.x, point.z)), "Route intersects cottage") and passed
	await get_tree().create_timer(0.5).timeout
	passed = _check(travel > 0.5, "Traveler must actually move") and passed
	passed = _check(animation != null and animation.is_playing(), "Walk animation must play") and passed
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path.path_join("walking.png"))
	lock_button.button_pressed = true
	var locked_yaw := target_yaw
	_rotate(45)
	passed = _check(target_yaw == locked_yaw, "Fixed mode must refuse rotation") and passed
	orbit_button.button_pressed = true
	passed = _check(not fixed, "Orbit must unlock camera") and passed
	await get_tree().create_timer(0.2).timeout
	passed = _check(target_yaw > locked_yaw, "Automatic orbit must advance") and passed
	_reset_view()
	passed = _check(not orbit and camera.size == 22, "Reset must restore zoom and stop orbit") and passed
	passed = _check(is_equal_approx(elevation, 35.264), "Reset must restore elevation") and passed
	_update_camera()
	var chosen_ground := Vector3(2, 0, -1)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_RIGHT
	click.position = camera.unproject_position(chosen_ground)
	click.pressed = true
	_unhandled_input(click)
	click.pressed = false
	_input(click)
	passed = _check(focus.distance_to(chosen_ground + Vector3(0, 0.8, 0)) < 0.01, "Right-click must center the chosen ground") and passed
	# Walking still uses the camera's ray after the map has been recentered.
	avatar.position = Vector3(0, 0, 0)
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = camera.unproject_position(Vector3(3, 0, 0))
	click.pressed = true
	_unhandled_input(click)
	passed = _check(not route.is_empty() and route.back().distance_to(Vector3(3, 0, 0)) < 0.01, "Left-click must walk after recentering") and passed
	# Exercise orbit tilt through the mouse path, including the low-angle clamp.
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_RIGHT
	press.pressed = true
	_unhandled_input(press)
	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(0, -1000)
	_unhandled_input(motion)
	passed = _check(is_equal_approx(elevation, 1), "Orbit tilt must reach and clamp at eye level") and passed
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_RIGHT
	var focus_before_release := focus
	_input(release)
	passed = _check(not dragging, "Mouse release must end orbit") and passed
	passed = _check(focus == focus_before_release, "Releasing an orbit drag must not recenter") and passed
	route.clear()
	avatar.position = Vector3(-2, 0, 1)
	_center_traveler()
	passed = _check(focus == avatar.position + Vector3(0, 0.8, 0), "Center traveler must restore the subject") and passed
	zoom_slider.value = 3
	yaw = 180
	target_yaw = yaw
	await get_tree().create_timer(0.2).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path.path_join("eye-level.png"))
	if passed:
		print("STUDY CHECKS PASSED: rendered angles, movement, lock, orbit, reset, eye-level tilt, right-click center, left-click after center, drag release")
	get_tree().quit(0 if passed else 1)
