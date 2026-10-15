extends VBoxContainer
var link: Node
var role_label: Label
var output: Label
var controls: VBoxContainer
var player: LineEdit
var area: OptionButton
var east: SpinBox
var north: SpinBox
var skill: OptionButton
var level: SpinBox

func _ready() -> void:
	role_label = _label("Staff access: inactive")
	var code := LineEdit.new()
	code.placeholder_text = "One-use staff code from administrator"
	code.secret = true
	add_child(code)
	_button("Enable staff access",func(): link.command("staff_redeem",{"code":code.text.strip_edges()}); code.clear())
	_button("Leave staff mode",func(): link.command("staff_leave"))
	controls = VBoxContainer.new()
	add_child(controls)
	player = LineEdit.new()
	player.placeholder_text = "Traveler ID (blank selects yourself)"
	controls.add_child(player)
	_button("Inspect selected traveler",func(): _send("inspect",{"player":_player()}),controls)
	area = OptionButton.new()
	area.add_item("outside")
	area.add_item("workshop")
	controls.add_child(area)
	east = _number("East / west",-510,510,0)
	north = _number("North / south",-510,510,9)
	_button("Teleport myself",func(): _confirm("teleport_self",{"x":east.value,"z":north.value,"area":area.get_item_text(area.selected)}),controls)
	skill = OptionButton.new()
	for item in ["running","woodcraft","observation"]: skill.add_item(item)
	controls.add_child(skill)
	level = _number("Skill level (administrator only)",0,10,0)
	_button("Set selected traveler's skill",func(): _confirm("skill",{"player":_player(),"skill":skill.get_item_text(skill.selected),"level":level.value}),controls)
	output = _label("")
	output.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	output.custom_minimum_size.x = 460
	link.staff_answer.connect(func(result): output.text = JSON.stringify(result.get("player",{})) if result.has("player") else result.get("message",""))
	link.changed.connect(func(state):
		var role: String = state.get("staff_role","")
		role_label.text = "Staff access: "+(role if role!="" else "inactive")
		controls.visible = role!=""
	)
	controls.hide()

func _label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	add_child(label)
	return label
func _button(text: String, callback: Callable, parent: Node = self) -> void:
	var button := Button.new()
	button.text = text
	button.pressed.connect(callback)
	parent.add_child(button)
func _number(text: String, minimum: float, maximum: float, value: float) -> SpinBox:
	var label := Label.new()
	label.text = text
	controls.add_child(label)
	var number := SpinBox.new()
	number.min_value=minimum
	number.max_value=maximum
	number.value=value
	controls.add_child(number)
	return number
func _player() -> String: return player.text.strip_edges() if player.text.strip_edges()!="" else link.local_id
func _send(action: String, arguments: Dictionary) -> void: link.command("staff",{"operation":action,"arguments":arguments})
func _confirm(action: String, arguments: Dictionary) -> void:
	var dialog := ConfirmationDialog.new()
	dialog.dialog_text="Confirm "+action.replace("_"," ")+"?"
	add_child(dialog)
	dialog.confirmed.connect(func(): arguments.confirmed=true; _send(action,arguments); dialog.queue_free())
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered()

func _process(_delta: float) -> void:
	if not link.connected:
		controls.hide()
		role_label.text="Staff access: inactive (not connected)"
