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
	apply()


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
		DisplayServer.window_set_size(windowed_resolution)
		_center_window()

	changed.emit()


# Re-centering matters when leaving fullscreen or growing the window: Godot
# keeps the previous top-left corner, so a window that grew past the screen
# edge would otherwise end up with its title bar off-screen.
#
# Centers on windowed_resolution rather than on window_get_size(): the resize
# above is a request to the window manager, not an immediate change, so on X11
# window_get_size() still reports the PREVIOUS size when read back this soon
# and the window lands off-center by half the delta.
func _center_window() -> void:
	var screen := DisplayServer.window_get_current_screen()
	var usable := DisplayServer.screen_get_usable_rect(screen)
	DisplayServer.window_set_position(usable.position + (usable.size - windowed_resolution) / 2)


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
