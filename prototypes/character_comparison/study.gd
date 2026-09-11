extends Node3D

# Standalone visual comparison. This does not alter the village or simulation.
const IDLE_PATH := "res://assets/player_idle.glb"
const WALK_PATH := "res://assets/player_walk.glb"
const IDLE_ORDER := [1, 3, 2, 4]
var camera: Camera3D
var model_root: Node3D
var stage: Node3D
var sprite: Sprite3D
var sprite_shadow: MeshInstance3D
var animation: AnimationPlayer
var idle_frames: Array[Texture2D] = []
var walk_frames: Array[Texture2D] = []
var idle_contract: Dictionary
var walk_contract: Dictionary
var yaw := 45.0
var elevation := 35.264
var walking := false
var walk_time := 0.0
var zoom: HSlider
var walk_button: CheckButton
var status: Label
var left_label: Label
var right_label: Label
var capture_mode := false

func _ready() -> void:
	idle_contract = JSON.parse_string(FileAccess.get_file_as_string("res://art/idle/godot-sprite3d.json"))
	for i in range(1, 5):
		idle_frames.append(load("res://art/idle/idle-%d.png" % i))
	# Walk drafts failed visual review and are excluded from this idle study.
	_build_world()
	_build_ui()
	_update_view()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):
			capture_mode = true
			_capture(arg.trim_prefix("--capture-dir="))

func _material(color: Color, texture: Texture2D = null) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.albedo_texture = texture
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
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
	add_child(sun)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(100,100)
	ground.mesh = plane
	var grass := _material(Color("65734e"),load("res://art/grass.png"))
	grass.metallic_specular=0.05
	grass.uv1_scale = Vector3(32,32,1)
	ground.material_override = grass
	add_child(ground)
	stage = Node3D.new()
	add_child(stage)
	var path := MeshInstance3D.new()
	var path_mesh := PlaneMesh.new()
	path_mesh.size = Vector2(40,5)
	path.mesh = path_mesh
	path.position.y = 0.012
	var dirt := _material(Color("a89879"),load("res://art/dirt.png"))
	dirt.metallic_specular=0.05
	dirt.uv1_scale = Vector3(12,2,1)
	path.material_override = dirt
	stage.add_child(path)
	_add_building("res://assets/inn.glb",Vector3(-7,0,-11),8.5)
	_add_building("res://assets/farmhouse.glb",Vector3(7,0,-10),5.2)
	model_root = Node3D.new()
	add_child(model_root)
	var model: Node3D = load(IDLE_PATH).instantiate()
	model_root.add_child(model)
	for mesh in model.find_children("*", "MeshInstance3D", true, false):
		for index in range(mesh.mesh.get_surface_count()):
			var mat = mesh.get_active_material(index).duplicate()
			if mat is StandardMaterial3D:
				mat.emission_enabled = false
				mat.metallic = 0
				mat.roughness = 0.95
				mesh.set_surface_override_material(index,mat)
	animation = _animation(model)
	var library := AnimationLibrary.new()
	for spec in [["idle",IDLE_PATH],["walk",WALK_PATH]]:
		var source: Node3D = load(spec[1]).instantiate()
		var source_player := _animation(source)
		for clip_name in source_player.get_animation_list():
			if clip_name == "RESET": continue
			var clip := source_player.get_animation(clip_name).duplicate() as Animation
			clip.loop_mode = Animation.LOOP_LINEAR
			for track in range(clip.get_track_count()):
				if clip.track_get_type(track) == Animation.TYPE_POSITION_3D and str(clip.track_get_path(track)).ends_with(":Hips"):
					for key in range(clip.track_get_key_count(track)):
						var value: Vector3 = clip.track_get_key_value(track,key)
						value.x=0
						value.z=0
						clip.track_set_key_value(track,key,value)
			library.add_animation(spec[0],clip)
			break
		source.free()
	animation.add_animation_library("compare",library)
	animation.play("compare/idle")
	animation.advance(0)
	# Preserve the existing 1.75m rig units. Mesh AABB is the unskinned bind
	# geometry and cannot measure this animated model's rendered height.
	sprite = Sprite3D.new()
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.no_depth_test = false
	sprite.shaded = false
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.alpha_scissor_threshold = 0.15
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(sprite)
	var shadow_mesh := CylinderMesh.new()
	shadow_mesh.top_radius=0.22
	shadow_mesh.bottom_radius=0.22
	shadow_mesh.height=0.002
	sprite_shadow = MeshInstance3D.new()
	sprite_shadow.mesh=shadow_mesh
	var shadow_material := _material(Color(0.09,0.10,0.075,0.22))
	shadow_material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	sprite_shadow.material_override=shadow_material
	sprite_shadow.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(sprite_shadow)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 18
	add_child(camera)
	camera.make_current()

func _bounds(node: Node3D, parent_transform: Transform3D) -> AABB:
	var transform := parent_transform * node.transform
	var result := AABB()
	var found := false
	if node is MeshInstance3D:
		result = transform * node.get_aabb()
		found = true
	for child in node.get_children():
		if child is Node3D:
			var child_bounds := _bounds(child,transform)
			if child_bounds.size != Vector3.ZERO:
				result = result.merge(child_bounds) if found else child_bounds
				found = true
	return result

func _animation(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer: return node
	for child in node.get_children():
		var found := _animation(child)
		if found: return found
	return null

func _add_building(path: String, position_value: Vector3, height: float) -> void:
	var model: Node3D = load(path).instantiate()
	var bounds := _bounds(model,Transform3D.IDENTITY)
	var scale_factor := height / bounds.size.y
	model.scale *= scale_factor
	model.position = position_value-Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)*scale_factor
	stage.add_child(model)

func _process(delta: float) -> void:
	if walking: walk_time += delta
	_update_view()

func _update_view() -> void:
	var a := deg_to_rad(yaw)
	var e := deg_to_rad(elevation)
	var right := Vector3(cos(a),0,-sin(a))
	var gap := clampf(camera.size*0.25,2.0,4.5)
	model_root.position = -right*gap*0.5
	sprite.position = right*gap*0.5
	sprite_shadow.position = sprite.position+Vector3(0,0.018,0)
	stage.rotation.y = a
	var focus := Vector3(0,0.85,0)
	camera.position = focus+Vector3(sin(a)*cos(e),sin(e),cos(a)*cos(e))*40
	camera.look_at(focus)
	var contract := walk_contract if walking else idle_contract
	sprite.pixel_size = float(contract.get("recommended_pixel_size",0.023255813953488372))
	var offset: Array = contract.get("sprite3d_offset",[0,39])
	sprite.offset = Vector2(offset[0],offset[1])
	if walking:
		var fps := float(walk_contract.get("fps",5.0))
		sprite.texture = walk_frames[int(walk_time*fps)%walk_frames.size()]
	else:
		var quadrant := int(floor(fposmod(yaw,360.0)/90.0))
		sprite.texture = idle_frames[IDLE_ORDER[quadrant]-1]
	if left_label:
		left_label.position=camera.unproject_position(model_root.position+Vector3(0,2.95,0))-Vector2(90,0)
		right_label.position=camera.unproject_position(sprite.position+Vector3(0,2.95,0))-Vector2(90,0)
		status.text="%d° yaw  |  %.1f° camera elevation  |  Both 1.75m nominal height" % [int(yaw),elevation]

func _preset(size_value: float, angle: float) -> void:
	zoom.value=size_value
	elevation=35.264 if walking else angle

func _rotate(amount: float) -> void:
	if walking: return
	yaw=fposmod(yaw+amount,360)

func _set_walk(value: bool) -> void:
	walking=value and walk_frames.size()==4
	walk_time=0
	walk_button.set_pressed_no_signal(walking)
	if walking:
		yaw=45
		elevation=35.264
	animation.play("compare/walk" if walking else "compare/idle",0.2)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.physical_keycode:
			KEY_Q: _rotate(-45)
			KEY_E: _rotate(45)
			KEY_MINUS: zoom.value+=1
			KEY_EQUAL: zoom.value-=1
			KEY_ESCAPE: get_tree().quit()
	if event is InputEventMouseButton and event.pressed:
		if event.button_index==MOUSE_BUTTON_WHEEL_UP: zoom.value-=1
		if event.button_index==MOUSE_BUTTON_WHEEL_DOWN: zoom.value+=1

func _label(text_value: String, size_value: int) -> Label:
	var label := Label.new()
	label.text=text_value
	label.add_theme_font_size_override("font_size",size_value)
	label.add_theme_color_override("font_color",Color("eee5d0"))
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return label

func _button(text_value: String, callback: Callable, parent: Node) -> void:
	var button := Button.new()
	button.text=text_value
	button.focus_mode=Control.FOCUS_NONE
	button.custom_minimum_size.y=38
	button.pressed.connect(callback)
	parent.add_child(button)

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var heading_back := ColorRect.new()
	heading_back.position=Vector2(12,12)
	heading_back.size=Vector2(1240,80)
	heading_back.color=Color(0.07,0.11,0.08,0.88)
	heading_back.mouse_filter=Control.MOUSE_FILTER_IGNORE
	layer.add_child(heading_back)
	var title := _label("L O N G W A L K   /   CHARACTER STUDY",24)
	title.position=Vector2(28,22)
	layer.add_child(title)
	var note := _label("Same scene, two character approaches. The sprite has painted lighting and a small contact shadow.",16)
	note.position=Vector2(28,60)
	layer.add_child(note)
	left_label=_label("Current 3D",19)
	right_label=_label("Classic sprite",19)
	for label in [left_label,right_label]:
		label.custom_minimum_size.x=180
		label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_shadow_color",Color("18221c"))
		label.add_theme_constant_override("shadow_offset_x",2)
		label.add_theme_constant_override("shadow_offset_y",2)
		layer.add_child(label)
	var panel := PanelContainer.new()
	panel.position=Vector2(28,744)
	var style := StyleBoxFlat.new()
	style.bg_color=Color("1d2922")
	style.set_corner_radius_all(8)
	style.content_margin_left=14
	style.content_margin_right=14
	style.content_margin_top=10
	style.content_margin_bottom=10
	panel.add_theme_stylebox_override("panel",style)
	layer.add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	var row := HBoxContainer.new()
	box.add_child(row)
	_button("Game view",_preset.bind(18,35.264),row)
	_button("Close-up",_preset.bind(6,35.264),row)
	_button("Low angle",_preset.bind(6,10),row)
	_button("Q  Rotate left",_rotate.bind(-45),row)
	_button("E  Rotate right",_rotate.bind(45),row)
	walk_button=CheckButton.new()
	walk_button.text="Walk study pending"
	walk_button.disabled=walk_frames.size()!=4
	walk_button.focus_mode=Control.FOCUS_NONE
	walk_button.toggled.connect(_set_walk)
	row.add_child(walk_button)
	_button("Quit",get_tree().quit,row)
	zoom=HSlider.new()
	zoom.min_value=4
	zoom.max_value=24
	zoom.value=18
	zoom.custom_minimum_size.x=950
	zoom.focus_mode=Control.FOCUS_NONE
	zoom.value_changed.connect(func(value): camera.size=value)
	box.add_child(zoom)
	box.add_child(_label("Sprite: four views painted at 35°. Its billboard height does not foreshorten with camera elevation.",14))
	status=_label("",14)
	box.add_child(status)

func _capture(path: String) -> void:
	DirAccess.make_dir_recursive_absolute(path)
	var passed := idle_frames.size()==4 and animation.has_animation("compare/idle") and animation.has_animation("compare/walk")
	passed = passed and absf(float(idle_contract["reference_subject_height_px"])*float(idle_contract["recommended_pixel_size"])-1.75)<0.001
	await get_tree().create_timer(0.5).timeout
	for spec in [["normal",18,35.264,45],["close",6,35.264,45],["low",6,10,45],["back",6,35.264,225],["facing-135",6,35.264,135],["facing-315",6,35.264,315]]:
		yaw=spec[3]
		_preset(spec[1],spec[2])
		await get_tree().create_timer(0.15).timeout
		passed = passed and sprite.texture == idle_frames[IDLE_ORDER[int(yaw/90)]-1]
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(path.path_join(spec[0]+".png"))
	if walk_frames.size()==4:
		_set_walk(true)
		_rotate(45)
		passed = passed and yaw==45 and elevation==35.264
		_preset(6,35.264)
		for i in range(4):
			walk_time=float(i)/float(walk_contract.get("fps",5.0))
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(path.path_join("walk-%d.png"%i))
	if passed:
		print("CHARACTER COMPARISON CHECKS PASSED: facing mapping, 1.75m sprite contract, real animation clips; walk frames: ",walk_frames.size())
	else:
		push_error("Character comparison check failed")
	get_tree().quit(0 if passed else 1)
