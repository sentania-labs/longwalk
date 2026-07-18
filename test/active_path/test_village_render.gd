extends SceneTree

# Headless test for the inn-green village district (decision 009): the no-PC /
# no-NPC free-cam render slice and its authored sim dataset. Asserts:
#   - build_inn_green_district() is deterministic authored data (constitution),
#     with the decision-009 item-9 census (inn anchor + >=2 cottages + tree +
#     lane junction + crown + >=5 prop groups) and correct blocking policy;
#   - every placement id joins to res://assets/village/manifest.json;
#   - the village scene boots headless with NO CharacterBody2D (no player) and
#     the camera rig starts in State.FREE with no follow target;
#   - the render layer builds a manifest-driven sprite per placement and lifts
#     the foreground crown above the depth-sorted world band.
#
# Invocation (run by tools/run_tests.sh):
#   godot --headless --script res://test/active_path/test_village_render.gd

const VillageScene := preload("res://scenes/village.tscn")
const VillageScript := preload("res://src/render/town/village_render.gd")
const TownLayoutScript := preload("res://src/sim/town_layout.gd")
const CameraRigScript := preload("res://src/render/town/camera_rig_2d.gd")


func _initialize() -> void:
	var failures := 0
	failures += _check_district_data()
	failures += _check_manifest_join()
	failures += _check_scene_boot()

	if failures == 0:
		print("\nAll village render checks passed.")
		quit(0)
	else:
		print("\n%d village render check(s) FAILED." % failures)
		quit(1)


func _check_district_data() -> int:
	var failures := 0
	var a: TownLayoutScript = TownLayoutScript.build_inn_green_district()
	var b: TownLayoutScript = TownLayoutScript.build_inn_green_district()

	failures += _check(a.width == b.width and a.height == b.height, "district dimensions deterministic")
	failures += _check(a.placements.size() == b.placements.size(), "district placement count deterministic (%d)" % a.placements.size())

	var ground_matches := true
	for y in range(a.height):
		for x in range(a.width):
			if a.ground[y][x] != b.ground[y][x]:
				ground_matches = false
	failures += _check(ground_matches, "district ground tiles deterministic")

	# Decision 009 item 9 census.
	var kinds := {}
	for p in a.placements:
		kinds[p.kind] = int(kinds.get(p.kind, 0)) + 1
	failures += _check(int(kinds.get("building_anchor", 0)) >= 1, "has an inn anchor")
	failures += _check(int(kinds.get("cottage", 0)) >= 2, "has >=2 cottages (%d)" % int(kinds.get("cottage", 0)))
	failures += _check(int(kinds.get("tree", 0)) >= 1, "has a large tree")
	failures += _check(int(kinds.get("crown", 0)) >= 1, "has a foreground crown")

	var prop_kinds := ["bush", "fence", "sign", "rock", "flower"]
	var prop_groups := 0
	for k in prop_kinds:
		if int(kinds.get(k, 0)) > 0:
			prop_groups += 1
	failures += _check(prop_groups >= 5, "has >=5 prop groups (%d)" % prop_groups)

	# A lane junction: at least one cell that is PATH on both a full row and a
	# full column crossing (the horizontal and vertical lanes meet).
	var has_junction := false
	for y in range(a.height):
		for x in range(a.width):
			if a.ground[y][x] == TownLayoutScript.GroundTile.PATH:
				var row_lane := true
				for xx in range(a.width):
					if a.ground[y][xx] != TownLayoutScript.GroundTile.PATH:
						row_lane = false
						break
				var col_lane := true
				for yy in range(a.height):
					if a.ground[yy][x] != TownLayoutScript.GroundTile.PATH:
						col_lane = false
						break
				if row_lane and col_lane:
					has_junction = true
	failures += _check(has_junction, "has a lane junction (crossing lanes)")

	# Blocking policy: a blocking placement's footprint is not walkable; a
	# non-blocking one (tree crown, props) does not obstruct.
	var blocking_blocks := true
	var nonblocking_clear := true
	for p in a.placements:
		var cell: Vector2i = p.cell
		if p.blocks:
			if a.is_cell_walkable(cell):
				blocking_blocks = false
		else:
			# Only meaningful where no OTHER blocker overlaps; the crown sits over
			# the tree trunk, so check a prop cell that no blocker covers.
			if p.kind == "flower" and not a.is_cell_walkable(cell):
				nonblocking_clear = false
	failures += _check(blocking_blocks, "blocking placements obstruct their footprint")
	failures += _check(nonblocking_clear, "non-blocking props do not obstruct movement")

	return failures


func _check_manifest_join() -> int:
	var failures := 0
	var manifest := VillageScript.load_manifest()
	failures += _check(not manifest.is_empty(), "manifest.json loads with objects (%d)" % manifest.size())
	var layout: TownLayoutScript = TownLayoutScript.build_inn_green_district()
	var all_joined := true
	var missing := ""
	for p in layout.placements:
		if not manifest.has(p.id):
			all_joined = false
			missing = p.id
	failures += _check(all_joined, "every placement id joins the manifest%s" % ("" if all_joined else " (missing '%s')" % missing))
	return failures


func _check_scene_boot() -> int:
	var failures := 0
	var village = VillageScene.instantiate()
	root.add_child(village)
	village._ready()

	# No player anywhere in the district scene (decision 009 item 5).
	failures += _check(not _has_character_body(village), "no CharacterBody2D in the district scene")

	var rig = village.camera_rig()
	failures += _check(rig != null, "camera rig built")
	if rig != null:
		failures += _check(rig._state == CameraRigScript.State.FREE, "camera starts in State.FREE")
		failures += _check(rig._player == null, "camera has no follow target")

	# Manifest-driven sprites: one per placement whose id is in the manifest.
	var world: Node2D = village.get_node("World")
	var sprite_count := 0
	var max_z := 0
	var crown_z := -1
	for child in world.get_children():
		if child is Sprite2D:
			sprite_count += 1
			max_z = maxi(max_z, child.z_index)
			if child.get_meta("kit_id", "") == "crown_foliage":
				crown_z = child.z_index
	failures += _check(sprite_count >= 12, "built manifest-driven sprites for the district (%d)" % sprite_count)
	failures += _check(crown_z == max_z and crown_z > 0, "foreground crown sorts above every world object (crown z=%d, max z=%d)" % [crown_z, max_z])

	village.free()
	return failures


func _has_character_body(node: Node) -> bool:
	if node is CharacterBody2D:
		return true
	for child in node.get_children():
		if _has_character_body(child):
			return true
	return false


func _check(condition: bool, label: String) -> int:
	if condition:
		print("[PASS] %s" % label)
		return 0
	print("[FAIL] %s" % label)
	return 1
