extends Node3D

# Disposable presentation experiment. No shared-world simulation lives here.
const ART = {
 "cottage_wide": preload("res://assets/cottage-wide.glb"),
 "cottage": preload("res://assets/cottage.glb"),
 "tree": preload("res://assets/tree-v2.glb"),
 "fence": preload("res://assets/fence.glb"),
 "shrub": preload("res://assets/shrub.glb"),
 "firewood": preload("res://assets/firewood.glb"),
}
const Walker = preload("res://assets/player_walk.glb")
const AREA := 24.0
const CELL := 0.5
var camera: Camera3D
var avatar: Node3D
var animation: AnimationPlayer
var walk_clip := "motion/walk"
var idle_clip := "motion/idle"
var yaw := 45.0
var target_yaw := 45.0
var elevation := 35.264
var focus := Vector3(0, 1.2, 0)
var focus_target := Vector3(0, 1.2, 0)
var pan_velocity := Vector3.ZERO
var edge_enabled := true
var edge_speed := 7.0
var arranged: Node3D
var ground_material: ShaderMaterial
var skeleton: Skeleton3D
var actor_model: Node3D
var camera_controls: PanelContainer
var capture_mode := false
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
	process_priority = 100
	_build_world()
	_build_navigation()
	_build_ui()
	_update_camera()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):
			capture_mode = true
			_capture_study(arg.trim_prefix("--capture-dir="))


func _material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.95
	return mat


func _build_world() -> void:
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("89948a")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("dbe3d3")
	env.ambient_light_energy = 0.48
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment = env
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -35, 0)
	sun.light_color = Color("fff0ce")
	sun.light_energy = 0.8
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 70
	add_child(sun)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(90, 90)
	ground.mesh = plane
	ground_material = ShaderMaterial.new()
	ground_material.shader = preload("res://ground.gdshader")
	ground_material.set_shader_parameter("grass_tex", preload("res://art/grass.png"))
	ground_material.set_shader_parameter("dirt_tex", preload("res://art/dirt.png"))
	ground_material.set_shader_parameter("soil_tex", preload("res://art/soil.png"))
	ground.material_override = ground_material
	add_child(ground)
	arranged = Node3D.new()
	add_child(arranged)
	_build_arrangement()
	avatar = Node3D.new()
	add_child(avatar)
	avatar.position = Vector3(0.5, 0, 3.5)
	var model := Walker.instantiate()
	actor_model = model
	avatar.add_child(model)
	skeleton = _find_skeleton(model)
	for mesh in model.find_children("*", "MeshInstance3D", true, false):
		for surface_index in range(mesh.mesh.get_surface_count()):
			var mat = mesh.get_active_material(surface_index).duplicate()
			if mat is StandardMaterial3D:
				mat.emission_enabled = false
				mat.metallic = 0
				mat.roughness = 0.95
				mesh.set_surface_override_material(surface_index, mat)
	animation = _find_animation(model)
	var library := AnimationLibrary.new()
	for spec in [["walk", "res://assets/player_walk.glb"], ["idle", "res://assets/player_idle.glb"]]:
		var source: Node3D = load(spec[1]).instantiate()
		var player := _find_animation(source)
		for name in player.get_animation_list():
			if name == "RESET":
				continue
			var clip := player.get_animation(name).duplicate() as Animation
			clip.loop_mode = Animation.LOOP_LINEAR
			# Strip planar root travel so input remains the sole movement authority.
			for track in range(clip.get_track_count()):
				if clip.track_get_type(track) == Animation.TYPE_POSITION_3D and str(clip.track_get_path(track)).ends_with(":Hips"):
					for key in range(clip.track_get_key_count(track)):
						var value: Vector3 = clip.track_get_key_value(track, key)
						value.x = 0
						value.z = 0
						clip.track_set_key_value(track, key, value)
			library.add_animation(spec[0], clip)
			break
		source.free()
	animation.add_animation_library("motion", library)
	animation.play(idle_clip)
	animation.advance(0)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 28.0
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


func _add_prop(key: String, pos: Vector3, height: float, angle := 0.0, blocking := false) -> Node3D:
	var holder := Node3D.new()
	arranged.add_child(holder)
	holder.position = pos
	holder.rotation_degrees.y = angle
	var model: Node3D = ART[key].instantiate()
	holder.add_child(model)
	var bounds := _bounds(model, Transform3D.IDENTITY)
	var factor := height / bounds.size.y
	model.scale *= factor
	model.position -= Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z) * factor
	if key == "shrub":
		# The generated leaf cluster is shallow. Cross three instances to build
		# a volume that retains leaf proportions when seen from the side.
		for angle_offset in [60.0, 120.0]:
			var cluster := model.duplicate() as Node3D
			holder.add_child(cluster)
			cluster.rotation_degrees.y += angle_offset
	if blocking:
		var world_bounds := _bounds(holder, Transform3D.IDENTITY)
		var rect := Rect2(Vector2(world_bounds.position.x, world_bounds.position.z), Vector2(world_bounds.size.x, world_bounds.size.z))
		footprint_rects.append(rect.grow(0.3))
	return holder


func _build_arrangement() -> void:
	# Authored positions for this fixed art study.
	var homes := [Vector3(-8, 0, -4.5), Vector3(3, 0, -4.5), Vector3(10, 0, 7.5)]
	for i in range(homes.size()):
		var pos: Vector3 = homes[i]
		var angle := 180.0 if i == 2 else 0.0
		_add_prop("cottage_wide" if i == 1 else "cottage", pos, 5.6 if i == 1 else 6.2, angle, true)
		var direction := -1.0 if i == 2 else 1.0
		_add_prop("firewood", pos + Vector3(5.1 if i == 1 else 3.7, 0, -0.2), 0.85, 90, true)
		for offset in [Vector3(-2.6, -0.03, 2.9), Vector3(2.4, -0.03, 3.0), Vector3(-3.2, -0.03, -1.4)]:
			if i == 1:
				offset.x *= 1.4
				offset.z *= 1.2
			_add_prop("shrub", pos + offset * Vector3(1, 1, direction), 0.65, 35 * i)
	for spec in [Vector4(-14, 0, 7.4, 25), Vector4(-2, 7.5, 6.8, 80), Vector4(12, -7.5, 7.4, 140)]:
		var pos := Vector3(spec.x, 0, spec.y)
		_add_prop("tree", pos, spec.z, spec.w)
		footprint_rects.append(Rect2(Vector2(pos.x - 0.6, pos.z - 0.6), Vector2(1.2, 1.2)))
		_add_prop("shrub", pos + Vector3(0.6, -0.04, 0.3), 0.45, 40)
	for x in [-11.6, -9.8, -8.0, -6.2, -4.4, 0.0, 1.8, 3.6, 5.4, 7.2]:
		_add_prop("fence", Vector3(x, 0, -8.7), 1.1, 0, true)
	for z in [-7.8, -6.0, -4.2]:
		_add_prop("fence", Vector3(-12.6, 0, z), 1.1, 90, true)


func _visit_home(value: int) -> void:
	pan_velocity = Vector3.ZERO
	focus_target = [Vector3(-8, 1.2, -1), Vector3(3, 1.2, -1), Vector3(10, 1.2, 5)][value]
	zoom_slider.value = 16
	if not fixed:
		target_yaw = 225 if value == 2 else 45
	status_label.text = "Home %d. Left-click the lane to walk here." % (value + 1)


func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	for child in node.get_children():
		var found := _find_skeleton(child)
		if found:
			return found
	return null


func _find_animation(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var found := _find_animation(child)
		if found:
			return found
	return null


func _build_navigation() -> void:
	nav.region = Rect2i(0, 0, 96, 96)
	nav.cell_size = Vector2.ONE * CELL
	nav.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	nav.update()
	nav.fill_solid_region(nav.region, false)
	for y in range(96):
		for x in range(96):
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
	_update_edge_scroll(delta)
	focus = focus.lerp(focus_target, 1.0 - exp(-delta * 6.0))
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
			avatar.position = avatar.position.move_toward(route[0], 1.6 * delta)
			travel += avatar.position.distance_to(old_pos)
			avatar.rotation.y = lerp_angle(avatar.rotation.y, atan2(delta_pos.x, delta_pos.z), 1.0 - exp(-delta * 12.0))
		if animation.current_animation != walk_clip:
			animation.play(walk_clip, 0.2)
	else:
		if animation.current_animation != idle_clip:
			animation.play(idle_clip, 0.25)
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
	elif event is InputEventKey and event.pressed:
		if event.physical_keycode == KEY_MINUS:
			zoom_slider.value += 1
			return
		if event.physical_keycode == KEY_EQUAL:
			zoom_slider.value -= 1
			return
		if event.echo:
			return
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
	focus_target = Vector3(hit.x, 1.2, hit.z)
	status_label.text = "View centered here. Space returns to the traveler."


func _center_traveler() -> void:
	pan_velocity = Vector3.ZERO
	focus_target = avatar.position + Vector3(0, 1.2, 0)
	status_label.text = "Centered on the traveler."


func _rotate(degrees: float) -> void:
	if not fixed:
		target_yaw += degrees


func _reset_view() -> void:
	pan_velocity = Vector3.ZERO
	focus_target = Vector3(0, 1.2, 0)
	target_yaw = 45
	zoom_slider.value = 28
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


func _edge_direction(mouse: Vector2, size: Vector2) -> Vector2:
	if mouse.x < 0 or mouse.y < 0 or mouse.x >= size.x or mouse.y >= size.y:
		return Vector2.ZERO
	var zone := 28.0
	return Vector2(
		clampf((mouse.x - size.x + zone) / zone, 0, 1) - clampf((zone - mouse.x) / zone, 0, 1),
		clampf((mouse.y - size.y + zone) / zone, 0, 1) - clampf((zone - mouse.y) / zone, 0, 1)
	).limit_length()


func _keyboard_pan_direction() -> Vector2:
	return Vector2(
		float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
		float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
	).limit_length()


func _update_edge_scroll(delta: float) -> void:
	var direction := Vector2.ZERO
	var focused := get_viewport().gui_get_focus_owner()
	var editing_text := focused is LineEdit or focused is TextEdit
	if not capture_mode and get_window().has_focus() and not editing_text:
		direction = _keyboard_pan_direction()
	if edge_enabled and not capture_mode and not dragging and get_window().has_focus() and get_viewport().gui_get_hovered_control() == null:
		direction += _edge_direction(get_viewport().get_mouse_position(), get_viewport().get_visible_rect().size)
	_apply_pan_input(direction.limit_length(), delta)


func _apply_pan_input(direction: Vector2, delta: float) -> void:
	var right := Vector3(cos(deg_to_rad(yaw)), 0, -sin(deg_to_rad(yaw)))
	var back := Vector3(sin(deg_to_rad(yaw)), 0, cos(deg_to_rad(yaw)))
	var desired := (right * direction.x + back * direction.y) * edge_speed
	pan_velocity = pan_velocity.lerp(desired, 1.0 - exp(-delta * 7.0))
	focus_target += pan_velocity * delta
	focus_target.x = clampf(focus_target.x, -21, 21)
	focus_target.z = clampf(focus_target.z, -21, 21)


func _panel(pos: Vector2, layer: CanvasLayer) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = pos
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.08, 0.065, 0.92)
	style.set_corner_radius_all(10)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)
	layer.add_child(panel)
	return panel


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var heading := VBoxContainer.new()
	heading.position = Vector2(28, 22)
	layer.add_child(heading)
	heading.add_child(_label("L O N G W A L K", 26))
	heading.add_child(_label("THE VILLAGE LANE", 14, Color("e8d4a7")))
	var bar := _panel(Vector2(28, 764), layer)
	var rows := VBoxContainer.new()
	bar.add_child(rows)
	rows.add_child(_label("Left-click: walk   ·   WASD / edges: pan   ·   Q/E: rotate   ·   -/=: zoom", 15))
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	rows.add_child(actions)
	for i in range(3):
		_button("Home %d" % (i + 1), _visit_home.bind(i), actions)
	_button("Center traveler", _center_traveler, actions)
	_button("Reset view", _reset_view, actions)
	_button("Camera controls", func(): camera_controls.visible = not camera_controls.visible, actions)
	_button("Quit", func(): get_tree().quit(), actions)
	camera_controls = _panel(Vector2(28, 285), layer)
	camera_controls.visible = false
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	camera_controls.add_child(box)
	box.add_child(_label("Camera", 20))
	var turns := HBoxContainer.new()
	box.add_child(turns)
	_button("↶ 45°", func(): _rotate(-45), turns)
	_button("45° ↷", func(): _rotate(45), turns)
	lock_button = CheckButton.new()
	lock_button.text = "Hold this angle"
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
	var edge := CheckButton.new()
	edge.text = "Pan at screen edges"
	edge.button_pressed = true
	edge.toggled.connect(func(value): edge_enabled = value)
	box.add_child(edge)
	box.add_child(_label("Pan speed (WASD and edges)", 14))
	var speed := HSlider.new()
	speed.min_value = 2
	speed.max_value = 14
	speed.value = edge_speed
	speed.value_changed.connect(func(value): edge_speed = value)
	box.add_child(speed)
	box.add_child(_label("View angle", 14))
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
	zoom_slider.max_value = 42
	zoom_slider.value = 28
	zoom_slider.value_changed.connect(func(value): camera.size = value)
	box.add_child(zoom_slider)
	angle_label = _label("", 13, Color("d9c38b"))
	box.add_child(angle_label)
	status_label = _label("Three homes, one lane. Scroll to zoom in.", 14)
	status_label.position = Vector2(28, 866)
	layer.add_child(status_label)


func _check(condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
	return condition


func _capture_study(path: String) -> void:
	var passed := true
	DirAccess.make_dir_recursive_absolute(path)
	await get_tree().create_timer(0.7).timeout
	for angle in [45.0, 135.0, 225.0, 315.0]:
		yaw = angle
		target_yaw = angle
		await get_tree().create_timer(0.3).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(path.path_join("lane-view-%d.png" % angle))
	for target in [Vector3(-8, 0, 0), Vector3(3, 0, 0), Vector3(10, 0, 3)]:
		passed = _check(_walk_to(target), "Each door approach must be reachable") and passed
		for point in route:
			for rect in footprint_rects:
				passed = _check(not rect.has_point(Vector2(point.x, point.z)), "Route enters a prop") and passed
		await get_tree().create_timer(0.5).timeout
		passed = _check(animation.current_animation == walk_clip, "Walk must select real walk clip") and passed
	route.clear()
	avatar.position = Vector3(0, 0, 2)
	avatar.rotation.y = 0
	_center_traveler()
	elevation_slider.value = 5
	zoom_slider.value = 4.5
	yaw = 0
	target_yaw = 0
	await get_tree().create_timer(1.0).timeout
	passed = _check(animation.current_animation == idle_clip and animation.is_playing(), "Idle must play continuously") and passed
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path.path_join("character-idle.png"))
	var hand_index := skeleton.find_bone("LeftHand")
	var elbow_index := skeleton.find_bone("LeftForeArm")
	if hand_index >= 0 and elbow_index >= 0:
		passed = _check(skeleton.get_bone_global_pose(hand_index).origin.y < skeleton.get_bone_global_pose(elbow_index).origin.y, "Idle hand should be below elbow") and passed
	passed = _check(_walk_to(Vector3(0, 0, 7)), "Motion sample must be reachable") and passed
	for frame in range(6):
		_center_traveler()
		await get_tree().create_timer(0.15).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(path.path_join("character-walk-%d.png" % frame))
	passed = _check(travel > 0.5, "Traveler must move") and passed
	passed = _check(_edge_direction(Vector2(1, 400), Vector2(1280, 800)).x < -0.9, "Left edge must pan") and passed
	passed = _check(_edge_direction(Vector2(640, 400), Vector2(1280, 800)) == Vector2.ZERO, "Center must not pan") and passed
	var previous := focus
	_center_traveler()
	passed = _check(focus == previous and focus_target != previous, "Center must glide") and passed
	# Exercise keyboard input through the same Godot input state as live keys.
	var key := InputEventKey.new()
	key.physical_keycode = KEY_W
	key.pressed = true
	Input.parse_input_event(key)
	Input.flush_buffered_events()
	var before := focus_target
	yaw = 45
	pan_velocity = Vector3.ZERO
	_apply_pan_input(_keyboard_pan_direction(), 0.1)
	passed = _check(focus_target.x < before.x and focus_target.z < before.z, "W must pan forward relative to the rotated view") and passed
	key.pressed = false
	Input.parse_input_event(key)
	Input.flush_buffered_events()
	passed = _check(_keyboard_pan_direction() == Vector2.ZERO, "Released key must stop driving pan") and passed
	var zoom_before := zoom_slider.value
	key.physical_keycode = KEY_EQUAL
	key.pressed = true
	_unhandled_input(key)
	passed = _check(zoom_slider.value < zoom_before, "Equals must zoom in") and passed
	key.physical_keycode = KEY_MINUS
	_unhandled_input(key)
	passed = _check(zoom_slider.value == zoom_before, "Minus must zoom out") and passed
	if passed:
		print("LANE CHECKS PASSED: keyboard pan/zoom,  four views, three door approaches, real idle/walk clips, movement, edge pan, smooth center")
	get_tree().quit(0 if passed else 1)
