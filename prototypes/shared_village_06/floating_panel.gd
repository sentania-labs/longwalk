extends Node
# One drag surface per window; placement uses the same logical canvas as the HUD.
var panel: Control
var handle: Control
var key := ""
var home := Vector2.ZERO
var dragging := false
var offset := Vector2.ZERO
var settings := ConfigFile.new()

static func attach(target: Control, title_bar: Control, identity: String) -> Node:
	var behavior = load("res://floating_panel.gd").new()
	behavior.panel = target
	behavior.handle = title_bar
	behavior.home = target.position
	behavior.key = identity
	target.add_child(behavior)
	return behavior

func _ready() -> void:
	add_to_group("floating_panels")
	handle.mouse_filter = Control.MOUSE_FILTER_STOP
	handle.mouse_default_cursor_shape = Control.CURSOR_MOVE
	handle.tooltip_text = "Drag to move this window"
	handle.gui_input.connect(_handle_input)
	panel.visibility_changed.connect(func():
		if not panel.visible: dragging = false
		else: _clamp.call_deferred()
	)
	get_viewport().size_changed.connect(func(): _clamp.call_deferred())
	select(key)

func select(identity: String) -> void:
	key = identity
	settings.load("user://window-positions.cfg")
	var saved = settings.get_value("windows",key,home)
	panel.position = saved if saved is Vector2 and saved.is_finite() else home
	_clamp.call_deferred()

func _handle_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		dragging = event.pressed
		offset = panel.get_global_mouse_position()-panel.position
		handle.accept_event()

func _input(event: InputEvent) -> void:
	if not dragging: return
	if event is InputEventMouseMotion:
		panel.position = panel.get_global_mouse_position()-offset
		_clamp()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		dragging = false
		settings.load("user://window-positions.cfg")
		settings.set_value("windows",key,panel.position)
		if settings.save("user://window-positions.cfg") != OK: push_error("Window position could not be saved")
		get_viewport().set_input_as_handled()

func _clamp() -> void:
	var available := panel.get_viewport_rect().size
	panel.position = panel.position.clamp(Vector2.ZERO,Vector2(maxf(0,available.x-panel.size.x),maxf(0,available.y-panel.size.y)))

func reset_position() -> void:
	settings.load("user://window-positions.cfg")
	settings.erase_section("windows")
	settings.save("user://window-positions.cfg")
	panel.position = home
	_clamp()
