extends RefCounted
class_name SpawnFinder

# Preloaded rather than referenced by global class name so this module resolves
# in a headless `--script` run (the global class cache is only built by the
# editor). The alias avoids clashing with the MacroMapGenerator global name.
const MacroMapGen := preload("res://src/macro_map.gd")

# SpawnFinder chooses a deterministic spawn point for a given seed: a coastal
# land cell (a land cell 4-adjacent to an ocean cell) on the LARGEST landmass.
#
# This is a SIM-side module: it reads the macro map only through the public
# MacroMapGenerator API (elevation_at / biome_at) and has zero dependency on
# rendering or input. It runs headless.
#
# Determinism (see CLAUDE.md):
#   The land/ocean classification is a pure function of (seed, position). The
#   connected-component pass visits cells in a fixed row-major order and the
#   winning coastal cell is selected by a fixed tie-break (lowest row-major
#   index), so the chosen spawn is identical on every run for a fixed seed. No
#   RNG is involved.
#
# Topology (see CLAUDE.md):
#   The land mask wraps east-west (column 0 and column width-1 are neighbors)
#   and does not wrap north-south. The flood fill honors that.

var _generator: MacroMapGen
var width: int
var height: int


func _init(generator: MacroMapGen) -> void:
	_generator = generator
	width = generator.width
	height = generator.height


# A cell is land when its authoritative elevation is at or above sea level.
func _is_land(px: int, py: int) -> bool:
	return _generator.elevation_at(px, py) >= MacroMapGen.SEA_LEVEL


# Wrap a column east-west; clamp is not needed because callers keep py in range.
func _wrap_col(px: int) -> int:
	return ((px % width) + width) % width


# Build the land mask once (row-major, py * width + px). Pure function of seed.
func _build_land_mask() -> PackedByteArray:
	var mask := PackedByteArray()
	mask.resize(width * height)
	for py in range(height):
		for px in range(width):
			mask[py * width + px] = 1 if _is_land(px, py) else 0
	return mask


# Find the spawn point. Returns a Dictionary:
#   { "cell": Vector2i(px, py), "landmass_size": int, "found": bool }
# `found` is false only for a degenerate all-ocean map, in which case `cell`
# falls back to the map center so callers still get a usable position.
func find_spawn() -> Dictionary:
	var mask := _build_land_mask()
	var total := width * height

	# Labels: -1 = unvisited land or ocean sentinel handled via mask, otherwise
	# the component id. component_size[id] tracks each component's cell count.
	var component := PackedInt32Array()
	component.resize(total)
	component.fill(-1)

	var component_size: Array[int] = []
	var next_id := 0

	# Iterative 4-connected flood fill with east-west wrap, north-south clamp.
	var stack := PackedInt32Array()
	for py in range(height):
		for px in range(width):
			var idx := py * width + px
			if mask[idx] == 0 or component[idx] != -1:
				continue
			# New component: BFS/DFS from here.
			var id := next_id
			next_id += 1
			var size := 0
			stack.clear()
			stack.push_back(idx)
			component[idx] = id
			while not stack.is_empty():
				var cur := stack[stack.size() - 1]
				stack.remove_at(stack.size() - 1)
				size += 1
				var cx := cur % width
				var cy := cur / width
				# Four neighbors: east/west wrap, north/south clamp (no wrap).
				var neighbors := [
					_wrap_col(cx - 1) + cy * width,
					_wrap_col(cx + 1) + cy * width,
				]
				if cy > 0:
					neighbors.append(cx + (cy - 1) * width)
				if cy < height - 1:
					neighbors.append(cx + (cy + 1) * width)
				for n in neighbors:
					if mask[n] == 1 and component[n] == -1:
						component[n] = id
						stack.push_back(n)
			component_size.append(size)

	if next_id == 0:
		# Degenerate all-ocean map: fall back to the map center.
		return {
			"cell": Vector2i(width / 2, height / 2),
			"landmass_size": 0,
			"found": false,
		}

	# Largest landmass by cell count. Ties break to the lowest component id,
	# which is the one whose first cell has the lowest row-major index, so the
	# choice is deterministic.
	var best_id := 0
	var best_size := component_size[0]
	for id in range(1, next_id):
		if component_size[id] > best_size:
			best_size = component_size[id]
			best_id = id

	# Coastal cell on the largest landmass: a land cell of best_id that is
	# 4-adjacent to ocean. Scan row-major and take the first, so the pick is
	# deterministic. Falls back to the first cell of the component if somehow no
	# coastal cell is found (a landmass with no ocean neighbor cannot happen for
	# a real map, but the guard keeps the function total).
	var fallback := Vector2i(-1, -1)
	for py in range(height):
		for px in range(width):
			var idx := py * width + px
			if component[idx] != best_id:
				continue
			if fallback.x < 0:
				fallback = Vector2i(px, py)
			if _has_ocean_neighbor(mask, px, py):
				return {
					"cell": Vector2i(px, py),
					"landmass_size": best_size,
					"found": true,
				}

	return {
		"cell": fallback,
		"landmass_size": best_size,
		"found": true,
	}


# True if any 4-neighbor of (px, py) is ocean. East-west wraps, north-south
# treats the hard poles as ocean-free edges (an edge cell can still be coastal
# via its in-bounds neighbors).
func _has_ocean_neighbor(mask: PackedByteArray, px: int, py: int) -> bool:
	if mask[_wrap_col(px - 1) + py * width] == 0:
		return true
	if mask[_wrap_col(px + 1) + py * width] == 0:
		return true
	if py > 0 and mask[px + (py - 1) * width] == 0:
		return true
	if py < height - 1 and mask[px + (py + 1) * width] == 0:
		return true
	return false
