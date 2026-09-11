extends Node3D

# Flat authored terrain. The simulation owns all positions and water tests.
const GROUND_SHADER = preload("res://terrain.gdshader")
const WATER_SHADER = preload("res://water.gdshader")

func _ready() -> void:
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
