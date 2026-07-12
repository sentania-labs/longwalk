extends Node3D
class_name CameraRig

# CameraRig owns the player's Camera3D and switches between first-person and
# third-person views. Yaw is applied to the player body (see player_controller);
# this rig only handles pitch (so first and third person share a look axis) and
# the camera placement for each view. RENDER-side module.

# Third-person camera offset in the rig's local space. The camera looks down
# -Z by default, so a positive Z places it behind the player, lifted a little.
const THIRD_PERSON_OFFSET := Vector3(0.0, 1.2, 4.5)
const FIRST_PERSON_OFFSET := Vector3.ZERO

# Pitch clamp so the player cannot flip the camera over the poles of its look.
const PITCH_MIN := -1.4
const PITCH_MAX := 1.4

var _pitch := 0.0
var third_person := false

@onready var _pivot: Node3D = $PitchPivot
@onready var _camera: Camera3D = $PitchPivot/Camera3D


func _ready() -> void:
	_apply_view()


# Add mouse-driven or keyboard-driven pitch (radians), clamped.
func add_pitch(delta_pitch: float) -> void:
	_pitch = clampf(_pitch + delta_pitch, PITCH_MIN, PITCH_MAX)
	_pivot.rotation.x = _pitch


# Current pitch (radians). Read by the player controller for the on-screen
# look diagnostic and by the input regression test.
func current_pitch() -> float:
	return _pitch


func toggle_view() -> void:
	third_person = not third_person
	_apply_view()


func _apply_view() -> void:
	_camera.position = THIRD_PERSON_OFFSET if third_person else FIRST_PERSON_OFFSET
	# In first person the body mesh would clip the near plane, so hide it there.
	_camera.current = true
