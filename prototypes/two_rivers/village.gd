extends Node3D

# Disposable presentation experiment. No shared-world simulation lives here.
const ART = {
  "inn": preload("res://assets/inn.glb"),
 "hall": preload("res://assets/hall.glb"),
 "farmhouse": preload("res://assets/farmhouse.glb"),
 "barn": preload("res://assets/barn.glb"),
 "market": preload("res://assets/market.glb"),
 "oak": preload("res://assets/oak.glb"),
 "bridge": preload("res://assets/bridge.glb"),
 "well": preload("res://assets/well.glb"),
 "cottage_wide": preload("res://assets/cottage-wide.glb"),
 "cottage": preload("res://assets/cottage.glb"),
 "tree": preload("res://assets/tree-v2.glb"),
 "fence": preload("res://assets/fence.glb"),
 "shrub": preload("res://assets/shrub.glb"),
 "firewood": preload("res://assets/firewood.glb"),
}
const Walker = preload("res://assets/player_walk.glb")
const LAND = preload("res://src/sim/landscape.gd")
const AREA := 512.0
const CELL := 1.0
var camera: Camera3D
var avatar: Node3D
var animation: AnimationPlayer
var walk_clip := "motion/walk"
var idle_clip := "motion/idle"
var run_clip := "motion/run"
var running := false
var follow_traveler := true
var follow_button: CheckButton
var map_view: Control
var landmarks := []
var tree_count := 0
var building_count := 0
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
	env.ambient_light_energy = 0.65
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment = env
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -35, 0)
	sun.light_color = Color("fff0ce")
	sun.light_energy = 0.7
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 240
	add_child(sun)
	add_child(preload("res://terrain.gd").new())
	arranged = Node3D.new()
	add_child(arranged)
	_build_arrangement()
	avatar = Node3D.new()
	add_child(avatar)
	avatar.position = Vector3(0, 0, 9)
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
	for spec in [["walk", "res://assets/player_walk.glb"], ["idle", "res://assets/player_idle.glb"], ["run", "res://assets/player_run.glb"]]:
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
	camera.size = 48.0
	camera.far = 1800
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


func _building(key: String, pos: Vector3, height: float, angle := 0.0) -> void:
	_add_prop(key, pos, height, angle, true)
	building_count += 1
	for offset in [Vector3(-3.6,0,3.9), Vector3(3.2,0,3.9)]:
		_add_prop("shrub", pos + offset.rotated(Vector3.UP,deg_to_rad(angle)), 0.65, angle)
	_add_prop("firewood",pos+Vector3(7 if key=="inn" else 5,0,-2).rotated(Vector3.UP,deg_to_rad(angle)),0.9,angle)
	if key in ["farmhouse","cottage","cottage_wide"]:
		for x in [-4.5,-2.7,-0.9,0.9,2.7,4.5]:
			_add_prop("fence",pos+Vector3(x,0,-6).rotated(Vector3.UP,deg_to_rad(angle)),1.05,angle,true)
		for z in [-4.8,-3.0,-1.2]:
			_add_prop("shrub",pos+Vector3(-5.2,0,z).rotated(Vector3.UP,deg_to_rad(angle)),0.85,angle)


func _build_arrangement() -> void:
	# Authored settlement: mixed rooflines around an open square and winding lanes.
	for spec in [
		["inn",Vector3(-16,0,-12),8.5,0.0],
		["hall",Vector3(13,0,-15),7.0,0.0],
		["farmhouse",Vector3(-26,0,22),5.2,130.0],
		["cottage",Vector3(23,0,26),6.0,180.0],
		["farmhouse",Vector3(-40,0,-7),5.3,10.0],
		["farmhouse",Vector3(-35,0,-30),4.8,85.0],
		["cottage_wide",Vector3(36,0,-9),5.5,10.0],
		["farmhouse",Vector3(52,0,29),5.5,185.0],
		["farmhouse",Vector3(-17,0,47),4.8,90.0],
		["cottage",Vector3(16,0,56),5.6,-85.0],
		["farmhouse",Vector3(-120,0,-83),5.0,0.0],
		["barn",Vector3(-102,0,-83),6.0,0.0],
		["farmhouse",Vector3(-78,0,145),5.3,180.0],
		["barn",Vector3(-58,0,148),6.5,180.0],
		["farmhouse",Vector3(157,0,124),5.4,180.0],
		["barn",Vector3(180,0,126),6.5,180.0],
		["farmhouse",Vector3(148,0,-216),5.0,0.0],
		["barn",Vector3(170,0,-220),6.0,0.0],
		["farmhouse",Vector3(-221,0,246),5.0,180.0]
	]:
		_building(spec[0],spec[1],spec[2],spec[3])
	for spec in [Vector3(-7,0,-2),Vector3(7,0,-3),Vector3(12,0,4)]:
		_add_prop("market",spec,2.6,0,true)
	_add_prop("well",Vector3(-5,0,6),2.8,0,true)
	for z in LAND.BRIDGES:
		_bridge(Vector3(LAND.river_x(z),0,z),false)
	_bridge(Vector3(0,0,LAND.tributary_z(0)),true)
	# Farm borders have deliberately open gateways at the lane ends.
	for field in LAND.FARMS:
		for x in range(int(field.position.x),int(field.end.x),2):
			_add_prop("shrub",Vector3(x,0,field.position.y-1),0.8,90)
			_add_prop("shrub",Vector3(x+1,0,field.end.y+1),0.7,90)
		for z in range(int(field.position.y)+5,int(field.end.y)-5,2):
			_add_prop("fence",Vector3(field.position.x-1,0,z),1.1,90)
			_add_prop("fence",Vector3(field.end.x+1,0,z),1.1,90)
	# Irregular low planting stitches the banks into their surrounding meadow.
	for z in range(-480,481,6):
		if absf(z-15)<16 or absf(z+175)<16 or absf(z-245)<16: continue
		for side in [-1,1]:
			var h:float=LAND.hash_cell(side,z,37)
			if h<0.3: continue
			_add_prop("shrub",Vector3(LAND.river_x(z)+side*(9+h*4),0,z),0.5+h*0.7,h*360)
	for z in [-65,-35,58,90,130]:
		_tree(Vector3(LAND.river_x(z)-15,0,z),8.2,z*5)
	# Small garden beds and a local orchard give the village a productive edge.
	for x in [-38,-35,-32,-29]:
		for z in [31,34,37,40]:
			_add_prop("shrub",Vector3(x,0,z),0.38,0)
	for x in [32,43,54]:
		for z in [52,63,74]:
			_tree(Vector3(x,0,z),5.5,20)
	for spec in [Vector3(-12,0,27),Vector3(30,0,-28),Vector3(-42,0,14),Vector3(65,0,-7),Vector3(-26,0,66),Vector3(111,0,30)]:
		_tree(spec,8.5,35)
	# Trees depend only on authored cell coordinates, never generation order.
	for z in range(-490,491,20):
		for x in range(-490,491,20):
			var h:float=LAND.hash_cell(x,z,7)
			var pos:=Vector2(x+(h-0.5)*10,z+(LAND.hash_cell(x,z,9)-0.5)*10)
			var radius:=pos.length()
			if radius < 90 or (radius < 215 and h < 0.84) or (radius >= 215 and h < 0.2):
				continue
			if LAND.road_distance(pos)<9 or LAND.water(pos) or absf(pos.x-LAND.river_x(pos.y))<12:
				continue
			var occupied:=false
			for field in LAND.FARMS:
				if field.grow(8).has_point(pos): occupied=true
			for rect in footprint_rects:
				if rect.grow(4).has_point(pos): occupied=true
			if not occupied: _tree(Vector3(pos.x,0,pos.y),8+h*5,h*360)
	landmarks=[
		["Village",Vector3(0,1.2,5),48.0],
		["West farms",Vector3(-123,1.2,-30),105.0],
		["Stone bridge",Vector3(LAND.river_x(15),1.2,15),48.0],
		["East farms",Vector3(170,1.2,75),110.0],
		["North crossing",Vector3(55,1.2,-175),160.0]]


func _tree(pos: Vector3,height:float,angle:float) -> void:
	_add_prop("oak",pos,height,angle)
	footprint_rects.append(Rect2(Vector2(pos.x-0.65,pos.z-0.65),Vector2(1.3,1.3)))
	tree_count+=1


func _bridge(pos:Vector3,small:bool) -> void:
	const PROFILE = preload("res://src/sim/bridge_profile.gd")
	var holder:=_add_prop("bridge",pos,3.2,90 if small else 0)
	var bounds:=_bounds(holder,Transform3D.IDENTITY)
	# The generated bridge spans its local X axis; flatten ends into the bank.
	var length:=bounds.size.z if small else bounds.size.x
	var factor:float=(12.0 if small else 24.0)/length
	holder.scale*=factor
	holder.position.y=PROFILE.SMALL_OFFSET if small else PROFILE.MAIN_OFFSET


func _ground_height(pos:Vector3) -> float:
	const PROFILE = preload("res://src/sim/bridge_profile.gd")
	for z in LAND.BRIDGES:
		if absf(pos.z-z)<3 and absf(pos.x-LAND.river_x(z))<12:
			return PROFILE.deck_height(pos.x-LAND.river_x(z),false)
	if absf(pos.x)<1.5 and absf(pos.z-LAND.tributary_z(0))<6:
		return PROFILE.deck_height(pos.z-LAND.tributary_z(0),true)
	return 0.0


func _visit_home(value: int) -> void:
	pan_velocity=Vector3.ZERO
	_set_follow(false)
	focus_target=landmarks[value][1]
	zoom_slider.value=landmarks[value][2]
	status_label.text=landmarks[value][0]+". Shift-click open ground to run here."


func _set_follow(value:bool) -> void:
	follow_traveler=value
	if follow_button: follow_button.set_pressed_no_signal(value)


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
	nav.region=Rect2i(0,0,1024,1024)
	nav.cell_size=Vector2.ONE*CELL
	nav.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	nav.update()
	for z in range(-512,512):
		var center:int=roundi(LAND.river_x(z))
		for x in range(center-8,center+9):
			var p:=Vector2(x,z)
			if LAND.water(p) and not LAND.crossing(p): nav.set_point_solid(_cell(Vector3(x,0,z)))
	for x in range(-512,110):
		var center:int=roundi(LAND.tributary_z(x))
		for z in range(center-5,center+6):
			var p:=Vector2(x,z)
			if LAND.water(p) and not LAND.crossing(p): nav.set_point_solid(_cell(Vector3(x,0,z)))
	for rect in footprint_rects:
		var begin:=Vector2i((rect.position+Vector2.ONE*AREA).ceil())
		var end:=Vector2i((rect.end+Vector2.ONE*AREA).floor())
		var solid:=Rect2i(begin,end-begin+Vector2i.ONE).intersection(nav.region)
		if solid.has_area(): nav.fill_solid_region(solid,true)


func _cell(pos: Vector3) -> Vector2i:
	return Vector2i(roundi((pos.x + AREA) / CELL), roundi((pos.z + AREA) / CELL))


func _walk_to(point: Vector3, run := false) -> bool:
	var end := _cell(point)
	if not nav.is_in_boundsv(end) or nav.is_point_solid(end):
		status_label.text = "Choose open ground beside the buildings."
		return false
	var ids := nav.get_id_path(_cell(avatar.position), end)
	if ids.is_empty():
		return false
	running = run
	route.clear()
	for id in ids:
		var step:=Vector3(id.x * CELL - AREA, 0, id.y * CELL - AREA)
		step.y=_ground_height(step)
		route.append(step)
	marker.position = route.back() + Vector3(0, 0.05, 0)
	marker.visible = true
	status_label.text = "Running to destination." if running else "Walking to destination."
	return true


func _process(delta: float) -> void:
	if follow_traveler and not route.is_empty():
		focus_target=avatar.position+Vector3(0,1.2,0)
	_update_edge_scroll(delta)
	focus = focus.lerp(focus_target, 1.0 - exp(-delta * 6.0))
	if orbit and not fixed:
		target_yaw += delta * 12.0
	yaw = lerpf(yaw, target_yaw, 1.0 - exp(-delta * 12.0))
	_update_camera()
	if not route.is_empty():
		var budget:float=(4.5 if running else 1.8)*delta
		while not route.is_empty() and budget>0:
			var difference:Vector3=route[0]-avatar.position
			var distance:=difference.length()
			if distance<0.001:
				route.pop_front()
				continue
			var step:=minf(budget,distance)
			avatar.position+=difference/distance*step
			travel+=step
			budget-=step
			avatar.rotation.y=lerp_angle(avatar.rotation.y,atan2(difference.x,difference.z),1-exp(-delta*12))
			if step>=distance: route.pop_front()
		var clip:=run_clip if running else walk_clip
		if animation.current_animation != clip:
			animation.play(clip, 0.2)
	else:
		if animation.current_animation != idle_clip:
			animation.play(idle_clip, 0.25)
		marker.visible = false
	angle_label.text = "%03d°  /  %.1f° elevation  /  %s" % [int(fposmod(yaw, 360)), elevation, "FIXED" if fixed else "ORBIT"]


func _update_camera() -> void:
	var a := deg_to_rad(yaw)
	var e := deg_to_rad(elevation)
	camera.position = focus + Vector3(sin(a) * cos(e), sin(e), cos(a) * cos(e)) * maxf(70.0, camera.size * 1.6)
	camera.look_at(focus)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_SPACE:
		_center_traveler()
		get_viewport().set_input_as_handled()
		return
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
				_walk_to(hit,event.shift_pressed)
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
			KEY_ESCAPE: get_tree().quit()


func _rehome_at(screen_position: Vector2) -> void:
	var hit = Plane(Vector3.UP, 0).intersects_ray(
		camera.project_ray_origin(screen_position), camera.project_ray_normal(screen_position))
	if hit == null or absf(hit.x) > AREA or absf(hit.z) > AREA:
		status_label.text = "Right-click within the meadow to center the view."
		return
	_set_follow(false)
	focus_target = Vector3(hit.x, 1.2, hit.z)
	status_label.text = "View centered here. Space returns to the traveler."


func _center_traveler() -> void:
	_set_follow(true)
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
	zoom_slider.value = 48
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
	if direction != Vector2.ZERO: _set_follow(false)
	_apply_pan_input(direction.limit_length(), delta)


func _apply_pan_input(direction: Vector2, delta: float) -> void:
	var right := Vector3(cos(deg_to_rad(yaw)), 0, -sin(deg_to_rad(yaw)))
	var back := Vector3(sin(deg_to_rad(yaw)), 0, cos(deg_to_rad(yaw)))
	var desired := (right * direction.x + back * direction.y) * edge_speed
	pan_velocity = pan_velocity.lerp(desired, 1.0 - exp(-delta * 7.0))
	focus_target += pan_velocity * delta
	focus_target.x = clampf(focus_target.x, -495, 495)
	focus_target.z = clampf(focus_target.z, -495, 495)


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
	heading.add_child(_label("TWO RIVERS  /  1 km²", 14, Color("e8d4a7")))
	var bar := _panel(Vector2(28, 764), layer)
	var rows := VBoxContainer.new()
	bar.add_child(rows)
	rows.add_child(_label("Click: walk   ·   Shift-click: run   ·   WASD: pan   ·   Q/E: rotate   ·   -/=: zoom", 15))
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	rows.add_child(actions)
	for i in range(landmarks.size()):
		_button(landmarks[i][0], _visit_home.bind(i), actions)
	_button("Center traveler", _center_traveler, actions)
	_button("Camera controls", func(): camera_controls.visible = not camera_controls.visible, actions)
	_button("Quit", func(): get_tree().quit(), actions)
	camera_controls = _panel(Vector2(28, 285), layer)
	camera_controls.visible = false
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	camera_controls.add_child(box)
	box.add_child(_label("Camera", 20))
	follow_button=CheckButton.new()
	follow_button.text="Follow traveler"
	follow_button.button_pressed=true
	follow_button.toggled.connect(_set_follow)
	box.add_child(follow_button)
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
	zoom_slider.max_value = 350
	zoom_slider.value = 48
	zoom_slider.value_changed.connect(func(value): camera.size = value)
	box.add_child(zoom_slider)
	angle_label = _label("", 13, Color("d9c38b"))
	box.add_child(angle_label)
	status_label = _label("Explore the square, farms, and crossings. Shift-click to run.", 14)
	status_label.position = Vector2(28, 866)
	layer.add_child(status_label)
	map_view=preload("res://region_map.gd").new()
	map_view.position=Vector2(1188,22)
	map_view.world=self
	layer.add_child(map_view)


func _check(condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
	return condition


func _capture_study(path:String) -> void:
	var passed:=true
	DirAccess.make_dir_recursive_absolute(path)
	_set_follow(false)
	await get_tree().create_timer(0.5).timeout
	for i in range(landmarks.size()):
		_visit_home(i)
		focus=focus_target
		await get_tree().create_timer(0.25).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(path.path_join("place-%d.png"%i))
	for point in [Vector3(-120,0,15),Vector3(150,0,15),Vector3(0,0,-190),Vector3(-50,0,120)]:
		passed=_check(_walk_to(point),"Farm and crossing must be reachable") and passed
		for step in route:
			passed=_check(not LAND.water(Vector2(step.x,step.z)) or LAND.crossing(Vector2(step.x,step.z)),"Route enters water outside bridge") and passed
		route.clear()
	avatar.position=Vector3(0,0,9)
	passed=_check(_walk_to(Vector3(0,0,30),true),"Run target reachable") and passed
	var start:=avatar.position
	await get_tree().create_timer(1).timeout
	passed=_check(avatar.position.distance_to(start)>3,"Shift run must move faster than walking") and passed
	passed=_check(animation.current_animation==run_clip,"Run must use real run animation") and passed
	route.clear()
	avatar.position=Vector3(LAND.river_x(15)-15,0,15)
	passed=_check(_walk_to(Vector3(LAND.river_x(15)+15,0,15),true),"Bridge crossing reachable") and passed
	focus_target=Vector3(LAND.river_x(15),1.2,15)
	focus=focus_target
	zoom_slider.value=32
	await get_tree().create_timer(3.5).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path.path_join("bridge-run.png"))
	route.clear()
	var key:=InputEventKey.new()
	key.physical_keycode=KEY_W
	key.pressed=true
	Input.parse_input_event(key)
	Input.flush_buffered_events()
	passed=_check(_keyboard_pan_direction().y<0,"W pans forward") and passed
	key=key.duplicate()
	key.pressed=false
	Input.parse_input_event(key)
	Input.flush_buffered_events()
	passed=_check(_keyboard_pan_direction()==Vector2.ZERO,"Key release stops driving") and passed
	if passed: print("TWO RIVERS CHECKS PASSED: 1024m map, %d buildings, %d trees, farm routes, bridge-only water crossings, run animation/speed, keyboard pan"%[building_count,tree_count])
	get_tree().quit(0 if passed else 1)
