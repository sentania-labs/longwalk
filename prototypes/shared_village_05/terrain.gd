extends Node3D

# Flat authored terrain. The simulation owns all positions and water tests.
const GROUND_SHADER = preload("res://terrain.gdshader")
const WATER_SHADER = preload("res://water.gdshader")

func _ready() -> void:
 # A broad ground continuation closes the horizon and the underside of water cuts.
 var skirt := MeshInstance3D.new()
 var base := PlaneMesh.new()
 base.size = Vector2(30000,30000)
 skirt.mesh = base
 skirt.position.y = -0.8
 var base_material := StandardMaterial3D.new()
 base_material.albedo_color = Color("596348")
 base_material.roughness = 1
 skirt.material_override = base_material
 add_child(skirt)
 var ground := MeshInstance3D.new()
 ground.name = "AuthoredGround"
 var plane := PlaneMesh.new()
 plane.size = Vector2(1024,1024)
 ground.mesh = plane
 var material := ShaderMaterial.new()
 material.shader = GROUND_SHADER
 material.set_shader_parameter("grass_tex",preload("res://art/grass.png"))
 material.set_shader_parameter("dirt_tex",preload("res://art/dirt.png"))
 material.set_shader_parameter("soil_tex",preload("res://art/soil.png"))
 material.set_shader_parameter("control_tex",preload("res://art/terrain-control.png"))
 material.set_shader_parameter("wear_tex",preload("res://art/terrain-wear.png"))
 ground.material_override = material
 add_child(ground)
 var water := MeshInstance3D.new()
 water.name = "TwoRiversWater"
 water.mesh = plane
 water.position.y = -0.18
 var water_material := ShaderMaterial.new()
 water_material.shader = WATER_SHADER
 water.material_override = water_material
 add_child(water)
