extends Node2D

# RENDER-side assembly of the starter town: reads TownLayout (SIM-side, see
# src/sim/town_layout.gd) and builds the actual ground sprites, building
# sprites/collision, boundary collision, and player. Nothing here computes
# world layout, it only draws what TownLayout already decided.

const TownLayoutScript := preload("res://src/sim/town_layout.gd")
const PlayerScene := preload("res://scenes/player.tscn")

const GROUND_TEXTURE_PATHS := {
	TownLayoutScript.GroundTile.GRASS: "res://tools/art/out/processed/grass_ground_tile.png",
	TownLayoutScript.GroundTile.PATH: "res://tools/art/out/processed/ground_path_tile.png",
}

const BUILDING_TEXTURE_PATHS := {
	"building_facade": "res://tools/art/out/processed/building_facade.png",
	"cottage_facade": "res://tools/art/out/processed/cottage_facade.png",
}

const TILE_SIZE := TownLayoutScript.TILE_SIZE
const BOUNDARY_THICKNESS := 64.0
const PLACEHOLDER_MARKER_COLOR := Color(0.9, 0.75, 0.2, 0.25)

@onready var _ground_layer: Node2D = $GroundLayer
@onready var _world: Node2D = $World
@onready var _boundary: Node2D = $Boundary
@onready var _name_label: Label = $UI/NameLabel

var _layout: TownLayoutScript

# Character choices from character creation. Public and settable directly
# (a headless test sets these before calling _ready()/build() rather than
# going through the GameState autoload) so this scene never hard-depends on
# tree-entry-triggered autoload resolution to be exercised. In normal play
# _ready() fills these from the GameState autoload if they were left unset.
var character_name := ""
var appearance_variant := ""


func _ready() -> void:
	if character_name.is_empty() or appearance_variant.is_empty():
		_load_from_game_state()
	_layout = TownLayoutScript.build_starter_town()
	_build_ground()
	_build_buildings()
	_build_boundary()
	_spawn_player()
	_name_label.text = character_name


func _load_from_game_state() -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null:
		character_name = "Traveler"
		appearance_variant = "moss"
		return
	character_name = game_state.character_name
	appearance_variant = game_state.appearance_variant


func _build_ground() -> void:
	for y in range(_layout.height):
		for x in range(_layout.width):
			var tile: int = _layout.ground[y][x]
			var sprite := Sprite2D.new()
			sprite.texture = load(GROUND_TEXTURE_PATHS[tile])
			sprite.centered = false
			sprite.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
			_ground_layer.add_child(sprite)


func _build_buildings() -> void:
	for building in _layout.buildings:
		if building.is_npc_placeholder:
			_build_placeholder_marker(building)
			continue

		var footprint_px := Vector2(building.footprint.x, building.footprint.y) * TILE_SIZE
		var footprint_origin := Vector2(building.cell.x, building.cell.y) * TILE_SIZE
		var footprint_center := footprint_origin + footprint_px / 2.0

		var texture: Texture2D = load(BUILDING_TEXTURE_PATHS[building.sprite_key])
		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.centered = true
		# Y-sort (see _world.y_sort_enabled in starter_town.tscn) compares
		# each direct child's own `position`, not where its texture is drawn.
		# The player's sort key is its feet (the CharacterBody2D's own
		# origin, see player.tscn's Sprite2D offset). To sort consistently
		# against that, this sprite's `position` must ALSO be the footprint's
		# bottom edge, with the taller texture then drawn upward from there
		# via `offset` rather than by moving `position` itself; moving
		# `position` up by half the texture height (as an earlier version of
		# this code did) put the sort key at the sprite's vertical middle,
		# which flipped front/back ordering against the player across
		# roughly the lower half of the building's height.
		sprite.position = Vector2(footprint_center.x, footprint_origin.y + footprint_px.y)
		sprite.offset = Vector2(0, -texture.get_height() / 2.0)
		_world.add_child(sprite)

		var body := StaticBody2D.new()
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = footprint_px
		shape.shape = rect
		body.add_child(shape)
		body.position = footprint_center
		_world.add_child(body)


func _build_placeholder_marker(building) -> void:
	var footprint_px := Vector2(building.footprint.x, building.footprint.y) * TILE_SIZE
	var footprint_origin := Vector2(building.cell.x, building.cell.y) * TILE_SIZE
	var marker := Polygon2D.new()
	marker.polygon = PackedVector2Array([
		Vector2(0, 0),
		Vector2(footprint_px.x, 0),
		Vector2(footprint_px.x, footprint_px.y),
		Vector2(0, footprint_px.y),
	])
	marker.color = PLACEHOLDER_MARKER_COLOR
	marker.position = footprint_origin
	_ground_layer.add_child(marker)


func _build_boundary() -> void:
	var size := _layout.pixel_size()
	_add_boundary_wall(Vector2(size.x / 2.0, -BOUNDARY_THICKNESS / 2.0), Vector2(size.x, BOUNDARY_THICKNESS))
	_add_boundary_wall(Vector2(size.x / 2.0, size.y + BOUNDARY_THICKNESS / 2.0), Vector2(size.x, BOUNDARY_THICKNESS))
	_add_boundary_wall(Vector2(-BOUNDARY_THICKNESS / 2.0, size.y / 2.0), Vector2(BOUNDARY_THICKNESS, size.y))
	_add_boundary_wall(Vector2(size.x + BOUNDARY_THICKNESS / 2.0, size.y / 2.0), Vector2(BOUNDARY_THICKNESS, size.y))


func _add_boundary_wall(center: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)
	body.position = center
	_boundary.add_child(body)


func _spawn_player() -> void:
	var player := PlayerScene.instantiate()
	player.set_appearance(appearance_variant)
	var spawn_cell := Vector2i(int(_layout.width / 2.0), 7)
	player.position = Vector2(spawn_cell.x, spawn_cell.y) * TILE_SIZE + Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)
	_world.add_child(player)

	var camera: Camera2D = player.get_node("Camera2D")
	var pixel_size := _layout.pixel_size()
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(pixel_size.x)
	camera.limit_bottom = int(pixel_size.y)
