extends SceneTree

# Headless smoke test for the M3 starter-town prototype boot flow: title
# screen -> character creation -> starter town. It instantiates every scene
# in this dispatch and asserts the sim-side town layout (src/sim/town_layout.gd)
# and the render layer built from it are sane, headless, no display server.
#
# Invocation (run by tools/run_tests.sh):
#   godot --headless --script res://test/active_path/test_boot_flow.gd

const TitleScreenScene := preload("res://scenes/title_screen.tscn")
const CharacterCreationScene := preload("res://scenes/character_creation.tscn")
const StarterTownScene := preload("res://scenes/starter_town.tscn")
const PlayerScene := preload("res://scenes/player.tscn")
const TownLayoutScript := preload("res://src/sim/town_layout.gd")


func _initialize() -> void:
	var failures := 0

	failures += _check_town_layout()
	failures += _check_scene_instantiates(TitleScreenScene, "title_screen.tscn", Control)
	failures += _check_scene_instantiates(CharacterCreationScene, "character_creation.tscn", Control)
	failures += _check_player_scene()
	failures += _check_starter_town_boot()

	if failures == 0:
		print("\nAll boot flow smoke checks passed.")
		quit(0)
	else:
		print("\n%d boot flow smoke check(s) FAILED." % failures)
		quit(1)


# TownLayout is authored data (see CLAUDE.md determinism rule): building the
# same starter town twice must produce identical, sane data with no RNG
# anywhere in the path.
func _check_town_layout() -> int:
	var failures := 0
	var layout_a: TownLayoutScript = TownLayoutScript.build_starter_town()
	var layout_b: TownLayoutScript = TownLayoutScript.build_starter_town()

	failures += _check(layout_a.width == layout_b.width and layout_a.height == layout_b.height, "town layout dimensions are deterministic")
	failures += _check(layout_a.buildings.size() >= 3 and layout_a.buildings.size() <= 6, "town has 3 to 6 buildings/plots (%d)" % layout_a.buildings.size())

	var ground_matches := true
	for y in range(layout_a.height):
		for x in range(layout_a.width):
			if layout_a.ground[y][x] != layout_b.ground[y][x]:
				ground_matches = false
	failures += _check(ground_matches, "town ground tiles are deterministic")

	# Every building's footprint must be fully in bounds and walkable cells
	# must exclude it (except reserved NPC plots, which do not block).
	var footprints_ok := true
	for building in layout_a.buildings:
		for dy in range(building.footprint.y):
			for dx in range(building.footprint.x):
				var cell := Vector2i(building.cell.x + dx, building.cell.y + dy)
				if not layout_a.is_cell_in_bounds(cell):
					footprints_ok = false
				if not building.is_npc_placeholder and layout_a.is_cell_walkable(cell):
					footprints_ok = false
	failures += _check(footprints_ok, "building footprints are in bounds and block walkability")

	var shopkeeper_plot_walkable := true
	for building in layout_a.buildings:
		if building.is_npc_placeholder:
			var cell := building.cell
			if not layout_a.is_cell_walkable(cell):
				shopkeeper_plot_walkable = false
	failures += _check(shopkeeper_plot_walkable, "reserved NPC plot does not block movement")

	return failures


func _check_scene_instantiates(scene: PackedScene, label: String, expected_type) -> int:
	var failures := 0
	failures += _check(scene != null, "%s loads" % label)
	if scene == null:
		return failures
	var instance := scene.instantiate()
	failures += _check(instance != null and is_instance_of(instance, expected_type), "%s instantiates as %s" % [label, expected_type])
	if instance != null:
		instance.free()
	return failures


func _check_player_scene() -> int:
	var failures := 0
	var player := PlayerScene.instantiate()
	failures += _check(player != null and player is CharacterBody2D, "player.tscn instantiates as CharacterBody2D")
	if player != null:
		player.set_appearance("moss")
		var sprite: Sprite2D = player.get_node("Sprite2D")
		failures += _check(sprite.texture != null, "player appearance texture loads")
		player.free()
	return failures


# Boots the starter town the same way the parked M2 smoke test boots
# game_main (see test/legacy_procedural/test_game_smoke.gd): calling _ready()
# directly rather than relying on add_child()-triggered tree entry. A node
# manually added to `root` during a --script SceneTree's _initialize is not
# treated as "inside the active scene tree" by Godot the way a real game
# boot's tree is, so tree-relative lookups like the GameState autoload
# (res://src/render/town/starter_town.gd's get_node("/root/GameState"))
# would silently fail here even though the same code works in normal play.
# Setting character_name/appearance_variant directly, as character creation's
# handoff would via GameState, sidesteps that without touching the autoload.
#
# This is safe for the @onready child references _ready() also uses
# (_ground_layer, _world, _boundary, _name_label): GDScript compiles
# @onready initializers into the start of the generated _ready() function
# itself, they are not a separate engine-triggered hook, and those
# initializers only need the child nodes to exist (true immediately after
# instantiate(), since a PackedScene's whole node hierarchy is built up
# front) rather than needing tree membership. Verified empirically: every
# check below (building bodies built, player spawned, 4 boundary walls,
# name label set) passes, which would be impossible if these were still
# null.
func _check_starter_town_boot() -> int:
	var failures := 0
	var town := StarterTownScene.instantiate()
	town.character_name = "Test Traveler"
	town.appearance_variant = "moss"
	town._ready()

	var world: Node2D = town.get_node("World")
	var building_bodies := 0
	var player_found := false
	var cottage_sprites := 0
	var cottage_smoke := 0
	var cottage_primitive_smoke := 0
	var smoke_on_other_facades := 0
	for child in world.get_children():
		if child is StaticBody2D:
			building_bodies += 1
		if child is CharacterBody2D:
			player_found = true
		if child is Sprite2D:
			var sprite_key: String = child.get_meta("sprite_key", "")
			var smoke := child.get_node_or_null("ChimneySmoke")
			if sprite_key == "cottage_facade":
				cottage_sprites += 1
				if smoke is CPUParticles2D and smoke.position == town.COTTAGE_SMOKE_OFFSET:
					cottage_smoke += 1
					if smoke.texture is GradientTexture2D:
						cottage_primitive_smoke += 1
			elif smoke != null:
				smoke_on_other_facades += 1

	failures += _check(building_bodies > 0, "starter town built building collision bodies (%d)" % building_bodies)
	failures += _check(player_found, "starter town spawned the player")
	failures += _check(cottage_sprites == 2, "starter town built 2 cottage sprites (%d)" % cottage_sprites)
	failures += _check(cottage_smoke == cottage_sprites, "each cottage has CPU smoke at the shared render offset (%d/%d)" % [cottage_smoke, cottage_sprites])
	failures += _check(cottage_primitive_smoke == cottage_sprites, "each cottage smoke emitter uses a Godot gradient primitive (%d/%d)" % [cottage_primitive_smoke, cottage_sprites])
	failures += _check(smoke_on_other_facades == 0, "non-cottage facades have no chimney smoke")

	var boundary: Node2D = town.get_node("Boundary")
	failures += _check(boundary.get_child_count() == 4, "starter town built 4 boundary walls (%d)" % boundary.get_child_count())

	var name_label: Label = town.get_node("UI/NameLabel")
	failures += _check(name_label.text == "Test Traveler", "starter town shows the character name")

	town.free()
	return failures


func _check(condition: bool, label: String) -> int:
	if condition:
		print("[PASS] %s" % label)
		return 0
	print("[FAIL] %s" % label)
	return 1
