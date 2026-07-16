extends Control

# Settings screen, reached from the title screen. Display options only for
# now (window mode, windowed resolution); audio and input remapping are not
# in scope until there is anything to remap.
#
# The actual window work lives in the DisplaySettings autoload
# (src/render/display_settings.gd), not here: the shortcut and the
# boot-time apply both need it to outlive this scene.

@onready var _fullscreen_check: CheckButton = $CenterContainer/VBoxContainer/FullscreenRow/FullscreenCheck
@onready var _resolution_row: HBoxContainer = $CenterContainer/VBoxContainer/ResolutionRow
@onready var _resolution_option: OptionButton = $CenterContainer/VBoxContainer/ResolutionRow/ResolutionOption

var _display_settings: Node


func _ready() -> void:
	# get_node_or_null rather than the "DisplaySettings" autoload global
	# identifier, for the same reason character_creation.gd uses it: the
	# global is only resolved on a normal main-scene boot, not when a
	# headless `--script` test loads this scene (see test/active_path/).
	_display_settings = get_node_or_null("/root/DisplaySettings")
	if _display_settings == null:
		return

	for resolution in _display_settings.RESOLUTIONS:
		_resolution_option.add_item("%d x %d" % [resolution.x, resolution.y])

	_display_settings.changed.connect(_sync_from_settings)
	_sync_from_settings()


# One-way refresh from the autoload's state. Driven by DisplaySettings.changed
# as well as _ready(), so toggling fullscreen with F11 while this screen is
# open moves the checkbox too.
func _sync_from_settings() -> void:
	_fullscreen_check.set_pressed_no_signal(_display_settings.fullscreen)

	var index: int = _display_settings.RESOLUTIONS.find(_display_settings.windowed_resolution)
	if index >= 0:
		_resolution_option.selected = index

	# Windowed resolution is meaningless in fullscreen (the window takes the
	# screen's size), so the picker greys out rather than silently ignoring
	# the player's choice.
	_resolution_row.modulate.a = 0.5 if _display_settings.fullscreen else 1.0
	_resolution_option.disabled = _display_settings.fullscreen


func _on_fullscreen_toggled(pressed: bool) -> void:
	if _display_settings != null:
		_display_settings.set_fullscreen(pressed)


func _on_resolution_selected(index: int) -> void:
	if _display_settings != null:
		_display_settings.set_windowed_resolution(_display_settings.RESOLUTIONS[index])


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")
