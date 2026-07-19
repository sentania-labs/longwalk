extends RefCounted
class_name CompositionKernel

# CompositionKernel: the pure, headless-capable terrain-response derivation for
# the Checkpoint B demo tile (decision 018 section 2 and section 5).
#
# It generalizes decision-016 `tools/art/bake_footprint_field.gd` (box SDF +
# apron coverage) and decision-016/017 `bake_lane_mask.gd` (polyline lane SDF)
# and subsumes decision-017 foundation vegetation (village_render.derive_base
# _vegetation) as derived output records on one shared per-texel/per-instance
# contract. Where decision 016/017 baked ONE static plate, this kernel takes an
# evolving sim-shaped snapshot plus (age, traffic, disturbance) as explicit
# arguments and derives the ground response and the flora set as a pure function
# of (world seed, named layer offset, absolute integer texel coord, snapshot
# facts). Same geometry + seed with different (age, traffic) => observably
# different ground, because the INPUTS differ, not because a patch was painted.
#
# HARD RULES honored (CLAUDE.md + decision 018):
#   - No randi()/randf()/RandomNumberGenerator. Every stochastic-looking value is
#     _hash(seed ^ layer_offset, integer coord): a fixed function of coordinate.
#   - No visit-order or traversal-order accumulator. Flora conflicts resolve by a
#     canonical tuple over the complete candidate set (input-order invariant).
#   - The snapshot is texture-free: no palette, pixel coord, shader param, or
#     viewport fact lives in the sim-shaped input. Palette + texel density are
#     render-side policy, below.
#
# DIVERGENCE NOTE for orchestrator/codex reconciliation (decision 018 owns the
# full kernel design): this Checkpoint B kernel derives the FINAL ground RGBA
# directly rather than emitting codex's two-channel response textures consumed by
# `ground.gdshader`. That is deliberate: Checkpoint B is OFFLINE with no viewport
# and no shader, so screen-space seam reconstruction (the 1-2px floor) does not
# apply; the coverage channel is derived and resolved here in ground space. The
# per-sample precedence order, the edge-oriented SDFs, the clamped-ratio
# darkening, the feature-relative apron, and the positional-hash scatter all
# match the section-2 contract. codex's channel split can wrap this kernel later
# without changing the policy.

const TEXELS_PER_CELL := 16

# Named layer offsets, decorrelated like the parked macro_map.gd pattern: each
# derived field keys off world_seed + a fixed offset so layers are independent
# but still fully determined by the one seed.
const GROUND_NOISE_OFFSET := 1301
const FIELD_CLUMP_OFFSET := 4703
const FOUNDATION_OFFSET := 6203
const WILD_OFFSET := 9341

enum Zone { WILD = 0, FIELD = 1, YARD = 2, LANE = 3 }


# A raw RGBA8 pixel buffer. Wrapped in a RefCounted so it passes BY REFERENCE
# (GDScript PackedByteArray is copy-on-write and would not mutate through a call)
# and so the whole tile is one Image.create_from_data at the end instead of
# hundreds of thousands of slow Image.set_pixel calls.
class Canvas:
	extends RefCounted
	var w: int
	var h: int
	var data: PackedByteArray

	func _init(p_w: int, p_h: int) -> void:
		w = p_w
		h = p_h
		data = PackedByteArray()
		data.resize(w * h * 4)

	func set_rgb(x: int, y: int, r: float, g: float, b: float) -> void:
		var i := (y * w + x) * 4
		data[i] = clampi(int(r * 255.0), 0, 255)
		data[i + 1] = clampi(int(g * 255.0), 0, 255)
		data[i + 2] = clampi(int(b * 255.0), 0, 255)
		data[i + 3] = 255

	func blend(x: int, y: int, c: Color) -> void:
		if x < 0 or y < 0 or x >= w or y >= h:
			return
		var i := (y * w + x) * 4
		if c.a >= 0.999:
			data[i] = clampi(int(c.r * 255.0), 0, 255)
			data[i + 1] = clampi(int(c.g * 255.0), 0, 255)
			data[i + 2] = clampi(int(c.b * 255.0), 0, 255)
			data[i + 3] = 255
			return
		if c.a <= 0.001:
			return
		var ia := 1.0 - c.a
		data[i] = clampi(int(float(data[i]) * ia + c.r * 255.0 * c.a), 0, 255)
		data[i + 1] = clampi(int(float(data[i + 1]) * ia + c.g * 255.0 * c.a), 0, 255)
		data[i + 2] = clampi(int(float(data[i + 2]) * ia + c.b * 255.0 * c.a), 0, 255)
		data[i + 3] = 255

	func get_rgb(x: int, y: int) -> Color:
		var i := (y * w + x) * 4
		return Color(float(data[i]) / 255.0, float(data[i + 1]) / 255.0, float(data[i + 2]) / 255.0, 1.0)

	func to_image() -> Image:
		return Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, data)

# ----- palette (render-side policy, NOT sim data). Warm town ground, pulled from
# the 016/017 substrate plates and the manifest tonal targets so the field reads
# in the team's authored palette even though the crop mark is drawn stylized
# (the spike shows no field; this grammar is the team's authored contribution). -
const COL_GRASS := Color(0.435, 0.405, 0.150)      # ground_grass_plate ~ (112,104,36)
const COL_LANE := Color(0.635, 0.522, 0.306)       # ground_lane ~ (162,133,78)
const COL_FIELD_SOIL := Color(0.360, 0.268, 0.160) # warm dark cultivated bed
const COL_WILD := Color(0.262, 0.280, 0.132)       # darker mottled understory ground
const COL_SOIL_TINT := Color(0.300, 0.230, 0.140)  # worn apron soil hue


class StructureRecord:
	extends RefCounted
	var id: String
	var cell: Vector2i          # top-left footprint cell
	var footprint: Vector2i     # size in cells
	var facing: String          # oriented door edge: "south" for the demo cottage
	var door_uv: Vector2        # door position along the footprint, 0..1 per axis
	var garden_edge: String     # planted flank
	var service_edge: String    # bare work flank
	var construction_tick: int

	func _init(p_id: String, p_cell: Vector2i, p_footprint: Vector2i, p_facing: String, p_door_uv: Vector2, p_garden: String, p_service: String, p_tick: int) -> void:
		id = p_id
		cell = p_cell
		footprint = p_footprint
		facing = p_facing
		door_uv = p_door_uv
		garden_edge = p_garden
		service_edge = p_service
		construction_tick = p_tick

	func center() -> Vector2:
		return Vector2(cell) + Vector2(footprint) * 0.5

	func door_point() -> Vector2:
		return Vector2(cell) + door_uv * Vector2(footprint)


# The immutable, texture-free tile snapshot handed to the deriver. Geometry +
# seed only; (age, traffic, disturbance) are passed to derive_* separately so two
# renders of the SAME snapshot with different state prove the evolution claim.
class TileSnapshot:
	extends RefCounted
	var world_seed: int
	var cells: Vector2i                       # tile size in cells (32x32)
	var base_zone: PackedByteArray            # row-major cells.x * cells.y of Zone
	var structures: Array                     # Array[StructureRecord]
	var lane_points: PackedVector2Array       # authored lane centerline, cell units
	var lane_half_widths: PackedFloat32Array
	var field_rect: Rect2                     # cultivated bed, cell units
	var access_gap_x: Vector2                 # crop-free corridor x-range into the field

	func zone_at(cx: int, cy: int) -> int:
		var x := clampi(cx, 0, cells.x - 1)
		var y := clampi(cy, 0, cells.y - 1)
		return base_zone[y * cells.x + x]


# ---------------------------------------------------------------------------
# Deterministic hashing. Mirrors village_render._mix_candidate (decision 017):
# pure positional integer mixing, no RNG, no GDScript hash(). 64-bit wraparound
# is intentional and matches the established derived-vegetation contract.
# ---------------------------------------------------------------------------
static func _mix(seed: int, a: int, b: int) -> int:
	var value := seed ^ (a * 0x45d9f3b) ^ (b * 0x119de1f3)
	value = (value ^ (value >> 16)) * 0x45d9f3b
	value = (value ^ (value >> 16)) * 0x45d9f3b
	return absi(value ^ (value >> 16))


static func _h01(seed: int, a: int, b: int) -> float:
	return float(_mix(seed, a, b) % 1000003) / 1000003.0


# Smooth value noise on an integer lattice (period `lattice` texels). Pure
# function of (seed, texel coord); used only for cosmetic ground luminance
# mottle, never for placement.
static func _value_noise(seed: int, px: float, py: float, lattice: float) -> float:
	var gx := floori(px / lattice)
	var gy := floori(py / lattice)
	var fx := px / lattice - float(gx)
	var fy := py / lattice - float(gy)
	var ux := fx * fx * (3.0 - 2.0 * fx)
	var uy := fy * fy * (3.0 - 2.0 * fy)
	var v00 := _h01(seed, gx, gy)
	var v10 := _h01(seed, gx + 1, gy)
	var v01 := _h01(seed, gx, gy + 1)
	var v11 := _h01(seed, gx + 1, gy + 1)
	var top: float = lerpf(v00, v10, ux)
	var bottom: float = lerpf(v01, v11, ux)
	return lerpf(top, bottom, uy)


# ---------------------------------------------------------------------------
# Edge-oriented signed distances (generalized from bake_footprint_field.gd and
# bake_lane_mask.gd).
# ---------------------------------------------------------------------------
static func _box_signed_distance(point: Vector2, minimum: Vector2, maximum: Vector2) -> float:
	var center := (minimum + maximum) * 0.5
	var half := (maximum - minimum) * 0.5
	var delta := (point - center).abs() - half
	return Vector2(maxf(delta.x, 0.0), maxf(delta.y, 0.0)).length() + minf(maxf(delta.x, delta.y), 0.0)


# Which oriented footprint face the exterior sample is nearest to, returned as a
# compass edge. Precedence-neutral geometry (spec Part A adjacency dependence).
static func _nearest_face(point: Vector2, minimum: Vector2, maximum: Vector2) -> String:
	var center := (minimum + maximum) * 0.5
	var half := (maximum - minimum) * 0.5
	var d := point - center
	var ex := absf(d.x) - half.x
	var ey := absf(d.y) - half.y
	if ex > ey:
		return "east" if d.x > 0.0 else "west"
	return "south" if d.y > 0.0 else "north"


static func lane_signed_distance(sample: Vector2, points: PackedVector2Array, half_widths: PackedFloat32Array) -> float:
	var best := INF
	for i in range(points.size() - 1):
		var a: Vector2 = points[i]
		var b: Vector2 = points[i + 1]
		var delta := b - a
		var t := clampf((sample - a).dot(delta) / delta.length_squared(), 0.0, 1.0)
		var half_width: float = lerpf(half_widths[i], half_widths[i + 1], t)
		best = minf(best, sample.distance_to(a + delta * t) - half_width)
	return best


# ---------------------------------------------------------------------------
# Time/use parameterization (decision 018 section 2: age -> apron maturity,
# traffic -> wear, disturbance -> soil break-up). age is an explicit literal.
# ---------------------------------------------------------------------------
static func _age_norm(age: int) -> float:
	return clampf((float(age) - 1.0) / 39.0, 0.0, 1.0)


# Per-face apron response as a clamped RATIO of local ground luminance plus a
# coverage weight, RELATIVE to the plinth feature (spec Part C). Returns
# {ratio, cover, soil}. ratio 1.0 = untouched ground; <1 = darker.
static func _apron_response(sd: float, face: String, age: int, traffic: float, disturbance: float) -> Dictionary:
	var an := _age_norm(age)
	# Base reach per adjacency subtype (cells). Door/lane face compressed and
	# clean; garden flank wide and planted; service flank bare and medium;
	# rear minimal. >3x door-vs-garden asymmetry (spec Part A) is preserved
	# across age because both scale by the same maturity factor.
	var reach_base := 0.6
	var floor_ratio := 0.6
	match face:
		"south":
			reach_base = 0.5
			floor_ratio = 0.72
		"west":
			reach_base = 1.4
			floor_ratio = 0.5
		"east":
			reach_base = 0.9
			floor_ratio = 0.62
		"north":
			reach_base = 0.65
			floor_ratio = 0.58
	var reach: float = reach_base * (0.6 + 0.55 * an)
	if sd < 0.0 or sd > reach:
		return {"ratio": 1.0, "cover": 0.0, "soil": 0.0}
	# Contact seam: a thin dark toe hugging the stone, ~0.35-0.4x of local ground
	# (spec Part A). Screen-space seam width with the 1-2px floor is a runtime
	# concern; offline we derive the coverage channel in ground space.
	var seam_w := 0.12
	var ratio: float
	var soil: float
	if sd < seam_w:
		ratio = 0.37
		soil = 0.15
	else:
		# Altered-ground apron recovering concavely back to open ground.
		var t := (sd - seam_w) / maxf(reach - seam_w, 0.0001)
		var dark := floor_ratio - 0.10 * an
		if face == "south":
			dark -= 0.10 * clampf(traffic, 0.0, 1.0)   # door/lane face wears lighter+worn
		dark = clampf(dark, 0.25, 0.95)
		ratio = lerpf(dark, 1.0, smoothstep(0.0, 1.0, t))
		# Disturbance breaks the soil apart (coverage-based, not a smooth ramp).
		soil = (1.0 - t) * (0.55 + 0.35 * disturbance)
	var cover := 1.0 - smoothstep(reach - 0.22, reach, sd)
	return {"ratio": ratio, "cover": cover, "soil": soil}


# Lane + access coverage and its wear-modulated color. traffic widens and
# lightens the compacted core (spec: lane travel core, warm compacted tan).
static func lane_coverage(sample: Vector2, snap: TileSnapshot, traffic: float) -> float:
	var sd := lane_signed_distance(sample, snap.lane_points, snap.lane_half_widths)
	var shoulder := 0.6 + 0.3 * clampf(traffic, 0.0, 1.0)
	var core := 1.0 if sd <= 0.0 else 0.0
	var cover := 1.0 - smoothstep(0.0, shoulder, sd)
	return maxf(core, cover)


# Door approach: a compacted landing from the door to the nearest lane point.
# Coverage of the access corridor (bridges the apron to the lane, no crops).
static func access_coverage(sample: Vector2, snap: TileSnapshot) -> float:
	var cover := 0.0
	for s in snap.structures:
		var door: Vector2 = s.door_point()
		var target := _nearest_lane_point(door, snap)
		var delta := target - door
		if delta.length_squared() < 0.0001:
			continue
		var t := clampf((sample - door).dot(delta) / delta.length_squared(), 0.0, 1.0)
		var closest := door + delta * t
		var dist := sample.distance_to(closest)
		cover = maxf(cover, 1.0 - smoothstep(0.35, 0.72, dist))
	return cover


static func _nearest_lane_point(p: Vector2, snap: TileSnapshot) -> Vector2:
	var best := p
	var best_d := INF
	for i in range(snap.lane_points.size() - 1):
		var a: Vector2 = snap.lane_points[i]
		var b: Vector2 = snap.lane_points[i + 1]
		var delta := b - a
		var t := clampf((p - a).dot(delta) / delta.length_squared(), 0.0, 1.0)
		var c := a + delta * t
		var d := p.distance_to(c)
		if d < best_d:
			best_d = d
			best = c
	return best


# ---------------------------------------------------------------------------
# Ground derivation: the final RGBA ground raster. Precedence resolved PER
# SAMPLE, composited low-to-high so the higher-precedence layer paints last
# (spec Part B: footprint > lane/access > foundation-apron > yard > field/wild).
# ---------------------------------------------------------------------------
static func derive_ground(snap: TileSnapshot, age: int, traffic: float, disturbance: float) -> Image:
	return derive_ground_canvas(snap, age, traffic, disturbance).to_image()


static func derive_ground_canvas(snap: TileSnapshot, age: int, traffic: float, disturbance: float) -> Canvas:
	var width := snap.cells.x * TEXELS_PER_CELL
	var height := snap.cells.y * TEXELS_PER_CELL
	var image := Canvas.new(width, height)
	var noise_seed := snap.world_seed + GROUND_NOISE_OFFSET
	for py in range(height):
		for px in range(width):
			var s := Vector2((float(px) + 0.5) / TEXELS_PER_CELL, (float(py) + 0.5) / TEXELS_PER_CELL)
			var cx := int(s.x)
			var cy := int(s.y)
			var zone := snap.zone_at(cx, cy)

			# --- base zone ground (yard/field/wild), with cosmetic luminance mottle
			var mottle := _value_noise(noise_seed, float(px), float(py), 22.0) - 0.5
			var fine := _value_noise(noise_seed + 77, float(px), float(py), 6.0) - 0.5
			var col: Color
			match zone:
				Zone.FIELD:
					col = COL_FIELD_SOIL
					# tilled rows: gentle darker striping along the bed
					var row := sin(s.y * PI * 1.4) * 0.5 + 0.5
					col = col.lerp(col.darkened(0.18), row * 0.4)
				Zone.WILD:
					col = COL_WILD
				_:
					col = COL_GRASS
			var lum := 1.0 + mottle * 0.24 + fine * 0.10
			col = Color(col.r * lum, col.g * lum, col.b * lum, 1.0)
			var local_lum := col.get_luminance()

			# --- foundation apron layer (over base, under lane/access)
			var sd_fp := INF
			var face := "south"
			var struct_hit: StructureRecord = null
			for s_rec in snap.structures:
				var mn := Vector2(s_rec.cell)
				var mx := mn + Vector2(s_rec.footprint)
				var d := _box_signed_distance(s, mn, mx)
				if d < sd_fp:
					sd_fp = d
					face = _nearest_face(s, mn, mx)
					struct_hit = s_rec
			# Map the physical flank to its adjacency subtype for this structure.
			var subtype := face
			if struct_hit != null:
				if face == struct_hit.garden_edge:
					subtype = "west"
				elif face == struct_hit.service_edge:
					subtype = "east"
				elif face == struct_hit.facing:
					subtype = "south"
				else:
					subtype = "north"
			if sd_fp > 0.0:
				var ap := _apron_response(sd_fp, subtype, age, traffic, disturbance)
				if ap.cover > 0.0:
					var darkened := Color(col.r * ap.ratio, col.g * ap.ratio, col.b * ap.ratio, 1.0)
					darkened = darkened.lerp(COL_SOIL_TINT.darkened(1.0 - ap.ratio), ap.soil * 0.5)
					col = col.lerp(darkened, ap.cover)

			# --- lane + access layer (over apron)
			var lane_c := lane_coverage(s, snap, traffic)
			var access_c := access_coverage(s, snap)
			var travel_c := maxf(lane_c, access_c)
			if travel_c > 0.0:
				var wear := clampf(traffic, 0.0, 1.0)
				# High use compacts the core lighter and greyer; low use keeps it
				# grassier at the edge.
				var lane_col := COL_LANE.lerp(Color(0.70, 0.63, 0.50), wear * 0.55)
				lane_col = Color(lane_col.r * (1.0 + mottle * 0.12), lane_col.g * (1.0 + mottle * 0.12), lane_col.b * (1.0 + mottle * 0.12), 1.0)
				col = col.lerp(lane_col, travel_c)

			# --- footprint interior (top precedence; the building sprite draws over
			# this, but the ground under it is a dark trampled pad).
			if sd_fp <= 0.0:
				col = Color(0.20, 0.17, 0.13, 1.0)

			image.set_rgb(px, py, col.r, col.g, col.b)
	return image


# ---------------------------------------------------------------------------
# Flora derivation: derived instance records on the shared contract. Field
# crops, foundation planting, and wild-edge vegetation, all placed by positional
# hash over a canonical candidate grid, conflicts resolved by a canonical tuple
# over the COMPLETE candidate set (input-order invariant). Sorted back-to-front
# for correct painter compositing AND as the deterministic canonical order.
# Returns Array[Dictionary]: {kind, pos (cell units), size, hash, sort_key}.
# ---------------------------------------------------------------------------
static func derive_flora(snap: TileSnapshot, age: int, traffic: float, disturbance: float) -> Array:
	var out: Array = []
	_derive_field_crops(snap, age, out)
	_derive_foundation(snap, age, out)
	_derive_wild(snap, age, out)
	# Canonical order: (y, x, kind). Independent of the order candidates were
	# generated, so re-deriving after any input reordering is byte-identical.
	out.sort_custom(func(a, b): return a.sort_key < b.sort_key)
	return out


static func _sort_key(pos: Vector2, kind: String) -> String:
	return "%08d:%08d:%s" % [int(round(pos.y * 1000.0)), int(round(pos.x * 1000.0)), kind]


# Sunflower field: warm cultivated bed already tinted by derive_ground; here the
# crops go in coherent clumps / short staggered rows, soft coverage-broken edges,
# a clean access gap to the lane, NO crops in yard/travel core/footprint/apron.
static func _derive_field_crops(snap: TileSnapshot, age: int, out: Array) -> void:
	var an := _age_norm(age)
	var seed := snap.world_seed + FIELD_CLUMP_OFFSET
	var r := snap.field_rect
	var row_step := 0.9
	var col_step := 0.62
	var row := 0
	var y := r.position.y + 0.55
	while y < r.position.y + r.size.y - 0.35:
		var stagger := (row % 2) * (col_step * 0.5)
		var x := r.position.x + 0.45 + stagger
		while x < r.position.x + r.size.x - 0.35:
			var pos := Vector2(x, y)
			if _crop_allowed(snap, pos):
				# Quarter-cell canonical candidate coordinate for the hash.
				var q := Vector2i(int(round(x * 4.0)), int(round(y * 4.0)))
				var h := _mix(seed, q.x, q.y)
				# Coherent clumps + coverage-broken edges: dense in the interior,
				# thinning near the bed boundary so edges read soft, not a hard rect.
				var edge := _field_edge_falloff(r, pos)
				var keep_pct := int(round((60.0 + 32.0 * edge)))
				if (h % 100) < keep_pct:
					# jitter within the cell so rows stagger organically but stay
					# a function of the coordinate hash only.
					var jx := (_h01(seed + 11, q.x, q.y) - 0.5) * 0.30
					var jy := (_h01(seed + 29, q.x, q.y) - 0.5) * 0.22
					var jpos := Vector2(x + jx, y + jy)
					var size := 0.30 + 0.10 * an + (float(h % 37) / 37.0) * 0.10
					out.append({"kind": "sunflower", "pos": jpos, "size": size, "hash": h, "sort_key": _sort_key(jpos, "sunflower")})
			x += col_step
		y += row_step
		row += 1


static func _field_edge_falloff(r: Rect2, pos: Vector2) -> float:
	# 1.0 deep inside the bed, -> 0.0 at the boundary.
	var dx: float = minf(pos.x - r.position.x, r.position.x + r.size.x - pos.x)
	var dy: float = minf(pos.y - r.position.y, r.position.y + r.size.y - pos.y)
	return clampf(minf(dx, dy) / 1.4, 0.0, 1.0)


static func _crop_allowed(snap: TileSnapshot, pos: Vector2) -> bool:
	var cx := int(pos.x)
	var cy := int(pos.y)
	if snap.zone_at(cx, cy) != Zone.FIELD:
		return false
	# Clean access corridor into the field (no crops), so the field opens to the
	# lane instead of walling it off.
	if pos.x >= snap.access_gap_x.x and pos.x <= snap.access_gap_x.y:
		return false
	# Never in the travel core / door approach.
	if lane_coverage(pos, snap, 1.0) > 0.05:
		return false
	if access_coverage(pos, snap) > 0.05:
		return false
	# Never on a footprint or hard against a wall (apron reads as soil, not crop).
	for s in snap.structures:
		var mn := Vector2(s.cell)
		var mx := mn + Vector2(s.footprint)
		if _box_signed_distance(pos, mn, mx) < 0.6:
			return false
	return true


# Foundation planting on the garden flank (decision-017 pattern), density growing
# with age. Young building: a couple of corner tufts; mature: a planted flank.
static func _derive_foundation(snap: TileSnapshot, age: int, out: Array) -> void:
	var an := _age_norm(age)
	var seed := snap.world_seed + FOUNDATION_OFFSET
	for s in snap.structures:
		var x0: int = s.cell.x
		var x1: int = s.cell.x + s.footprint.x
		var y0: int = s.cell.y
		var y1: int = s.cell.y + s.footprint.y
		# Walk the garden (west) flank plus the two facing corners at quarter-cell
		# resolution; keep by positional hash, keep-limit rises with age.
		var candidates: Array = []
		for qy in range(y0 * 4, y1 * 4 + 1):
			candidates.append(Vector2i(x0 * 4, qy))       # west flank
		candidates.append(Vector2i(x0 * 4, y1 * 4))         # SW facing corner
		candidates.append(Vector2i(x1 * 4, y1 * 4))         # SE facing corner
		for q in candidates:
			var qv: Vector2i = q
			var hh := _mix(seed, qv.x, qv.y)
			var keep_limit := int(round(28.0 + 55.0 * an))
			# Force the two mandatory corners so a young building still shows >=2
			# foundation anchors (decision-017 invariant).
			var mandatory: bool = (qv == Vector2i(x0 * 4, y1 * 4)) or (qv == Vector2i(x1 * 4, y1 * 4))
			if not mandatory and (hh % 100) >= keep_limit:
				continue
			var pos := Vector2(qv) / 4.0
			var size := 0.24 + 0.10 * an + (float(hh % 23) / 23.0) * 0.06
			out.append({"kind": "tuft", "pos": pos, "size": size, "hash": hh, "sort_key": _sort_key(pos, "tuft")})


# Wild-edge vegetation: dense mixed scatter (spec: the maximum-vegetation case).
static func _derive_wild(snap: TileSnapshot, age: int, out: Array) -> void:
	var seed := snap.world_seed + WILD_OFFSET
	for cy in range(snap.cells.y):
		for cx in range(snap.cells.x):
			if snap.base_zone[cy * snap.cells.x + cx] != Zone.WILD:
				continue
			# Up to four sub-cell candidates per wild cell.
			for sub in range(4):
				var qx := cx * 2 + (sub % 2)
				var qy := cy * 2 + (sub / 2)
				var h := _mix(seed, qx, qy)
				if (h % 100) >= 70:
					continue
				var pos := Vector2(float(qx) + 0.5, float(qy) + 0.5) * 0.5
				# Keep the lane travel core and the door approach clear even where the
				# wild border meets them (spec Part A: no rooted flora in the core; the
				# feathered edge may carry sparse tufts, which is why this excludes the
				# core, not the shoulder).
				if lane_signed_distance(pos, snap.lane_points, snap.lane_half_widths) <= 0.15:
					continue
				if access_coverage(pos, snap) > 0.5:
					continue
				var kind := "bush" if (h % 5) < 2 else "tuft"
				var size := 0.28 + (float(h % 31) / 31.0) * 0.20
				out.append({"kind": kind, "pos": pos, "size": size, "hash": h, "sort_key": _sort_key(pos, kind)})
