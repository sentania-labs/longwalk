extends Control

# Title screen: two options for this first playable slice, "New Game" and
# "Quit". There is no "Continue" here: there is no save system yet (see
# ARCHITECTURE.md, "three-layer persistence design", not implemented until a
# later milestone), so a returning-player option would have nothing to load.
# "Start Game" and "New Character" also collapse into one "New Game" button:
# without persistence they are the same action, since every playthrough
# starts at character creation.

func _on_new_game_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/character_creation.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
