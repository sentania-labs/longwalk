extends StaticBody3D
class_name TerrainChunk

# TerrainChunk builds ONE square patch of walkable terrain (mesh + collision)
# from the sim-side TerrainSampler. This is a RENDER-side module: it depends on
# the sim layer (one directional, allowed) but the sim layer never depends on
# it. All authoritative height/biome data comes from the sampler; this file
# only turns that data into Godot geometry.
#
# Floating origin: a chunk stores its logical world origin (the world-space
# position of its (0,0) corner, y unused) and is placed at
# `logical_origin - render_origin`. When the world rebases the origin, the
# chunk is repositioned without rebuilding its mesh (the geometry is in local
# space relative to the chunk corner).

const TerrainSamplerC := preload("res://src/legacy_procedural/sim/terrain_sampler.gd")

# Geometry of a chunk. CHUNK_SIZE is the side length in world units; RES is the
# number of quads per side (so there are RES + 1 vertices per side). A 48 unit
# chunk at RES 24 gives 2 world units between vertices, fine detail for walking.
const CHUNK_SIZE := 48.0
const RES := 24

# Biome vertex colors. These deliberately mirror the values in
# MacroMapGenerator.BIOME_COLORS (duplicated here rather than imported so the
# render side never reaches into generator internals) so the walkable 3D ground
# reads as the same biome the 2D macro map shows at that location. Each biome is
# a visibly distinct hue so terrain is legible while walking.
const BIOME_COLORS := {
	"ocean": Color8(30, 62, 120),
	"beach": Color8(214, 199, 140),
	"plains": Color8(126, 176, 92),
	"forest": Color8(52, 110, 58),
	"desert": Color8(211, 182, 108),
	"tundra": Color8(168, 178, 172),
	"mountain": Color8(122, 116, 110),
}

var chunk_coord: Vector2i
var logical_origin: Vector3

var _mesh_instance: MeshInstance3D


# Build the chunk geometry for the given chunk grid coordinate. `sampler` is the
# sim TerrainSampler; `render_origin` is the current floating-origin offset.
func build(sampler, coord: Vector2i, render_origin: Vector3) -> void:
	chunk_coord = coord
	logical_origin = Vector3(float(coord.x) * CHUNK_SIZE, 0.0, float(coord.y) * CHUNK_SIZE)

	var step := CHUNK_SIZE / float(RES)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Precompute the vertex grid (local positions + colors) so triangles can
	# reference shared samples. Heights are sampled at LOGICAL world positions so
	# the terrain is a pure function of (seed, position) regardless of origin.
	var verts: Array[Vector3] = []
	var colors: Array[Color] = []
	verts.resize((RES + 1) * (RES + 1))
	colors.resize((RES + 1) * (RES + 1))
	for gz in range(RES + 1):
		for gx in range(RES + 1):
			var lx := float(gx) * step
			var lz := float(gz) * step
			var wx := logical_origin.x + lx
			var wz := logical_origin.z + lz
			var h: float = sampler.height_at(wx, wz)
			var i := gz * (RES + 1) + gx
			verts[i] = Vector3(lx, h, lz)
			var biome: String = sampler.biome_at(wx, wz)
			colors[i] = BIOME_COLORS.get(biome, Color.MAGENTA)

	# Emit two triangles per quad. Godot treats clockwise-wound triangles (viewed
	# from the front) as front-facing, so this winding is the one that makes
	# generate_normals() produce UPWARD normals. The previous winding pointed the
	# normals down, which lit the terrain from underneath: from above the ground
	# showed only dim sky ambient and the biome vertex colors never read, so the
	# world looked like a featureless dark/brown expanse (Scott's report).
	for gz in range(RES):
		for gx in range(RES):
			var i00 := gz * (RES + 1) + gx
			var i10 := i00 + 1
			var i01 := i00 + (RES + 1)
			var i11 := i01 + 1
			_add_tri(st, verts, colors, i00, i11, i01)
			_add_tri(st, verts, colors, i00, i10, i11)

	st.generate_normals()

	var mesh := st.commit()

	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 1.0
	_mesh_instance.material_override = mat
	add_child(_mesh_instance)

	# Collision from the SAME height grid as the mesh, but as a HeightMapShape3D
	# rather than a triangle-soup (ConcavePolygonShape3D). A capsule CharacterBody
	# walking on a trimesh catches on the internal edges between triangles
	# ("ghost collisions"): the contact normal points sideways, is_on_floor never
	# latches, and the player wedges in place. A HeightMapShape3D is a dedicated
	# grid collider immune to that, and it samples exactly the vertex heights so
	# the player still walks on what is drawn.
	#
	# The shape is a unit-spaced grid centered on its origin, so it is scaled by
	# `step` to match the mesh's vertex spacing and shifted by half a chunk to put
	# its corner at the chunk's (0,0), lining collision up with the mesh.
	var hmap := HeightMapShape3D.new()
	hmap.map_width = RES + 1
	hmap.map_depth = RES + 1
	var heights := PackedFloat32Array()
	heights.resize((RES + 1) * (RES + 1))
	for i in range((RES + 1) * (RES + 1)):
		heights[i] = verts[i].y
	hmap.map_data = heights
	var collision := CollisionShape3D.new()
	collision.shape = hmap
	collision.scale = Vector3(step, 1.0, step)
	collision.position = Vector3(CHUNK_SIZE * 0.5, 0.0, CHUNK_SIZE * 0.5)
	add_child(collision)

	reposition(render_origin)


func _add_tri(st: SurfaceTool, verts: Array[Vector3], colors: Array[Color], a: int, b: int, c: int) -> void:
	st.set_color(colors[a])
	st.add_vertex(verts[a])
	st.set_color(colors[b])
	st.add_vertex(verts[b])
	st.set_color(colors[c])
	st.add_vertex(verts[c])


# Re-place the chunk for a (possibly shifted) render origin. Geometry is local
# to the chunk corner, so no rebuild is needed.
func reposition(render_origin: Vector3) -> void:
	position = logical_origin - render_origin
