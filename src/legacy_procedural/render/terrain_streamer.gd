extends Node3D
class_name TerrainStreamer

# TerrainStreamer keeps a modest radius of TerrainChunks loaded around the
# player and frees chunks that fall outside that radius as the player moves.
# This is the M2 "streamed radius" (full planet-scale streaming is M3). It is a
# RENDER-side module.
#
# Chunks are keyed by integer chunk coordinate. The player's LOGICAL position
# (origin-independent) decides which chunk coordinates should be resident, so
# streaming is stable across floating-origin rebases.

const TerrainChunkScript := preload("res://src/legacy_procedural/render/terrain_chunk.gd")

# How many chunks out from the player's chunk to keep loaded, in each direction.
# Radius 3 gives a 7x7 block of loaded chunks (about 336 world units across at
# the default 48 unit chunk size), enough to walk around on for M2.
const CHUNK_RADIUS := 3

var _sampler
var _chunks := {}          # Vector2i -> TerrainChunk
var _current_center := Vector2i(2147483647, 2147483647)  # force first update


func setup(sampler) -> void:
	_sampler = sampler


# Chunk coordinate containing a logical world position.
func _chunk_coord_for(logical_pos: Vector3) -> Vector2i:
	var cx := int(floor(logical_pos.x / TerrainChunkScript.CHUNK_SIZE))
	var cz := int(floor(logical_pos.z / TerrainChunkScript.CHUNK_SIZE))
	return Vector2i(cx, cz)


# Ensure the right chunks are loaded for the player's logical position, building
# new ones and freeing far ones. Only does work when the player crosses a chunk
# boundary. Returns true if the resident set changed.
func update_streaming(logical_pos: Vector3, render_origin: Vector3) -> bool:
	var center := _chunk_coord_for(logical_pos)
	if center == _current_center:
		return false
	_current_center = center

	# Load any missing chunks in range.
	for dz in range(-CHUNK_RADIUS, CHUNK_RADIUS + 1):
		for dx in range(-CHUNK_RADIUS, CHUNK_RADIUS + 1):
			var coord := Vector2i(center.x + dx, center.y + dz)
			if not _chunks.has(coord):
				var chunk = TerrainChunkScript.new()
				add_child(chunk)
				chunk.build(_sampler, coord, render_origin)
				_chunks[coord] = chunk

	# Free chunks outside the radius (Chebyshev distance).
	var to_remove: Array = []
	for coord in _chunks.keys():
		if abs(coord.x - center.x) > CHUNK_RADIUS or abs(coord.y - center.y) > CHUNK_RADIUS:
			to_remove.append(coord)
	for coord in to_remove:
		_chunks[coord].queue_free()
		_chunks.erase(coord)

	return true


# Reposition every resident chunk after a floating-origin rebase.
func reposition_all(render_origin: Vector3) -> void:
	for coord in _chunks.keys():
		_chunks[coord].reposition(render_origin)


# Sample the ground height at a logical world position (used to seat the player
# on spawn). Delegates to the sim sampler so it agrees with the built mesh.
func ground_height(wx: float, wz: float) -> float:
	return _sampler.height_at(wx, wz)


func loaded_chunk_count() -> int:
	return _chunks.size()
