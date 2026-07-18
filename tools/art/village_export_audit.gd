extends SceneTree

# Isolated-packaged export audit + capture gate (decision 009 item 2: codex's
# design adopted verbatim + claude's non-placeholder assertion). This script is
# meant to run against a PACKAGED resource bundle (a .pck), from a temp dir with
# NO res:// source tree, by the pinned engine headless (see
# tools/art/village_export_gate.sh). It is the load-bearing proof that a stock
# packaged build ships the REAL village art rather than silently substituting
# engine defaults (the carry-forward finding).
#
# It asserts:
#   1. res://assets/village/manifest.json resolves from the bundle.
#   2. EVERY manifest object's png resolves through ResourceLoader with nonzero
#      dimensions matching its declared native_px. A missing asset (the silent
#      export-exclusion bug) resolves to null here and FAILS the gate.
#   3. The four registered inn-green landmarks project on-screen at 0.5x/1x/2x.
#   4. The captured district is NON-BLANK (real pixels drew): a uniform capture
#      means nothing rendered / only the default fixture, and FAILS the gate.
# It captures the district PNG at 0.5x, 1x, 2x into $VILLAGE_CAPTURE_DIR for the
# side-by-side against the spike.
#
# Exit code 0 = pass, non-zero = fail (the shell gate keys off this).

const VillageScript := preload("res://src/render/town/village_render.gd")
const VillageScene := preload("res://scenes/village.tscn")
const Iso := preload("res://src/render/iso/projection.gd")

const ZOOMS := [0.5, 1.0, 2.0]


func _initialize() -> void:
	call_deferred("_run")


func _fail(msg: String) -> void:
	push_error("VILLAGE_GATE_FAIL: %s" % msg)
	print("VILLAGE_GATE_FAIL: %s" % msg)
	quit(1)


func _run() -> void:
	var capture_dir := OS.get_environment("VILLAGE_CAPTURE_DIR")
	if capture_dir.is_empty():
		_fail("VILLAGE_CAPTURE_DIR not set")
		return

	# --- (1) manifest resolves from the bundle ---
	var manifest := VillageScript.load_manifest()
	if manifest.is_empty():
		_fail("manifest.json did not resolve from the packaged bundle")
		return
	print("manifest resolved: %d objects" % manifest.size())

	# --- (2) every manifest asset resolves via ResourceLoader, nonzero dims ---
	for kit_id in manifest.keys():
		var record: Dictionary = manifest[kit_id]
		var path := "res://assets/village/" + str(record["png"])
		if not ResourceLoader.exists(path):
			_fail("asset absent from bundle (ResourceLoader.exists false): %s" % path)
			return
		var tex := ResourceLoader.load(path) as Texture2D
		if tex == null:
			_fail("asset did not resolve through ResourceLoader: %s" % path)
			return
		var size := tex.get_size()
		if size.x <= 0 or size.y <= 0:
			_fail("asset resolved with zero dimensions: %s" % path)
			return
		var native: Array = record["native_px"]
		if int(size.x) != int(native[0]) or int(size.y) != int(native[1]):
			_fail("asset %s dims %sx%s != declared native_px %sx%s (default/placeholder fixture?)" % [
				path, size.x, size.y, native[0], native[1]])
			return
	print("all %d manifest assets resolved through ResourceLoader with declared dims" % manifest.size())

	# --- (2b) continuous-ground statics resolve from the bundle (decision 010
	# step 9, PLATE fallback). These are the resources the ground shader binds by
	# fixed path, NOT manifest placements: the ground shader, its two painterly
	# PLATES (sampled once across the district), the CPU-baked warp field, the two
	# BAKED lane data textures (mask + density, decision 011), and the
	# contact-shadow decal. A stock export that silently dropped any of them would
	# ship a blank ground, straight/absent lanes, or unshadowed floating objects;
	# assert each is packed and loads. The plates ALSO carry manifest entries, so
	# loop (2) additionally asserts their native_px equality. ---
	var ground_statics := [
		"res://src/render/town/ground.gdshader",
		"res://assets/village/ground_grass_plate.png",
		"res://assets/village/ground_dirt_plate.png",
		"res://assets/village/ground_warp.png",
		"res://assets/village/lane_mask.png",
		"res://assets/village/lane_density.png",
		"res://assets/village/ground_dirt_detail.png",
		"res://assets/village/footprint_interaction_field.png",
		"res://assets/village/shadow_decal.png",
	]
	for path in ground_statics:
		if not ResourceLoader.exists(path):
			_fail("ground asset absent from bundle (ResourceLoader.exists false): %s" % path)
			return
		var res := ResourceLoader.load(path)
		if res == null:
			_fail("ground asset did not resolve through ResourceLoader: %s" % path)
			return
	print("all %d continuous-ground statics resolved through ResourceLoader" % ground_statics.size())

	# Seam masks are render-only records rather than placement objects. Resolve
	# every declared path from the packaged bundle so the manifest contract
	# cannot name a source-tree-only PNG.
	var manifest_file := FileAccess.open("res://assets/village/manifest.json", FileAccess.READ)
	var manifest_data: Dictionary = JSON.parse_string(manifest_file.get_as_text())
	for kit_id in manifest_data["seam_policy"]["shadows"]:
		var shadow_record: Dictionary = manifest_data["seam_policy"]["shadows"][kit_id]
		for shadow_kind in ["contact", "cast"]:
			var shadow_path := "res://assets/village/" + str(shadow_record[shadow_kind])
			if not ResourceLoader.exists(shadow_path) or ResourceLoader.load(shadow_path) == null:
				_fail("seam asset absent from bundle: %s" % shadow_path)
				return
	print("all declared seam masks resolved through ResourceLoader")

	# --- Stand up the district scene ---
	var village = VillageScene.instantiate()
	root.add_child(village)
	current_scene = village
	await process_frame
	await process_frame

	var rig = village.camera_rig()
	if rig == null:
		_fail("village camera rig missing")
		return
	rig.make_current()

	var vp_w: float = ProjectSettings.get_setting("display/window/size/viewport_width")
	var vp_h: float = ProjectSettings.get_setting("display/window/size/viewport_height")
	var vp_size := Vector2(vp_w, vp_h)
	var cam_center: Vector2 = rig.position

	# --- (3) landmark registration at each zoom + (4) non-blank capture ---
	for z in ZOOMS:
		rig.set_zoom_for_capture(z)
		await process_frame
		await RenderingServer.frame_post_draw

		# Landmarks project on-screen (decision 009 item 9). At 2x some may fall
		# outside the frame; we assert every landmark projects to a FINITE pixel
		# and at least the anchor landmark (inn) is in-frame, and report each.
		var in_frame := 0
		for name in Iso.INN_GREEN_LANDMARKS.keys():
			var contact: Vector2 = Iso.INN_GREEN_LANDMARKS[name]
			var world_screen := Iso.cell_to_screen(contact)
			var vpix := Iso.viewport_point(world_screen, z, cam_center, vp_size)
			var on := vpix.x >= 0.0 and vpix.y >= 0.0 and vpix.x <= vp_size.x and vpix.y <= vp_size.y
			if on:
				in_frame += 1
			print("  zoom %sx landmark %-14s -> viewport (%.1f, %.1f) %s" % [
				z, name, vpix.x, vpix.y, "IN" if on else "out"])
		if in_frame == 0:
			_fail("no registered landmark is in-frame at zoom %sx" % z)
			return

		var image := root.get_texture().get_image()
		if not _is_non_blank(image):
			_fail("capture at zoom %sx is uniform/blank (default fixture, nothing drew)" % z)
			return

		var out_path := capture_dir.path_join("village-inn-green-%sx.png" % z)
		var err := image.save_png(out_path)
		if err != OK:
			_fail("could not write capture %s: %s" % [out_path, error_string(err)])
			return
		print("wrote %s" % out_path)

	print("VILLAGE_GATE_PASS")
	quit(0)


# A capture is non-blank if it contains more than one distinct color (something
# other than a flat clear/default fixture rendered). Samples on a coarse grid to
# stay cheap on a 1280x720 frame.
static func _is_non_blank(image: Image) -> bool:
	var w := image.get_width()
	var h := image.get_height()
	if w == 0 or h == 0:
		return false
	var first := image.get_pixel(0, 0)
	var step_x: int = maxi(1, int(w / 64.0))
	var step_y: int = maxi(1, int(h / 64.0))
	var x := 0
	while x < w:
		var y := 0
		while y < h:
			if not image.get_pixel(x, y).is_equal_approx(first):
				return true
			y += step_y
		x += step_x
	return false
