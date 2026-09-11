extends Node
const LINK = preload("res://src/net/world_link.gd")
var link: Node
var scene: Node3D
var connection_panel: PanelContainer
var hud: CanvasLayer
var status: Label
var address: LineEdit
var port: SpinBox
var profile: OptionButton
var admin_box: VBoxContainer
var backup_list: OptionButton
var save_interval: SpinBox
var max_players: SpinBox
var day_length: SpinBox
var clock_hour: SpinBox
var diagnostics: Label
var credentials := {}
var client_settings := ConfigFile.new()
var profiles := ["Traveler 1", "Traveler 2", "Traveler 3", "Traveler 4"]
var capture_path := ""
var capture_elapsed := 0.0
var capture_frames := 0
var capture_offline := false
var capture_menu := false
var capture_workshop := false
var menu_opened := false
var last_config := {}
var repair_panel: PanelContainer
var art_message: Label
var launch_panel: PanelContainer
var launch_status: Label

func _ready() -> void:
	name = "Main"
	link = LINK.new()
	link.name = "Network"
	add_child(link)
	var server := false
	var data := "user://world"
	var bot := ""
	for arg in OS.get_cmdline_user_args():
		if arg == "--server": server = true
		if arg.begins_with("--data="): data = arg.trim_prefix("--data=")
		if arg.begins_with("--bot="): bot = arg.trim_prefix("--bot=")
		if arg.begins_with("--capture="): capture_path = arg.trim_prefix("--capture=")
		if arg == "--capture-offline": capture_offline = true
		if arg == "--capture-menu": capture_menu = true
		if arg == "--capture-workshop": capture_workshop = true
	if server:
		if not link.start_server(ProjectSettings.globalize_path(data)):
			push_error(link.error)
			get_tree().quit(1)
		return
	if bot != "":
		var runner: Node = load("res://test/workshop_bot.gd" if bot in ["workshop","reconnect_workshop","exit_workshop","finish_workshop"] else "res://test/network_bot.gd").new()
		runner.link = link
		runner.scenario = bot
		add_child(runner)
		return
	if not OS.has_feature("editor"):
		var art_error: String = load("res://asset_loader.gd").mount(load("res://asset_loader.gd").selected_path())
		if art_error != "":
			_art_repair(art_error)
			return
	_start_client()

func _start_client() -> void:
	client_settings.load("user://shared-client.cfg")
	for label in profiles:
		var credential: String = client_settings.get_value("profiles",label,"")
		if credential.length()!=64: credential = Crypto.new().generate_random_bytes(32).hex_encode()
		credentials[label] = credential
		client_settings.set_value("profiles",label,credential)
	_save_client()
	scene = load("res://village.gd").new()
	scene.network = link
	add_child(scene)
	link.notice.connect(_notice)
	link.changed.connect(_state)
	link.joined.connect(func(_id,_owner): _notice("Connected. The first registered traveler owns this private prototype."))
	_build_panel()
	hud = load("res://game_hud.gd").new()
	hud.link = link
	hud.village = scene
	hud.connection_panel = connection_panel
	add_child(hud)
	_build_launcher()
	link.joined.connect(func(_id,_owner): launch_panel.hide())

func _build_launcher() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 8
	add_child(layer)
	launch_panel = PanelContainer.new()
	launch_panel.custom_minimum_size = Vector2(460,0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("1d3020")
	style.border_color = Color("8c9166")
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(24)
	launch_panel.add_theme_stylebox_override("panel",style)
	layer.add_child(launch_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",12)
	launch_panel.add_child(column)
	var heading: Label = hud._label("Two Rivers",30)
	column.add_child(heading)
	column.add_child(hud._label("Working Day 06 · "+_build_identity(),14))
	launch_status = hud._label("",16)
	launch_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	launch_status.custom_minimum_size.x = 400
	launch_status.text = "%s:%d\n%s" % [address.text,int(port.value),profiles[profile.selected]]
	column.add_child(launch_status)
	hud._button("Join village",_connect,column)
	hud._button("Connection settings",func(): launch_panel.hide(); connection_panel.show(),column)
	hud._button("Look around without connecting",func(): launch_panel.hide(),column)
	hud._button("Quit",func(): get_tree().quit(),column)
	var center := func(): launch_panel.position = (get_viewport().get_visible_rect().size-launch_panel.size)/2
	launch_panel.resized.connect(center)
	get_viewport().size_changed.connect(center)
	center.call_deferred()

func _build_identity() -> String:
	if not FileAccess.file_exists("res://release_manifest.json"): return "Source preview"
	var manifest = JSON.parse_string(FileAccess.get_file_as_string("res://release_manifest.json"))
	return str(manifest.get("build_id","Source preview")).left(12) if manifest is Dictionary else "Source preview"

func _button(label: String, callback: Callable, parent: Node) -> Button:
	var button := Button.new()
	button.text = label
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _build_panel() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	var panel := PanelContainer.new()
	connection_panel = panel
	panel.hide()
	panel.position = Vector2(850,300)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06,0.09,0.065,0.96)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel",style)
	layer.add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	var head := HBoxContainer.new()
	column.add_child(head)
	var title := Label.new()
	title.text = "Connection / world · 06"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	_button("×",func(): panel.hide(),head).tooltip_text = "Close"
	load("res://floating_panel.gd").attach(panel,title,"Connection")
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(550,500)
	column.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(box)
	var build_label := Label.new()
	build_label.text = "Client build: "+_build_identity()
	box.add_child(build_label)
	address = LineEdit.new()
	address.placeholder_text = "Server address (UDP 7777)"
	address.text = client_settings.get_value("connection","address","127.0.0.1")
	box.add_child(address)
	var port_row := HBoxContainer.new()
	box.add_child(port_row)
	var port_label := Label.new()
	port_label.text = "UDP port"
	port_row.add_child(port_label)
	port = SpinBox.new()
	port.min_value = 1
	port.max_value = 65535
	port.value = client_settings.get_value("connection","port",7777)
	port_row.add_child(port)
	profile = OptionButton.new()
	for label in profiles: profile.add_item(label)
	profile.select(clampi(int(client_settings.get_value("connection","profile",0)),0,3))
	box.add_child(profile)
	var buttons := HBoxContainer.new()
	box.add_child(buttons)
	_button("Connect / Retry",_connect,buttons)
	_button("Disconnect",func(): link.disconnect_client("Disconnected"),buttons)
	status = Label.new()
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.custom_minimum_size.x = 490
	status.text = "Connect to the Docker world. Use different profiles for two local clients."
	box.add_child(status)
	_button("Art pack location...",_choose_art_file,box)
	_button("View square oak",func(): scene._view_resource(),box)
	_button("Walk to square oak",func(): scene._walk_to(Vector3(-12,0,30)),box)
	_button("Harvest square oak (must be nearby)",func(): link.command("harvest"),box)
	var note := Label.new()
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.text = "Private LAN prototype. First registered traveler becomes world owner. Credentials are local to each profile; transport is not encrypted."
	box.add_child(note)
	admin_box = VBoxContainer.new()
	box.add_child(admin_box)
	var heading := Label.new()
	heading.text = "World owner controls"
	admin_box.add_child(heading)
	_button("Pause / Resume world",func(): link.command("pause"),admin_box)
	var interval_label := Label.new()
	interval_label.text = "Position checkpoint interval (seconds)"
	admin_box.add_child(interval_label)
	save_interval = SpinBox.new()
	save_interval.min_value = 1
	save_interval.max_value = 60
	save_interval.value = 5
	admin_box.add_child(save_interval)
	var limit_label := Label.new()
	limit_label.text = "Concurrent player limit"
	admin_box.add_child(limit_label)
	max_players = SpinBox.new()
	max_players.min_value = 2
	max_players.max_value = 16
	max_players.value = 4
	admin_box.add_child(max_players)
	var day_label := Label.new()
	day_label.text = "Full day length (real minutes)"
	admin_box.add_child(day_label)
	day_length = SpinBox.new()
	day_length.min_value = 12
	day_length.max_value = 1440
	day_length.value = 144
	admin_box.add_child(day_length)
	var clock_label := Label.new()
	clock_label.text = "Set world hour (0 to 23)"
	admin_box.add_child(clock_label)
	clock_hour = SpinBox.new()
	clock_hour.min_value = 0
	clock_hour.max_value = 23
	clock_hour.value = 15
	admin_box.add_child(clock_hour)
	_button("Set world time",func(): link.command("clock",{"minutes":clock_hour.value*60}),admin_box)
	_button("Save world settings",func(): link.command("settings",{"save_interval":save_interval.value,"max_players":int(max_players.value),"day_minutes":day_length.value}),admin_box)
	_button("Create backup",func(): link.command("backup"),admin_box)
	backup_list = OptionButton.new()
	admin_box.add_child(backup_list)
	_button("Restore selected backup (world must be paused)",func():
		if backup_list.selected>=0: link.command("restore",{"name":backup_list.get_item_text(backup_list.selected)})
	,admin_box)
	diagnostics = Label.new()
	diagnostics.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(diagnostics)
	admin_box.hide()

func _connect() -> void:
	last_config = {}
	client_settings.set_value("connection","address",address.text.strip_edges())
	client_settings.set_value("connection","profile",profile.selected)
	client_settings.set_value("connection","port",int(port.value))
	_save_client()
	link.connect_client(address.text.strip_edges(),credentials[profiles[profile.selected]],int(port.value))

func _save_client() -> void:
	if client_settings.save("user://shared-client.cfg") != OK: push_error("Client preferences could not be saved")

func _notice(message: String) -> void:
	if status: status.text = message
	if launch_status: launch_status.text = message

func _state(state: Dictionary) -> void:
	admin_box.visible = link.is_owner
	if last_config != state.config:
		save_interval.value = state.config.save_interval
		max_players.value = state.config.max_players
		day_length.value = state.config.get("day_minutes",144)
		last_config = state.config.duplicate()
	diagnostics.text = "Players: %d | Revision: %d | Saved generation: %d\n%s%s" % [state.actors.size(),state.revision,state.saved_generation,"PAUSED" if state.paused else "World running",(" | STORAGE ERROR: "+state.error) if state.error!="" else ""]
	var metrics: Dictionary = state.get("metrics",{})
	if not metrics.is_empty(): diagnostics.text += "\nTick peak: %.2f ms | Motion: %d bytes\nLast save: %.1f sec | Citizen: %d\nProtocol: %s" % [metrics.get("tick_peak_ms",0),metrics.get("motion_bytes",0),metrics.get("save_age",0),metrics.get("citizens",0),metrics.get("protocol","")]
	if metrics.has("sim_lag_ms"): diagnostics.text += "\nSimulation backlog: %.1f ms" % metrics.sim_lag_ms
	if metrics.has("action_peak_ms"): diagnostics.text += "\nAction peak: %.2f ms" % metrics.action_peak_ms
	if metrics.has("build"): diagnostics.text += "\nServer build: "+str(metrics.build)
	if metrics.has("fauna"): diagnostics.text += "\nMeadow fauna: %d | Births: %d" % [metrics.fauna,metrics.births]
	var old_selection := backup_list.get_item_text(backup_list.selected) if backup_list.selected>=0 else ""
	var items := []
	for i in range(backup_list.item_count): items.append(backup_list.get_item_text(i))
	if items != state.backups:
		backup_list.clear()
		for name in state.backups: backup_list.add_item(name)
		for i in range(backup_list.item_count):
			if backup_list.get_item_text(i)==old_selection: backup_list.select(i)

func _process(delta: float) -> void:
	if not is_instance_valid(scene): return
	if not capture_path.is_empty():
		capture_frames += 1
		if capture_frames == 20 and not capture_offline: _connect()
	if not capture_path.is_empty() and (link.connected or capture_offline):
		capture_elapsed += delta
		if capture_workshop and capture_elapsed > 3 and not menu_opened:
			assert(scene.area == "workshop" and scene.room.visible and not scene.arranged.visible)
			assert(not scene.show_route)
			hud._open("Character")
			menu_opened = true
		if capture_menu and capture_elapsed > 3 and not menu_opened:
			scene._open_context(scene.camera.unproject_position(Vector3(-12,4,27)))
			assert(scene.context_selection.get("kind") == "square_oak", "Context ray must select the square oak")
			assert(scene.context_panel.visible)
			menu_opened = true
		if capture_elapsed>8:
			capture_path = _capture(capture_path)

func _capture(path: String) -> String:
	if capture_workshop:
		var mouse: Vector2 = scene.camera.unproject_position(Vector3(0,1,-3))
		var press := InputEventMouseButton.new()
		press.button_index = MOUSE_BUTTON_RIGHT
		press.pressed = true
		press.position = mouse
		scene._unhandled_input(press)
		press.pressed = false
		scene._input(press)
		assert(scene.context_panel.visible and scene.context_selection.kind == "trade", "Right-click must select carpenter")
		scene._choose_context("inspect")
		assert(scene.status_label.text.contains("carpenter"))
		print("WORKSHOP UI PASSED: right-click carpenter, inspect, discovered equipment and hidden routes")
	# Exercise free inspection independently of the authoritative traveler.
	var original: Vector3 = scene.avatar.position
	scene._set_inspection(true)
	scene.inspection_position = Vector3(-102,1.7,-74)
	scene.inspection_pitch = 0
	scene.yaw = 0
	scene.target_yaw = 0
	scene._update_camera()
	for i in range(100): scene._apply_pan_input(Vector2(0,-1),0.05)
	if scene.inspection_position.z > -95 or scene.avatar.position != original:
		push_error("Free inspection failed or moved authoritative traveler")
		get_tree().quit(1)
		return ""
	print("FREE INSPECTION CHECK PASSED: camera crossed barn; traveler unchanged")
	scene._center_traveler()
	get_viewport().get_texture().get_image().save_png(path)
	print("SHARED CLIENT RENDERED: %d visible network actors" % link.snapshot.get("actors",[]).size())
	get_tree().quit()
	return ""

func _art_repair(message: String) -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	repair_panel = PanelContainer.new()
	repair_panel.position = Vector2(380,240)
	repair_panel.custom_minimum_size = Vector2(680,260)
	layer.add_child(repair_panel)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("233425")
	style.set_content_margin_all(24)
	style.set_corner_radius_all(12)
	repair_panel.add_theme_stylebox_override("panel",style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",16)
	repair_panel.add_child(column)
	var heading := Label.new()
	heading.text = "Let's find the village art"
	heading.add_theme_font_size_override("font_size",26)
	column.add_child(heading)
	art_message = Label.new()
	art_message.text = message
	art_message.custom_minimum_size.x = 620
	art_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(art_message)
	_button("Locate matching art pack...",_choose_art_file,column)
	_button("Quit",func(): get_tree().quit(),column)

func _choose_art_file() -> void:
	var chooser := FileDialog.new()
	chooser.title = "Locate Longwalk art pack"
	chooser.access = FileDialog.ACCESS_FILESYSTEM
	chooser.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	chooser.filters = PackedStringArray(["*.pck ; Longwalk art pack"])
	chooser.current_dir = OS.get_executable_path().get_base_dir()
	add_child(chooser)
	chooser.file_selected.connect(func(path):
		_accept_art_file(path)
		chooser.queue_free()
	)
	chooser.canceled.connect(chooser.queue_free)
	chooser.popup_centered(Vector2i(900,600))

func _accept_art_file(path: String) -> void:
	var loader = load("res://asset_loader.gd")
	var error: String = loader.validate(path)
	if error == "" and not is_instance_valid(scene): error = loader.mount(path)
	if error == "" and not loader.remember(path): error = "Could not save the art location. Check that your profile folder is writable."
	if error != "":
		if is_instance_valid(art_message): art_message.text = error
		else: _notice(error)
		return
	if is_instance_valid(scene):
		_notice("Art pack location saved for the next launch.")
		return
	if is_instance_valid(repair_panel): repair_panel.queue_free()
	_start_client()
