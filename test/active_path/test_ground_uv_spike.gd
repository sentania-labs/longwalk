extends SceneTree

# Coordinate spike for the continuous ground quad (decision 010 step 1, the
# mandated proof). The ground plane is ONE mesh whose UV array is set to the CELL
# corners of its projected-diamond vertices, so the fragment shader receives
# fractional CELL space by affine interpolation with no per-frame screen->iso
# inversion. This test proves that construction is geometrically sound BEFORE the
# UV mapping is called low-risk:
#
#   - it exercises the REAL geometry (VillageRender.ground_quad_geometry, the same
#     static _build_ground() builds the mesh from), not a copy;
#   - it reconstructs the two triangles and their per-vertex CELL uvs, projects a
#     dense set of known cell points (corners, per-cell centers, and points ON the
#     shared v0->v2 diagonal) to screen through Iso.cell_to_screen, interpolates
#     the UV back via barycentric coordinates within the containing triangle, and
#     asserts the recovered UV equals the original cell within a tight bound;
#   - it specifically bounds the coordinate error ACROSS THE SHARED DIAGONAL by
#     interpolating each diagonal sample from BOTH triangles and asserting they
#     agree (a triangulation seam would show up here).
#
# Because Iso.cell_to_screen is a linear map, the projected cell rectangle is a
# parallelogram and UV interpolation is globally affine, so the recovered error
# is float-precision only. A regression that reorders vertices, mismatches the UV
# assignment, or picks a non-shared diagonal breaks this.
#
# Invocation (run by tools/run_tests.sh):
#   godot --headless --script res://test/active_path/test_ground_uv_spike.gd

const VillageRender := preload("res://src/render/town/village_render.gd")
const Iso := preload("res://src/render/iso/projection.gd")

# Tight tolerance in CELL units. The verts round-trip through a float32
# PackedVector2Array, so the residual is float precision, not method error.
const EPS := 0.01


func _initialize() -> void:
	var failures := 0
	# The shipping district plus a couple of odd sizes so the proof is not
	# accidental to 16x14 (asymmetric, and a degenerate-thin strip).
	for size in [Vector2i(16, 14), Vector2i(9, 5), Vector2i(3, 11)]:
		failures += _check_size(size.x, size.y)

	if failures == 0:
		print("\nAll ground UV spike checks passed.")
		quit(0)
	else:
		print("\n%d ground UV spike check(s) FAILED." % failures)
		quit(1)


func _check_size(width: int, height: int) -> int:
	var failures := 0
	var geo := VillageRender.ground_quad_geometry(width, height)
	var verts: PackedVector2Array = geo["verts"]
	var uvs: PackedVector2Array = geo["uvs"]
	var indices: PackedInt32Array = geo["indices"]

	# Structural: 4 corners, 2 triangles sharing the (0,0)->(w,h) diagonal.
	var ok_struct := verts.size() == 4 and uvs.size() == 4 and indices.size() == 6
	ok_struct = ok_struct and indices[0] == 0 and indices[1] == 1 and indices[2] == 2
	ok_struct = ok_struct and indices[3] == 0 and indices[4] == 2 and indices[5] == 3
	failures += _check(ok_struct, "%dx%d: quad is 4 corners + 2 tris on the shared 0-2 diagonal" % [width, height])
	# UVs are exactly the cell corners of the grid.
	var ok_uv := uvs[0] == Vector2(0, 0) and uvs[1] == Vector2(width, 0) \
			and uvs[2] == Vector2(width, height) and uvs[3] == Vector2(0, height)
	failures += _check(ok_uv, "%dx%d: UV array equals the grid cell corners" % [width, height])

	# Triangle A = (v0,v1,v2), triangle B = (v0,v2,v3).
	var w := float(width)
	var h := float(height)

	# --- interior sample: every cell center, routed to its containing triangle ---
	var max_err := 0.0
	for y in range(height):
		for x in range(width):
			var cell := Vector2(float(x) + 0.5, float(y) + 0.5)
			var screen := Iso.cell_to_screen(cell)
			# Side of the diagonal: x*h - y*w >= 0 -> triangle A, else B.
			var recovered: Vector2
			if cell.x * h - cell.y * w >= 0.0:
				recovered = _bary_uv(screen, verts[0], verts[1], verts[2], uvs[0], uvs[1], uvs[2])
			else:
				recovered = _bary_uv(screen, verts[0], verts[2], verts[3], uvs[0], uvs[2], uvs[3])
			max_err = maxf(max_err, (recovered - cell).length())
	failures += _check(max_err < EPS, "%dx%d: cell centers recover to CELL space (max err %.6f)" % [width, height, max_err])

	# --- corners recover exactly ---
	var corner_err := 0.0
	var corner_cells := [Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)]
	for cell in corner_cells:
		var screen := Iso.cell_to_screen(cell)
		var use_a: bool = cell.x * h - cell.y * w >= 0.0
		var recovered: Vector2
		if use_a:
			recovered = _bary_uv(screen, verts[0], verts[1], verts[2], uvs[0], uvs[1], uvs[2])
		else:
			recovered = _bary_uv(screen, verts[0], verts[2], verts[3], uvs[0], uvs[2], uvs[3])
		corner_err = maxf(corner_err, (recovered - cell).length())
	failures += _check(corner_err < EPS, "%dx%d: outer corners recover to CELL space (max err %.6f)" % [width, height, corner_err])

	# --- shared diagonal: both triangles must agree along the seam ---
	var seam_err := 0.0
	var cross_err := 0.0
	for i in range(21):
		var t := float(i) / 20.0
		var cell := Vector2(t * w, t * h)
		var screen := Iso.cell_to_screen(cell)
		var from_a := _bary_uv(screen, verts[0], verts[1], verts[2], uvs[0], uvs[1], uvs[2])
		var from_b := _bary_uv(screen, verts[0], verts[2], verts[3], uvs[0], uvs[2], uvs[3])
		seam_err = maxf(seam_err, (from_a - from_b).length())
		cross_err = maxf(cross_err, maxf((from_a - cell).length(), (from_b - cell).length()))
	failures += _check(seam_err < EPS, "%dx%d: both triangles agree across the shared diagonal (max gap %.6f)" % [width, height, seam_err])
	failures += _check(cross_err < EPS, "%dx%d: diagonal samples recover to CELL space (max err %.6f)" % [width, height, cross_err])

	return failures


# Barycentric interpolation of the per-vertex UVs at point p inside triangle
# (a,b,c). This mirrors the GPU's affine attribute interpolation, so it proves
# what the fragment shader will actually see for UV.
func _bary_uv(p: Vector2, a: Vector2, b: Vector2, c: Vector2, ua: Vector2, ub: Vector2, uc: Vector2) -> Vector2:
	var v0 := b - a
	var v1 := c - a
	var v2 := p - a
	var d00 := v0.dot(v0)
	var d01 := v0.dot(v1)
	var d11 := v1.dot(v1)
	var d20 := v2.dot(v0)
	var d21 := v2.dot(v1)
	var denom := d00 * d11 - d01 * d01
	var v := (d11 * d20 - d01 * d21) / denom
	var w := (d00 * d21 - d01 * d20) / denom
	var u := 1.0 - v - w
	return ua * u + ub * v + uc * w


func _check(condition: bool, label: String) -> int:
	if condition:
		print("[PASS] %s" % label)
		return 0
	print("[FAIL] %s" % label)
	return 1
