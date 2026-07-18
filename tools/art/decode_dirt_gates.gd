extends SceneTree

# Numeric decode harness for the decision-012 dirt composite gates (claude's
# render slice). This is a DEV tool, not shipping game code: it lives under
# tools/art/ (never packed into the game asset path) and is allowed to read the
# committed PNGs directly, exactly like the bake tools do. It does NOT eyeball a
# capture; it reproduces ground.gdshader's fragment math over the committed
# grass/dirt/dirt_detail plates and the baked lane_mask/lane_density, then
# decodes the three ratified gates:
#
#   Gate 1 (#1 structure): mean spatial luminance gradient (bytes) of the
#     rendered CLEAN dirt crop, i.e. solid shoulder dirt (dirt_amount high,
#     off the protected core, where the full R high-frequency band applies).
#     Target >= 8.0 (from ~4.5 pre-composite; spike ~11.7). The protected core
#     is reported separately and is expected to stay LOW-gradient (it only ever
#     receives the broad G drift, the honesty ruling).
#   Gate 2 (#2 transition): perpendicular 0.2->0.8 dirt_amount rise span across
#     unobstructed lane edges, in cell units and screen pixels at 1x, plus a
#     non-monotone-isoline check (the edge-break makes the 0.5 crossing wander,
#     it is not a 1-2px step).
#   Gate 3 (#3 coverage): dirt-area fraction (dirt_amount >= 0.5) over the whole
#     unobstructed district ground. Target grass-dominant (< 0.5).
#
# The evaluation grid is the 1024x1024 plate resolution, which is ~1:1 with 1x
# screen pixels along the district (see docs/art/village/ground-plate-note.md:
# ~1145 px across 16 cells at 1x, ~0.9 screen px per plate texel), so a
# per-texel gradient reads as bytes per ~screen-pixel at 1x. Perpendicular
# cell-axis spans convert to screen pixels at 1x by sqrt(64^2 + 32^2) = 71.55
# px/cell (the iso cell_to_screen scale, TILE_W 128 / TILE_H 64).
#
# It is capture-independent and occlusion-free by construction (it never places
# a building or a shadow), which is exactly Gate 3's "unobstructed ground-only"
# requirement.
#
# CAVEAT: the Gate 1 gradient here is measured at NATIVE plate resolution. The
# real render minifies the plate under the iso projection with base-level
# bilinear (no committed mips), which smooths the very-high-frequency R detail,
# so the AUTHORITATIVE rendered Gate 1 (a curated dirt crop on the actual
# capture) is materially LOWER than this native proxy. See
# tools/art/capture_ground_only.gd for the ground-only rendered captures the
# rendered Gate 1 is decoded from. Gate 3 (coverage) and Gate 2 (isoline shape)
# are resolution-robust and read the same either way.

const GRID := 1024
const GRID_SIZE := Vector2(16.0, 14.0)
const PX_PER_CELL_1X := 71.55  # sqrt(64^2 + 32^2), axis-aligned perpendicular
# CanvasModulate grade applied by village_render.gd (_ready). Folded in so the
# decoded gradient matches the graded rendered capture, not the raw plate.
const GRADE := Vector3(1.0, 0.95, 0.88)

# Shader defaults MIRRORED from ground.gdshader. Keep in sync; the sweep below
# lets me pick the committed values before pasting them back into the shader.
const CORE_LO := 0.35
const CORE_HI := 0.65
const SHOULDER_LO := 0.03
const SHOULDER_MID := 0.30
const SHOULDER_HI := 0.60
const DENSITY_CONTRAST := 0.5
const TONE_CONTRAST := 0.16
const DETAIL_SHOULDER_AMP := 0.40
const DETAIL_CORE_AMP := 0.11
const EDGE_BREAK_AMP := 0.20
const EDGE_BREAK_OFFSET := Vector2(0.041, 0.067)

var _grass_lum := PackedFloat32Array()
var _dirt_r := PackedFloat32Array()
var _dirt_g := PackedFloat32Array()
var _dirt_b := PackedFloat32Array()
var _detail_r := PackedFloat32Array()
var _detail_g := PackedFloat32Array()
var _edge_r := PackedFloat32Array()
var _core := PackedFloat32Array()
var _shoulder := PackedFloat32Array()
var _density := PackedFloat32Array()


func _init() -> void:
	_cache_fields()
	print("=== decision-012 dirt gate decode (grid %dx%d ~= 1x screen px) ===" % [GRID, GRID])
	_report(DETAIL_SHOULDER_AMP, DETAIL_CORE_AMP, EDGE_BREAK_AMP, SHOULDER_LO, SHOULDER_MID, SHOULDER_HI)

	print("\n--- Gate 1 sweep: shoulder-dirt gradient vs detail_shoulder_amp ---")
	for amp in [0.10, 0.14, 0.18, 0.22, 0.26, 0.30]:
		var g := _shoulder_dirt_gradient(amp)
		print("  detail_shoulder_amp=%.2f -> clean dirt gradient %.2f bytes" % [amp, g])

	print("\n--- Gate 3 sweep: coverage vs shoulder feather (amp fixed) ---")
	for hi in [0.55, 0.60, 0.65, 0.72]:
		var cov := _coverage(EDGE_BREAK_AMP, SHOULDER_LO, SHOULDER_MID, hi)
		print("  shoulder_hi=%.2f -> dirt fraction %.4f" % [hi, cov])
	quit(0)


func _cache_fields() -> void:
	var grass := _load("res://assets/village/ground_grass_plate.png")
	var dirt := _load("res://assets/village/ground_dirt_plate.png")
	var detail := _load("res://assets/village/ground_dirt_detail.png")
	var mask := _load("res://assets/village/lane_mask.png")
	var density := _load("res://assets/village/lane_density.png")
	grass.convert(Image.FORMAT_RGB8)
	dirt.convert(Image.FORMAT_RGB8)
	detail.convert(Image.FORMAT_RG8)
	mask.convert(Image.FORMAT_RG8)
	density.convert(Image.FORMAT_R8)

	var n := GRID * GRID
	_grass_lum.resize(n)
	_dirt_r.resize(n); _dirt_g.resize(n); _dirt_b.resize(n)
	_detail_r.resize(n); _detail_g.resize(n); _edge_r.resize(n)
	_core.resize(n); _shoulder.resize(n); _density.resize(n)

	for y in range(GRID):
		for x in range(GRID):
			var i := y * GRID + x
			var gp := grass.get_pixel(x, y)
			_grass_lum[i] = gp.r * GRADE.x * 0.2126 + gp.g * GRADE.y * 0.7152 + gp.b * GRADE.z * 0.0722
			var dp := dirt.get_pixel(x, y)
			_dirt_r[i] = dp.r; _dirt_g[i] = dp.g; _dirt_b[i] = dp.b
			var de := detail.get_pixel(x, y)
			_detail_r[i] = de.r; _detail_g[i] = de.g
			# Edge-break: R sampled at the fixed rot90+offset UV (shader eb_uv).
			var u := float(x) / float(GRID)
			var v := float(y) / float(GRID)
			var eu := clampf(v + EDGE_BREAK_OFFSET.x, 0.0, 1.0)
			var ev := clampf(1.0 - u + EDGE_BREAK_OFFSET.y, 0.0, 1.0)
			var ex := clampi(int(eu * GRID), 0, GRID - 1)
			var ey := clampi(int(ev * GRID), 0, GRID - 1)
			_edge_r[i] = detail.get_pixel(ex, ey).r
			# lane_mask / lane_density: bilinear (paint_uv == mask_uv).
			var lane := _bilinear2(mask, u, v)
			_core[i] = lane.x
			_shoulder[i] = lane.y
			_density[i] = _bilinear1(density, u, v)


# dirt_amount for one texel under given shoulder-feather params (shader math).
func _dirt_amount(i: int, edge_amp: float, s_lo: float, s_mid: float, s_hi: float) -> float:
	var core_solid := smoothstep(CORE_LO, CORE_HI, _core[i])
	var broken := _shoulder[i] + (_edge_r[i] - 0.5) * edge_amp
	var dirt_full := smoothstep(s_mid, s_hi, broken)
	var dirt_edge := smoothstep(s_lo, s_mid, broken)
	var wear := lerpf(1.0 - DENSITY_CONTRAST, 1.0, _density[i])
	var shoulder_cov := maxf(dirt_full, dirt_edge * wear)
	return maxf(core_solid, shoulder_cov)


# Rendered luminance for one texel (shader composite), given the detail amps.
func _lum(i: int, sh_amp: float, core_amp: float, edge_amp: float, s_lo: float, s_mid: float, s_hi: float) -> float:
	var core_solid := smoothstep(CORE_LO, CORE_HI, _core[i])
	var dirt_amount := _dirt_amount(i, edge_amp, s_lo, s_mid, s_hi)
	var wear_tone := lerpf(1.0 - TONE_CONTRAST, 1.0, _density[i])
	var sh_mod := lerpf(1.0 - sh_amp, 1.0 + sh_amp, _detail_r[i])
	var core_mod := lerpf(1.0 - core_amp, 1.0 + core_amp, _detail_g[i])
	var detail_mod := lerpf(sh_mod, core_mod, core_solid)
	# dirt_rgb = mix(dirt, dirt*wear_tone, 1-core_solid) then * detail_mod.
	var f := lerpf(1.0, wear_tone, 1.0 - core_solid) * detail_mod
	var dr := _dirt_r[i] * f * GRADE.x
	var dg := _dirt_g[i] * f * GRADE.y
	var db := _dirt_b[i] * f * GRADE.z
	var dirt_lum := dr * 0.2126 + dg * 0.7152 + db * 0.0722
	return lerpf(_grass_lum[i], dirt_lum, dirt_amount) * 255.0


func _report(sh_amp: float, core_amp: float, edge_amp: float, s_lo: float, s_mid: float, s_hi: float) -> void:
	print("params: shoulder_amp=%.2f core_amp=%.2f edge_amp=%.2f feather=%.2f/%.2f/%.2f" % [sh_amp, core_amp, edge_amp, s_lo, s_mid, s_hi])
	var g_shoulder := _shoulder_dirt_gradient(sh_amp)
	var g_core := _core_dirt_gradient(core_amp)
	print("GATE1 clean shoulder-dirt gradient = %.2f bytes  (target >= 8.0)" % g_shoulder)
	print("GATE1 protected-core gradient       = %.2f bytes  (expected LOW, broad-drift only)" % g_core)
	# Flat-core tell (decision 012 item 5, QA pass 4 tell #1): the protected core
	# samples the dirt plate directly, so its richness is TONAL (std of rendered
	# luminance), not high-frequency. Report the core-inclusive gradient (all clean
	# dirt) and the core luminance std so the plate-driven fix is quantified: a flat
	# plate leaves both low, a structured plate lifts both.
	var g_all := _all_dirt_gradient(sh_amp, core_amp)
	var core_std := _core_luminance_std(core_amp)
	print("GATE1 core-inclusive dirt gradient  = %.2f bytes  (all clean dirt, core+shoulder)" % g_all)
	print("GATE1 protected-core luminance std  = %.2f bytes  (tonal richness, was flat pre-regen)" % core_std)
	var cov := _coverage(edge_amp, s_lo, s_mid, s_hi)
	print("GATE3 dirt fraction = %.4f  (target grass-dominant < 0.5)" % cov)
	_gate2(edge_amp, s_lo, s_mid, s_hi)
	# Shimmer ceiling: the rendered dirt must be no busier than the already
	# SHIPPING grass plate, which was judged clean at 0.5x (ground-plate-note).
	# Same plate sampling frequency, so if dirt gradient <= grass gradient it
	# cannot crawl worse than a surface already accepted at 0.5x.
	var grass_grad := _grass_gradient()
	print("SHIMMER grass-plate gradient (accepted-clean reference) = %.2f bytes" % grass_grad)
	print("SHIMMER ceiling: keep GATE1 dirt gradient <= %.2f (no busier than shipping grass)" % grass_grad)


# Gate 1: mean |dLum| over neighbor pairs where BOTH texels are clean solid
# shoulder dirt (dirt_amount >= 0.9 and core_solid < 0.5).
func _shoulder_dirt_gradient(sh_amp: float) -> float:
	return _masked_gradient(sh_amp, DETAIL_CORE_AMP, EDGE_BREAK_AMP, false)


# The protected core (dirt_amount >= 0.9 and core_solid >= 0.5): should be LOW.
func _core_dirt_gradient(core_amp: float) -> float:
	return _masked_gradient(DETAIL_SHOULDER_AMP, core_amp, EDGE_BREAK_AMP, true)


# Core-inclusive: mean |dLum| over EVERY clean solid dirt texel (core and
# shoulder together, dirt_amount >= 0.9), the whole rendered dirt surface.
func _all_dirt_gradient(sh_amp: float, core_amp: float) -> float:
	var total := 0.0
	var count := 0
	for y in range(GRID):
		for x in range(GRID):
			var i := y * GRID + x
			if _dirt_amount(i, EDGE_BREAK_AMP, SHOULDER_LO, SHOULDER_MID, SHOULDER_HI) < 0.9:
				continue
			var li := _lum(i, sh_amp, core_amp, EDGE_BREAK_AMP, SHOULDER_LO, SHOULDER_MID, SHOULDER_HI)
			if x + 1 < GRID:
				var j := i + 1
				if _dirt_amount(j, EDGE_BREAK_AMP, SHOULDER_LO, SHOULDER_MID, SHOULDER_HI) >= 0.9:
					total += absf(li - _lum(j, sh_amp, core_amp, EDGE_BREAK_AMP, SHOULDER_LO, SHOULDER_MID, SHOULDER_HI))
					count += 1
			if y + 1 < GRID:
				var j2 := i + GRID
				if _dirt_amount(j2, EDGE_BREAK_AMP, SHOULDER_LO, SHOULDER_MID, SHOULDER_HI) >= 0.9:
					total += absf(li - _lum(j2, sh_amp, core_amp, EDGE_BREAK_AMP, SHOULDER_LO, SHOULDER_MID, SHOULDER_HI))
					count += 1
	return total / maxf(count, 1) if count > 0 else 0.0


# Std of rendered luminance over the protected core clean dirt: the DIRECT
# flat-core measure. A flat plate leaves this near zero; the structured plate
# lifts it. This is the tonal richness the honesty ruling keeps on the core.
func _core_luminance_std(core_amp: float) -> float:
	var values := PackedFloat32Array()
	for y in range(GRID):
		for x in range(GRID):
			var i := y * GRID + x
			if _is_clean(i, EDGE_BREAK_AMP, true):
				values.append(_lum(i, DETAIL_SHOULDER_AMP, core_amp, EDGE_BREAK_AMP, SHOULDER_LO, SHOULDER_MID, SHOULDER_HI))
	if values.is_empty():
		return 0.0
	var mean := 0.0
	for v in values:
		mean += v
	mean /= values.size()
	var variance := 0.0
	for v in values:
		variance += (v - mean) * (v - mean)
	return sqrt(variance / values.size())


func _masked_gradient(sh_amp: float, core_amp: float, edge_amp: float, want_core: bool) -> float:
	var total := 0.0
	var count := 0
	for y in range(GRID):
		for x in range(GRID):
			var i := y * GRID + x
			if not _is_clean(i, edge_amp, want_core):
				continue
			var li := _lum(i, sh_amp, core_amp, edge_amp, SHOULDER_LO, SHOULDER_MID, SHOULDER_HI)
			if x + 1 < GRID:
				var j := i + 1
				if _is_clean(j, edge_amp, want_core):
					total += absf(li - _lum(j, sh_amp, core_amp, edge_amp, SHOULDER_LO, SHOULDER_MID, SHOULDER_HI))
					count += 1
			if y + 1 < GRID:
				var j2 := i + GRID
				if _is_clean(j2, edge_amp, want_core):
					total += absf(li - _lum(j2, sh_amp, core_amp, edge_amp, SHOULDER_LO, SHOULDER_MID, SHOULDER_HI))
					count += 1
	return total / maxf(count, 1) if count > 0 else 0.0


func _is_clean(i: int, edge_amp: float, want_core: bool) -> bool:
	var core_solid := smoothstep(CORE_LO, CORE_HI, _core[i])
	var da := _dirt_amount(i, edge_amp, SHOULDER_LO, SHOULDER_MID, SHOULDER_HI)
	if da < 0.9:
		return false
	return (core_solid >= 0.5) if want_core else (core_solid < 0.5)


# Mean luminance gradient of the raw grass plate over the same grid: the
# shipping surface's own high-frequency level, the shimmer ceiling.
func _grass_gradient() -> float:
	var total := 0.0
	var count := 0
	for y in range(GRID):
		for x in range(GRID):
			var i := y * GRID + x
			var li := _grass_lum[i] * 255.0
			if x + 1 < GRID:
				total += absf(li - _grass_lum[i + 1] * 255.0); count += 1
			if y + 1 < GRID:
				total += absf(li - _grass_lum[i + GRID] * 255.0); count += 1
	return total / count


func _coverage(edge_amp: float, s_lo: float, s_mid: float, s_hi: float) -> float:
	var dirt := 0
	var n := GRID * GRID
	for i in range(n):
		if _dirt_amount(i, edge_amp, s_lo, s_mid, s_hi) >= 0.5:
			dirt += 1
	return float(dirt) / float(n)


# Gate 2: scan three horizontal rows that cross the roughly-vertical lane 2
# (cell x ~ 9-10) away from the junction pool and placements. Report the
# 0.2->0.8 rise span, and count 0.5-crossing reversals over a vertical window
# to show the isoline is non-monotone (edge-break present).
func _gate2(edge_amp: float, s_lo: float, s_mid: float, s_hi: float) -> void:
	var rows_cell := [1.5, 3.5, 12.0]  # cell-y, clear of junction (~7.8) and props
	print("GATE2 transition (0.2->0.8 dirt_amount rise across lane edges):")
	for cy in rows_cell:
		var y := int(cy / GRID_SIZE.y * GRID)
		var span_texels := _rise_span_on_row(y, edge_amp, s_lo, s_mid, s_hi)
		if span_texels < 0:
			print("  row cell-y %.1f: no clean 0.2->0.8 edge found" % cy)
			continue
		var span_cells := float(span_texels) / float(GRID) * GRID_SIZE.y
		print("  row cell-y %.1f: rise span %d texels = %.2f cells = %.1f px @1x" % [cy, span_texels, span_cells, span_cells * PX_PER_CELL_1X])
	var reversals := _isoline_reversals(edge_amp, s_lo, s_mid, s_hi)
	print("GATE2 isoline 0.5-crossing reversals over vertical window = %d (>0 => non-monotone edge-break)" % reversals)


# Find the first left->right 0.2->0.8 rise on a row, return its texel width.
func _rise_span_on_row(y: int, edge_amp: float, s_lo: float, s_mid: float, s_hi: float) -> int:
	var lo_x := -1
	for x in range(GRID):
		var da := _dirt_amount(y * GRID + x, edge_amp, s_lo, s_mid, s_hi)
		if da <= 0.2:
			lo_x = x
		elif da >= 0.8 and lo_x >= 0:
			return x - lo_x
	return -1


# Over a vertical window straddling the left edge of lane 2, take the x where
# dirt_amount crosses 0.5 per row and count direction reversals (a straight
# edge is monotone/near-constant; the edge-break makes it wander).
func _isoline_reversals(edge_amp: float, s_lo: float, s_mid: float, s_hi: float) -> int:
	var crossings := PackedInt32Array()
	var y0 := int(0.5 / GRID_SIZE.y * GRID)
	var y1 := int(6.5 / GRID_SIZE.y * GRID)
	for y in range(y0, y1):
		var prev := _dirt_amount(y * GRID, edge_amp, s_lo, s_mid, s_hi)
		var cx := -1
		for x in range(1, GRID):
			var da := _dirt_amount(y * GRID + x, edge_amp, s_lo, s_mid, s_hi)
			if prev < 0.5 and da >= 0.5:
				cx = x
				break
			prev = da
		if cx >= 0:
			crossings.append(cx)
	var reversals := 0
	for k in range(2, crossings.size()):
		var d0 := crossings[k - 1] - crossings[k - 2]
		var d1 := crossings[k] - crossings[k - 1]
		if d0 != 0 and d1 != 0 and sign(d0) != sign(d1):
			reversals += 1
	return reversals


func _bilinear2(img: Image, u: float, v: float) -> Vector2:
	var w := img.get_width()
	var h := img.get_height()
	var fx := clampf(u, 0.0, 1.0) * (w - 1)
	var fy := clampf(v, 0.0, 1.0) * (h - 1)
	var x0 := int(fx); var y0 := int(fy)
	var x1 := mini(x0 + 1, w - 1); var y1 := mini(y0 + 1, h - 1)
	var tx := fx - x0; var ty := fy - y0
	var c00 := img.get_pixel(x0, y0); var c10 := img.get_pixel(x1, y0)
	var c01 := img.get_pixel(x0, y1); var c11 := img.get_pixel(x1, y1)
	var r := lerpf(lerpf(c00.r, c10.r, tx), lerpf(c01.r, c11.r, tx), ty)
	var g := lerpf(lerpf(c00.g, c10.g, tx), lerpf(c01.g, c11.g, tx), ty)
	return Vector2(r, g)


func _bilinear1(img: Image, u: float, v: float) -> float:
	return _bilinear2(img, u, v).x


func _load(path: String) -> Image:
	var img := Image.load_from_file(path)
	if img == null or img.is_empty():
		push_error("decode harness could not load %s" % path)
		quit(1)
	return img
