extends SceneTree

# Reproducible in-engine acceptance capture for the 160 px player contract.
# Each tile is cropped from the live starter-town viewport at zoom 1.0 after
# the real PlayerController2D applies one atlas region.

const StarterTownScene := preload("res://scenes/starter_town.tscn")
const OUTPUT := "res://docs/art/player-walk-option-c-capture.png"
const CELL := 160


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var town = StarterTownScene.instantiate()
	town.character_name = "Option C Capture"
	town.appearance_variant = "moss"
	root.add_child(town)
	current_scene = town
	await process_frame
	await process_frame

	var player = town.get_node("World/Player")
	var camera: Camera2D = player.get_node("Camera2D")
	camera.zoom = Vector2.ONE
	var montage := Image.create(CELL * 4, CELL * 4, false, Image.FORMAT_RGBA8)
	for row in range(4):
		for frame in range(4):
			player._facing = row
			player._walk_frame = frame
			player._apply_walk_frame()
			await process_frame
			await RenderingServer.frame_post_draw
			var viewport_image := root.get_texture().get_image()
			var center := viewport_image.get_size() / 2
			var source_rect := Rect2i(center.x - CELL / 2, center.y - CELL, CELL, CELL)
			montage.blit_rect(viewport_image, source_rect, Vector2i(frame * CELL, row * CELL))

	var error := montage.save_png(ProjectSettings.globalize_path(OUTPUT))
	if error != OK:
		push_error("failed to save walk capture: %s" % error_string(error))
		quit(1)
		return
	print("wrote %s" % OUTPUT)
	quit(0)
