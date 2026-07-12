extends SceneTree

# Regression guard that LOOK input actually reaches and moves the camera, not
# just that action names are registered. The earlier test_input_map.gd checks
# registration only; the dead-mouse-look bug lived entirely in the gap it left:
# every action existed and every event arrived, but a per-event re-read of
# Input.mouse_mode (which can report VISIBLE right after being set to CAPTURED)
# silently zeroed all camera rotation. Registration passed; the camera never
# moved. This test closes that gap by asserting rotation actually changes.
#
# It builds a real player instance in a headless SceneTree and:
#   1. injects an InputEventMouseMotion and asserts the body yaw AND the camera
#      rig pitch both changed (mouse look),
#   2. presses the yaw_left action, ticks a physics frame, asserts the body
#      yawed (keyboard yaw, Q/E),
#   3. presses the pitch_up action, ticks a physics frame, asserts the rig
#      pitched (keyboard pitch, arrow keys).
#
# Look is gated on the controller's own capture flag (not Input.mouse_mode,
# which cannot be CAPTURED headless), so _set_mouse_captured(true) puts the
# controller on exactly the code path the export runs.
#
# Invocation (run by tools/run_tests.sh):
#   godot --headless --script res://test/test_player_input.gd

const PlayerScene := preload("res://scenes/player.tscn")
const InputActionsScript := preload("res://src/render/input_actions.gd")


func _initialize() -> void:
	var failures := 0
	InputActionsScript.register()

	var player = PlayerScene.instantiate()
	get_root().add_child(player)
	await process_frame
	player._set_mouse_captured(true)

	# 1. Mouse look: a single motion event must yaw the body and pitch the rig.
	var yaw0: float = player.rotation.y
	var pitch0: float = player._rig.current_pitch()
	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(120, 60)
	Input.parse_input_event(motion)
	await process_frame
	failures += _check(player.rotation.y != yaw0,
		"mouse motion yawed the body (%.4f -> %.4f)" % [yaw0, player.rotation.y])
	failures += _check(player._rig.current_pitch() != pitch0,
		"mouse motion pitched the camera rig (%.4f -> %.4f)" % [pitch0, player._rig.current_pitch()])

	# 2. Keyboard yaw (Q/E): holding yaw_left across a physics frame must rotate
	# the body.
	var yaw1: float = player.rotation.y
	Input.action_press("yaw_left")
	player._physics_process(0.1)
	Input.action_release("yaw_left")
	failures += _check(player.rotation.y != yaw1,
		"yaw_left action rotated the body (%.4f -> %.4f)" % [yaw1, player.rotation.y])

	# 3. Keyboard pitch (arrow keys): holding pitch_up across a physics frame must
	# pitch the rig.
	var pitch1: float = player._rig.current_pitch()
	Input.action_press("pitch_up")
	player._physics_process(0.1)
	Input.action_release("pitch_up")
	failures += _check(player._rig.current_pitch() != pitch1,
		"pitch_up action pitched the camera rig (%.4f -> %.4f)" % [pitch1, player._rig.current_pitch()])

	if failures == 0:
		print("\nAll player-input checks passed.")
		quit(0)
	else:
		print("\n%d player-input check(s) FAILED." % failures)
		quit(1)


func _check(condition: bool, label: String) -> int:
	if condition:
		print("[PASS] %s" % label)
		return 0
	print("[FAIL] %s" % label)
	return 1
