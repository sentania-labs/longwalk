extends RefCounted
class_name TownLayout

# TownLayout is the SIM-side data for the hand-authored starter town: a
# finite grid of ground tiles plus a handful of hand-placed buildings. It has
# zero dependency on Viewport, Camera, or any UI node and runs headless (see
# CLAUDE.md, "Simulation/rendering separation"). The render layer
# (src/render/town/starter_town.gd) reads this data to build the actual
# TileMap/sprite/collision scene; it never writes back into it.
#
# This is authored data, not generated: build_starter_town() below places
# every building and path tile by hand. There is no seed and no RNG call
# anywhere in this file. If a future dispatch reuses the parked
# src/legacy_procedural/macro_map.gd generator to draft a town layout before
# hand-curation, the determinism rule in CLAUDE.md still applies to that
# draft step, but nothing here depends on it.

const TILE_SIZE := 128

enum GroundTile { GRASS, PATH }

# Per-terrain movement cost, charged when a route ENTERS a cell (see
# NavGrid.find_path). PATH is cheaper than GRASS, so a route prefers roads;
# this is a preference, not a guarantee, because the weighting only makes grass
# 2.25x more expensive per cell, so a long enough road detour still loses to a
# short grass crossing (decision 006, point 4).
#
# LOAD-BEARING INVARIANT: every value here is >= MIN_TERRAIN_COST, and
# MIN_TERRAIN_COST is exactly 1.0. NavGrid multiplies its base step cost
# (ORTHOGONAL_COST / DIAGONAL_COST) by this terrain cost, while its
# octile_distance() heuristic assumes the unweighted base step. Because no
# terrain multiplier drops below 1.0, no edge is ever cheaper than that
# unweighted step, so the heuristic never overestimates and stays admissible
# and consistent untouched. If a future tuning drops any value below 1.0 (for
# example "make the road cheaper at 0.8"), that guarantee breaks silently: the
# search can then reopen closed cells and the determinism argument in
# nav_grid.gd's header no longer holds. test/active_path/test_nav_grid.gd pins
# this invariant so such a change reds the suite instead of passing quietly.
const MIN_TERRAIN_COST := 1.0
const TERRAIN_COST := {
	GroundTile.PATH: 1.0,
	GroundTile.GRASS: 2.25,
}

class BuildingPlacement:
	var id: String
	# Top-left grid cell of the building's footprint.
	var cell: Vector2i
	# Footprint size in tiles (width, height).
	var footprint: Vector2i
	# Key into the render layer's sprite lookup; empty for a reserved plot
	# that has no building sprite yet.
	var sprite_key: String
	# True for a plot reserved for a future NPC building (for example the
	# shopkeeper), not yet a placed structure. Reserved plots do not block
	# movement. See ROADMAP.md, "M3: starter-town prototype": NPCs and the
	# interactable shopkeeper are a following dispatch, not this one.
	var is_npc_placeholder: bool

	func _init(p_id: String, p_cell: Vector2i, p_footprint: Vector2i, p_sprite_key: String, p_is_npc_placeholder := false) -> void:
		id = p_id
		cell = p_cell
		footprint = p_footprint
		sprite_key = p_sprite_key
		is_npc_placeholder = p_is_npc_placeholder

	func front_center_cell() -> Vector2i:
		return Vector2i(cell.x + int(footprint.x / 2.0), cell.y + footprint.y)


# A generic authored placement for the inn-green district (decision 009). This
# is SEMANTIC placement data only: an id (the join key the render layer's asset
# manifest is keyed by), a semantic placement kind, the top-left footprint cell,
# the footprint size, and a collision policy (blocks). It is deliberately
# TEXTURE-IGNORANT and VIEWPORT-FREE (decision 009 item 4): no texture path, no
# anchor pixel, no screen coordinate, and no render category (no is_prop). The
# render layer (src/render/town/village_render.gd) joins this to
# res://assets/village/manifest.json by `id` and decides everything visual.
#
# `kind` is a SEMANTIC label (what the thing is: inn, cottage, tree, ...), not a
# render category. Non-blocking placements (trees, bushes, flowers, the
# foreground crown) carry blocks=false and never obstruct movement; they are
# still first-class authored entities here so the future ecology sim layer
# (CLAUDE.md) can reason about them without a render dependency.
class DistrictPlacement:
	var id: String
	var kind: String
	var cell: Vector2i
	var footprint: Vector2i
	var blocks: bool

	func _init(p_id: String, p_kind: String, p_cell: Vector2i, p_footprint: Vector2i, p_blocks: bool) -> void:
		id = p_id
		kind = p_kind
		cell = p_cell
		footprint = p_footprint
		blocks = p_blocks


var width: int
var height: int
# ground[y][x] -> GroundTile
var ground: Array
var buildings: Array[BuildingPlacement]
# Generic authored placements (inn-green district). Empty for the legacy
# starter town, which uses `buildings` above. See DistrictPlacement.
var placements: Array


func _init(p_width: int, p_height: int, p_ground: Array, p_buildings: Array[BuildingPlacement], p_placements: Array = []) -> void:
	width = p_width
	height = p_height
	ground = p_ground
	buildings = p_buildings
	placements = p_placements


func ground_tile_at(cell: Vector2i) -> int:
	return ground[cell.y][cell.x]


func terrain_cost_at(cell: Vector2i) -> float:
	return TERRAIN_COST[ground[cell.y][cell.x]]


func is_cell_in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < width and cell.y < height


func is_cell_blocked_by_building(cell: Vector2i) -> bool:
	for building in buildings:
		if building.is_npc_placeholder:
			continue
		if cell.x >= building.cell.x and cell.x < building.cell.x + building.footprint.x \
				and cell.y >= building.cell.y and cell.y < building.cell.y + building.footprint.y:
			return true
	for placement in placements:
		if not placement.blocks:
			continue
		if cell.x >= placement.cell.x and cell.x < placement.cell.x + placement.footprint.x \
				and cell.y >= placement.cell.y and cell.y < placement.cell.y + placement.footprint.y:
			return true
	return false


func is_cell_walkable(cell: Vector2i) -> bool:
	return is_cell_in_bounds(cell) and not is_cell_blocked_by_building(cell)


func pixel_size() -> Vector2:
	return Vector2(width * TILE_SIZE, height * TILE_SIZE)


static func _carve_path_to_street(ground: Array, building: BuildingPlacement, street_y: int) -> void:
	var front_x := building.cell.x + int(building.footprint.x / 2.0)
	var bottom_y := building.cell.y + building.footprint.y
	var top_y := building.cell.y - 1
	if bottom_y <= street_y:
		for y in range(bottom_y, street_y + 1):
			ground[y][front_x] = GroundTile.PATH
	else:
		for y in range(street_y, top_y + 1):
			ground[y][front_x] = GroundTile.PATH


static func build_starter_town() -> TownLayout:
	var width := 18
	var height := 14

	var ground: Array = []
	for y in range(height):
		var row: Array = []
		for x in range(width):
			row.append(GroundTile.GRASS)
		ground.append(row)

	# Main street: a horizontal path spine every building opens onto.
	var street_y := 7
	for x in range(width):
		ground[street_y][x] = GroundTile.PATH

	var buildings: Array[BuildingPlacement] = []

	var general_store := BuildingPlacement.new("general_store", Vector2i(7, 2), Vector2i(3, 2), "building_facade")
	buildings.append(general_store)
	_carve_path_to_street(ground, general_store, street_y)

	var cottage_a := BuildingPlacement.new("cottage_a", Vector2i(2, 3), Vector2i(2, 2), "cottage_facade")
	buildings.append(cottage_a)
	_carve_path_to_street(ground, cottage_a, street_y)

	var cottage_b := BuildingPlacement.new("cottage_b", Vector2i(13, 4), Vector2i(2, 2), "cottage_facade")
	buildings.append(cottage_b)
	_carve_path_to_street(ground, cottage_b, street_y)

	# Reserved plot for the shopkeeper's building. A following dispatch adds
	# the interactable shopkeeper NPC (see ROADMAP.md); this dispatch only
	# marks the spot so the layout has one ready-made. No NPC logic here.
	var shopkeeper_plot := BuildingPlacement.new("shopkeeper_plot", Vector2i(8, 9), Vector2i(2, 2), "", true)
	buildings.append(shopkeeper_plot)
	_carve_path_to_street(ground, shopkeeper_plot, street_y)

	return TownLayout.new(width, height, ground, buildings)


# ---------------------------------------------------------------------------
# Inn-green district (decision 009 item 9): the first buildable Two Rivers
# district. Authored SEMANTIC data only: a grid, a lane junction, and a set of
# DistrictPlacements (inn anchor + cottages + smithy + a large tree + fences +
# flowers + rocks + prop groups + a foreground crown). No player, no NPCs. The
# render layer joins each placement `id` to res://assets/village/manifest.json
# and owns every texture, anchor, and screen coordinate. This function stays
# viewport-free and texture-ignorant; it never imports a render or projection
# symbol. build_starter_town() above is left untouched.
#
# The `id`s here are the shared kit-ids that key the asset manifest. An id may
# repeat (there are several fence_section placements); the render layer derives
# a per-instance depth-sort key from the id plus the placement index, so the
# duplicate ids here stay a clean join key rather than a unique-name field.
static func build_inn_green_district() -> TownLayout:
	var width := 16
	var height := 14

	var ground: Array = []
	for y in range(height):
		var row: Array = []
		for x in range(width):
			row.append(GroundTile.GRASS)
		ground.append(row)

	# Lane junction: a horizontal lane and a vertical lane crossing near the
	# green's center. PATH is the lane terrain (render maps it to ground_lane).
	var lane_y := 8
	var lane_x := 8
	for x in range(width):
		ground[lane_y][x] = GroundTile.PATH
	for y in range(height):
		ground[y][lane_x] = GroundTile.PATH

	var placements: Array = []
	# Blocking structures.
	placements.append(DistrictPlacement.new("inn", "building_anchor", Vector2i(5, 2), Vector2i(4, 3), true))
	placements.append(DistrictPlacement.new("cottage_front", "cottage", Vector2i(2, 4), Vector2i(2, 2), true))
	placements.append(DistrictPlacement.new("cottage_rear", "cottage", Vector2i(12, 3), Vector2i(2, 2), true))
	placements.append(DistrictPlacement.new("smithy_cluster", "building", Vector2i(11, 10), Vector2i(3, 2), true))

	# Large tree (blocks its trunk footprint). Its overhanging crown is a
	# separate, separately-sorted foreground placement (kind "crown"), anchored
	# over the same ground so it can draw ABOVE everything without occluding the
	# trunk's own depth contact.
	placements.append(DistrictPlacement.new("tree_large", "tree", Vector2i(3, 10), Vector2i(2, 2), true))
	placements.append(DistrictPlacement.new("crown_foliage", "crown", Vector2i(2, 9), Vector2i(3, 3), false))

	# Non-blocking prop groups (>=5): bushes, a fence run, a sign at the
	# junction, rocks, and two flower clusters.
	placements.append(DistrictPlacement.new("bush_a", "bush", Vector2i(6, 11), Vector2i(1, 1), false))
	placements.append(DistrictPlacement.new("bush_b", "bush", Vector2i(10, 4), Vector2i(1, 1), false))
	placements.append(DistrictPlacement.new("fence_section", "fence", Vector2i(2, 6), Vector2i(1, 1), false))
	placements.append(DistrictPlacement.new("fence_section", "fence", Vector2i(3, 6), Vector2i(1, 1), false))
	placements.append(DistrictPlacement.new("fence_section", "fence", Vector2i(4, 6), Vector2i(1, 1), false))
	placements.append(DistrictPlacement.new("sign_post", "sign", Vector2i(9, 7), Vector2i(1, 1), false))
	placements.append(DistrictPlacement.new("rock_a", "rock", Vector2i(13, 12), Vector2i(1, 1), false))
	placements.append(DistrictPlacement.new("rock_b", "rock", Vector2i(1, 12), Vector2i(1, 1), false))
	placements.append(DistrictPlacement.new("flower_cluster_a", "flower", Vector2i(10, 6), Vector2i(1, 1), false))
	placements.append(DistrictPlacement.new("flower_cluster_b", "flower", Vector2i(14, 6), Vector2i(1, 1), false))

	return TownLayout.new(width, height, ground, [] as Array[BuildingPlacement], placements)
