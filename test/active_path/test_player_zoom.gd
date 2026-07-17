extends SceneTree

const PlayerScene := preload("res://scenes/player.tscn")

func _initialize() -> void:
	var failures := 0

	var player = PlayerScene.instantiate()
	var camera: Camera2D = player.get_node("Camera2D")
	var sprite: Sprite2D = player.get_node("Sprite2D")
	var collider: CollisionShape2D = player.get_node("CollisionShape2D")

	failures += _check(player._zoom_index == 2, "Default zoom index is 2")
	failures += _check(camera.zoom == Vector2.ONE, "Default camera zoom is 1.0")

	# Pin invariants before zoom
	var base_origin: Vector2 = player.position
	var base_sprite_offset: Vector2 = sprite.offset
	var base_collider_shape: Shape2D = collider.shape
	var base_collider_pos: Vector2 = collider.position
	var base_sprite_scale: Vector2 = sprite.scale
	var test_world_pos := Vector2(1000, 1000)
	var base_nav_cell: Vector2i = player.world_to_cell(test_world_pos)
	var base_nav_center: Vector2 = player.cell_to_world_center(base_nav_cell)

	# Test zoom in bounds
	player._set_zoom_index(3)
	failures += _check(player._zoom_index == 3, "Zoom index updated to 3")

	# Advance process to finish easing
	for i in range(100):
		player._process(0.016)

	failures += _check(camera.zoom == Vector2(1.25, 1.25), "Camera zoom updated to 1.25")
	failures += _check(player.position == base_origin, "Node origin stayed pinned")
	failures += _check(sprite.offset == base_sprite_offset, "Sprite anchor stayed pinned")
	failures += _check(collider.shape == base_collider_shape, "Collider geometry stayed pinned")
	failures += _check(collider.position == base_collider_pos, "Collider pos stayed pinned")
	failures += _check(sprite.scale == base_sprite_scale, "Sprite scale (cell size) stayed pinned")
	failures += _check(player.world_to_cell(test_world_pos) == base_nav_cell, "Navigation conversion (world_to_cell) stayed pinned")
	failures += _check(player.cell_to_world_center(base_nav_cell) == base_nav_center, "Navigation conversion (cell_to_world) stayed pinned")

	# Test max bound
	player._set_zoom_index(10)
	for i in range(100):
		player._process(0.016)
	failures += _check(player._zoom_index == 5, "Zoom index clamped to max (5)")
	failures += _check(camera.zoom == Vector2(2.0, 2.0), "Camera zoom clamped to 2.0")

	# Test min bound
	player._set_zoom_index(-1)
	for i in range(100):
		player._process(0.016)
	failures += _check(player._zoom_index == 0, "Zoom index clamped to min (0)")
	failures += _check(camera.zoom == Vector2(0.5, 0.5), "Camera zoom clamped to 0.5")

	# Input events
	var event_in = InputEventAction.new()
	event_in.action = "zoom_in"
	event_in.pressed = true
	player._unhandled_input(event_in)
	for i in range(100):
		player._process(0.016)
	failures += _check(player._zoom_index == 1, "Zoom index incremented by input event")
	failures += _check(camera.zoom == Vector2(0.75, 0.75), "Camera zoom updated by input event")

	var event_out = InputEventAction.new()
	event_out.action = "zoom_out"
	event_out.pressed = true
	player._unhandled_input(event_out)
	for i in range(100):
		player._process(0.016)
	failures += _check(player._zoom_index == 0, "Zoom index decremented by input event")
	failures += _check(camera.zoom == Vector2(0.5, 0.5), "Camera zoom updated by input event")


	# Test dynamic zoom bounds based on layout
	var layout = preload("res://src/sim/town_layout.gd").build_starter_town()
	player.set_layout(layout)

	player._set_zoom_index(-1)
	for i in range(100):
		player._process(0.016)

	var min_z: float = camera.zoom.x
	var vp_w: float = ProjectSettings.get_setting("display/window/size/viewport_width")
	var vp_h: float = ProjectSettings.get_setting("display/window/size/viewport_height")
	var vis_w = vp_w / min_z
	var vis_h = vp_h / min_z
	var town_w = layout.pixel_size().x
	var town_h = layout.pixel_size().y

	failures += _check(vis_w <= town_w, "Viewport width at min zoom fits within town")
	failures += _check(vis_h <= town_h, "Viewport height at min zoom fits within town")

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
