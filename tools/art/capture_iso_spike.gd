extends SceneTree

# Five-layer early taste gate: ground reference, cast shadow, contact shadow,
# one building, and the accepted neutral player, composed by Godot.

const OUTPUT := "res://docs/art/iso-five-asset-spike.png"


func _initialize() -> void:
	call_deferred("_capture")


func _texture(path: String) -> ImageTexture:
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	return ImageTexture.create_from_image(image)


func _sprite(path: String, position: Vector2, centered := true) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = _texture(path)
	sprite.position = position
	sprite.centered = centered
	return sprite


func _capture() -> void:
	var scene := Node2D.new()
	root.add_child(scene)
	current_scene = scene

	var ground := _sprite("res://tools/art/out/iso/style_board.png", Vector2(576, 324))
	ground.scale = Vector2(0.65, 0.65)
	scene.add_child(ground)

	var cast := _sprite("res://tools/art/out/iso/processed/cottage_cast_shadow_rgba.png", Vector2(590, 430))
	cast.modulate = Color(0.08, 0.07, 0.05, 0.32)
	scene.add_child(cast)
	var contact := _sprite("res://tools/art/out/iso/processed/cottage_contact_shadow_rgba.png", Vector2(590, 430))
	contact.modulate = Color(0.04, 0.035, 0.025, 0.62)
	scene.add_child(contact)

	var building := _sprite("res://tools/art/out/iso/processed/cottage.png", Vector2(590, 430))
	scene.add_child(building)
	var player := _sprite("res://tools/art/out/iso/processed/player_neutral.png", Vector2(770, 475))
	scene.add_child(player)

	await process_frame
	await RenderingServer.frame_post_draw
	var capture := root.get_texture().get_image()
	var error := capture.save_png(ProjectSettings.globalize_path(OUTPUT))
	if error != OK:
		push_error("failed to save spike: %s" % error_string(error))
		quit(1)
		return
	print("wrote %s" % OUTPUT)
	quit(0)
