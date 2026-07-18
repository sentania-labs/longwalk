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
const NavGridScript := preload("res://src/sim/nav_grid.gd")
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
	failures += _check(a.lanes.size() == b.lanes.size() and a.lanes.size() == 3, "authored lane count deterministic (%d)" % a.lanes.size())

	var ground_matches := true
	for y in range(a.height):
		for x in range(a.width):
			if a.ground[y][x] != b.ground[y][x]:
				ground_matches = false
	failures += _check(ground_matches, "district ground tiles deterministic")
	var lanes_match := true
	for i in range(a.lanes.size()):
		if a.lanes[i].points != b.lanes[i].points or a.lanes[i].half_widths != b.lanes[i].half_widths:
			lanes_match = false
	failures += _check(lanes_match, "fractional lane geometry deterministic")

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

	# Semantic lane invariants replace the old full-row/full-column cross.
	var junction := Vector2i(7, 7)
	var approaches: Array[Vector2i] = [Vector2i(3, 6), Vector2i(7, 5), Vector2i(13, 5), Vector2i(12, 9)]
	var entrances: Array[Vector2i] = [Vector2i(0, 8), Vector2i(15, 7), Vector2i(10, 0), Vector2i(9, 13)]
	failures += _check(a.ground_tile_at(junction) == TownLayoutScript.GroundTile.PATH, "lane junction has derived PATH")
	for cell in approaches:
		var route := NavGridScript.find_path(a, junction, cell)
		failures += _check(not route.is_empty(), "building approach %s connects to junction" % cell)
	for cell in entrances:
		var route := NavGridScript.find_path(a, junction, cell)
		failures += _check(not route.is_empty(), "district entrance %s is reachable" % cell)

	var no_path_under_blockers := true
	for p in a.placements:
		if not p.blocks:
			continue
		for yy in range(p.cell.y, p.cell.y + p.footprint.y):
			for xx in range(p.cell.x, p.cell.x + p.footprint.x):
				if a.ground_tile_at(Vector2i(xx, yy)) == TownLayoutScript.GroundTile.PATH:
					no_path_under_blockers = false
	failures += _check(no_path_under_blockers, "derived PATH never overlaps blocking footprints")

	# This is an actual A* preference assertion, not only PATH connectivity.
	var preferred := NavGridScript.find_path(a, approaches[0], approaches[2])
	var route_cost := _route_cost(a, preferred)
	var grass_steps := 0
	for cell in preferred.slice(1):
		if a.ground_tile_at(cell) == TownLayoutScript.GroundTile.GRASS:
			grass_steps += 1
	failures += _check(not preferred.is_empty() and grass_steps <= 1, "A* between cottage fronts stays on the curved lane (grass steps=%d)" % grass_steps)
	failures += _check(route_cost <= 15.0, "lane-preferred route has bounded weighted cost (%.3f <= 15.0)" % route_cost)

	var width_varies := false
	for lane in a.lanes:
		for half_width in lane.half_widths:
			if absf(half_width - lane.half_widths[0]) > 0.2:
				width_varies = true
	failures += _check(width_varies, "authored half-width varies along lanes")
	failures += _check_lane_mask_contract()

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


func _route_cost(layout, path: Array[Vector2i]) -> float:
	var cost := 0.0
	for i in range(1, path.size()):
		var delta := path[i] - path[i - 1]
		var base := NavGridScript.DIAGONAL_COST if delta.x != 0 and delta.y != 0 else NavGridScript.ORTHOGONAL_COST
		cost += base * layout.terrain_cost_at(path[i])
	return cost


func _check_lane_mask_contract() -> int:
	var failures := 0
	var mask := Image.load_from_file("res://assets/village/lane_mask.png")
	var density := Image.load_from_file("res://assets/village/lane_density.png")
	# PNG decoding may expand two-channel and grayscale sources. Convert back to
	# the baker's pre-upload formats before checking its Image-byte contract.
	mask.convert(Image.FORMAT_RG8)
	density.convert(Image.FORMAT_R8)
	failures += _check(mask.get_width() == 256 and mask.get_height() == 224, "lane mask is 16 texels per cell")
	failures += _check(density.get_size() == mask.get_size(), "lane density dimensions match mask")
	failures += _check(_sha256(mask.get_data()) == "7e26447ef141426311bcf13459779b54c25f211fabcdee4fc59532046f7df43d", "lane mask pre-upload bytes match fingerprint")
	failures += _check(_sha256(density.get_data()) == "eb2996df775e53ee16a25a400bcb89a8580c6c7c71c9cd834dffde52d88e5fc6", "lane density pre-upload bytes match fingerprint")
	var core_preserved := true
	for y in range(mask.get_height()):
		for x in range(mask.get_width()):
			var channels := mask.get_pixel(x, y)
			if channels.r > channels.g + 0.001:
				core_preserved = false
	failures += _check(core_preserved, "coverage and independent density never reduce protected core")
	return failures


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()


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
