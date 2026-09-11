extends CanvasLayer
const WORK = preload("res://src/sim/workshop.gd")
var link: Node
var village: Node3D
var connection_panel: Control
var panel: PanelContainer
var contents: VBoxContainer
var title: Label
var location: Label
var region_time: Label
var status: Label
var toast: Label
var belt: HBoxContainer
var current := ""
var person := {}
var signature := ""
var toast_age := 0.0
var last_scene_message := ""
var elapsed := 0.0
var vitals: Label

func _ready() -> void:
	layer = 7
	location = _label("Village square",22)
	location.position = Vector2(25,20)
	add_child(location)
	region_time = _label("Two Rivers · Late afternoon",14)
	region_time.position = Vector2(25,52)
	add_child(region_time)
	var menu := MenuButton.new()
	menu.flat = false
	menu.text = "Open an interface  ▾"
	menu.position = Vector2(615,20)
	menu.size = Vector2(220,42)
	_skin_button(menu)
	add_child(menu)
	for item in ["Character","Inventory","Skills","Journal","Map / travel","Camera / controls","Connection / world","Quit"]: menu.get_popup().add_item(item)
	menu.get_popup().id_pressed.connect(func(id):
		match id:
			0: _open("Character")
			1: _open("Inventory")
			2: _open("Skills")
			3: _open("Journal")
			4: _open("Map / travel")
			5: village.camera_controls.visible = not village.camera_controls.visible
			6: connection_panel.visible = not connection_panel.visible
			7: get_tree().quit()
	)
	var stats := _panel(Vector2(24,770),Vector2(270,100))
	status = _label("Not connected",16)
	stats.add_child(status)
	var quick := _panel(Vector2(1070,790),Vector2(345,85))
	belt = HBoxContainer.new()
	belt.add_theme_constant_override("separation",6)
	quick.add_child(belt)
	panel = _panel(Vector2(1030,155),Vector2(380,555))
	var column := VBoxContainer.new()
	panel.add_child(column)
	var head := HBoxContainer.new()
	column.add_child(head)
	title = _label("Inventory",23)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	_button("×",func(): panel.hide(); current="",head)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(350,495)
	column.add_child(scroll)
	contents = VBoxContainer.new()
	contents.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	contents.add_theme_constant_override("separation",10)
	scroll.add_child(contents)
	panel.hide()
	toast = _label("Open Connection / world to join your village.",16)
	toast.position = Vector2(390,710)
	toast.custom_minimum_size = Vector2(620,70)
	toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(toast)
	link.notice.connect(_notice)
	link.changed.connect(_state)
	_refresh_belt()

func _label(text: String, size: int = 16) -> Label:
	var value := Label.new()
	value.text = text
	value.add_theme_font_size_override("font_size",size)
	value.add_theme_color_override("font_color",Color("eee7ca"))
	value.add_theme_color_override("font_shadow_color",Color(0,0,0,0.8))
	value.add_theme_constant_override("shadow_offset_x",1)
	value.add_theme_constant_override("shadow_offset_y",1)
	return value
func _panel(pos: Vector2, size: Vector2) -> PanelContainer:
	var p := PanelContainer.new()
	p.position = pos
	p.custom_minimum_size = size
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08,0.14,0.09,0.94)
	style.border_color = Color("727c55")
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(14)
	p.add_theme_stylebox_override("panel",style)
	add_child(p)
	return p
func _skin_button(button: Button) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("303f29")
	style.border_color = Color("8c9166")
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(8)
	button.add_theme_stylebox_override("normal",style)
	button.add_theme_color_override("font_color",Color("eee7ca"))
func _button(text: String, callback: Callable, parent: Node) -> Button:
	var button := Button.new()
	button.text = text
	_skin_button(button)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button
func _notice(message: String) -> void:
	toast.text = message
	toast.show()
	toast_age = 7
func _state(state: Dictionary) -> void:
	person = state.get("person",{})
	var next := str([person.get("inventory"),person.get("equipment"),person.get("quest"),person.get("hotbar"),person.get("area")])
	if next != signature:
		signature = next
		_refresh_belt()
		if panel.visible: _render()
func _process(delta: float) -> void:
	toast_age -= delta
	if toast_age <= 0: toast.hide()
	elapsed += delta
	if elapsed < 0.25: return
	elapsed = 0
	if village.status_label.text != last_scene_message:
		last_scene_message = village.status_label.text
		_notice(last_scene_message)
	if not link.connected:
		status.text = "Not connected\nOpen Connection / world"
		return
	if is_instance_valid(vitals): vitals.text = "Health: %d / 100\nStamina: %d / 100\nCoins: %d" % [person.get("health",100),person.get("stamina",100),person.get("coins",0)]
	var place := "Countryside"
	if person.get("area","outside") == "workshop": place = "Carpenter's workshop"
	elif village.avatar.position.distance_to(Vector3.ZERO)<55: place = "Village square"
	elif village.avatar.position.distance_to(WORK.ENTRY)<35: place = "West farms"
	var clock: float = link.snapshot.get("clock",900)
	var period := "Night" if clock<300 or clock>=1200 else "Sunrise" if clock<420 else "Morning" if clock<720 else "Afternoon" if clock<900 else "Late afternoon" if clock<1080 else "Sunset"
	location.text = place
	region_time.text = "Two Rivers · "+period
	status.text = "Traveler\nHealth  %d / 100\nStamina  %d / 100%s" % [person.get("health",100),person.get("stamina",100),"\nWorld paused" if link.snapshot.get("paused",false) else ""]
func _open(which: String) -> void:
	current = which
	panel.show()
	_render()
func _text(text: String) -> Label:
	var label := _label(text)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	contents.add_child(label)
	return label
func _render() -> void:
	for child in contents.get_children(): contents.remove_child(child); child.queue_free()
	title.text = current
	if person.is_empty() and current not in ["Map / travel"]:
		_text("Connect to see your character.")
		return
	match current:
		"Character":
			_text("Your equipment")
			for slot in person.discovered:
				var item: String = person.equipment.get(slot,"")
				var shown: String = "Linen tunic" if slot=="body" else "Worn boots" if slot=="feet" else WORK.ITEMS.get(item,"Empty")
				_text(slot.capitalize()+": "+shown)
			vitals = _text("Health: %d / 100\nStamina: %d / 100\nCoins: %d" % [person.health,person.stamina,person.coins])
			_text("Equipment categories appear as you discover them.")
		"Inventory":
			for item in WORK.ITEMS:
				if person.inventory[item] <= 0: continue
				_text(WORK.ITEMS[item]+" × "+str(int(person.inventory[item])))
				if item != "wood": _button("Use / equip "+WORK.ITEMS[item],_command.bind("use",{"item":item}),contents)
				var select := OptionButton.new()
				select.add_item("Assign to quick slot...")
				for i in range(4): select.add_item("Slot "+str(i+1))
				select.item_selected.connect(func(index):
					if index>0: _command("assign",{"slot":index-1,"item":item})
				)
				contents.add_child(select)
			_text("Four ready-to-use slots. Bread restores stamina; potions restore health when needed.")
		"Skills":
			_text("Woodcraft: "+str(int(person.woodcraft))+" completed commission\nConstitution: 10\nRunning spends stamina. Walk to recover it, or eat bread.")
		"Journal":
			if person.quest.complete:
				_text("Commission complete\nYou received five coins and a copper ring. A finger slot is now available in Character.")
			else:
				_text("The carpenter's first commission\nCollect six wood and the axe. Equip the axe, prepare the wood at the bench, then exchange it with the carpenter.")
			if person.area == "outside":
				_button("Walk to workshop door",func(): village._walk_to(WORK.ENTRY,true),contents)
				_button("Enter workshop",_command.bind("enter",{}),contents)
			else:
				for spec in [["wood","Wood bundle"],["tool","Tool rack"],["bench","Workbench"],["trade","Carpenter"],["exit","Exit"]]:
					_button("Walk to "+spec[1],func(): village._walk_to(village._approach_point(WORK.POINTS[spec[0]])),contents)
					_button({"wood":"Collect bundle","tool":"Take axe","bench":"Prepare wood","trade":"Exchange materials","exit":"Leave workshop"}[spec[0]],_command.bind(spec[0],{}),contents)
		"Map / travel":
			_button("Center on traveler",func(): village._center_traveler(),contents)
			_button("Walk to workshop",func(): village._walk_to(WORK.ENTRY,true),contents)
			if village.area == "outside":
				for i in range(village.landmarks.size()): _button(village.landmarks[i][0],village._visit_home.bind(i),contents)
			_button("Toggle minimap",func(): village.map_view.visible=not village.map_view.visible,contents)
func _command(op: String, arguments: Dictionary = {}) -> void:
	var args := arguments.duplicate()
	args.op = op
	link.command("workshop",args)
func _refresh_belt() -> void:
	for child in belt.get_children(): belt.remove_child(child); child.queue_free()
	for i in range(4):
		var item: String = person.get("hotbar",["","","",""])[i]
		var count: int = person.get("inventory",{}).get(item,0)
		var caption: String = {"bread":"Bread","potion":"Potion","axe":"Axe","ring":"Ring","wood":"Wood"}.get(item,"Empty")
		var button := _button(str(i+1)+"\n"+caption+ ("\n×"+str(count) if count>0 else ""),_command.bind("use",{"item":item}),belt)
		button.custom_minimum_size = Vector2(73,60)
		button.add_theme_font_size_override("font_size",12)
		button.disabled = count <= 0
func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode >= KEY_1 and event.physical_keycode <= KEY_4:
		var focus := get_viewport().gui_get_focus_owner()
		if focus is LineEdit or focus is TextEdit: return
		var item: String = person.get("hotbar",["","","",""])[event.physical_keycode-KEY_1]
		if item != "": _command("use",{"item":item})
		get_viewport().set_input_as_handled()

func close_panels() -> bool:
	if panel.visible:
		panel.hide()
		current = ""
		return true
	if connection_panel.visible:
		connection_panel.hide()
		return true
	return false
