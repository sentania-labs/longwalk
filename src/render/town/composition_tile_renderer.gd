extends RefCounted
class_name CompositionTileRenderer

# Render-side consumption of the CompositionKernel outputs for the Checkpoint B
# demo tile: takes the derived ground raster + derived flora instance set and
# composites the stylized cottage and flora on top, back-to-front, into one RGBA
# Image. This is the "does it read as built-on to Scott's eye" slice.
#
# The building and flora marks are drawn stylized-procedural (stem + bloom disc,
# a timber-and-roof cottage block) rather than stamped from the 1024x1024
# generation-source kits: the kits are building/flora CLUSTERS carrying a
# generation background, not single field sunflowers, and the offline proof is
# about the GROUND response and the field grammar, not the building art. Every
# mark is colored from the team's authored palette (below) and is a pure function
# of the derived instance record, so the composite stays deterministic and
# byte-stable. Divergence noted here and in the kernel for codex reconciliation.

const Kernel := preload("res://src/render/town/composition_kernel.gd")
const TEXELS_PER_CELL := Kernel.TEXELS_PER_CELL

# Authored field / structure palette (warm town look, from the manifest tonal
# targets and the spike ground plates).
const COL_STEM := Color(0.33, 0.42, 0.15)
const COL_LEAF := Color(0.30, 0.40, 0.14)
const COL_PETAL := Color(0.84, 0.70, 0.24)
const COL_PETAL_HI := Color(0.93, 0.82, 0.40)
const COL_CENTER := Color(0.31, 0.21, 0.11)
const COL_BUSH := Color(0.24, 0.32, 0.14)
const COL_BERRY := Color(0.62, 0.20, 0.22)
const COL_SHADOW := Color(0.0, 0.0, 0.0, 0.28)

const COL_STONE := Color(0.52, 0.50, 0.44)
const COL_STONE_DARK := Color(0.34, 0.32, 0.28)
const COL_WALL := Color(0.60, 0.44, 0.26)
const COL_WALL_HI := Color(0.68, 0.52, 0.33)
const COL_ROOF := Color(0.42, 0.24, 0.18)
const COL_ROOF_HI := Color(0.52, 0.31, 0.23)
const COL_DOOR := Color(0.18, 0.13, 0.10)
const COL_STEP := Color(0.58, 0.50, 0.38)


static func render_tile(snap: Kernel.TileSnapshot, age: int, traffic: float, disturbance: float) -> Image:
	return render_tile_canvas(snap, age, traffic, disturbance).to_image()


static func render_tile_canvas(snap: Kernel.TileSnapshot, age: int, traffic: float, disturbance: float) -> Kernel.Canvas:
	var image := Kernel.derive_ground_canvas(snap, age, traffic, disturbance)
	var flora: Array = Kernel.derive_flora(snap, age, traffic, disturbance)

	# Build one back-to-front draw list of buildings + flora so overlaps composite
	# correctly. The building's feet are its south base row; sort everything by
	# ground contact y (canonical, matches the kernel's flora sort).
	var drawables: Array = []
	for s in snap.structures:
		var feet_y := float(s.cell.y + s.footprint.y)
		drawables.append({"type": "building", "sort_y": feet_y, "struct": s})
	for f in flora:
		drawables.append({"type": "flora", "sort_y": f.pos.y, "flora": f})
	drawables.sort_custom(func(a, b): return a.sort_y < b.sort_y)

	for d in drawables:
		if d.type == "building":
			_draw_cottage(image, d.struct, age, traffic)
		else:
			_draw_flora(image, d.flora, traffic, disturbance)
	return image


static func _draw_flora(image: Kernel.Canvas, f: Dictionary, traffic: float, disturbance: float) -> void:
	var base: Vector2 = f.pos * float(TEXELS_PER_CELL)
	var size_px: float = f.size * float(TEXELS_PER_CELL)
	var h: int = f.hash
	match f.kind:
		"sunflower":
			_draw_sunflower(image, base, size_px, h)
		"bush":
			_draw_bush(image, base, size_px, h)
		_:
			_draw_tuft(image, base, size_px, h)


static func _draw_sunflower(image: Kernel.Canvas, base: Vector2, size_px: float, h: int) -> void:
	# Ground shadow.
	_fill_ellipse(image, base + Vector2(0.5, 0.6) * (size_px * 0.5), Vector2(size_px * 0.55, size_px * 0.28), COL_SHADOW)
	var stem_h := size_px * 2.1
	var top := base - Vector2(0.0, stem_h)
	var sway := (float(h % 17) / 17.0 - 0.5) * size_px * 0.5
	top.x += sway
	# Stem.
	_draw_stroke(image, base, top, maxf(1.0, size_px * 0.14), COL_STEM)
	# Two leaves.
	var mid := base.lerp(top, 0.5)
	_draw_stroke(image, mid, mid + Vector2(-size_px * 0.7, -size_px * 0.1), maxf(1.0, size_px * 0.16), COL_LEAF)
	_draw_stroke(image, mid, mid + Vector2(size_px * 0.7, -size_px * 0.05), maxf(1.0, size_px * 0.16), COL_LEAF)
	# Bloom: yellow petal ring + brown center + a highlight.
	var bloom_r := size_px * 0.62
	_fill_circle(image, top, bloom_r, COL_PETAL)
	_fill_circle(image, top - Vector2(bloom_r * 0.22, bloom_r * 0.22), bloom_r * 0.7, COL_PETAL_HI)
	_fill_circle(image, top, bloom_r * 0.48, COL_CENTER)


static func _draw_bush(image: Kernel.Canvas, base: Vector2, size_px: float, h: int) -> void:
	_fill_ellipse(image, base + Vector2(0.0, size_px * 0.35), Vector2(size_px * 0.8, size_px * 0.4), COL_SHADOW)
	var lobes := 3 + (h % 3)
	for i in range(lobes):
		var a := float(i) / float(lobes) * TAU + float(h % 7)
		var off := Vector2(cos(a), sin(a) * 0.6) * size_px * 0.5
		_fill_circle(image, base + Vector2(0.0, -size_px * 0.4) + off, size_px * 0.6, COL_BUSH)
	# A few berries on some bushes.
	if (h % 3) == 0:
		for i in range(3):
			var bh := (h >> (i * 3)) % 100
			var bp := base + Vector2((float(bh) / 100.0 - 0.5) * size_px, -size_px * (0.3 + float(bh % 7) / 12.0))
			_fill_circle(image, bp, maxf(1.0, size_px * 0.16), COL_BERRY)


static func _draw_tuft(image: Kernel.Canvas, base: Vector2, size_px: float, h: int) -> void:
	_fill_ellipse(image, base + Vector2(0.0, size_px * 0.2), Vector2(size_px * 0.55, size_px * 0.25), COL_SHADOW)
	var blades := 4 + (h % 4)
	for i in range(blades):
		var spread := (float(i) / float(maxi(blades - 1, 1)) - 0.5) * size_px * 1.1
		var tip := base + Vector2(spread * 0.8, -size_px * (1.0 + float((h >> i) % 5) / 8.0))
		_draw_stroke(image, base, tip, maxf(1.0, size_px * 0.12), COL_STEM)


# Stylized cottage: a stone base course at the footprint, a timber façade wall
# rising toward the viewer's away side, and a pitched roof. The south apron and
# door notch stay visible in front so the three-band ground response reads.
static func _draw_cottage(image: Kernel.Canvas, s: Kernel.StructureRecord, age: int, traffic: float) -> void:
	var x0 := float(s.cell.x) * TEXELS_PER_CELL
	var x1 := float(s.cell.x + s.footprint.x) * TEXELS_PER_CELL
	var y_south := float(s.cell.y + s.footprint.y) * TEXELS_PER_CELL
	var roof_top := float(s.cell.y) * TEXELS_PER_CELL
	var wall_h := 1.7 * TEXELS_PER_CELL
	var wall_top := y_south - wall_h

	# Stone base course, a low plinth at the very front of the footprint.
	_fill_rect(image, x0, y_south - TEXELS_PER_CELL * 0.35, x1, y_south, COL_STONE)
	_fill_rect(image, x0, y_south - TEXELS_PER_CELL * 0.14, x1, y_south, COL_STONE_DARK)

	# Timber façade.
	_fill_rect(image, x0, wall_top, x1, y_south - TEXELS_PER_CELL * 0.30, COL_WALL)
	_fill_rect(image, x0, wall_top, x1, wall_top + wall_h * 0.16, COL_WALL_HI)

	# Roof plane covering the footprint behind the façade, then a gable ridge
	# rising above the plot so the building reads as a pitched cottage rather than
	# a flat dark block.
	_fill_rect(image, x0 - 3.0, roof_top, x1 + 3.0, wall_top, COL_ROOF)
	var apex := Vector2((x0 + x1) * 0.5, roof_top - TEXELS_PER_CELL * 0.5)
	_fill_triangle(image, Vector2(x0 - 4.0, roof_top + 2.0), Vector2(x1 + 4.0, roof_top + 2.0), apex, COL_ROOF)
	_fill_triangle(image, Vector2(x0 - 4.0, roof_top + 2.0), apex, Vector2((x0 + x1) * 0.5, roof_top + 2.0), COL_ROOF_HI)
	# Ridge highlight down the roof plane.
	_fill_rect(image, x0 - 3.0, roof_top, (x0 + x1) * 0.5, roof_top + wall_h * 0.10, COL_ROOF_HI)

	# Door in the façade at the authored uv, with a light worn step.
	var door_cx := (float(s.cell.x) + s.door_uv.x * float(s.footprint.x)) * TEXELS_PER_CELL
	var door_w := TEXELS_PER_CELL * 0.7
	var door_h := wall_h * 0.62
	_fill_rect(image, door_cx - door_w * 0.5, y_south - TEXELS_PER_CELL * 0.30 - door_h, door_cx + door_w * 0.5, y_south - TEXELS_PER_CELL * 0.30, COL_DOOR)
	_fill_rect(image, door_cx - door_w * 0.6, y_south - TEXELS_PER_CELL * 0.30, door_cx + door_w * 0.6, y_south - TEXELS_PER_CELL * 0.10, COL_STEP)


# ---------------------------------------------------------------------------
# Primitive rasterizers with straight alpha compositing. Bounded pixel work;
# every call is a pure function of its arguments.
# ---------------------------------------------------------------------------
static func _blend(image: Kernel.Canvas, x: int, y: int, c: Color) -> void:
	image.blend(x, y, c)


static func _fill_rect(image: Kernel.Canvas, x0: float, y0: float, x1: float, y1: float, c: Color) -> void:
	for y in range(int(floor(minf(y0, y1))), int(ceil(maxf(y0, y1)))):
		for x in range(int(floor(minf(x0, x1))), int(ceil(maxf(x0, x1)))):
			_blend(image, x, y, c)


static func _fill_circle(image: Kernel.Canvas, center: Vector2, r: float, c: Color) -> void:
	var r2 := r * r
	for y in range(int(floor(center.y - r)), int(ceil(center.y + r))):
		for x in range(int(floor(center.x - r)), int(ceil(center.x + r))):
			var dx := float(x) + 0.5 - center.x
			var dy := float(y) + 0.5 - center.y
			if dx * dx + dy * dy <= r2:
				_blend(image, x, y, c)


static func _fill_ellipse(image: Kernel.Canvas, center: Vector2, radii: Vector2, c: Color) -> void:
	for y in range(int(floor(center.y - radii.y)), int(ceil(center.y + radii.y))):
		for x in range(int(floor(center.x - radii.x)), int(ceil(center.x + radii.x))):
			var dx := (float(x) + 0.5 - center.x) / maxf(radii.x, 0.001)
			var dy := (float(y) + 0.5 - center.y) / maxf(radii.y, 0.001)
			if dx * dx + dy * dy <= 1.0:
				_blend(image, x, y, c)


static func _draw_stroke(image: Kernel.Canvas, a: Vector2, b: Vector2, thickness: float, c: Color) -> void:
	var steps := int(ceil(a.distance_to(b))) + 1
	var r := maxf(thickness * 0.5, 0.5)
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		_fill_circle(image, a.lerp(b, t), r, c)


static func _fill_triangle(image: Kernel.Canvas, a: Vector2, b: Vector2, cc: Vector2, col: Color) -> void:
	var min_x := int(floor(min(a.x, min(b.x, cc.x))))
	var max_x := int(ceil(max(a.x, max(b.x, cc.x))))
	var min_y := int(floor(min(a.y, min(b.y, cc.y))))
	var max_y := int(ceil(max(a.y, max(b.y, cc.y))))
	for y in range(min_y, max_y):
		for x in range(min_x, max_x):
			var p := Vector2(float(x) + 0.5, float(y) + 0.5)
			if _point_in_triangle(p, a, b, cc):
				_blend(image, x, y, col)


static func _point_in_triangle(p: Vector2, a: Vector2, b: Vector2, c: Vector2) -> bool:
	var d1 := _edge_sign(p, a, b)
	var d2 := _edge_sign(p, b, c)
	var d3 := _edge_sign(p, c, a)
	var has_neg := (d1 < 0.0) or (d2 < 0.0) or (d3 < 0.0)
	var has_pos := (d1 > 0.0) or (d2 > 0.0) or (d3 > 0.0)
	return not (has_neg and has_pos)


static func _edge_sign(p: Vector2, a: Vector2, b: Vector2) -> float:
	return (p.x - b.x) * (a.y - b.y) - (a.x - b.x) * (p.y - b.y)
