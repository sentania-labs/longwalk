extends Node3D

# game_main is the M2 entry point and the render/sim wiring hub. It:
#   - resolves the world seed (from --seed on the command line, else a minimal
#     menu, else a default),
#   - builds the sim layers (MacroMapGenerator -> TerrainSampler, SpawnFinder),
#   - finds the deterministic coastal spawn on the largest landmass,
#   - assembles the render tree (terrain streamer, player, water, day/night),
#   - and runs the per-frame loop: streaming, water follow, and the
#     floating-origin rebase that begins the origin-shifting work (ARCHITECTURE
#     section 4), keeping the player near the numerical origin.
#
# The sim layers have zero dependency on any of the render nodes below; the
# dependency is strictly render -> sim.

const MacroMap := preload("res://src/macro_map.gd")
const TerrainSamplerC := preload("res://src/sim/terrain_sampler.gd")
const SpawnFinderC := preload("res://src/sim/spawn_finder.gd")
const TerrainStreamerScript := preload("res://src/render/terrain_streamer.gd")
const TerrainChunkScript := preload("res://src/render/terrain_chunk.gd")
const WaterScript := preload("res://src/render/water.gd")
const DayNightScript := preload("res://src/render/day_night.gd")
const InputActionsScript := preload("res://src/render/input_actions.gd")
const PlayerScene := preload("res://scenes/player.tscn")

const DEFAULT_SEED := 424242

# Re-base the world origin whenever the player drifts this far (in world units)
# from the current origin in the XZ plane. Kept comfortably inside float
# precision so the rebase demonstrates the mechanism well before jitter would
# appear. The shift is snapped to the chunk grid so chunk coordinates stay
# aligned across a rebase.
const REBASE_THRESHOLD := 256.0

var _sampler
var _streamer: Node3D
var _player: CharacterBody3D
var _water: MeshInstance3D
var _day_night: Node
var _hud: Label

var render_origin := Vector3.ZERO
var _running := false

# Optional smoke-test frame budget (headless): --smoketest=<frames> runs that
# many physics frames then quits 0, so CI/local runs can load the whole game
# without a display and catch script errors.
var _smoketest_frames := -1
var _frames := 0


func _ready() -> void:
	_setup_input_actions()

	var args := _parse_args(OS.get_cmdline_user_args())
	if args.has("smoketest"):
		_smoketest_frames = int(args.get("smoketest", "120"))
	if args.has("seed"):
		start_game(int(args["seed"]))
	elif _smoketest_frames >= 0:
		start_game(DEFAULT_SEED)
	else:
		_show_menu()


# --- Menu -------------------------------------------------------------------
func _show_menu() -> void:
	var layer := CanvasLayer.new()
	layer.name = "MenuLayer"
	add_child(layer)

	var panel := VBoxContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -140
	panel.offset_top = -80
	panel.add_theme_constant_override("separation", 10)
	layer.add_child(panel)

	var title := Label.new()
	title.text = "longwalk"
	panel.add_child(title)

	var hint := Label.new()
	hint.text = "World seed:"
	panel.add_child(hint)

	var seed_edit := LineEdit.new()
	seed_edit.text = str(DEFAULT_SEED)
	seed_edit.custom_minimum_size = Vector2(240, 0)
	panel.add_child(seed_edit)

	var start_button := Button.new()
	start_button.text = "Explore"
	panel.add_child(start_button)

	# Controls hint, shown before the world loads so a playtester knows every
	# binding. Kept in sync with the README Controls section and input_actions.gd.
	var controls := Label.new()
	controls.text = "Controls\n" \
		+ "Move: W A S D    Sprint: Shift    Jump / swim up: Space\n" \
		+ "Look: mouse    Yaw: Q E    Pitch: Up / Down arrows\n" \
		+ "Camera view: C    Sleep: R    Release cursor: Esc"
	controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(controls)

	start_button.pressed.connect(func():
		var seed_text := seed_edit.text.strip_edges()
		var seed_value := int(seed_text) if seed_text.is_valid_int() else DEFAULT_SEED
		layer.queue_free()
		start_game(seed_value)
	)


# --- Game assembly ----------------------------------------------------------
func start_game(seed_value: int) -> void:
	print("[game_main] starting world seed=%d" % seed_value)
	var generator := MacroMap.new(seed_value)
	_sampler = TerrainSamplerC.new(generator)

	var spawn: Dictionary = SpawnFinderC.new(generator).find_spawn()
	var cell: Vector2i = spawn["cell"]
	if not spawn["found"]:
		push_warning("[game_main] no landmass for seed %d, spawning at map center" % seed_value)
	var spawn_center: Vector3 = _sampler.macro_to_world_center(cell.x, cell.y)
	print("[game_main] spawn macro cell=%s landmass=%d world=%s" % [cell, spawn["landmass_size"], spawn_center])

	# Anchor the render origin at the spawn so the player starts near local zero.
	render_origin = Vector3(spawn_center.x, 0.0, spawn_center.z)

	_day_night = DayNightScript.new()
	add_child(_day_night)

	_streamer = TerrainStreamerScript.new()
	add_child(_streamer)
	_streamer.setup(_sampler)

	_water = WaterScript.new()
	add_child(_water)

	_player = PlayerScene.instantiate()
	add_child(_player)
	_player.setup(_sampler)
	# Local start position: origin covers the XZ, so start at local X/Z 0, lifted
	# a couple of units above the ground so the player settles onto the mesh.
	var start_height: float = _sampler.height_at(spawn_center.x, spawn_center.z)
	_player.position = Vector3(0.0, maxf(start_height, 0.0) + 2.0, 0.0)
	_player.render_origin = render_origin
	_player.sleep_requested.connect(_on_sleep_requested)

	# Build the initial ring of chunks immediately so the player lands on ground.
	_streamer.update_streaming(_player.position + render_origin, render_origin)

	_build_hud()
	_running = true


func _on_sleep_requested() -> void:
	if _day_night != null:
		_day_night.sleep()


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "HUD"
	add_child(layer)

	# Crosshair.
	var dot := ColorRect.new()
	dot.color = Color(1, 1, 1, 0.6)
	dot.custom_minimum_size = Vector2(4, 4)
	dot.anchor_left = 0.5
	dot.anchor_top = 0.5
	dot.anchor_right = 0.5
	dot.anchor_bottom = 0.5
	dot.offset_left = -2
	dot.offset_top = -2
	dot.offset_right = 2
	dot.offset_bottom = 2
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(dot)

	_hud = Label.new()
	_hud.position = Vector2(12, 10)
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_hud)


func _physics_process(_delta: float) -> void:
	if not _running:
		return

	# Keep the player's origin offset current so its water query works in logical
	# space, then stream and follow.
	_player.render_origin = render_origin
	var logical: Vector3 = _player.position + render_origin
	_streamer.update_streaming(logical, render_origin)
	_water.follow(_player.position)

	_maybe_rebase()

	if _hud != null and _day_night != null:
		var state := "swim" if _player.swimming else "walk"
		var vel: Vector3 = _player.velocity
		var speed := Vector2(vel.x, vel.z).length()
		# Position and velocity update every frame so a playtester can confirm
		# movement objectively from the HUD, independent of visual terrain cues.
		# The look line reports the raw mouse delta received this frame and the
		# live yaw/pitch, so a playtest can tell "no motion events arriving" from
		# "events arrive but the camera does not rotate". Diagnostic, kept on
		# purpose for the next playtest.
		var look: Dictionary = _player.consume_look_debug()
		var rel: Vector2 = look["rel"]
		_hud.text = "%s  %s\npos (%.1f, %.1f, %.1f)\nvel %.2f m/s  (%.1f, %.1f, %.1f)\nlook rel (%.0f, %.0f)  yaw %.2f  pitch %.2f" % [
			_day_night.time_string(), state,
			logical.x, logical.y, logical.z,
			speed, vel.x, vel.y, vel.z,
			rel.x, rel.y, look["yaw"], look["pitch"],
		]

	if _smoketest_frames >= 0:
		_frames += 1
		if _frames >= _smoketest_frames:
			print("[game_main] smoketest complete after %d frames, chunks=%d" % [_frames, _streamer.loaded_chunk_count()])
			get_tree().quit(0)


# Floating-origin rebase: when the player's LOCAL position drifts past the
# threshold, snap the world back so the player is near local zero again. The
# shift is applied to the origin (so logical positions are unchanged), to the
# player, and to every loaded chunk. Snapped to the chunk grid so chunk
# coordinates line up across the rebase.
func _maybe_rebase() -> void:
	var flat := Vector2(_player.position.x, _player.position.z)
	if flat.length() < REBASE_THRESHOLD:
		return
	var chunk_size: float = TerrainChunkScript.CHUNK_SIZE
	var shift := Vector3(
		round(_player.position.x / chunk_size) * chunk_size,
		0.0,
		round(_player.position.z / chunk_size) * chunk_size
	)
	if shift == Vector3.ZERO:
		return
	render_origin += shift
	_player.position -= shift
	_player.render_origin = render_origin
	_streamer.reposition_all(render_origin)
	print("[game_main] rebased origin by %s, new origin=%s" % [shift, render_origin])


# --- Input actions ----------------------------------------------------------
# Registered in code (so project.godot stays minimal) from the single binding
# table in input_actions.gd, which the regression test also reads so the two
# cannot drift.
func _setup_input_actions() -> void:
	InputActionsScript.register()


func _parse_args(raw: PackedStringArray) -> Dictionary:
	var parsed := {}
	for arg in raw:
		if arg.begins_with("--") and arg.contains("="):
			var trimmed := arg.substr(2)
			var eq := trimmed.find("=")
			parsed[trimmed.substr(0, eq)] = trimmed.substr(eq + 1)
	return parsed
