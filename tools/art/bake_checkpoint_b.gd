extends SceneTree

# Checkpoint B offline bake (decision 018 section 5): ONE 32x32-cell tile with a
# cottage, a lane + door approach, a yard, one AUTHORED sunflower field, and a
# wild edge, rendered from TWO sim snapshots of IDENTICAL geometry + seed:
#   - age-1  low-use  (young)
#   - age-40 high-use (mature)
# and a byte-difference assertion proving (a) re-deriving unchanged inputs is
# byte-identical, and (b) the two states are observably different. Exits nonzero
# on any failure. OFFLINE: headless CPU derivation, no viewport, no runtime path.
# age/traffic/disturbance are passed as explicit literal arguments; there is NO
# persistence store and NO src/sim change (the sim-shaped snapshot is an in-tool
# literal fixture for this one tile).
#
# Run (also the exact byte-diff command, prints PASS/FAIL and exits nonzero on
# failure):
#   tools/godot/godot --headless --path . --script tools/art/bake_checkpoint_b.gd
# or the wrapper: tools/art/checkpoint_b.sh

const Kernel := preload("res://src/render/town/composition_kernel.gd")
const Renderer := preload("res://src/render/town/composition_tile_renderer.gd")

const OUT_DIR := "res://tools/art/out/checkpoint_b"

# Explicit literal state arguments (decision 018 section 5). Same snapshot, two
# states.
const YOUNG := {"age": 1, "traffic": 0.15, "disturbance": 0.10}
const MATURE := {"age": 40, "traffic": 0.90, "disturbance": 0.70}

const WORLD_SEED := 7018


func _init() -> void:
	var snap := _build_fixture()
	var failures: Array[String] = []

	# --- Determinism: unchanged inputs must be byte-identical.
	var young_ca := Renderer.render_tile_canvas(snap, YOUNG.age, YOUNG.traffic, YOUNG.disturbance)
	var young_cb := Renderer.render_tile_canvas(snap, YOUNG.age, YOUNG.traffic, YOUNG.disturbance)
	var mature_c := Renderer.render_tile_canvas(snap, MATURE.age, MATURE.traffic, MATURE.disturbance)
	var young_a := young_ca.to_image()
	var mature := mature_c.to_image()

	if young_ca.data != young_cb.data:
		failures.append("determinism: two renders of the young snapshot are NOT byte-identical")

	# Ground layer alone must also be deterministic (kernel purity).
	var g1 := Kernel.derive_ground_canvas(snap, YOUNG.age, YOUNG.traffic, YOUNG.disturbance)
	var g2 := Kernel.derive_ground_canvas(snap, YOUNG.age, YOUNG.traffic, YOUNG.disturbance)
	if g1.data != g2.data:
		failures.append("determinism: two derivations of the young GROUND are NOT byte-identical")

	# --- Evolution: changed inputs must be observably different.
	if young_ca.data == mature_c.data:
		failures.append("evolution: young and mature snapshots are byte-IDENTICAL (ground did not respond to state+time)")
	var diff_px := _count_diff_pixels_bytes(young_ca.data, mature_c.data)
	if diff_px < 2000:
		failures.append("evolution: young vs mature differ in only %d pixels (expected a broad ground response)" % diff_px)

	# --- Flora determinism: the canonical-tuple order is input-invariant.
	var flora_a := Kernel.derive_flora(snap, MATURE.age, MATURE.traffic, MATURE.disturbance)
	var flora_b := Kernel.derive_flora(snap, MATURE.age, MATURE.traffic, MATURE.disturbance)
	if not _flora_equal(flora_a, flora_b):
		failures.append("determinism: two flora derivations differ")

	# --- Field grammar: the field stays a field, the door/lane stay clean.
	failures.append_array(_check_field_grammar(snap, flora_a))

	# --- Emit captures.
	_ensure_dir()
	var young_path := "%s/tile_young_age1.png" % OUT_DIR
	var mature_path := "%s/tile_mature_age40.png" % OUT_DIR
	var compare_path := "%s/compare_young_vs_mature.png" % OUT_DIR
	var field_path := "%s/field_zone_legend.png" % OUT_DIR
	_save(young_a, young_path, failures)
	_save(mature, mature_path, failures)
	_save(_compose_side_by_side(young_a, mature), compare_path, failures)
	_save(_compose_field_legend(snap, mature), field_path, failures)

	print("checkpoint_b young_sha256=%s" % _sha(young_a))
	print("checkpoint_b mature_sha256=%s" % _sha(mature))
	print("checkpoint_b young_vs_mature_diff_pixels=%d / %d" % [diff_px, young_a.get_width() * young_a.get_height()])
	print("checkpoint_b flora_instances(mature)=%d" % flora_a.size())
	print("checkpoint_b captures: %s | %s | %s | %s" % [young_path, mature_path, compare_path, field_path])

	if failures.is_empty():
		print("checkpoint_b RESULT=PASS")
		quit(0)
	else:
		for f in failures:
			printerr("checkpoint_b FAIL: %s" % f)
		print("checkpoint_b RESULT=FAIL (%d)" % failures.size())
		quit(1)


# ---------------------------------------------------------------------------
# The in-tool LITERAL fixture: a texture-free sim-shaped snapshot for one tile.
# Hand-authored geometry, no seed-driven generation, no src/sim dependency.
# ---------------------------------------------------------------------------
func _build_fixture() -> Kernel.TileSnapshot:
	var w := 32
	var h := 32
	var snap := Kernel.TileSnapshot.new()
	snap.world_seed = WORLD_SEED
	snap.cells = Vector2i(w, h)

	# Cottage: 5x4 footprint, door on the south (lane-facing) edge; garden on the
	# west flank, service on the east flank.
	var cottage := Kernel.StructureRecord.new("demo_cottage", Vector2i(11, 12), Vector2i(5, 4), "south", Vector2(0.42, 1.0), "west", "east", 0)
	snap.structures = [cottage]

	# Authored lane running east-west below the cottage; a swelling/narrowing
	# rhythm like the inn-green lanes.
	snap.lane_points = PackedVector2Array([
		Vector2(0.0, 19.4), Vector2(6.0, 19.8), Vector2(12.0, 19.1),
		Vector2(18.0, 19.5), Vector2(24.0, 18.9), Vector2(31.0, 19.3),
	])
	snap.lane_half_widths = PackedFloat32Array([1.05, 1.2, 0.95, 1.15, 1.0, 1.1])

	# Authored sunflower field: a cultivated bed in the upper-right, with a clean
	# vertical access corridor opening toward the lane.
	snap.field_rect = Rect2(19.0, 3.0, 11.0, 13.0)
	snap.access_gap_x = Vector2(23.0, 24.6)

	# Base zone grid: default YARD, then field, then the wild edge (top + left L),
	# then rasterize the lane travel core.
	var zones := PackedByteArray()
	zones.resize(w * h)
	for cy in range(h):
		for cx in range(w):
			var z: int = Kernel.Zone.YARD
			if snap.field_rect.has_point(Vector2(float(cx) + 0.5, float(cy) + 0.5)):
				z = Kernel.Zone.FIELD
			if cy < 3 or cx < 3:
				z = Kernel.Zone.WILD
			zones[cy * w + cx] = z
	# Lane core cells (centerline within half width) -> LANE.
	for cy in range(h):
		for cx in range(w):
			var c := Vector2(float(cx) + 0.5, float(cy) + 0.5)
			if Kernel.lane_signed_distance(c, snap.lane_points, snap.lane_half_widths) <= 0.0:
				zones[cy * w + cx] = Kernel.Zone.LANE
	snap.base_zone = zones
	return snap


# ---------------------------------------------------------------------------
# Field-grammar assertions: the field stays a field, the travel core / door
# approach stay crop-free, the access gap stays open.
# ---------------------------------------------------------------------------
func _check_field_grammar(snap: Kernel.TileSnapshot, flora: Array) -> Array[String]:
	var problems: Array[String] = []
	var sunflowers := 0
	for f in flora:
		if f.kind == "sunflower":
			sunflowers += 1
			var cx := int(f.pos.x)
			var cy := int(f.pos.y)
			if snap.zone_at(cx, cy) != Kernel.Zone.FIELD:
				problems.append("crop outside FIELD zone at %s" % f.pos)
			if f.pos.x >= snap.access_gap_x.x and f.pos.x <= snap.access_gap_x.y:
				problems.append("crop inside the clean access gap at %s" % f.pos)
		# No flora of ANY kind in the lane travel CORE or the door approach. The
		# feathered lane shoulder MAY carry sparse tufts (spec Part A), so this
		# tests core membership (signed distance into the lane), not the shoulder.
		if Kernel.lane_signed_distance(f.pos, snap.lane_points, snap.lane_half_widths) <= 0.15:
			problems.append("%s in the lane travel core at %s" % [f.kind, f.pos])
		if Kernel.access_coverage(f.pos, snap) > 0.5:
			problems.append("%s in the door approach at %s" % [f.kind, f.pos])
	if sunflowers < 40:
		problems.append("field reads as scatter not a field: only %d crops" % sunflowers)
	# Cap the reported problems so a systemic error does not flood the log.
	if problems.size() > 8:
		var head := problems.slice(0, 8)
		head.append("... and %d more" % (problems.size() - 8))
		return head
	return problems


# ---------------------------------------------------------------------------
# Capture composition.
# ---------------------------------------------------------------------------
func _compose_side_by_side(young: Image, mature: Image) -> Image:
	var gap := 16
	var header := 22
	var w := young.get_width() + gap + mature.get_width()
	var h := header + maxi(young.get_height(), mature.get_height())
	var canvas := Image.create(w, h, false, Image.FORMAT_RGBA8)
	canvas.fill(Color(0.12, 0.12, 0.13, 1.0))
	# Legend header: cool tag over the young half, warm tag over the mature half
	# (left = age 1 low-use, right = age 40 high-use).
	_fill_band(canvas, 0, 0, young.get_width(), header, Color(0.32, 0.46, 0.52, 1.0))
	_fill_band(canvas, young.get_width() + gap, 0, mature.get_width(), header, Color(0.60, 0.42, 0.24, 1.0))
	canvas.blit_rect(young, Rect2i(0, 0, young.get_width(), young.get_height()), Vector2i(0, header))
	canvas.blit_rect(mature, Rect2i(0, 0, mature.get_width(), mature.get_height()), Vector2i(young.get_width() + gap, header))
	return canvas


func _compose_field_legend(snap: Kernel.TileSnapshot, base: Image) -> Image:
	var tpc := Kernel.TEXELS_PER_CELL
	var canvas := base.duplicate()
	# Outline the FIELD cells and mark the clean access gap so the designated
	# field zone is legible at a glance.
	for cy in range(snap.cells.y):
		for cx in range(snap.cells.x):
			if snap.zone_at(cx, cy) != Kernel.Zone.FIELD:
				continue
			var field_up := snap.zone_at(cx, cy - 1) != Kernel.Zone.FIELD
			var field_left := snap.zone_at(cx - 1, cy) != Kernel.Zone.FIELD
			var field_down := snap.zone_at(cx, cy + 1) != Kernel.Zone.FIELD
			var field_right := snap.zone_at(cx + 1, cy) != Kernel.Zone.FIELD
			var line := Color(0.95, 0.85, 0.30, 0.9)
			if field_up:
				_fill_band(canvas, cx * tpc, cy * tpc, tpc, 2, line)
			if field_down:
				_fill_band(canvas, cx * tpc, (cy + 1) * tpc - 2, tpc, 2, line)
			if field_left:
				_fill_band(canvas, cx * tpc, cy * tpc, 2, tpc, line)
			if field_right:
				_fill_band(canvas, (cx + 1) * tpc - 2, cy * tpc, 2, tpc, line)
	# Access-gap marker (magenta), the crop-free corridor into the field.
	var gx0 := int(snap.access_gap_x.x * tpc)
	var gx1 := int(snap.access_gap_x.y * tpc)
	var gy0 := int(snap.field_rect.position.y * tpc)
	var gy1 := int((snap.field_rect.position.y + snap.field_rect.size.y) * tpc)
	_fill_band(canvas, gx0, gy0, 2, gy1 - gy0, Color(0.90, 0.30, 0.70, 0.9))
	_fill_band(canvas, gx1, gy0, 2, gy1 - gy0, Color(0.90, 0.30, 0.70, 0.9))
	return canvas


func _fill_band(image: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for yy in range(y, y + h):
		for xx in range(x, x + w):
			if xx >= 0 and yy >= 0 and xx < image.get_width() and yy < image.get_height():
				var dst := image.get_pixel(xx, yy)
				image.set_pixel(xx, yy, dst.lerp(Color(c.r, c.g, c.b, 1.0), c.a))


func _count_diff_pixels_bytes(a: PackedByteArray, b: PackedByteArray) -> int:
	var count := 0
	var n := a.size()
	var i := 0
	while i < n:
		if a[i] != b[i] or a[i + 1] != b[i + 1] or a[i + 2] != b[i + 2]:
			count += 1
		i += 4
	return count


func _flora_equal(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for i in range(a.size()):
		if a[i].sort_key != b[i].sort_key or a[i].size != b[i].size:
			return false
	return true


func _ensure_dir() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))


func _save(image: Image, path: String, failures: Array[String]) -> void:
	var err := image.save_png(path)
	if err != OK:
		failures.append("save failed for %s: %s" % [path, error_string(err)])


func _sha(image: Image) -> String:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(image.get_data())
	return ctx.finish().hex_encode()
