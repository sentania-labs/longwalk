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
var nav := preload("res://src/sim/travel_grid.gd").new()
var angle_label: Label
var controls_label: Label
var status_label: Label
var lock_button: CheckButton
var orbit_button: CheckButton
var zoom_slider: HSlider
var elevation_slider: HSlider
var marker: MeshInstance3D
var footprint_rects: Array[Rect2] = []
var network: Node
var placed_ids: Array[String] = []
var bake_visuals := ""
var resource_tree: Node3D
var remote_actors := {}
var resource_cut := false
var pick_records := []
var context_panel: PanelContainer
var context_box: VBoxContainer
var context_selection := {}
var context_state := ""
var context_point := Vector2.ZERO
var travel := 0.0
var rotation_speed := 70.0
var inspecting := false
var inspection_position := Vector3.ZERO
var inspection_pitch := 8.0
var overhead_zoom := 48.0
var overhead_elevation := 35.264
var inspection_button: CheckButton
var route_choice: OptionButton
var route_line: MeshInstance3D
var preview_route: Array[Vector3] = []
var preview_target := Vector3.ZERO
var preview_timer := 0.0
var preview_valid := false
var reverse_zoom := false
var binding_action := ""
var binding_buttons := {}
var keyboard_rotating := false
var loading_settings := false
const DEFAULT_KEYS = {"forward":KEY_W,"back":KEY_S,"left":KEY_A,"right":KEY_D,"rotate_left":KEY_Q,"rotate_right":KEY_E,"zoom_in":KEY_MINUS,"zoom_out":KEY_EQUAL,"center":KEY_SPACE,"inspect":KEY_TAB,"reset_view":KEY_R,"fly_up":KEY_PAGEUP,"fly_down":KEY_PAGEDOWN}
var keys: Dictionary = DEFAULT_KEYS.duplicate()
const SETTINGS_PATH = "user://comfort-settings.cfg"



func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="): capture_mode = true
		if arg.begins_with("--bake-visuals="): bake_visuals = arg.trim_prefix("--bake-visuals=")
	process_priority = 100
	_build_world()
	if bake_visuals != "":
		_write_visuals()
		set_process(false)
		get_tree().quit()
		return
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--bake-baseline="):
			var rects := []
			for rect in footprint_rects: rects.append([rect.position.x,rect.position.y,rect.size.x,rect.size.y])
			var data := {"schema":1,"placements":placed_ids,"footprints":rects,"resource":{"id":"square_oak","position":[-12,0,27]}}
			var file := FileAccess.open(arg.trim_prefix("--bake-baseline="),FileAccess.WRITE)
			file.store_string(JSON.stringify(data))
			file.close()
			print("BASELINE BAKED: %d footprints, %d placements" % [rects.size(),placed_ids.size()])
			set_process(false)
			get_tree().quit()
			return
	_build_navigation()
	_build_ui()
	_build_context()
	if not capture_mode: _load_settings()
	_update_camera()
	if network: network.changed.connect(_receive_world)


func _material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.95
	return mat


func _build_world() -> void:
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("799daf")
	sky_material.sky_horizon_color = Color("c5cbb5")
	sky_material.ground_horizon_color = Color("c5cbb5")
	sky_material.ground_bottom_color = Color("495b36")
	var sky := Sky.new()
	sky.sky_material = sky_material
	env.sky = sky
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
	placed_ids.append("%s:%.3f:%.3f:%.3f:%.3f" % [key,pos.x,pos.z,height,angle])
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


func _transform_values(value: Transform3D) -> Array:
	return [value.basis.x.x,value.basis.x.y,value.basis.x.z,value.basis.y.x,value.basis.y.y,value.basis.y.z,value.basis.z.x,value.basis.z.y,value.basis.z.z,value.origin.x,value.origin.y,value.origin.z]


func _read_transform(value: Array) -> Transform3D:
	return Transform3D(Basis(Vector3(value[0],value[1],value[2]),Vector3(value[3],value[4],value[5]),Vector3(value[6],value[7],value[8])),Vector3(value[9],value[10],value[11]))


func _write_visuals() -> void:
	var baseline: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://world/baseline.json"))
	assert(baseline.placements == placed_ids, "Authoring output must match the existing baseline before freezing")
	var records := []
	for i in range(arranged.get_child_count()):
		var holder := arranged.get_child(i) as Node3D
		var models := []
		for model in holder.get_children(): models.append(_transform_values(model.transform))
		records.append({"id":placed_ids[i],"transform":_transform_values(holder.transform),"models":models})
	var file := FileAccess.open(bake_visuals,FileAccess.WRITE)
	file.store_string(JSON.stringify({"schema":1,"baseline":FileAccess.get_sha256("res://world/baseline.json"),"records":records}))
	file.close()
	print("VISUAL PLACEMENTS FROZEN: ",records.size())


func _build_arrangement() -> void:
	if bake_visuals != "":
		_author_arrangement()
		return
	var baseline: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://world/baseline.json"))
	var visuals = JSON.parse_string(FileAccess.get_file_as_string("res://world/visuals.json"))
	var failure: String = preload("res://visual_manifest.gd").validate(visuals,baseline,FileAccess.get_sha256("res://world/baseline.json"),ART.keys())
	if failure != "":
		push_error(failure)
		get_tree().quit(1)
		return
	for record in visuals.records:
		var key: String = record.id.get_slice(":",0)
		var holder := Node3D.new()
		arranged.add_child(holder)
		holder.transform = _read_transform(record.transform)
		for values in record.models:
			var model: Node3D = ART[key].instantiate()
			holder.add_child(model)
			model.transform = _read_transform(values)
		pick_records.append({"id":record.id,"key":key,"node":holder,"bounds":_bounds(holder,Transform3D.IDENTITY)})
		placed_ids.append(record.id)
		if key == "oak": tree_count += 1
		if key in ["inn","hall","farmhouse","barn","cottage","cottage_wide"]: building_count += 1
		if record.id == "oak:-12.000:27.000:8.500:35.000": resource_tree = holder
	_set_landmarks()
	print("FROZEN VISUALS LOADED: ",placed_ids.size()," placements")


func _author_arrangement() -> void:
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
	# Render the same field barriers that the headless router blocks.
	for barrier in LAND.field_barriers():
		var horizontal: bool = barrier.size.x > barrier.size.y
		var length: float = maxf(barrier.size.x, barrier.size.y) - 0.9
		var count := maxi(1, ceili(length / 1.8))
		for i in range(count):
			var center: Vector2 = barrier.get_center()
			var offset := -length * 0.5 + (i + 0.5) * length / count
			if horizontal: center.x += offset
			else: center.y += offset
			var fence := _add_prop("fence", Vector3(center.x,0,center.y), 1.1, 0 if horizontal else 90)
			var bounds := _bounds(fence, Transform3D.IDENTITY)
			var actual := bounds.size.x if horizontal else bounds.size.z
			# Fit each section to its shared barrier, preserving clear gateways.
			fence.scale.x *= (length / count) / actual
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
	_set_landmarks()


func _set_landmarks() -> void:
	landmarks=[
		["Village",Vector3(0,1.2,5),48.0],
		["West farms",Vector3(-123,1.2,-30),105.0],
		["Stone bridge",Vector3(LAND.river_x(15),1.2,15),48.0],
		["East farms",Vector3(170,1.2,75),110.0],
		["North crossing",Vector3(55,1.2,-175),160.0]]


func _tree(pos: Vector3,height:float,angle:float) -> void:
	var tree := _add_prop("oak",pos,height,angle)
	if pos == Vector3(-12,0,27): resource_tree = tree
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
	if inspecting: _set_inspection(false)
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
	var baseline: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://world/baseline.json"))
	if baseline.placements != placed_ids:
		push_error("Rendered placements do not match authored baseline")
		get_tree().quit(1)
		return
	var authoritative: Array[Rect2] = []
	for r in baseline.footprints: authoritative.append(Rect2(r[0],r[1],r[2],r[3]))
	nav.prepare(authoritative)
	route_line = MeshInstance3D.new()
	var mat := _material(Color("e6cf87"))
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	route_line.material_override = mat
	add_child(route_line)


func _cell(pos: Vector3) -> Vector2i:
	return Vector2i(roundi((pos.x + AREA) / CELL), roundi((pos.z + AREA) / CELL))


func _route_to(point: Vector3) -> Array[Vector3]:
	var result: Array[Vector3] = []
	var end := _cell(point)
	var start := _cell(avatar.position)
	if not nav.is_in_boundsv(end) or nav.is_point_solid(end) or not nav.is_in_boundsv(start): return result
	for id in nav.get_id_path(start, end):
		var step := Vector3(id.x - AREA, 0, id.y - AREA)
		step.y = _ground_height(step)
		result.append(step)
	return result


func _walk_to(point: Vector3, run := false) -> bool:
	if not network or not network.connected:
		status_label.text = "Connect to a world before moving the traveler."
		return false
	preview_route = _route_to(point)
	_draw_route(preview_route)
	network.command("move",{"target":[point.x,point.z],"run":run,"prefer":nav.prefer_paths})
	status_label.text = "Movement requested from server."
	return true


func _draw_route(points: Array[Vector3]) -> void:
	var mesh := ImmediateMesh.new()
	if points.size() > 1:
		mesh.surface_begin(Mesh.PRIMITIVE_LINES)
		for i in range(1, points.size()):
			mesh.surface_add_vertex(points[i-1] + Vector3(0,0.08,0))
			mesh.surface_add_vertex(points[i] + Vector3(0,0.08,0))
		mesh.surface_end()
	route_line.mesh = mesh


func _ground_hit(screen: Vector2) -> Variant:
	var hit = Plane(Vector3.UP, 0).intersects_ray(camera.project_ray_origin(screen),camera.project_ray_normal(screen))
	if hit == null or absf(hit.x) >= AREA-1 or absf(hit.z) >= AREA-1: return null
	return hit


func _update_preview(delta: float) -> void:
	preview_timer -= delta
	if capture_mode or dragging or (context_panel and context_panel.visible) or not get_window().has_focus() or preview_timer > 0: return
	preview_timer = 0.3
	if get_viewport().gui_get_hovered_control() != null: return
	var hit = _ground_hit(get_viewport().get_mouse_position())
	if hit == null: return
	if preview_valid and hit.distance_to(preview_target) < 1.0: return
	preview_target = hit
	preview_valid = true
	preview_route = _route_to(hit)
	_draw_route(preview_route)


func _process(delta: float) -> void:
	if follow_traveler and not inspecting and network and network.connected:
		focus_target=avatar.position+Vector3(0,1.2,0)
	_update_keyboard_rotation(delta)
	_update_edge_scroll(delta)
	_update_preview(delta)
	focus = focus.lerp(focus_target, 1.0 - exp(-delta * 6.0))
	if orbit and not fixed and not inspecting:
		target_yaw += delta * 12.0
	if not keyboard_rotating: yaw = lerpf(yaw, target_yaw, 1.0 - exp(-delta * 12.0))
	_update_camera()
	_update_network_actors(delta)
	angle_label.text = "%03d° / %.1f° / %s" % [int(fposmod(yaw,360)), inspection_pitch if inspecting else elevation, "INSPECT" if inspecting else "OVERHEAD"]


func _update_camera() -> void:
	if inspecting:
		camera.projection = Camera3D.PROJECTION_PERSPECTIVE
		camera.position = inspection_position
		camera.rotation = Vector3(-deg_to_rad(inspection_pitch), deg_to_rad(yaw), 0)
		return
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	var a := deg_to_rad(yaw)
	var e := deg_to_rad(elevation)
	camera.position = focus + Vector3(sin(a) * cos(e), sin(e), cos(a) * cos(e)) * maxf(70.0, camera.size * 1.6)
	camera.look_at(focus)


func _input(event: InputEvent) -> void:
	if context_panel and context_panel.visible:
		if event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
			context_panel.hide()
			get_viewport().set_input_as_handled()
			return
		if event is InputEventMouseButton and event.pressed and not context_panel.get_global_rect().has_point(event.position):
			context_panel.hide()
			get_viewport().set_input_as_handled()
			return
	if event is InputEventKey and event.pressed and not event.echo:
		if binding_action != "":
			if event.physical_keycode == KEY_ESCAPE:
				binding_action = ""
				_refresh_bindings()
			elif event.physical_keycode in [KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META]:
				status_label.text = "Choose a key without a modifier. Shift remains Run."
			elif event.physical_keycode in keys.values():
				status_label.text = "That key is already assigned. Choose another, or Escape to cancel."
			else:
				keys[binding_action] = event.physical_keycode
				binding_action = ""
				_refresh_bindings()
				_save_settings()
			get_viewport().set_input_as_handled()
			return
		if event.physical_keycode == keys.center:
			_center_traveler()
			get_viewport().set_input_as_handled()
		elif event.physical_keycode == keys.inspect:
			_set_inspection(not inspecting)
			get_viewport().set_input_as_handled()
		elif event.physical_keycode == keys.reset_view:
			_reset_view()
			get_viewport().set_input_as_handled()
		elif event.physical_keycode == KEY_ESCAPE:
			if inspecting: _set_inspection(false)
			elif camera_controls.visible: camera_controls.hide()
			else: get_tree().quit()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed and dragging:
		dragging = false
		if drag_distance < 5 and get_viewport().gui_get_hovered_control() == null: _open_context(event.position)
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			dragging = event.pressed
			drag_distance = 0
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP: _zoom_by(-1)
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN: _zoom_by(1)
		elif event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var hit = _ground_hit(event.position)
			if hit != null: _walk_to(hit, event.shift_pressed)
	elif event is InputEventMouseMotion and dragging:
		drag_distance += event.relative.length()
		if drag_distance >= 5 and not fixed:
			target_yaw -= event.relative.x * 0.3
			elevation_slider.value += event.relative.y * 0.2


func _pressed(action: String) -> bool:
	return binding_action == "" and Input.is_physical_key_pressed(keys[action])


func _update_keyboard_rotation(delta: float) -> void:
	keyboard_rotating = false
	if capture_mode or not get_window().has_focus() or binding_action != "": return
	var turn := float(_pressed("rotate_right")) - float(_pressed("rotate_left"))
	if turn != 0 and not fixed:
		target_yaw = yaw + turn * rotation_speed * delta
		yaw = target_yaw
		keyboard_rotating = true
	var zoom := float(_pressed("zoom_out")) - float(_pressed("zoom_in"))
	if zoom != 0: _zoom_by(zoom * delta * 25 * (-1 if reverse_zoom else 1))


func _zoom_by(amount: float) -> void:
	zoom_slider.value += amount


func _set_inspection(value: bool) -> void:
	if value == inspecting: return
	if value:
		overhead_zoom = camera.size
		overhead_elevation = elevation
	inspecting = value
	inspection_button.set_pressed_no_signal(value)
	pan_velocity = Vector3.ZERO
	_set_follow(false)
	orbit_button.button_pressed = false
	if value:
		var start := focus + Vector3(sin(deg_to_rad(yaw)),0,cos(deg_to_rad(yaw))) * 4
		inspection_position = start
		inspection_position.y = _ground_height(start) + 1.7
		elevation_slider.min_value = -75
		elevation_slider.max_value = 80
		elevation_slider.value = 8
		inspection_pitch = 8
		zoom_slider.min_value = 30
		zoom_slider.max_value = 90
		zoom_slider.value = 65
		camera.fov = 65
		status_label.text = "Free flight: WASD moves, PgUp/PgDn changes height, right-drag looks. Tab overhead; Space traveler."
	else:
		elevation_slider.min_value = 1
		elevation_slider.max_value = 60
		elevation_slider.value = overhead_elevation
		zoom_slider.min_value = 3
		zoom_slider.max_value = 350
		zoom_slider.value = overhead_zoom
		focus_target = Vector3(inspection_position.x,1.2,inspection_position.z)
		focus = focus_target
		status_label.text = "Overhead view."
	_update_camera()


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
	if inspecting: _set_inspection(false)
	_set_follow(true)
	pan_velocity = Vector3.ZERO
	focus_target = avatar.position + Vector3(0, 1.2, 0)
	status_label.text = "Centered on the traveler."


func _rotate(degrees: float) -> void:
	if not fixed:
		target_yaw += degrees


func _reset_view() -> void:
	if inspecting: _set_inspection(false)
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
		float(_pressed("right")) - float(_pressed("left")),
		float(_pressed("back")) - float(_pressed("forward"))
	).limit_length()


func _update_edge_scroll(delta: float) -> void:
	var direction := Vector2.ZERO
	var focused := get_viewport().gui_get_focus_owner()
	var editing_text := focused is LineEdit or focused is TextEdit
	if not capture_mode and get_window().has_focus() and not editing_text:
		direction = _keyboard_pan_direction()
	if edge_enabled and not inspecting and not capture_mode and not dragging and get_window().has_focus() and get_viewport().gui_get_hovered_control() == null:
		direction += _edge_direction(get_viewport().get_mouse_position(), get_viewport().get_visible_rect().size)
	if direction != Vector2.ZERO: _set_follow(false)
	_apply_pan_input(direction.limit_length(), delta)


func _apply_pan_input(direction: Vector2, delta: float) -> void:
	var right := Vector3(cos(deg_to_rad(yaw)), 0, -sin(deg_to_rad(yaw)))
	var back := Vector3(sin(deg_to_rad(yaw)), 0, cos(deg_to_rad(yaw)))
	var desired := (right * direction.x + back * direction.y) * edge_speed
	pan_velocity = pan_velocity.lerp(desired, 1.0 - exp(-delta * 7.0))
	if inspecting:
		# Inspection is a free camera, independent of character navigation.
		var forward := -camera.global_basis.z
		inspection_position += (camera.global_basis.x * direction.x - forward * direction.y) * edge_speed * delta
		var vertical := float(_pressed("fly_up"))-float(_pressed("fly_down"))
		inspection_position.y += vertical*edge_speed*delta
		inspection_position.x = clampf(inspection_position.x,-510,510)
		inspection_position.z = clampf(inspection_position.z,-510,510)
		inspection_position.y = clampf(inspection_position.y,0.3,250)
		focus = Vector3(inspection_position.x,1.2,inspection_position.z)
		focus_target = focus
		return
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
	heading.add_child(_label("SHARED VILLAGE 03  /  1 km²", 14, Color("e8d4a7")))
	var bar := _panel(Vector2(28, 708), layer)
	var rows := VBoxContainer.new()
	bar.add_child(rows)
	controls_label = _label("", 15)
	rows.add_child(controls_label)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	rows.add_child(actions)
	for i in range(landmarks.size()):
		_button(landmarks[i][0], _visit_home.bind(i), actions)
	_button("Center traveler", _center_traveler, actions)
	_button("Camera controls", func(): camera_controls.visible = not camera_controls.visible, actions)
	_button("Quit", func(): get_tree().quit(), actions)
	var travel_controls := HBoxContainer.new()
	rows.add_child(travel_controls)
	travel_controls.add_child(_label("Route preview:",14))
	route_choice = OptionButton.new()
	route_choice.add_item("Prefer paths")
	route_choice.add_item("Direct route")
	route_choice.item_selected.connect(func(index):
		nav.prefer_paths = index == 0
		preview_valid = false
		_save_settings()
	)
	travel_controls.add_child(route_choice)
	inspection_button = CheckButton.new()
	inspection_button.text = "Inspect at ground level"
	inspection_button.toggled.connect(_set_inspection)
	travel_controls.add_child(inspection_button)
	camera_controls = _panel(Vector2(28, 140), layer)
	camera_controls.visible = false
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(460, 530)
	camera_controls.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 7)
	scroll.add_child(box)
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
	edge.toggled.connect(func(value): edge_enabled = value; _save_settings())
	edge.name = "EdgePan"
	box.add_child(edge)
	box.add_child(_label("Pan speed (WASD and edges)", 14))
	var speed := HSlider.new()
	speed.min_value = 2
	speed.max_value = 14
	speed.value = edge_speed
	speed.value_changed.connect(func(value): edge_speed = value; _save_settings())
	speed.name = "PanSpeed"
	box.add_child(speed)
	box.add_child(_label("Rotation speed (degrees/sec)",14))
	var turn_speed := HSlider.new()
	turn_speed.name = "TurnSpeed"
	turn_speed.min_value = 10
	turn_speed.max_value = 180
	turn_speed.value = rotation_speed
	turn_speed.value_changed.connect(func(value): rotation_speed = value; _save_settings())
	box.add_child(turn_speed)
	var reverse := CheckButton.new()
	reverse.name = "ReverseZoom"
	reverse.text = "Reverse keyboard zoom"
	reverse.toggled.connect(func(value): reverse_zoom = value; _refresh_bindings(); _save_settings())
	box.add_child(reverse)
	box.add_child(_label("View angle", 14))
	elevation_slider = HSlider.new()
	elevation_slider.min_value = 1
	elevation_slider.max_value = 60
	elevation_slider.step = 0.001
	elevation_slider.value = elevation
	elevation_slider.value_changed.connect(func(value):
		if inspecting: inspection_pitch = value
		else: elevation = value
	)
	box.add_child(elevation_slider)
	box.add_child(_label("Zoom", 14))
	zoom_slider = HSlider.new()
	zoom_slider.step = 0.01
	zoom_slider.min_value = 3
	zoom_slider.max_value = 350
	zoom_slider.value = 48
	zoom_slider.value_changed.connect(func(value):
		if inspecting: camera.fov = value
		else: camera.size = value
	)
	box.add_child(zoom_slider)
	angle_label = _label("", 13, Color("d9c38b"))
	box.add_child(angle_label)
	box.add_child(_label("Keyboard bindings (click, then press a key)",14))
	for action in DEFAULT_KEYS:
		var button := Button.new()
		button.pressed.connect(func():
			binding_action = action
			button.text = "Press a key, Escape cancels"
		)
		binding_buttons[action] = button
		box.add_child(button)
	_refresh_bindings()
	_button("Reset control preferences", _reset_preferences, box)
	status_label = _label("Explore the square, farms, and crossings. Shift-click to run.", 14)
	status_label.position = Vector2(28, 872)
	layer.add_child(status_label)
	map_view=preload("res://region_map.gd").new()
	map_view.position=Vector2(1188,22)
	map_view.world=self
	layer.add_child(map_view)


func _refresh_bindings() -> void:
	if controls_label:
		controls_label.text = "Right-click: actions · Shift-click: run · Hold %s/%s: rotate · %s: in / %s: out · %s: inspect" % [OS.get_keycode_string(keys.rotate_left),OS.get_keycode_string(keys.rotate_right),OS.get_keycode_string(keys.zoom_out if reverse_zoom else keys.zoom_in),OS.get_keycode_string(keys.zoom_in if reverse_zoom else keys.zoom_out),OS.get_keycode_string(keys.inspect)]
	for action in binding_buttons:
		binding_buttons[action].text = action.replace("_", " ").capitalize() + ": " + OS.get_keycode_string(keys[action])


func _save_settings(path: String = SETTINGS_PATH) -> void:
	if loading_settings or (capture_mode and path == SETTINGS_PATH): return
	var cfg := ConfigFile.new()
	for action in keys: cfg.set_value("keys", action, keys[action])
	cfg.set_value("camera", "pan_speed", edge_speed)
	cfg.set_value("camera", "rotation_speed", rotation_speed)
	cfg.set_value("camera", "edge_pan", edge_enabled)
	cfg.set_value("camera", "reverse_zoom", reverse_zoom)
	cfg.set_value("travel", "prefer_paths", nav.prefer_paths)
	var error := cfg.save(path)
	if error != OK and status_label: status_label.text = "Preferences could not be saved."


func _load_settings(path: String = SETTINGS_PATH) -> void:
	loading_settings = true
	var cfg := ConfigFile.new()
	if cfg.load(path) == OK:
		var candidate := {}
		var used := []
		var valid := true
		for action in DEFAULT_KEYS:
			var code = cfg.get_value("keys",action,DEFAULT_KEYS[action])
			if not code is int or code <= 0 or code in used or code in [KEY_SHIFT,KEY_CTRL,KEY_ALT,KEY_META,KEY_ESCAPE]: valid = false
			candidate[action] = code
			used.append(code)
		if valid: keys = candidate
		edge_speed = clampf(float(cfg.get_value("camera","pan_speed",7.0)),2,14)
		rotation_speed = clampf(float(cfg.get_value("camera","rotation_speed",70.0)),10,180)
		edge_enabled = bool(cfg.get_value("camera","edge_pan",true))
		reverse_zoom = bool(cfg.get_value("camera","reverse_zoom",false))
		nav.prefer_paths = bool(cfg.get_value("travel","prefer_paths",true))
	_sync_preferences()
	loading_settings = false


func _sync_preferences() -> void:
	camera_controls.find_child("PanSpeed",true,false).value = edge_speed
	camera_controls.find_child("TurnSpeed",true,false).value = rotation_speed
	camera_controls.find_child("EdgePan",true,false).button_pressed = edge_enabled
	camera_controls.find_child("ReverseZoom",true,false).button_pressed = reverse_zoom
	route_choice.select(0 if nav.prefer_paths else 1)
	_refresh_bindings()


func _reset_preferences() -> void:
	keys = DEFAULT_KEYS.duplicate()
	edge_speed = 7
	rotation_speed = 70
	edge_enabled = true
	reverse_zoom = false
	nav.prefer_paths = true
	loading_settings = true
	_sync_preferences()
	loading_settings = false
	_save_settings()
	preview_valid = false




func _receive_world(state: Dictionary) -> void:
	resource_cut = state.cut
	if resource_tree: resource_tree.visible = not resource_cut
	nav.set_point_solid(_cell(Vector3(-12,0,27)),not resource_cut)
	preview_valid = false
	var present := []
	for person in state.actors:
		present.append(person.id)
		if person.id == network.local_id: continue
		if not remote_actors.has(person.id):
			var actor := Node3D.new()
			var model := Walker.instantiate()
			actor.add_child(model)
			var player := _find_animation(model)
			player.add_animation_library("motion",animation.get_animation_library("motion"))
			add_child(actor)
			player.play(idle_clip)
			actor.position = Vector3(person.position[0],person.position[1],person.position[2])
			remote_actors[person.id] = actor
	for ident in remote_actors.keys():
		if ident not in present:
			remote_actors[ident].queue_free()
			remote_actors.erase(ident)
	if context_panel and context_panel.visible: _refresh_context()


func _update_network_actors(delta: float) -> void:
	avatar.visible = network != null and network.connected
	if not network or not network.connected:
		for actor in remote_actors.values(): actor.visible = false
		return
	for person in network.snapshot.get("actors",[]):
		var actor: Node3D = avatar if person.id==network.local_id else remote_actors.get(person.id)
		if not actor: continue
		actor.visible = true
		var target := Vector3(person.position[0],person.position[1],person.position[2])
		var difference := target-actor.position
		if difference.length()>10: actor.position = target
		else: actor.position = actor.position.lerp(target,1.0-exp(-delta*12))
		if Vector2(difference.x,difference.z).length()>0.025:
			actor.rotation.y = lerp_angle(actor.rotation.y,atan2(difference.x,difference.z),1.0-exp(-delta*12))
		var player := animation if actor==avatar else _find_animation(actor)
		var clip := (run_clip if person.running else walk_clip) if person.moving else idle_clip
		if player.current_animation != clip: player.play(clip,0.15)


func _view_resource() -> void:
	if inspecting: _set_inspection(false)
	_set_follow(false)
	focus_target = Vector3(-12,1.2,27)
	zoom_slider.value = 28
	status_label.text = "Square oak. Walk nearby, then Harvest in the connection panel."


func _build_context() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	context_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("20291f")
	style.border_color = Color("c5b57c")
	style.set_border_width_all(2)
	style.set_content_margin_all(12)
	context_panel.add_theme_stylebox_override("panel",style)
	layer.add_child(context_panel)
	context_box = VBoxContainer.new()
	context_box.custom_minimum_size.x = 265
	context_panel.add_child(context_box)
	context_panel.hide()

func _pick_context(screen: Vector2) -> Dictionary:
	var origin := camera.project_ray_origin(screen)
	var direction := camera.project_ray_normal(screen)
	var closest := INF
	var selected := {}
	for record in pick_records:
		if not record.node.visible: continue
		var hit = record.bounds.intersects_ray(origin,direction)
		if hit != null and origin.distance_to(hit) < closest:
			closest = origin.distance_to(hit)
			selected = record
	var ground = _ground_hit(screen)
	if selected.is_empty():
		if ground == null: return {}
		if ground.distance_to(Vector3(-12,0,27)) < 1.5:
			return {"kind":"square_oak","name":"Square oak","point":Vector3(-12,0,27)}
		return {"kind":"ground","name":"Ground","point":ground}
	var kind: String = "square_oak" if selected.node == resource_tree else selected.key
	return {"kind":kind,"name":kind.replace("_"," ").capitalize(),"point":selected.node.position}

func _open_context(screen: Vector2) -> void:
	context_selection = _pick_context(screen)
	if context_selection.is_empty(): return
	context_point = screen
	context_state = ""
	context_panel.show()
	_refresh_context()

func _refresh_context() -> void:
	var online: bool = network != null and network.connected
	var paused: bool = network.snapshot.get("paused",false) if online else false
	var nearby := avatar.position.distance_to(Vector3(-12,0,27)) <= 3.5
	var fingerprint := str([online,paused,nearby,resource_cut])
	if fingerprint == context_state: return
	context_state = fingerprint
	for child in context_box.get_children():
		context_box.remove_child(child)
		child.queue_free()
	var heading := Label.new()
	heading.text = context_selection.name
	context_box.add_child(heading)
	for action in preload("res://context_actions.gd").choices(context_selection.kind,resource_cut,nearby,online and not paused):
		var button := Button.new()
		button.text = action.label
		button.disabled = not action.enabled
		button.pressed.connect(_choose_context.bind(action.id))
		context_box.add_child(button)
	context_panel.reset_size()
	context_panel.position = context_point.clamp(Vector2.ZERO,get_viewport().get_visible_rect().size-context_panel.get_combined_minimum_size())

func _choose_context(action: String) -> void:
	context_panel.hide()
	match action:
		"walk", "run":
			var destination: Vector3 = context_selection.point
			if context_selection.kind != "ground": destination = _approach_point(destination)
			_walk_to(destination,action == "run")
		"harvest": network.command("harvest")
		"inspect":
			match context_selection.kind:
				"square_oak": status_label.text = "Square oak: harvested. No inventory reward in this prototype." if resource_cut else "Square oak: standing. Move within 3.5m to harvest."
				"firewood": status_label.text = "A pile of stacked firewood. Inspectable scenery; collecting wood comes with inventory."
				"ground": status_label.text = "Ground at %.0f, %.0f. Roads are preferred; direct routes still respect obstacles." % [context_selection.point.x,context_selection.point.z]
				_: status_label.text = context_selection.name + ". Scenery inspection; building entry and other interactions come later."

func _approach_point(point: Vector3) -> Vector3:
	var best := point
	var distance := INF
	for x in range(-12,13):
		for z in range(-12,13):
			var candidate := Vector3(roundf(point.x)+x,0,roundf(point.z)+z)
			var id := _cell(candidate)
			if not nav.is_in_boundsv(id) or nav.is_point_solid(id): continue
			var score := candidate.distance_to(point)*2 + candidate.distance_to(avatar.position)
			if score < distance:
				distance = score
				best = candidate
	return best
