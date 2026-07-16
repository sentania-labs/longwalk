extends Node

# Display settings: window mode (borderless fullscreen vs windowed) and the
# windowed resolution, persisted to user://settings.cfg and re-applied at
# boot.
#
# This is an autoload for two reasons that a per-scene script could not
# cover: the saved mode has to be applied before the first scene draws, so
# the player never sees the default window flash to their chosen one, and
# the fullscreen shortcut has to work from every scene rather than only
# while the settings screen happens to be open.
#
# Render-layer only (see CLAUDE.md, simulation/rendering separation). The
# sim layer must never read from here; nothing about window size may reach a
# simulation decision, or the headless/server build would diverge from the
# windowed one.

const CONFIG_PATH := "user://settings.cfg"
const SECTION := "display"
const KEY_FULLSCREEN := "fullscreen"
const KEY_WINDOWED_WIDTH := "windowed_width"
const KEY_WINDOWED_HEIGHT := "windowed_height"

const DEFAULT_FULLSCREEN := false
const DEFAULT_RESOLUTION := Vector2i(1280, 720)

# Windowed sizes offered by the settings screen. All 16:9, matching the base
# viewport declared in project.godot: stretch/aspect="keep" letterboxes any
# other shape rather than distorting it, so a non-16:9 entry here would only
# buy the player black bars.
const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
]

# Emitted after any applied change, including one made via the F11 /
# Alt+Enter shortcut while the settings screen is open, so open UI can
# re-sync instead of showing a stale toggle.
signal changed

var fullscreen := DEFAULT_FULLSCREEN
var windowed_resolution := DEFAULT_RESOLUTION


func _ready() -> void:
	# ALWAYS so the fullscreen shortcut keeps working if the game is ever
	# paused (a pause menu is a later milestone, but an autoload that stops
	# responding to F11 mid-pause would be a confusing thing to debug then).
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_settings()
	# Before the first apply(), not only when the player opens the settings
	# screen: a settings file carried over from a larger monitor would
	# otherwise size the first window to something that does not fit.
	clamp_to_available()
	apply()


# The screen area a window may actually occupy: the desktop minus whatever the
# OS reserves (a taskbar, a dock, a menu bar). Smaller than the physical
# resolution on essentially every real desktop, which is why the presets are
# checked against this rather than against screen_get_size().
func _usable_rect() -> Rect2i:
	return DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())


# The presets that fit the current screen. Kept as a pure function of the
# usable size so it is testable without a display server; available_resolutions()
# supplies the real one.
static func resolutions_fitting(usable_size: Vector2i) -> Array[Vector2i]:
	var fitting: Array[Vector2i] = []
	for resolution in RESOLUTIONS:
		if resolution.x <= usable_size.x and resolution.y <= usable_size.y:
			fitting.append(resolution)
	# Never return nothing. On a screen smaller than the smallest preset the
	# window is clamped by apply() regardless, and a picker with no entries at
	# all would just read as broken.
	if fitting.is_empty():
		fitting.append(RESOLUTIONS[0])
	return fitting


# Where a window of `size` sits centered in `usable`, never starting above or
# left of the usable area. The clamp is the point: on a 1080p monitor the
# usable height is under 1080 once the taskbar is subtracted, so centering the
# 1920x1080 preset there would otherwise yield a negative y and put the title
# bar out of reach. Pure, for the same testability reason as above.
static func centered_position(usable: Rect2i, size: Vector2i) -> Vector2i:
	var centered := usable.position + (usable.size - size) / 2
	return Vector2i(maxi(centered.x, usable.position.x), maxi(centered.y, usable.position.y))


func available_resolutions() -> Array[Vector2i]:
	if DisplayServer.get_name() == "headless":
		return RESOLUTIONS
	return resolutions_fitting(_usable_rect().size)


# Snaps windowed_resolution to the largest preset this screen can show if the
# current choice does not fit. available_resolutions() is ascending, so the
# last entry is the largest.
func clamp_to_available() -> void:
	var available := available_resolutions()
	if not windowed_resolution in available:
		windowed_resolution = available[available.size() - 1]


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen"):
		set_fullscreen(not fullscreen)
		get_viewport().set_input_as_handled()


func set_fullscreen(value: bool) -> void:
	fullscreen = value
	apply()
	save_settings()


func set_windowed_resolution(value: Vector2i) -> void:
	windowed_resolution = value
	apply()
	save_settings()


# Pushes the current settings onto the actual window. Safe to call when no
# real window exists: the headless display server has no window to size, and
# calling into it would be meaningless rather than merely wasteful.
func apply() -> void:
	if DisplayServer.get_name() == "headless":
		changed.emit()
		return

	if fullscreen:
		# WINDOW_MODE_FULLSCREEN, not WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		# Godot 4's plain fullscreen is a borderless window sized to the
		# screen, which alt-tabs cleanly. Exclusive fullscreen takes the
		# display mode and makes alt-tab a mode switch.
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		var usable := _usable_rect()
		# Final clamp, even though clamp_to_available() already snapped the
		# choice to a fitting preset: it catches a screen too small for even
		# the smallest preset. stretch/aspect="keep" letterboxes the result
		# rather than distorting it, so a clamped, off-aspect window is a
		# cosmetic cost, not a broken one.
		var size := windowed_resolution.min(usable.size)
		DisplayServer.window_set_size(size)
		# Re-position after every resize: Godot keeps the previous top-left
		# corner, so a window that grew would otherwise hang off the screen
		# edge. Computed from `size` rather than read back via
		# window_get_size(), because the resize above is a request to the
		# window manager and not an immediate change; on X11 the read-back
		# still reports the PREVIOUS size this soon, which lands the window
		# off-center by half the delta.
		DisplayServer.window_set_position(centered_position(usable, size))

	changed.emit()


func load_settings(path: String = CONFIG_PATH) -> void:
	var config := ConfigFile.new()
	# Any read failure (no file on first run, or a corrupt/hand-edited one)
	# leaves the defaults in place rather than propagating: unreadable
	# settings are not worth failing a boot over.
	if config.load(path) != OK:
		fullscreen = DEFAULT_FULLSCREEN
		windowed_resolution = DEFAULT_RESOLUTION
		return

	fullscreen = bool(config.get_value(SECTION, KEY_FULLSCREEN, DEFAULT_FULLSCREEN))
	var width := int(config.get_value(SECTION, KEY_WINDOWED_WIDTH, DEFAULT_RESOLUTION.x))
	var height := int(config.get_value(SECTION, KEY_WINDOWED_HEIGHT, DEFAULT_RESOLUTION.y))
	var loaded := Vector2i(width, height)
	# Only accept a size this build actually offers. A settings file written
	# by an older build (or by hand) could otherwise pin the window to a
	# resolution the settings screen cannot represent, leaving the player
	# unable to change it back from the UI.
	windowed_resolution = loaded if loaded in RESOLUTIONS else DEFAULT_RESOLUTION


func save_settings(path: String = CONFIG_PATH) -> void:
	var config := ConfigFile.new()
	config.set_value(SECTION, KEY_FULLSCREEN, fullscreen)
	config.set_value(SECTION, KEY_WINDOWED_WIDTH, windowed_resolution.x)
	config.set_value(SECTION, KEY_WINDOWED_HEIGHT, windowed_resolution.y)
	config.save(path)
