extends Node

# GameState is the session-only carrier for the choices made in character
# creation (name, appearance) so the starter town can pick them up. It holds
# plain data with no Viewport/Camera/UI dependency, so it stays on the SIM
# side of the module boundary (see CLAUDE.md) even though it is registered
# as an autoload for convenience. There is no save/load here; persistence is
# a later milestone (see ARCHITECTURE.md, "three-layer persistence design").

const DEFAULT_APPEARANCE_VARIANT := "moss"
const DEFAULT_CHARACTER_NAME := "Traveler"

var character_name: String = DEFAULT_CHARACTER_NAME
var appearance_variant: String = DEFAULT_APPEARANCE_VARIANT


func reset() -> void:
	character_name = DEFAULT_CHARACTER_NAME
	appearance_variant = DEFAULT_APPEARANCE_VARIANT
