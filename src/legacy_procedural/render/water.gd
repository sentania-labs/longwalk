extends MeshInstance3D
class_name Water

# Water is the sea-level plane. Sea level is logical Y = 0, and the floating
# origin only ever shifts X and Z, so the plane stays at local Y = 0 and simply
# follows the player horizontally so it always fills the view. RENDER-side.
#
# The player controller decides swimming from the sim sampler (is_water), not
# from this visual plane, so the plane is purely cosmetic and can be a single
# large quad.

const PLANE_SIZE := 4000.0


func _ready() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(PLANE_SIZE, PLANE_SIZE)
	mesh = plane

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.30, 0.52, 0.72)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.15
	mat.metallic = 0.2
	# Do not cast shadows from the flat sea; it would stripe the ocean floor.
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	material_override = mat


# Follow the player horizontally. `player_local` is the player's position in the
# world/render space (local, origin-relative). Y is pinned to sea level.
func follow(player_local: Vector3) -> void:
	position = Vector3(player_local.x, 0.0, player_local.z)
