extends SceneTree

# Reproducible in-engine acceptance capture for the player walk sheet, retargeted
# for the isometric render spine (decision 008). Each tile is cropped from the
# live starter-town viewport after the real PlayerController2D applies one atlas
# region, so the montage shows exactly what ships, drawn through the iso
# projection.
#
# The capture stands up its OWN Camera2D in projected screen space, centered on
# the player's projected feet, rather than depending on the interactive camera
# rig (which agy's slice reworks; see src/render/town/starter_town.gd). This
# also folds in the round-004 P2 fix: the previous version called
# player.get_node("Camera2D"), but the camera moved to World/CameraRig2D in
# round 004, so that path was stale. This version does not reach for the rig at
# all.
#
# The facing/frame grid is derived from the loaded atlas, so it adapts
# automatically when codex's generated 8-facing walk sheet replaces the current
# sheet (the atlas cell size is the player controller's WALK_CELL_SIZE).

const StarterTownScene := preload("res://scenes/starter_town.tscn")
const Iso := preload("res://src/render/iso/projection.gd")
const OUTPUT := "res://docs/art/player-walk-iso-capture.png"
const CELL := 160


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var town = StarterTownScene.instantiate()
	town.character_name = "Iso Capture"
	town.appearance_variant = "moss"
	root.add_child(town)
	current_scene = town
	await process_frame
	await process_frame

	var player = town.get_node("World/Player")

	# Freeze the player's physics processing for the capture. With no route the
	# controller's _physics_process() calls _update_walk_animation(_, false),
	# which resets _walk_frame to zero and reapplies that region. Because the
	# capture loop selects a frame and then awaits the next process/render frame,
	# an intervening physics tick would overwrite the selection before the
	# screenshot, repeating frame zero or dropping frames. Disabling physics
	# processing removes the race entirely; nothing else drives the node here.
	# (External Codex review of PR #21 round 2, P2.)
	player.set_physics_process(false)

	# Own camera in projected screen space, centered on the projected feet.
	var camera := Camera2D.new()
	camera.zoom = Vector2.ONE
	camera.position = Iso.world_to_screen(player.position)
	town.add_child(camera)
	camera.make_current()

	var cell_size: Vector2 = player.WALK_CELL_SIZE
	var facings := int(player._walk_atlas.get_height() / cell_size.y)
	var frames := int(player._walk_atlas.get_width() / cell_size.x)

	var montage := Image.create(CELL * frames, CELL * facings, false, Image.FORMAT_RGBA8)
	for row in range(facings):
		for frame in range(frames):
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
