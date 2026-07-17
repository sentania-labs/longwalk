extends SceneTree

const PlayerScene := preload("res://scenes/player.tscn")
const PlayerController := preload("res://src/render/town/player_controller_2d.gd")

func _initialize() -> void:
	var failures := 0
	
	var player = PlayerScene.instantiate()
	var camera: Camera2D = player.get_node("Camera2D")
	
	# Default zoom is index 2, which is 1.0. However, _set_zoom_index isn't called on init.
	# Wait, if _zoom_index is 2, the Camera2D initially has whatever zoom is set in the editor (which is 1.0).
	failures += _check(player._zoom_index == 2, "Default zoom index is 2")
	failures += _check(camera.zoom == Vector2.ONE, "Default camera zoom is 1.0")
	
	# Test zoom in bounds
	player._set_zoom_index(3)
	failures += _check(player._zoom_index == 3, "Zoom index updated to 3")
	failures += _check(camera.zoom == Vector2(1.25, 1.25), "Camera zoom updated to 1.25")
	
	# Test max bound
	player._set_zoom_index(10)
	failures += _check(player._zoom_index == 5, "Zoom index clamped to max (5)")
	failures += _check(camera.zoom == Vector2(2.0, 2.0), "Camera zoom clamped to 2.0")
	
	# Test min bound
	player._set_zoom_index(-1)
	failures += _check(player._zoom_index == 0, "Zoom index clamped to min (0)")
	failures += _check(camera.zoom == Vector2(0.5, 0.5), "Camera zoom clamped to 0.5")
	
	# Test zoom out
	player._set_zoom_index(1)
	failures += _check(player._zoom_index == 1, "Zoom index updated to 1")
	failures += _check(camera.zoom == Vector2(0.75, 0.75), "Camera zoom updated to 0.75")
	
	# Input events
	var event_in = InputEventAction.new()
	event_in.action = "zoom_in"
	event_in.pressed = true
	player._unhandled_input(event_in)
	failures += _check(player._zoom_index == 2, "Zoom index incremented by input event")
	failures += _check(camera.zoom == Vector2(1.0, 1.0), "Camera zoom updated by input event")

	var event_out = InputEventAction.new()
	event_out.action = "zoom_out"
	event_out.pressed = true
	player._unhandled_input(event_out)
	failures += _check(player._zoom_index == 1, "Zoom index decremented by input event")
	failures += _check(camera.zoom == Vector2(0.75, 0.75), "Camera zoom updated by input event")
	
	player.free()
	
	if failures == 0:
		print("\nAll zoom checks passed.")
		quit(0)
	else:
		print("\n%d zoom check(s) FAILED." % failures)
		quit(1)

func _check(condition: bool, description: String) -> int:
	if condition:
		print("PASS: %s" % description)
		return 0
	push_error("FAIL: %s" % description)
	return 1
