extends CharacterBody3D
class_name PlayerController

# PlayerController is the M2 character: walk, run (sprint), swim, jump, and a
# sleep action. RENDER-side. It depends on the sim TerrainSampler (one
# directional) only to know whether it is over water; all other state is local
# physics.
#
# Yaw is applied to this body (so movement is body-relative); the child
# CameraRig handles pitch. Mouse look and the camera/sleep keybinds are read
# here and dispatched.

signal sleep_requested

const WALK_SPEED := 5.0
const RUN_SPEED := 9.0
const SWIM_SPEED := 4.0
const JUMP_VELOCITY := 5.5
const GRAVITY := 18.0
const MOUSE_SENSITIVITY := 0.0025

# Acceleration blends velocity toward the target so movement is not instant.
const GROUND_ACCEL := 12.0
const AIR_ACCEL := 3.0
const SWIM_ACCEL := 6.0

# Water: the surface sits at logical Y = 0 (sea level). The player is treated as
# swimming when it is over an ocean cell and its body has sunk to near or below
# the surface. Buoyancy floats an idle swimmer up to a waterline just below the
# surface.
const SWIM_ENTER_Y := 0.6
const WATERLINE_Y := -0.4
const BUOYANCY := 6.0
const SWIM_VERTICAL_SPEED := 3.5

var _sampler
# Floating-origin offset, refreshed each frame by the world so the water query
# uses logical world coordinates.
var render_origin := Vector3.ZERO
var swimming := false

# Untyped so this script also loads in a headless `--script` test (the global
# class cache that resolves the CameraRig type is only built by the editor).
@onready var _rig := $CameraRig
@onready var _mesh: MeshInstance3D = $Mesh


func setup(sampler) -> void:
	_sampler = sampler


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# Default view is first person; hide the placeholder body so it does not
	# fill the camera. It reappears in third person.
	_mesh.visible = _rig.third_person


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# Horizontal mouse yaws the body; vertical pitches the camera rig.
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		_rig.add_pitch(-event.relative.y * MOUSE_SENSITIVITY)
	elif event.is_action_pressed("toggle_camera"):
		_rig.toggle_view()
		_mesh.visible = _rig.third_person
	elif event.is_action_pressed("sleep"):
		sleep_requested.emit()
	elif event.is_action_pressed("toggle_mouse"):
		# Free or recapture the mouse (handy for menus / alt-tab).
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _logical_pos() -> Vector3:
	return global_position + render_origin


func _physics_process(delta: float) -> void:
	var logical := _logical_pos()
	var over_water: bool = _sampler != null and _sampler.is_water(logical.x, logical.z)
	swimming = over_water and logical.y < SWIM_ENTER_Y

	if swimming:
		_swim(delta)
	else:
		_walk(delta)

	move_and_slide()


# Build the horizontal movement direction from input, relative to body yaw.
func _input_direction() -> Vector3:
	var input := Vector3.ZERO
	input.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input.z = Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	if input.length() > 1.0:
		input = input.normalized()
	# Rotate into world space by the body's yaw.
	return (transform.basis * input)


func _walk(delta: float) -> void:
	var speed := RUN_SPEED if Input.is_action_pressed("sprint") else WALK_SPEED
	var dir := _input_direction()
	var target := Vector3(dir.x, 0.0, dir.z) * speed

	var accel := GROUND_ACCEL if is_on_floor() else AIR_ACCEL
	velocity.x = move_toward(velocity.x, target.x, accel * speed * delta)
	velocity.z = move_toward(velocity.z, target.z, accel * speed * delta)

	if is_on_floor():
		if Input.is_action_pressed("jump"):
			velocity.y = JUMP_VELOCITY
	else:
		velocity.y -= GRAVITY * delta


func _swim(delta: float) -> void:
	var speed := SWIM_SPEED * (1.4 if Input.is_action_pressed("sprint") else 1.0)
	var dir := _input_direction()
	var target := Vector3(dir.x, 0.0, dir.z) * speed
	velocity.x = move_toward(velocity.x, target.x, SWIM_ACCEL * speed * delta)
	velocity.z = move_toward(velocity.z, target.z, SWIM_ACCEL * speed * delta)

	# Vertical: jump to rise, sprint-independent sink via crouch-less default is
	# handled by buoyancy pulling toward the waterline. Logical Y equals local Y
	# because the floating origin only shifts X and Z.
	var logical_y := global_position.y + render_origin.y
	var vertical := 0.0
	if Input.is_action_pressed("jump"):
		vertical = SWIM_VERTICAL_SPEED
	elif Input.is_action_pressed("sprint") and Input.is_action_pressed("move_back"):
		vertical = 0.0
	else:
		# Buoyancy eases the swimmer toward the waterline when not actively
		# rising, so an idle swimmer bobs at the surface instead of sinking.
		vertical = clampf((WATERLINE_Y - logical_y) * BUOYANCY, -SWIM_VERTICAL_SPEED, SWIM_VERTICAL_SPEED)
	velocity.y = move_toward(velocity.y, vertical, SWIM_ACCEL * delta * 4.0)
