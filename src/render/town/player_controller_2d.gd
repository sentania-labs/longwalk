extends CharacterBody2D
class_name PlayerController2D

# RENDER-side top-down player controller: 8-directional movement, collision
# against buildings and the town boundary via Godot's built-in physics
# (StaticBody2D colliders the starter-town render layer builds from
# TownLayout). No sim/world-state logic lives here.

const SPEED := 220.0


func set_appearance(appearance_variant: String) -> void:
	# get_node() rather than an @onready var: set_appearance() is meant to be
	# callable right after instantiate(), including from a headless test that
	# never adds the node to a live SceneTree (see test/active_path/), and
	# @onready resolution only fires on tree entry.
	var sprite: Sprite2D = get_node("Sprite2D")
	var path := "res://tools/art/out/processed/player_character_%s.png" % appearance_variant
	sprite.texture = load(path)


func _physics_process(_delta: float) -> void:
	var input_vector := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)
	if input_vector.length() > 1.0:
		input_vector = input_vector.normalized()
	velocity = input_vector * SPEED
	move_and_slide()
