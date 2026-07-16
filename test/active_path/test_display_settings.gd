extends SceneTree

# Guards the display-settings plumbing (src/render/display_settings.gd): the
# ConfigFile round-trip, the validation that keeps a stale or hand-edited
# settings file from pinning the window to a size the settings screen cannot
# offer back, and the InputMap registration behind the fullscreen shortcut.
#
# The window-mode side (DisplayServer.window_set_mode and friends) is
# deliberately not covered: there is no window under --headless to assert
# against, and DisplaySettings.apply() short-circuits there. What is testable
# without a display server is the persistence and the bindings, which is also
# where the silent-failure bugs live: a key that was never registered is dead
# forever with no error (the same class of bug pinned by
# test/legacy_procedural/test_input_map.gd), and a settings file that fails to
# round-trip just quietly forgets the player's choice.
#
# Invocation (run by tools/run_tests.sh):
#   godot --headless --script res://test/active_path/test_display_settings.gd

const DisplaySettingsScript := preload("res://src/render/display_settings.gd")
const SettingsScreenScene := preload("res://scenes/settings_screen.tscn")

# A scratch path under user://, not the real CONFIG_PATH: this test must not
# clobber the settings of whoever is running it locally.
const TEST_CONFIG_PATH := "user://test_settings.cfg"


func _initialize() -> void:
	var failures := 0

	failures += _check_defaults_when_absent()
	failures += _check_round_trip()
	failures += _check_rejects_unoffered_resolution()
	failures += _check_resolutions_match_base_aspect()
	failures += _check_fullscreen_action_bindings()
	failures += _check_settings_screen_instantiates()

	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_CONFIG_PATH))

	if failures == 0:
		print("\nAll display settings checks passed.")
		quit(0)
	else:
		print("\n%d display settings check(s) FAILED." % failures)
		quit(1)


func _check_defaults_when_absent() -> int:
	var failures := 0
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_CONFIG_PATH))

	var settings := DisplaySettingsScript.new()
	settings.fullscreen = true
	settings.windowed_resolution = Vector2i(1920, 1080)
	# A missing file must reset to defaults, not leave whatever was in memory.
	settings.load_settings(TEST_CONFIG_PATH)

	failures += _check(settings.fullscreen == DisplaySettingsScript.DEFAULT_FULLSCREEN, "missing settings file falls back to the default window mode")
	failures += _check(settings.windowed_resolution == DisplaySettingsScript.DEFAULT_RESOLUTION, "missing settings file falls back to the default resolution")
	settings.free()
	return failures


func _check_round_trip() -> int:
	var failures := 0
	var writer := DisplaySettingsScript.new()
	writer.fullscreen = true
	writer.windowed_resolution = Vector2i(1920, 1080)
	writer.save_settings(TEST_CONFIG_PATH)

	var reader := DisplaySettingsScript.new()
	reader.load_settings(TEST_CONFIG_PATH)

	failures += _check(reader.fullscreen == true, "fullscreen survives a save/load round-trip")
	failures += _check(reader.windowed_resolution == Vector2i(1920, 1080), "windowed resolution survives a save/load round-trip (%s)" % reader.windowed_resolution)

	# The false case separately: `false` is also get_value()'s implicit
	# fallback shape, so a save that silently wrote nothing would still read
	# back as false and pass a true-only check.
	writer.fullscreen = false
	writer.windowed_resolution = Vector2i(1600, 900)
	writer.save_settings(TEST_CONFIG_PATH)
	reader.load_settings(TEST_CONFIG_PATH)

	failures += _check(reader.fullscreen == false, "windowed mode survives a save/load round-trip")
	failures += _check(reader.windowed_resolution == Vector2i(1600, 900), "a second windowed resolution survives a save/load round-trip (%s)" % reader.windowed_resolution)

	writer.free()
	reader.free()
	return failures


func _check_rejects_unoffered_resolution() -> int:
	var failures := 0
	# Simulates a settings file written by a build that offered a size this
	# one does not, or edited by hand. Accepting it would size the window to
	# something the settings screen has no entry for, so the player could not
	# pick their way back out of it.
	var config := ConfigFile.new()
	config.set_value(DisplaySettingsScript.SECTION, DisplaySettingsScript.KEY_FULLSCREEN, false)
	config.set_value(DisplaySettingsScript.SECTION, DisplaySettingsScript.KEY_WINDOWED_WIDTH, 800)
	config.set_value(DisplaySettingsScript.SECTION, DisplaySettingsScript.KEY_WINDOWED_HEIGHT, 600)
	config.save(TEST_CONFIG_PATH)

	var settings := DisplaySettingsScript.new()
	settings.load_settings(TEST_CONFIG_PATH)
	failures += _check(settings.windowed_resolution == DisplaySettingsScript.DEFAULT_RESOLUTION,
		"a resolution this build does not offer falls back to the default (%s)" % settings.windowed_resolution)
	settings.free()
	return failures


# project.godot sets window/stretch/aspect="keep", which letterboxes anything
# that is not the base viewport's aspect ratio. An offered resolution that did
# not match would therefore ship guaranteed black bars, so the list and the
# base viewport are pinned together here.
func _check_resolutions_match_base_aspect() -> int:
	var failures := 0
	var base_width: int = ProjectSettings.get_setting("display/window/size/viewport_width")
	var base_height: int = ProjectSettings.get_setting("display/window/size/viewport_height")
	var base_aspect := float(base_width) / float(base_height)

	failures += _check(DisplaySettingsScript.DEFAULT_RESOLUTION == Vector2i(base_width, base_height),
		"the default resolution is the base viewport size (%dx%d)" % [base_width, base_height])
	failures += _check(DisplaySettingsScript.RESOLUTIONS.size() > 0, "at least one windowed resolution is offered")

	for resolution in DisplaySettingsScript.RESOLUTIONS:
		var aspect := float(resolution.x) / float(resolution.y)
		failures += _check(is_equal_approx(aspect, base_aspect),
			"offered resolution %s matches the base viewport aspect ratio" % resolution)

	return failures


# The shortcut is polled by name via InputEvent.is_action_pressed, which
# returns false forever for an unregistered action rather than erroring. Both
# bindings are asserted individually: dropping one would leave the other
# working, so a has_action() check alone would not notice.
func _check_fullscreen_action_bindings() -> int:
	var failures := 0
	failures += _check(InputMap.has_action("toggle_fullscreen"), "InputMap has the toggle_fullscreen action")
	if not InputMap.has_action("toggle_fullscreen"):
		return failures

	var has_f11 := false
	var has_alt_enter := false
	for event in InputMap.action_get_events("toggle_fullscreen"):
		if not event is InputEventKey:
			continue
		if event.keycode == KEY_F11:
			has_f11 = true
		if event.keycode == KEY_ENTER and event.alt_pressed:
			has_alt_enter = true

	failures += _check(has_f11, "toggle_fullscreen is bound to F11")
	failures += _check(has_alt_enter, "toggle_fullscreen is bound to Alt+Enter")
	return failures


func _check_settings_screen_instantiates() -> int:
	var failures := 0
	var instance := SettingsScreenScene.instantiate()
	failures += _check(instance != null and instance is Control, "settings_screen.tscn instantiates as Control")
	if instance != null:
		instance.free()
	return failures


func _check(condition: bool, label: String) -> int:
	if condition:
		print("[PASS] %s" % label)
		return 0
	print("[FAIL] %s" % label)
	return 1
