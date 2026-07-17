extends SceneTree

const TownScene := preload("res://scenes/starter_town.tscn")


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var town = TownScene.instantiate()
	town.character_name = "Traveler"
	town.appearance_variant = "moss"
	root.add_child(town)
	await process_frame
	await process_frame
	if OS.get_environment("LONGWALK_BEFORE") == "1":
		_apply_before_art(town)
	var player = town.get_node("World/Player")
	player.position = Vector2(9 * 128 + 64, 7 * 128 + 112)
	await process_frame
	await process_frame
	var output := OS.get_environment("LONGWALK_CAPTURE")
	if output.is_empty():
		output = "res://docs/art/round-004-after.png"
	var image := root.get_viewport().get_texture().get_image()
	var error := image.save_png(output)
	if error != OK:
		push_error("capture failed: %s" % error)
		quit(1)
		return
	print("wrote %s" % output)
	quit()


func _apply_before_art(town) -> void:
	var ground = town.get_node("GroundLayer")
	for index in range(town._layout.width * town._layout.height):
		var x: int = index % town._layout.width
		var y: int = int(index / town._layout.width)
		var key: int = town._layout.ground[y][x]
		var path := "res://tools/art/out/processed/grass_ground_tile.png"
		if key == 1:
			path = "res://tools/art/out/processed/ground_path_tile.png"
		ground.get_child(index).texture = load(path)
	for child in town.get_node("World").get_children():
		if child.has_meta("flora"):
			child.visible = false
		elif child.has_meta("sprite_key"):
			var key: String = child.get_meta("sprite_key")
			child.texture = load("res://tools/art/out/processed/%s.png" % key)
			child.scale = Vector2.ONE
			child.offset = Vector2(0, -child.texture.get_height() / 2.0)
