extends SceneTree

# Regression guard for the "WASD/Esc do nothing" class of bug: if the player
# controller polls an input action that was never registered in the InputMap,
# Input.is_action_pressed() silently returns false forever and the key is dead.
# That is invisible until someone playtests the export, so it is pinned here.
#
# This test asserts two things, both against the SAME source of truth
# (input_actions.gd, which the running game also registers from):
#   1. Every binding in InputActions.BINDINGS lands in the live InputMap after
#      InputActions.register() runs (the game's startup path).
#   2. Every action name the render code actually references by string (via
#      Input.is_action_pressed / get_action_strength / etc., or the equivalent
#      InputEvent.is_action_pressed) exists in that InputMap. This is the check
#      that would have caught the drift: a controller referencing an action the
#      binding table forgot.
#
# Invocation (run by tools/run_tests.sh):
#   godot --headless --script res://test/legacy_procedural/test_input_map.gd

const InputActionsScript := preload("res://src/legacy_procedural/render/input_actions.gd")

# Render scripts that reference input actions by name. Scanned as text so a typo
# or a newly-referenced-but-unregistered action fails CI, not a playtest.
const SCANNED_SOURCES := [
	"res://src/legacy_procedural/render/player_controller.gd",
	"res://src/legacy_procedural/render/game_main.gd",
]


func _initialize() -> void:
	var failures := 0

	# 1. The game's own registration path must populate the InputMap.
	InputActionsScript.register()
	for action in InputActionsScript.BINDINGS:
		failures += _check(InputMap.has_action(action), "InputMap has registered action '%s'" % action)

	# 2. Every action name referenced in render source must be registered.
	var referenced := _scan_referenced_actions()
	failures += _check(referenced.size() > 0, "found action references in render source (%d)" % referenced.size())
	for action in referenced:
		failures += _check(InputMap.has_action(action),
			"referenced action '%s' is registered (would be a silently-dead key otherwise)" % action)

	if failures == 0:
		print("\nAll input-map checks passed.")
		quit(0)
	else:
		print("\n%d input-map check(s) FAILED." % failures)
		quit(1)


# Collect the distinct action-name string literals passed to the input-polling
# calls across SCANNED_SOURCES.
func _scan_referenced_actions() -> Array:
	var re := RegEx.new()
	# Matches is_action_pressed("x") / is_action_just_pressed / is_action_released
	# / is_action_just_released / get_action_strength / get_action_raw_strength.
	re.compile('(?:is_action_pressed|is_action_just_pressed|is_action_released|is_action_just_released|get_action_strength|get_action_raw_strength)\\(\\s*"([^"]+)"')
	var found := {}
	for path in SCANNED_SOURCES:
		var f := FileAccess.open(path, FileAccess.READ)
		if f == null:
			push_error("could not open %s for scanning" % path)
			continue
		var text := f.get_as_text()
		f.close()
		for m in re.search_all(text):
			found[m.get_string(1)] = true
	return found.keys()


func _check(condition: bool, label: String) -> int:
	if condition:
		print("[PASS] %s" % label)
		return 0
	print("[FAIL] %s" % label)
	return 1
