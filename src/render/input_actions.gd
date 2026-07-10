extends RefCounted
class_name InputActions

# Single source of truth for the game's input action names and their default
# physical-key bindings. game_main registers these at startup and the player
# controller polls them by name; test/test_input_map.gd asserts the two can
# never drift (every action the controller references must live in this map, and
# every entry here must land in the live InputMap). RENDER-side: input is a
# render/UI concern and the sim core never reads it.
#
# The actions are registered in code (rather than baked into project.godot) so
# the project descriptor stays minimal, but the binding table lives here, apart
# from the wiring, precisely so a test can verify it without booting the game.
#
# Physical keycodes (not logical keycodes) are used so WASD lands on the same
# physical keys regardless of keyboard layout, and so the bindings survive the
# export unchanged.

const BINDINGS := {
	"move_forward": KEY_W,
	"move_back": KEY_S,
	"move_left": KEY_A,
	"move_right": KEY_D,
	"sprint": KEY_SHIFT,
	"jump": KEY_SPACE,
	"sleep": KEY_R,
	"toggle_camera": KEY_C,
	"toggle_mouse": KEY_ESCAPE,
}


# Register every binding above into the live InputMap, idempotently. Called once
# at startup by game_main, and directly by the regression test.
static func register() -> void:
	for action in BINDINGS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		var ev := InputEventKey.new()
		ev.physical_keycode = BINDINGS[action]
		InputMap.action_add_event(action, ev)
