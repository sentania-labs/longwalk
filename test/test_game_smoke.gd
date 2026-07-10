extends SceneTree

# Headless integration smoke test for the M2 walkable world. It boots the full
# game wiring (game_main -> sim sampler + spawn + streamer + player scene) in a
# headless SceneTree, steps a few physics frames, and asserts the world came up
# sane: chunks streamed in, the player exists, and it settled onto (or above)
# the terrain rather than falling forever.
#
# It calls start_game() directly rather than going through _ready's command-line
# path: adding a node during a --script SceneTree's _initialize does not drive
# _ready the way the real main-loop main scene does, so the direct call is the
# reliable way to exercise the wiring headless. The rendering main loop itself
# cannot run headless with the gl_compatibility renderer, so this test covers
# everything except the actual pixel draw.
#
# Invocation (run by tools/run_tests.sh):
#   godot --headless --script res://test/test_game_smoke.gd

const GameMainScript := preload("res://src/render/game_main.gd")
const MainScene := preload("res://scenes/main.tscn")
const PlayerScene := preload("res://scenes/player.tscn")

const SEED := 424242


func _initialize() -> void:
	var failures := 0

	# Scenes must load and instantiate without error.
	failures += _check(MainScene != null, "main.tscn loads")
	failures += _check(PlayerScene != null, "player.tscn loads")
	var player_probe := PlayerScene.instantiate()
	failures += _check(player_probe != null and player_probe is CharacterBody3D, "player instantiates as CharacterBody3D")
	if player_probe != null:
		player_probe.free()

	# Boot the game with a fixed seed and step several physics frames so
	# streaming runs and the player settles.
	var pos_a := _boot_and_step(SEED, 30)
	failures += _check(_last_running, "game reached running state")
	failures += _check(_last_chunks > 0, "terrain chunks streamed in (%d)" % _last_chunks)
	failures += _check(pos_a.y > -1000.0, "player did not fall through the world (y=%.2f)" % pos_a.y)

	# The boot must be deterministic for a fixed seed: same spawn position and
	# same streamed chunk count.
	var chunks_a := _last_chunks
	var pos_b := _boot_and_step(SEED, 30)
	failures += _check(pos_a.is_equal_approx(pos_b), "spawn position is deterministic for a fixed seed")
	failures += _check(chunks_a == _last_chunks, "streamed chunk count is deterministic (%d vs %d)" % [chunks_a, _last_chunks])

	if failures == 0:
		print("\nAll game smoke checks passed.")
		quit(0)
	else:
		print("\n%d game smoke check(s) FAILED." % failures)
		quit(1)


var _last_running := false
var _last_chunks := 0


# Boot a fresh game for `seed_value`, step `frames` physics frames, and return
# the player's final local position. Records running state and chunk count.
func _boot_and_step(seed_value: int, frames: int) -> Vector3:
	var game = GameMainScript.new()
	root.add_child(game)
	game.start_game(seed_value)
	for i in range(frames):
		game._physics_process(1.0 / 60.0)
	_last_running = game._running
	_last_chunks = game._streamer.loaded_chunk_count()
	var pos: Vector3 = game._player.position
	game.free()
	return pos


func _check(condition: bool, label: String) -> int:
	if condition:
		print("[PASS] %s" % label)
		return 0
	print("[FAIL] %s" % label)
	return 1
