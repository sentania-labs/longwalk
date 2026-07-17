extends RefCounted
class_name PlayerWorldFixture

const TownLayoutScript := preload("res://src/sim/town_layout.gd")

const TILE_SIZE := 128
const SPRITE_CELL_SIZE := Vector2i(160, 160)
const FEET_CONTACT_ROW := 159
const SPRITE_OFFSET := Vector2(0, -80)
const SHIPPING_DISPLAY_SCALE := Vector2.ONE

const LAYOUT_SIZE := Vector2i(18, 14)
const STREET_ROW := 7
const SPAWN_CELL := Vector2i(9, 7)
const SPAWN_WORLD_POSITION := Vector2(1216, 960)


static func build_layout():
	return TownLayoutScript.build_starter_town()
