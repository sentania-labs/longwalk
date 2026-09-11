extends Node3D
var wings: Array[Node3D] = []
var phase := 0.0
func _ready() -> void:
	var body := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.06
	sphere.height = 0.18
	sphere.radial_segments = 8
	sphere.rings = 4
	body.mesh = sphere
	body.rotation.x = PI/2
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color("ffe4a0")
	glow.emission_enabled = true
	glow.emission = Color("ffd477")
	glow.roughness = 1
	body.material_override = glow
	add_child(body)
	for side in [-1,1]:
		var pivot := Node3D.new()
		add_child(pivot)
		var wing := MeshInstance3D.new()
		var mesh := QuadMesh.new()
		mesh.size = Vector2(0.2,0.12)
		wing.mesh = mesh
		wing.position.x = side*0.1
		wing.rotation.x = PI/2
		var material := StandardMaterial3D.new()
		material.albedo_color = Color("bdaf82")
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		material.roughness = 1
		wing.material_override = material
		pivot.add_child(wing)
		wings.append(pivot)
	var light := OmniLight3D.new()
	light.light_color = Color("ffd78c")
	light.light_energy = 0.25
	light.omni_range = 0.8
	add_child(light)
func _process(delta: float) -> void:
	if not is_visible_in_tree(): return
	phase += delta*18
	for i in range(wings.size()): wings[i].rotation.z = sin(phase)*(1 if i==0 else -1)*0.9
