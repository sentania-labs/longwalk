extends Node
signal changed(state: Dictionary)
signal notice(message: String)
signal joined(ident: String, owner: bool)
const WORLD = preload("res://src/sim/shared_world.gd")
const STORE = preload("res://src/sim/world_store.gd")
var world: RefCounted
var store: RefCounted
var serving := false
var connected := false
var local_id := ""
var is_owner := false
var token := ""
var version := ""
var connections := {}
var connected_at := {}
var last_command := {}
var sequence := 0
var latest_sequence := -1
var last_state := 0.0
var checkpoint := 0.0
var broadcast_timer := 0.0
var heartbeat_timer := 0.0
var heartbeat_path := OS.get_environment("LONGWALK_HEALTH_FILE")
var error := ""
var snapshot := {}
var frozen := false
var boot_id := Crypto.new().generate_random_bytes(12).hex_encode()

func _ready() -> void:
	version = FileAccess.get_sha256("res://world/baseline.json")
	multiplayer.connected_to_server.connect(func():
		_set_peer_timeout(1)
		hello.rpc_id(1,version,token)
	)
	multiplayer.connection_failed.connect(func(): disconnect_client("Connection failed. Check address and UDP port 7777, then Retry."))
	multiplayer.server_disconnected.connect(func(): disconnect_client("Disconnected. Retry to recover this traveler."))
	multiplayer.peer_disconnected.connect(_left)
	multiplayer.peer_connected.connect(func(peer):
		if serving:
			connected_at[peer] = Time.get_ticks_msec()
			_set_peer_timeout(peer)
	)

func start_server(path: String) -> bool:
	serving = true
	if heartbeat_path!="" and FileAccess.file_exists(heartbeat_path): DirAccess.remove_absolute(heartbeat_path)
	store = STORE.new()
	var state: Dictionary = store.initialize(path,version)
	if state.is_empty():
		error = store.error
		frozen = true
		var candidates: Array[String] = store.records("state-")
		candidates.reverse()
		candidates.append_array(store.records("backup-"))
		for name in candidates:
			var previous: Dictionary = store.read_record(name)
			if not previous.is_empty() and previous.owner != "":
				state = previous
				break
		if state.is_empty(): return false
		push_error("World entered owner-only recovery mode; latest save is invalid")
	world = WORLD.new()
	world.initialize(JSON.parse_string(FileAccess.get_file_as_string("res://world/baseline.json")),state)
	var peer := ENetMultiplayerPeer.new()
	var result := peer.create_server(7777,32)
	if result != OK:
		error = "Cannot listen on UDP 7777"
		return false
	multiplayer.multiplayer_peer = peer
	connected = true
	print("WORLD READY: baseline verified; single writer; UDP 7777")
	return true

func connect_client(address: String, credential: String) -> void:
	disconnect_client("")
	token = credential
	var peer := ENetMultiplayerPeer.new()
	var result := peer.create_client(address,7777)
	if result != OK:
		notice.emit("Could not start connection")
		return
	multiplayer.multiplayer_peer = peer
	last_state = Time.get_ticks_msec()/1000.0
	notice.emit("Connecting...")

func disconnect_client(message: String) -> void:
	if serving: return
	connected = false
	is_owner = false
	local_id = ""
	latest_sequence = -1
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	if message != "": notice.emit(message)

func _left(peer: int) -> void:
	if not serving: return
	if connections.has(peer):
		world.stop(connections[peer])
		connections.erase(peer)
		if not frozen: _commit()
	connected_at.erase(peer)
	last_command.erase(peer)

func _commit() -> bool:
	if store.save(world.data):
		checkpoint = 0
		return true
	error = store.error
	frozen = true
	world.routes.clear()
	world.running.clear()
	push_error("World persistence failed; actions stopped")
	return false

@rpc("any_peer","call_remote","reliable")
func hello(baseline: String, credential: String) -> void:
	if not serving: return
	var peer := multiplayer.get_remote_sender_id()
	if connections.has(peer): return
	if baseline != version or credential.length()!=64 or not credential.is_valid_hex_number():
		answer.rpc_id(peer,{"message":"Client/world version or credential mismatch"})
		return
	if connections.size() >= int(world.data.config.max_players):
		answer.rpc_id(peer,{"message":"World unavailable or connection limit reached"})
		return
	var ident := credential.sha256_text()
	if frozen and ident != world.data.owner:
		answer.rpc_id(peer,{"message":"Owner-only recovery mode"})
		return
	if ident in connections.values():
		answer.rpc_id(peer,{"message":"This traveler is already connected. Choose a different local profile."})
		return
	if not world.data.players.has(ident):
		if world.data.players.size()>=64:
			answer.rpc_id(peer,{"message":"Prototype character capacity reached"})
			return
		world.data.players[ident] = {"position":[(world.data.players.size()%8)*2,0,9]}
		if world.data.owner == "": world.data.owner = ident
		if not _commit(): return
	connections[peer] = ident
	answer.rpc_id(peer,{"id":ident,"owner":world.data.owner==ident,"message":"Connected"})
	_push_state(peer)

@rpc("any_peer","call_remote","reliable")
func request(action: String, arguments: Dictionary) -> void:
	if not serving: return
	var peer := multiplayer.get_remote_sender_id()
	if not connections.has(peer): return
	var now := Time.get_ticks_msec()
	var recent: Array = last_command.get(peer,[])
	recent = recent.filter(func(value): return now-int(value)<1000)
	if recent.size()>=10: return
	recent.append(now)
	last_command[peer] = recent
	var ident: String = connections[peer]
	var message := ""
	if frozen and action not in ["restore","backups"]:
		answer.rpc_id(peer,{"message":"Storage error: " + error + ". World actions are stopped."})
		return
	match action:
		"move":
			if not arguments.get("target") is Array or not arguments.get("run") is bool or not arguments.get("prefer") is bool: return
			message = world.move(ident,arguments.target,arguments.run,arguments.prefer)
			if message == "": message = "Server accepted movement"
		"harvest":
			var previous: Dictionary = world.data.duplicate(true)
			message = world.harvest(ident)
			if message == "":
				if _commit(): message = "Square oak harvested and saved"
				else:
					world.data = previous
					world.apply_resource()
					message = "Harvest not accepted: storage failure"
		"pause", "backup", "restore", "settings", "backups":
			if ident != world.data.owner:
				message = "Only the world owner can administer this prototype"
			else: message = _admin(action,arguments)
		_: message = "Unknown action"
	answer.rpc_id(peer,{"message":message})
	_push_state()

func _admin(action: String, arguments: Dictionary) -> String:
	match action:
		"pause":
			world.data.paused = not world.data.paused
			world.routes.clear()
			world.running.clear()
			return "World pause updated" if _commit() else error
		"settings":
			var interval = arguments.get("save_interval")
			var limit = arguments.get("max_players")
			if (not interval is int and not interval is float) or (not limit is int and not limit is float): return "Invalid settings"
			if not is_finite(float(interval)) or not is_finite(float(limit)) or float(interval)<1 or float(interval)>60 or float(limit)<2 or float(limit)>16: return "Settings outside supported range"
			world.data.config = {"save_interval":float(interval),"max_players":int(limit)}
			return "Settings saved" if _commit() else error
		"backup":
			# The sim and this write run on one thread. No tick interleaves the copy.
			if not _commit(): return error
			var name: String = store.backup(world.data)
			return "Backup saved: " + name if name != "" else store.error
		"restore":
			if not world.data.paused and not frozen: return "Pause the world before restoring"
			var name = arguments.get("name","")
			if not name is String or name not in store.records("backup-"): return "Choose an existing backup"
			var restored: Dictionary = store.read_record(name)
			if restored.is_empty(): return store.error
			# Preserve current identities and owner access while restoring world
			# facts and known positions. Newer characters keep their current position.
			var previous: Dictionary = world.data.duplicate(true)
			if store.backup(previous) == "": return "Could not preserve displaced state: " + store.error
			for ident in previous.players:
				if not restored.players.has(ident): restored.players[ident] = previous.players[ident]
			restored.owner = previous.owner
			restored.revision = int(previous.revision)+1
			restored.paused = true
			world.data = restored
			world.routes.clear()
			world.running.clear()
			world.apply_resource()
			if _commit():
				frozen = false
				error = ""
				return "Backup restored; world remains paused"
			world.data = previous
			world.apply_resource()
			return error
	return "Backup list refreshed"

@rpc("authority","call_remote","reliable")
func answer(payload: Dictionary) -> void:
	if serving: return
	if payload.has("id"):
		local_id = payload.id
		is_owner = payload.owner
		connected = true
		joined.emit(local_id,is_owner)
	if payload.has("message"): notice.emit(payload.message)

@rpc("authority","call_remote","unreliable_ordered")
func state(payload: Dictionary) -> void:
	if serving or int(payload.get("sequence",-1))<=latest_sequence: return
	latest_sequence = payload.sequence
	last_state = Time.get_ticks_msec()/1000.0
	snapshot = payload
	changed.emit(payload)

func command(action: String, arguments: Dictionary = {}) -> void:
	if connected and not serving: request.rpc_id(1,action,arguments)
	else: notice.emit("Connect before issuing world actions")

func _push_state(peer: int = 0) -> void:
	sequence += 1
	var actors := []
	for ident in connections.values():
		actors.append({"id":ident,"position":world.data.players[ident].position,"moving":world.routes.has(ident),"running":world.running.get(ident,false)})
	var payload := {"sequence":sequence,"boot":boot_id,"actors":actors,"cut":world.data.cut,"revision":world.data.revision,"saved_generation":store.generation,"paused":world.data.paused or frozen,"error":error,"config":world.data.config,"backups":store.records("backup-")}
	if peer: state.rpc_id(peer,payload)
	else:
		for id in connections: state.rpc_id(id,payload)

func _process(delta: float) -> void:
	if serving and connected:
		heartbeat_timer += delta
		if heartbeat_timer>=1 and heartbeat_path!="":
			heartbeat_timer = 0
			var heartbeat := FileAccess.open(heartbeat_path,FileAccess.WRITE)
			if heartbeat:
				heartbeat.store_string("serving")
				heartbeat.close()
		if not frozen:
			world.tick(minf(delta,0.1))
			checkpoint += delta
			if checkpoint>=float(world.data.config.save_interval) and not connections.is_empty(): _commit()
		for peer in connected_at.keys():
			if not connections.has(peer) and Time.get_ticks_msec()-int(connected_at[peer])>5000:
				multiplayer.multiplayer_peer.disconnect_peer(peer)
				connected_at.erase(peer)
		broadcast_timer += delta
		if broadcast_timer>=0.1:
			broadcast_timer = 0
			_push_state()
	elif not serving and multiplayer.multiplayer_peer and Time.get_ticks_msec()/1000.0-last_state>6:
		disconnect_client("Server stopped responding. Retry to reconnect; old clicks will not replay.")


func _set_peer_timeout(peer: int) -> void:
	var transport := multiplayer.multiplayer_peer as ENetMultiplayerPeer
	if transport and transport.get_peer(peer): transport.get_peer(peer).set_timeout(8,2000,5000)
