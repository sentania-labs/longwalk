extends Control

# Character creation: a name field and a choice of tunic-color presets
# rendered over the base player_character art (see
# tools/art/process_assets.py for how the preset textures are generated).
# On confirm, the choice is written into GameState (SIM-side session data,
# see src/sim/game_state.gd) and the starter town scene loads it from there.

const APPEARANCE_VARIANTS := ["moss", "slate_blue", "burgundy"]
const APPEARANCE_LABELS := {
	"moss": "Moss",
	"slate_blue": "Slate Blue",
	"burgundy": "Burgundy",
}
const PREVIEW_TEXTURE_PATH_FORMAT := "res://tools/art/out/processed/player_character_%s.png"

@onready var _name_edit: LineEdit = $CenterContainer/VBoxContainer/NameRow/NameEdit
@onready var _preview: TextureRect = $CenterContainer/VBoxContainer/Preview
@onready var _appearance_row: HBoxContainer = $CenterContainer/VBoxContainer/AppearanceRow

var _selected_appearance: String = APPEARANCE_VARIANTS[0]


func _ready() -> void:
	for variant in APPEARANCE_VARIANTS:
		var button := Button.new()
		button.text = APPEARANCE_LABELS[variant]
		button.toggle_mode = true
		button.button_pressed = variant == _selected_appearance
		button.pressed.connect(_on_appearance_selected.bind(variant, button))
		_appearance_row.add_child(button)
	_update_preview()


func _on_appearance_selected(variant: String, pressed_button: Button) -> void:
	_selected_appearance = variant
	for button in _appearance_row.get_children():
		button.button_pressed = button == pressed_button
	_update_preview()


func _update_preview() -> void:
	_preview.texture = load(PREVIEW_TEXTURE_PATH_FORMAT % _selected_appearance)


func _on_enter_town_pressed() -> void:
	var chosen_name := _name_edit.text.strip_edges()
	if chosen_name.is_empty():
		chosen_name = "Traveler"

	# get_node_or_null rather than the "GameState" autoload global
	# identifier: GDScript only resolves autoload singletons as compile-time
	# global identifiers when the project boots through its normal
	# main-scene path, not when this script is loaded from a `--script`
	# headless test (see test/active_path/, tools/run_tests.sh). The
	# fallback also means this scene degrades gracefully if ever opened
	# standalone in the editor.
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.character_name = chosen_name
		game_state.appearance_variant = _selected_appearance

	get_tree().change_scene_to_file("res://scenes/starter_town.tscn")
