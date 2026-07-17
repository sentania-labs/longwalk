extends SceneTree

const Fixture := preload("res://test/fixtures/player_world_fixture.gd")
const TownLayoutScript := preload("res://src/sim/town_layout.gd")
const PlayerScene := preload("res://scenes/player.tscn")


func _initialize() -> void:
	var failures := 0
	var layout = Fixture.build_layout()

	failures += _check(TownLayoutScript.TILE_SIZE == Fixture.TILE_SIZE, "fixture tile size matches TownLayout")
	failures += _check(Vector2i(layout.width, layout.height) == Fixture.LAYOUT_SIZE, "starter-town dimensions stay fixed")
	failures += _check(layout.pixel_size() == Vector2(Fixture.LAYOUT_SIZE * Fixture.TILE_SIZE), "starter-town pixel size follows the fixed scale")
	failures += _check(Fixture.SPAWN_WORLD_POSITION == Vector2(Fixture.SPAWN_CELL * Fixture.TILE_SIZE) + Vector2.ONE * Fixture.TILE_SIZE / 2.0, "spawn is the center of the shared spawn cell")
	failures += _check(layout.is_cell_walkable(Fixture.SPAWN_CELL), "shared spawn cell is walkable")

	var expected_buildings := {
		"general_store": [Vector2i(7, 2), Vector2i(3, 2), false],
		"cottage_a": [Vector2i(2, 3), Vector2i(2, 2), false],
		"cottage_b": [Vector2i(13, 4), Vector2i(2, 2), false],
		"shopkeeper_plot": [Vector2i(8, 9), Vector2i(2, 2), true],
	}
	failures += _check(layout.buildings.size() == expected_buildings.size(), "starter-town fixture keeps four authored placements")
	for building in layout.buildings:
		var expected = expected_buildings.get(building.id)
		failures += _check(expected != null, "starter-town fixture recognizes building '%s'" % building.id)
		if expected != null:
			failures += _check(building.cell == expected[0] and building.footprint == expected[1] and building.is_npc_placeholder == expected[2], "building '%s' keeps its cell and footprint" % building.id)

	var player := PlayerScene.instantiate()
	var sprite: Sprite2D = player.get_node("Sprite2D")
	var collider: CollisionShape2D = player.get_node("CollisionShape2D")
	var rect := collider.shape as RectangleShape2D
	failures += _check(sprite.centered, "player visual remains centered")
	failures += _check(sprite.offset == Fixture.SPRITE_OFFSET, "160 px visual ends at the feet origin")
	failures += _check(sprite.scale == Fixture.SHIPPING_DISPLAY_SCALE, "player visual ships at one-to-one scale")
	failures += _check(Fixture.FEET_CONTACT_ROW == Fixture.SPRITE_CELL_SIZE.y - 1, "feet contact is the final zero-based cell row")
	failures += _check(rect != null and rect.size == Vector2(36, 20), "player collider remains 36 by 20 pixels")
	failures += _check(collider.position == Vector2(0, -10), "player collider remains positioned relative to the feet origin")

	for variant in ["moss", "slate_blue", "burgundy"]:
		player.set_appearance(variant)
		failures += _check(sprite.texture != null, "appearance '%s' loads" % variant)
		if sprite.texture != null:
			failures += _check(sprite.texture.get_height() == Fixture.SPRITE_CELL_SIZE.y, "appearance '%s' keeps the 160 px shipping height" % variant)
			failures += _check(sprite.texture.get_width() == Fixture.SPRITE_CELL_SIZE.x, "appearance '%s' keeps the 160 px shipping width" % variant)
			var atlas_texture := sprite.texture as AtlasTexture
			failures += _check(atlas_texture != null, "appearance '%s' uses an atlas region" % variant)
			if atlas_texture != null:
				failures += _check(atlas_texture.atlas.get_size() == Vector2(640, 640), "appearance '%s' provides four facings and four frames" % variant)

	player.set_appearance("moss")
	for facing in range(4):
		player._facing = facing
		for frame in range(4):
			player._walk_frame = frame
			player._apply_walk_frame()
			var region: Rect2 = (sprite.texture as AtlasTexture).region
			failures += _check(region == Rect2(frame * 160, facing * 160, 160, 160), "facing %d frame %d selects its 160 px atlas cell" % [facing, frame])

	player._update_facing(Vector2.DOWN)
	failures += _check(player._facing == player.Facing.DOWN, "downward movement selects the down walk row")
	player._update_facing(Vector2.UP)
	failures += _check(player._facing == player.Facing.UP, "upward movement selects the up walk row")
	player._update_facing(Vector2.RIGHT)
	failures += _check(player._facing == player.Facing.RIGHT, "rightward movement selects the source side row")
	player._update_facing(Vector2.LEFT)
	failures += _check(player._facing == player.Facing.LEFT, "leftward movement selects the mirrored side row")
	player.free()

	if failures == 0:
		print("\nAll player/world contract checks passed.")
		quit(0)
	else:
		print("\n%d player/world contract check(s) FAILED." % failures)
		quit(1)


func _check(condition: bool, description: String) -> int:
	if condition:
		print("PASS: %s" % description)
		return 0
	push_error("FAIL: %s" % description)
	return 1
