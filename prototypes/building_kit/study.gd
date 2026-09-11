extends Node3D
const BAY = 2.0
const WALL = 3.0
var materials: Dictionary = {}
var assembly: Node3D
var camera: Camera3D
var yaw := 0.65
var tilt := 0.52
var distance := 22.0
var layout := 0
var roof_type := "thatch"
var roof_visible := true
var label: Label
var roof_nodes: Array[Node3D] = []

func _ready():
	for key in ["plaster","stone","timber","thatch","slate","earth"]:
		var mat=StandardMaterial3D.new()
		mat.albedo_texture=load("res://art/"+key+".png")
		mat.roughness=1.0
		mat.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		materials[key]=mat
	var glass=StandardMaterial3D.new()
	glass.albedo_color=Color(0.15,0.23,0.24)
	glass.roughness=0.35
	materials["glass"]=glass
	var env=WorldEnvironment.new()
	env.environment=Environment.new()
	env.environment.background_mode=Environment.BG_COLOR
	env.environment.background_color=Color(0.22,0.27,0.22)
	env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color=Color(0.88,0.92,1.0)
	env.environment.ambient_light_energy=0.48
	add_child(env)
	var sun=DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-48,-28,0)
	sun.light_color=Color(1,0.92,0.80)
	sun.light_energy=0.8
	sun.shadow_enabled=true
	add_child(sun)
	camera=Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	add_child(camera)
	box(self,Vector3(0,-0.18,0),Vector3(38,0.3,30),"earth")
	ui()
	rebuild()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):
			capture.call_deferred(arg.trim_prefix("--capture-dir="))

func box(parent: Node3D, pos: Vector3, size: Vector3, material: String) -> MeshInstance3D:
	var node=MeshInstance3D.new()
	var mesh=ArrayMesh.new()
	var verts=PackedVector3Array()
	var normals=PackedVector3Array()
	var uvs=PackedVector2Array()
	var faces=[
		[Vector3(0,0,1),Vector3.RIGHT,Vector3.UP,size.x,size.y],
		[Vector3(0,0,-1),Vector3.LEFT,Vector3.UP,size.x,size.y],
		[Vector3.RIGHT,Vector3.FORWARD,Vector3.UP,size.z,size.y],
		[Vector3.LEFT,Vector3.BACK,Vector3.UP,size.z,size.y],
		[Vector3.UP,Vector3.RIGHT,Vector3.FORWARD,size.x,size.z],
		[Vector3.DOWN,Vector3.RIGHT,Vector3.BACK,size.x,size.z]]
	for face in faces:
		var normal: Vector3=face[0]
		var u: Vector3=face[1]
		var v: Vector3=face[2]
		var center=normal*size*0.5
		for q in [Vector2(-1,-1),Vector2(-1,1),Vector2(1,1),Vector2(-1,-1),Vector2(1,1),Vector2(1,-1)]:
			verts.append(center+u*q.x*face[3]*0.5+v*q.y*face[4]*0.5)
			normals.append(normal)
			uvs.append(Vector2((q.x+1)*face[3]*0.25,(1-q.y)*face[4]*0.25))
	var arrays=[]
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=verts
	arrays[Mesh.ARRAY_NORMAL]=normals
	arrays[Mesh.ARRAY_TEX_UV]=uvs
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	mesh.surface_set_material(0,materials[material])
	node.mesh=mesh
	node.position=pos
	parent.add_child(node)
	return node

func beam(parent: Node3D,a: Vector3,b: Vector3,width=0.16):
	var n=box(parent,(a+b)*0.5,Vector3(width,a.distance_to(b),width),"timber")
	n.quaternion=Quaternion(Vector3.UP,(b-a).normalized())

# Every facade module occupies the same 2 m by 3 m bay.
# Apertures are empty space between plaster pieces, with inset frames and leaves.
func wall_module(parent: Node3D,pos: Vector3,angle: float,kind: String):
	var n=Node3D.new()
	parent.add_child(n)
	n.position=pos
	n.rotation.y=angle
	box(n,Vector3(0,0.22,0),Vector3(BAY,0.44,0.32),"stone")
	if kind=="plain":
		box(n,Vector3(0,1.68,0),Vector3(BAY,2.48,0.22),"plaster")
	else:
		var low=0.44 if kind=="door" else 1.12
		var high=2.52 if kind=="door" else 2.32
		var half=0.55
		box(n,Vector3(-0.775,1.68,0),Vector3(0.45,2.48,0.22),"plaster")
		box(n,Vector3(0.775,1.68,0),Vector3(0.45,2.48,0.22),"plaster")
		if low>0.44: box(n,Vector3(0,(low+0.44)/2,0),Vector3(1.1,low-0.44,0.22),"plaster")
		box(n,Vector3(0,(high+2.92)/2,0),Vector3(1.1,2.92-high,0.22),"plaster")
		for x in [-half,half]: box(n,Vector3(x,(low+high)/2,0.02),Vector3(0.13,high-low+0.15,0.32),"timber")
		for y in [low,high]: box(n,Vector3(0,y,0.04),Vector3(1.22,0.13,0.35),"timber")
		if kind=="door":
			var leaf=box(n,Vector3(-0.17,(low+high)/2,-0.15),Vector3(0.96,high-low-0.1,0.09),"timber")
			leaf.rotation.y=-0.35
			box(n,Vector3(0,0.20,0.58),Vector3(1.35,0.4,0.9),"stone")
		else:
			box(n,Vector3(0,(low+high)/2,-0.035),Vector3(0.94,high-low-0.1,0.04),"glass")
			beam(n,Vector3(0,low,0.10),Vector3(0,high,0.10),0.065)
			beam(n,Vector3(-half,(low+high)/2,0.10),Vector3(half,(low+high)/2,0.10),0.065)
			for x in [-0.81,0.81]: box(n,Vector3(x,(low+high)/2,0.17),Vector3(0.35,high-low,0.075),"timber")
	for x in [-1.0,1.0]: box(n,Vector3(x,1.5,0),Vector3(0.17,3,0.34),"timber")
	for y in [0.48,2.93]: box(n,Vector3(0,y,0),Vector3(2,0.16,0.34),"timber")
	if kind=="plain": beam(n,Vector3(-0.88,0.56,0.15),Vector3(0.88,2.85,0.15),0.14)

func triangle(parent: Node3D,points: Array,material: String):
	var mesh=ArrayMesh.new()
	var a=[]
	a.resize(Mesh.ARRAY_MAX)
	a[Mesh.ARRAY_VERTEX]=PackedVector3Array(points)
	a[Mesh.ARRAY_TEX_UV]=PackedVector2Array([Vector2(0,1),Vector2(1,1),Vector2(0.5,0)])
	a[Mesh.ARRAY_NORMAL]=PackedVector3Array([Vector3.FORWARD,Vector3.FORWARD,Vector3.FORWARD])
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,a)
	var mat=materials[material].duplicate()
	mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	mesh.surface_set_material(0,mat)
	var node=MeshInstance3D.new()
	node.mesh=mesh
	parent.add_child(node)

func house(origin: Vector3,nx: int,nz: int):
	var n=Node3D.new()
	assembly.add_child(n)
	n.position=origin
	var w=nx*BAY
	var d=nz*BAY
	box(n,Vector3(0,0.04,0),Vector3(w,0.08,d),"timber")
	for i in nx:
		var x=-w/2+1+i*BAY
		wall_module(n,Vector3(x,0,d/2),0,"door" if i==nx/2 else "window")
		wall_module(n,Vector3(-x,0,-d/2),PI,"window" if i%2==0 else "plain")
	for i in nz:
		var z=-d/2+1+i*BAY
		wall_module(n,Vector3(w/2,0,z),PI/2,"window" if i%2==0 else "plain")
		wall_module(n,Vector3(-w/2,0,-z),-PI/2,"window" if i%2==0 else "plain")
	var roof=Node3D.new()
	n.add_child(roof)
	roof_nodes.append(roof)
	roof.visible=roof_visible
	var rise=2.0
	var half=d/2+0.4
	var slope=atan2(rise,half)
	var length=sqrt(half*half+rise*rise)
	for sign_value in [-1,1]:
		var panel=box(roof,Vector3(0,WALL+rise/2,sign_value*half/2),Vector3(w+0.7,0.18,length),roof_type)
		panel.rotation.x=sign_value*slope
	for x in [-w/2,w/2]:
		triangle(roof,[Vector3(x,WALL,-d/2),Vector3(x,WALL,d/2),Vector3(x,WALL+rise,0)],"plaster")
		beam(roof,Vector3(x,WALL,-d/2),Vector3(x,WALL+rise,0))
		beam(roof,Vector3(x,WALL,d/2),Vector3(x,WALL+rise,0))
		beam(roof,Vector3(x,WALL,0),Vector3(x,WALL+rise,0))
	beam(roof,Vector3(-w/2-0.38,WALL+rise+0.08,0),Vector3(w/2+0.38,WALL+rise+0.08,0),0.22)
	box(roof,Vector3(-w/2+1,WALL+1.2,-d/4),Vector3(0.7,2.4,0.7),"stone")

func rebuild():
	if assembly: remove_child(assembly); assembly.queue_free()
	roof_nodes.clear()
	assembly=Node3D.new()
	add_child(assembly)
	match layout:
		0: house(Vector3.ZERO,3,2)
		1: house(Vector3.ZERO,5,3)
		2:
			house(Vector3(-6,0,-3),2,3)
			house(Vector3(5,0,-4),3,2)
			house(Vector3(0,0,5),4,2)
	label.text=["Cottage: 6 x 4 m","Longhouse: 10 x 6 m","Courtyard: three footprints, shared pieces"][layout]+"  |  2 m wall bays  |  "+roof_type

func _process(dt):
	if Input.is_physical_key_pressed(KEY_Q): yaw-=dt
	if Input.is_physical_key_pressed(KEY_E): yaw+=dt
	camera.size=distance
	camera.position=Vector3(sin(yaw)*cos(tilt),sin(tilt),cos(yaw)*cos(tilt))*35+Vector3(0,1.5,0)
	camera.look_at(Vector3(0,1.5,0))

func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		yaw-=event.relative.x*0.008
		tilt=clampf(tilt+event.relative.y*0.005,0.12,1.25)
	if event is InputEventMouseButton and event.pressed:
		if event.button_index==MOUSE_BUTTON_WHEEL_UP: distance=maxf(8,distance-1)
		if event.button_index==MOUSE_BUTTON_WHEEL_DOWN: distance=minf(38,distance+1)
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE: get_tree().quit()

func ui():
	var layer=CanvasLayer.new()
	add_child(layer)
	var panel=PanelContainer.new()
	panel.position=Vector2(20,20)
	layer.add_child(panel)
	var stack=VBoxContainer.new()
	panel.add_child(stack)
	var title=Label.new()
	title.text="BUILDING KIT / CONSTRUCTION STUDY"
	title.add_theme_font_size_override("font_size",22)
	stack.add_child(title)
	label=Label.new()
	stack.add_child(label)
	var row=HBoxContainer.new()
	stack.add_child(row)
	for i in 3:
		var button=Button.new()
		button.text=["Cottage","Longhouse","Courtyard"][i]
		button.pressed.connect(func(): layout=i; distance=28 if i==2 else 18; rebuild())
		row.add_child(button)
	var roof_button=Button.new()
	roof_button.text="Switch thatch / slate"
	roof_button.pressed.connect(func(): roof_type="slate" if roof_type=="thatch" else "thatch"; rebuild())
	row.add_child(roof_button)
	var cutaway=CheckButton.new()
	cutaway.text="Hide roof"
	cutaway.toggled.connect(func(on): roof_visible=not on; rebuild())
	row.add_child(cutaway)
	var help=Label.new()
	help.text="Right drag: orbit / tilt    Q E: rotate    Wheel: zoom    Esc: exit"
	stack.add_child(help)

func capture(folder: String):
	DirAccess.make_dir_recursive_absolute(folder)
	for i in 3:
		layout=i
		distance=30 if i==2 else 18
		for material in ["thatch","slate"]:
			roof_type=material
			rebuild()
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(folder+"/layout-"+str(i)+"-"+material+".png")
	roof_visible=false
	layout=0
	distance=16
	rebuild()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(folder+"/cutaway.png")
	print("BUILDING KIT CAPTURE PASS: 3 layouts, 2 roof finishes, cutaway")
	get_tree().quit()
