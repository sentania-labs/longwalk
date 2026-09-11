extends Node3D
var village: Node3D
func _ready() -> void:
	var light := OmniLight3D.new()
	light.position = Vector3(0,3,-1)
	light.light_color = Color("ffd8a0")
	light.light_energy = 1.4
	light.omni_range = 16
	add_child(light)
	for x in range(-8,8): _box(Vector3(x+0.5,-0.15,0),Vector3(0.98,0.3,12),Color("776344"))
	_box(Vector3(0,1.7,-6),Vector3(16,3.4,0.25),Color("b8ad83"))
	_box(Vector3(-8,1.7,0),Vector3(0.25,3.4,12),Color("a39671"))
	_box(Vector3(8,1.7,0),Vector3(0.25,3.4,12),Color("a39671"))
	for x in [-7.8,0,7.8]: _box(Vector3(x,1.7,-5.8),Vector3(0.22,3.4,0.25),Color("574c36"))
	for p in [Vector3(-5,0,-3),Vector3(5,0,-3)]:
		_box(p+Vector3(0,0.9,0),Vector3(2,0.2,1),Color("675336"))
		for x in [-0.75,0.75]: _box(p+Vector3(x,0.4,0),Vector3(0.15,0.8,0.7),Color("675336"))
	var pile = preload("res://assets/firewood.glb").instantiate()
	add_child(pile)
	var bounds: AABB = village._bounds(pile,Transform3D.IDENTITY)
	pile.scale *= 1.0 / bounds.size.y
	pile.position = Vector3(-5,0,2)-Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)/bounds.size.y
	# A simple rack-mounted axe makes the first tool legible at this scale.
	_box(Vector3(5,1.25,-3),Vector3(0.08,0.8,0.08),Color("a68b5b"))
	_box(Vector3(5.17,1.56,-3),Vector3(0.4,0.22,0.07),Color("c0c2b6"))
	var citizen = village.Walker.instantiate()
	village._normalize_character_materials(citizen)
	citizen.position = Vector3(0,0,-3)
	add_child(citizen)
	var anim: AnimationPlayer = village._find_animation(citizen)
	anim.add_animation_library("motion",village.animation.get_animation_library("motion"))
	anim.play("motion/idle")
	for spec in [["Wood bundle",Vector3(-5,1.6,2)],["Workbench",Vector3(-5,2,-3)],["Tool rack",Vector3(5,2,-3)],["Carpenter",Vector3(0,2.3,-3)],["Exit",Vector3(0,0.4,5)]]:
		var label := Label3D.new()
		label.text = spec[0]
		label.position = spec[1]
		label.font_size = 32
		label.pixel_size = 0.009
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.modulate = Color("eee4bc")
		add_child(label)
func _box(pos: Vector3, size: Vector3, color: Color) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.95
	mesh.material_override = mat
	mesh.position = pos
	add_child(mesh)
