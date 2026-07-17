extends Node2D
class_name ClickMarker

# RENDER-side click feedback: a brief expanding ring at the cell the click
# actually routed to. Pure feedback, no sim state and no input handling; the
# starter town moves it and calls ping() when a route is accepted.
#
# Drawn with _draw() rather than a texture: it is a Godot primitive, so it
# needs no art pass and does not block on the sprite work in this round.
# Deliberately shown at the RESOLVED destination cell centre, not at the raw
# mouse position, so that a click on a cottage roof visibly answers with where
# the player is actually going (see NavGrid.nearest_walkable).

const DURATION := 0.45
const START_RADIUS := 10.0
const END_RADIUS := 46.0
const RING_WIDTH := 3.0
const RING_COLOR := Color(1.0, 0.98, 0.85)

var _elapsed := DURATION
var _active := false


func _ready() -> void:
	visible = false


func ping() -> void:
	_elapsed = 0.0
	_active = true
	visible = true
	queue_redraw()


func _process(delta: float) -> void:
	if not _active:
		return
	_elapsed += delta
	if _elapsed >= DURATION:
		_active = false
		visible = false
	queue_redraw()


func _draw() -> void:
	if not _active:
		return
	var progress: float = clampf(_elapsed / DURATION, 0.0, 1.0)
	var radius: float = lerpf(START_RADIUS, END_RADIUS, ease(progress, 0.35))
	var color := RING_COLOR
	color.a = 1.0 - progress
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, color, RING_WIDTH, true)
