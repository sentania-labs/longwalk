extends CharacterBody3D
class_name PlayerController

# PlayerController is the M2 character: walk, run (sprint), swim, jump, and a
# sleep action. RENDER-side. It depends on the sim TerrainSampler (one
# directional) only to know whether it is over water; all other state is local
# physics.
#
# Yaw is applied to this body (so movement is body-relative); the child
# CameraRig handles pitch. Mouse look, keyboard look, and the camera/sleep
# keybinds are read here and dispatched.
#
# All discrete input (look, capture toggle, camera toggle, sleep) is handled in
# _input, not _unhandled_input. _input sees every event before any UI Control can
# consume it, the same reliable path the Esc capture toggle already used. Look is
# gated on our own capture flag (see _captured), never on a re-read of
# Input.mouse_mode: the platform can silently report a mode other than CAPTURED at
# the moment motion events arrive (setting MOUSE_MODE_CAPTURED can read straight
# back as VISIBLE), which was silently zeroing all camera rotation even though the
# motion events themselves arrived fine. That readback gate was the dead
# mouse-look bug.

signal sleep_requested

const WALK_SPEED := 5.0
const RUN_SPEED := 9.0
const SWIM_SPEED := 4.0
const JUMP_VELOCITY := 5.5
const GRAVITY := 18.0
const MOUSE_SENSITIVITY := 0.0025

# Keyboard look rates (radians per second) for Q/E yaw and arrow-key pitch, the
# no-mouse alternative to mouse look.
const KEY_YAW_SPEED := 1.8
const KEY_PITCH_SPEED := 1.8

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

# Our own record of whether the game intends the mouse captured. Look is gated on
# this, not on Input.mouse_mode, because the platform's reported mode is not a
# reliable readback (see the header note). _set_mouse_captured is the only writer.
var _captured := false

# Mouse motion accumulated since the last HUD read, exposed for the on-screen
# look diagnostic so a playtester can tell "no motion events are arriving" from
# "events arrive but the camera does not rotate".
var mouse_rel_this_frame := Vector2.ZERO

# Whether the mouse was captured when the window lost focus, so focus regain can
# restore capture. See _notification.
var _was_captured := false

# Untyped so this script also loads in a headless `--script` test (the global
# class cache that resolves the CameraRig type is only built by the editor).
@onready var _rig := $CameraRig
@onready var _mesh: MeshInstance3D = $Mesh


func setup(sampler) -> void:
	_sampler = sampler


func _ready() -> void:
	_set_mouse_captured(true)
	# Default view is first person; hide the placeholder body so it does not
	# fill the camera. It reappears in third person.
	_mesh.visible = _rig.third_person


# All discrete input is handled here in _input (which sees every event first),
# NOT _unhandled_input, so it runs even if a UI Control is present that would
# otherwise swallow the event. The editor auto-releases a captured mouse and
# forwards motion on focus changes, which masked export-only issues; an exported
# build has no such safety net.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_mouse"):
		_set_mouse_captured(not _captured)
		get_viewport().set_input_as_handled()
		return
	# Horizontal mouse yaws the body; vertical pitches the camera rig. Gated on
	# our own capture intent, not Input.mouse_mode (see the header note).
	if event is InputEventMouseMotion and _captured:
		mouse_rel_this_frame += event.relative
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		_rig.add_pitch(-event.relative.y * MOUSE_SENSITIVITY)
		return
	if event.is_action_pressed("toggle_camera"):
		_rig.toggle_view()
		_mesh.visible = _rig.third_person
	elif event.is_action_pressed("sleep"):
		sleep_requested.emit()


func _set_mouse_captured(captured: bool) -> void:
	_captured = captured
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if captured else Input.MOUSE_MODE_VISIBLE


# Snapshot of the look state for the on-screen diagnostic, clearing the
# accumulated mouse delta so each read reports motion since the previous frame.
func consume_look_debug() -> Dictionary:
	var d := {"rel": mouse_rel_this_frame, "yaw": rotation.y, "pitch": _rig.current_pitch()}
	mouse_rel_this_frame = Vector2.ZERO
	return d


# Never leave the OS with a captured (hidden, window-confined) cursor while the
# game window is not focused; otherwise alt-tabbing away feels like the whole PC
# is locked. Release capture on focus out and restore it on focus in.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if _captured:
			_was_captured = true
			_set_mouse_captured(false)
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		if _was_captured:
			_was_captured = false
			_set_mouse_captured(true)


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

	_apply_keyboard_look(delta)
	move_and_slide()


# Keyboard camera control, polled every physics frame like movement so it is
# frame-rate independent. Q/E yaw the body, arrow Up/Down pitch the camera rig,
# the same rotations mouse look drives.
func _apply_keyboard_look(delta: float) -> void:
	var yaw := Input.get_action_strength("yaw_left") - Input.get_action_strength("yaw_right")
	if yaw != 0.0:
		rotate_y(yaw * KEY_YAW_SPEED * delta)
	var pitch := Input.get_action_strength("pitch_up") - Input.get_action_strength("pitch_down")
	if pitch != 0.0:
		_rig.add_pitch(pitch * KEY_PITCH_SPEED * delta)


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
