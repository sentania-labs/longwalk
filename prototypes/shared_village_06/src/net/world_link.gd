extends Node
signal changed(state: Dictionary)
signal notice(message: String)
signal joined(ident: String, owner: bool)
const PROTOCOL = "shared-village-06"
const WORLD = preload("res://src/sim/shared_world.gd")
const STORE = preload("res://src/sim/world_store.gd")
var world: RefCounted
var store: RefCounted
var serving := false
var connected := false
var connecting := false
var local_id := ""
var is_owner := false
var token := ""
var version := ""
var build_identity := "source"
var connections := {}
var pending_moves := {}
var move_queue: Array[int] = []
var connected_at := {}
var last_command := {}
var sequence := 0
var latest_sequence := -1
var last_state := 0.0
var checkpoint := 0.0
var simulation_accumulator := 0.0
var broadcast_timer := 0.0
var heartbeat_timer := 0.0
var heartbeat_path := OS.get_environment("LONGWALK_HEALTH_FILE")
var error := ""
var snapshot := {}
var incoming_snapshot := {}
var sent_details := {}
var max_motion_bytes := 0
var cached_backups: Array[String] = []
var last_saved := 0.0
var tick_peak_ms := 0.0
var action_peak_ms := 0.0
var metrics := {}
var public_wildlife := {}
var frozen := false
var boot_id := Crypto.new().generate_random_bytes(12).hex_encode()

func _ready() -> void:
	version = FileAccess.get_sha256("res://world/baseline.json")
	if FileAccess.file_exists("res://release_manifest.json"):
		var manifest = JSON.parse_string(FileAccess.get_file_as_string("res://release_manifest.json"))
		if manifest is Dictionary: build_identity = str(manifest.get("build_id","source")).left(12)
	multiplayer.connected_to_server.connect(func():
		_set_peer_timeout(1)
		hello.rpc_id(1,version + "|" + PROTOCOL,token)
	)
	multiplayer.connection_failed.connect(func(): disconnect_client.call_deferred("Connection failed. Check the address and UDP port, then Retry."))
	multiplayer.server_disconnected.connect(func(): disconnect_client.call_deferred("Disconnected. Retry to recover this traveler."))
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
	cached_backups = store.records("backup-")
	world = WORLD.new()
	world.initialize(JSON.parse_string(FileAccess.get_file_as_string("res://world/baseline.json")),state)
	public_wildlife = world.FAUNA.public_state(world.data)
	var peer := ENetMultiplayerPeer.new()
	var result := peer.create_server(7777,32)
	if result != OK:
		error = "Cannot listen on UDP 7777"
		return false
	multiplayer.multiplayer_peer = peer
	connected = true
	print("WORLD READY: baseline verified; single writer; UDP 7777")
	return true

func connect_client(address: String, credential: String, port: int = 7777) -> void:
	disconnect_client("")
	connecting = true
	token = credential
	var peer := ENetMultiplayerPeer.new()
	var result := peer.create_client(address,port)
	if result != OK:
		connecting = false
		notice.emit("Could not start connection")
		return
	multiplayer.multiplayer_peer = peer
	last_state = Time.get_ticks_msec()/1000.0
	notice.emit("Connecting...")

func disconnect_client(message: String) -> void:
	if serving: return
	connected = false
	connecting = false
	is_owner = false
	local_id = ""
	latest_sequence = -1
	snapshot = {}
	incoming_snapshot = {}
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	if message != "": notice.emit(message)

func _left(peer: int) -> void:
	if not serving: return
	pending_moves.erase(peer)
	move_queue.erase(peer)
	if connections.has(peer):
		world.stop(connections[peer])
		connections.erase(peer)
		if not frozen: _commit()
	connected_at.erase(peer)
	last_command.erase(peer)
	sent_details.erase(peer)

func _commit() -> bool:
	if store.save(world.data):
		checkpoint = 0
		last_saved = Time.get_ticks_msec()/1000.0
		return true
	error = store.error
	frozen = true
	pending_moves.clear()
	move_queue.clear()
	world.routes.clear()
	world.running.clear()
	push_error("World persistence failed; actions stopped")
	return false

@rpc("any_peer","call_remote","reliable")
func hello(baseline: String, credential: String) -> void:
	if not serving: return
	var peer := multiplayer.get_remote_sender_id()
	if connections.has(peer): return
	if baseline != version + "|" + PROTOCOL:
		answer.rpc_id(peer,{"message":"Version mismatch: this server requires Shared Village 06 with the matching world baseline."})
		return
	if credential.length()!=64 or not credential.is_valid_hex_number():
		answer.rpc_id(peer,{"message":"Invalid traveler credential"})
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
		world.WORK.ensure(world.data.players[ident])
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
	var request_started := Time.get_ticks_usec()
	var ident: String = connections[peer]
	var message := ""
	if frozen and action not in ["restore","backups"]:
		answer.rpc_id(peer,{"message":"Storage error: " + error + ". World actions are stopped."})
		return
	match action:
		"move":
			if not arguments.get("target") is Array or not arguments.get("run") is bool or not arguments.get("prefer") is bool: return
			if arguments.target.size()!=2: return
			# Keep only the latest intent per peer and solve one route per frame.
			# This gives networking a chance to run between expensive distant queries.
			if not pending_moves.has(peer): move_queue.append(peer)
			pending_moves[peer] = {"target":arguments.target.duplicate(),"run":arguments.run,"prefer":arguments.prefer}
			return
		"workshop":
			var op = arguments.get("op","")
			if not op is String: return
			var before: Dictionary = world.data.duplicate(true)
			world.active = connections.values()
			message = world.workshop(ident,op,arguments)
			if message == "":
				if _commit(): message = "Saved: " + world.WORK.receipt(op,arguments)
				else: world.data = before; message = "Action not accepted: storage failure"
			else: world.data = before
		"village":
			var op = arguments.get("op","")
			if not op is String: return
			var before: Dictionary = world.data.duplicate(true)
			message = world.village_action(ident,op,arguments)
			if message == "":
				if _commit(): message = "Saved: " + world.COMMUNITY.receipt(op)
				else: world.data = before; message = "Action not accepted: storage failure"
			else: world.data = before
		"harvest":
			var previous: Dictionary = world.data.duplicate(true)
			message = world.harvest(ident)
			if message == "":
				if _commit(): message = "Square oak harvested and saved"
				else:
					world.data = previous
					world.apply_resource()
					message = "Harvest not accepted: storage failure"
		"pause", "backup", "restore", "settings", "backups", "clock":
			if ident != world.data.owner:
				message = "Only the world owner can administer this prototype"
			else: message = _admin(action,arguments)
		_: message = "Unknown action"
	answer.rpc_id(peer,{"message":message})
	_push_state()
	action_peak_ms = maxf(action_peak_ms,(Time.get_ticks_usec()-request_started)/1000.0)

func _admin(action: String, arguments: Dictionary) -> String:
	match action:
		"pause":
			pending_moves.clear()
			move_queue.clear()
			world.data.paused = not world.data.paused
			world.routes.clear()
			world.running.clear()
			return "World pause updated" if _commit() else error
		"clock":
			var minutes = arguments.get("minutes")
			if (not minutes is int and not minutes is float) or not is_finite(float(minutes)) or minutes<0 or minutes>=1440: return "Choose a valid time of day."
			world.data.clock = float(minutes)
			return "World time updated" if _commit() else error
		"settings":
			var interval = arguments.get("save_interval")
			var limit = arguments.get("max_players")
			if (not interval is int and not interval is float) or (not limit is int and not limit is float): return "Invalid settings"
			if not is_finite(float(interval)) or not is_finite(float(limit)) or float(interval)<1 or float(interval)>60 or float(limit)<2 or float(limit)>16: return "Settings outside supported range"
			var day = arguments.get("day_minutes",world.data.config.get("day_minutes",144))
			if (not day is int and not day is float) or not is_finite(float(day)) or day<12 or day>1440: return "Day length must be 12 to 1440 real minutes."
			world.data.config = {"save_interval":float(interval),"max_players":int(limit),"day_minutes":float(day)}
			return "Settings saved" if _commit() else error
		"backup":
			# The sim and this write run on one thread. No tick interleaves the copy.
			if not _commit(): return error
			var name: String = store.backup(world.data)
			if name != "": cached_backups.append(name)
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
			var displaced: String = store.backup(previous)
			if displaced == "": return "Could not preserve displaced state: " + store.error
			cached_backups.append(displaced)
			for ident in previous.players:
				if not restored.players.has(ident): restored.players[ident] = previous.players[ident]
			restored.schema = 3
			restored.owner = previous.owner
			restored.revision = int(previous.revision)+1
			restored.paused = true
			for person in restored.players.values(): world.WORK.ensure(person)
			world.COMMUNITY.ensure(restored)
			world.FAUNA.ensure(restored)
			simulation_accumulator = 0
			world.fauna.accumulator = 0
			public_wildlife = world.FAUNA.public_state(restored)
			world.community.route.clear()
			world.community.goal = ""
			world.data = restored
			pending_moves.clear()
			move_queue.clear()
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
	cached_backups = store.records("backup-")
	return "Backup list refreshed"

@rpc("authority","call_remote","reliable")
func answer(payload: Dictionary) -> void:
	if serving: return
	if payload.has("id"):
		local_id = payload.id
		is_owner = payload.owner
		connected = true
		connecting = false
		joined.emit(local_id,is_owner)
	if payload.has("message"): notice.emit(payload.message)

# Reliable character/world facts are separate from small, replaceable motion updates.
@rpc("authority","call_remote","reliable")
func details(payload: Dictionary) -> void:
	if serving: return
	incoming_snapshot.merge(payload,true)
	_emit_snapshot()

@rpc("authority","call_remote","unreliable_ordered")
func state(packet: PackedByteArray) -> void:
	if serving or packet.size()>65536: return
	var decoded := packet.decompress_dynamic(262144,FileAccess.COMPRESSION_DEFLATE)
	if decoded.is_empty(): return
	var payload = bytes_to_var(decoded)
	if not payload is Dictionary or int(payload.get("sequence",-1))<=latest_sequence: return
	latest_sequence = payload.sequence
	last_state = Time.get_ticks_msec()/1000.0
	incoming_snapshot.merge(payload,true)
	_emit_snapshot()

func _emit_snapshot() -> void:
	if not incoming_snapshot.has("person") or not incoming_snapshot.has("actors") or not incoming_snapshot.has("vitals"): return
	var person: Dictionary = incoming_snapshot.person
	person.health = incoming_snapshot.vitals[0]
	person.stamina = incoming_snapshot.vitals[1]
	person.practice.running = incoming_snapshot.vitals[2]
	for actor in incoming_snapshot.actors:
		if actor.id == local_id:
			person.position = actor.position
			person.area = actor.area
	snapshot = incoming_snapshot.duplicate(true)
	changed.emit(snapshot)

func command(action: String, arguments: Dictionary = {}) -> void:
	if connected and not serving: request.rpc_id(1,action,arguments)
	else: notice.emit("Connect before issuing world actions")

func _push_state(peer: int = 0) -> void:
	sequence += 1
	var actors := []
	var names := {}
	for ident in connections.values():
		names[ident] = world.data.players[ident].get("display_name","Traveler")
		actors.append({"id":ident,"position":world.data.players[ident].position,"area":world.data.players[ident].get("area","outside"),"moving":not frozen and not world.data.paused and world.moved.get(ident,false),"running":world.running.get(ident,false)})
	var payload := {"citizen":world.data.citizen,"elapsed":world.data.elapsed,"clock":world.data.get("clock",900),"sequence":sequence,"boot":boot_id,"actors":actors,"revision":world.data.revision,"saved_generation":store.generation}
	var recipients: Array = [peer] if peer else connections.keys()
	for id in recipients:
		var person: Dictionary = world.data.players[connections[id]].duplicate(true)
		payload.vitals = [person.health,person.stamina,person.practice.running]
		person.erase("position")
		person.erase("health")
		person.erase("stamina")
		person.practice.erase("running")
		var facts := {"wildlife":public_wildlife,"names":names,"person":person,"cut":world.data.cut,"gathering":world.data.gathering,"paused":world.data.paused or frozen,"error":error,"config":world.data.config,"backups":cached_backups,"metrics":metrics}
		var signature := JSON.stringify(facts).sha256_text()
		if sent_details.get(id,"") != signature:
			sent_details[id] = signature
			details.rpc_id(id,facts)
		var packet := var_to_bytes(payload).compress(FileAccess.COMPRESSION_DEFLATE)
		max_motion_bytes = maxi(max_motion_bytes,packet.size())
		state.rpc_id(id,packet)

func _process(delta: float) -> void:
	var started := Time.get_ticks_usec()
	if serving and connected:
		if FileAccess.file_exists("/tmp/world-stop"):
			var saved := not frozen and _commit()
			print("WORLD STOPPED: final checkpoint saved" if saved else "WORLD STOPPED: storage failure, existing records retained")
			get_tree().quit(0 if saved else 1)
			return
		heartbeat_timer += delta
		if heartbeat_timer>=1:
			heartbeat_timer = 0
			public_wildlife = world.FAUNA.public_state(world.data)
			metrics = {"tick_peak_ms":snappedf(tick_peak_ms,0.01),"action_peak_ms":snappedf(action_peak_ms,0.01),"sim_lag_ms":snappedf(simulation_accumulator*1000,0.1),"motion_bytes":max_motion_bytes,"checkpoints":store.generation,"save_age":maxf(0,Time.get_ticks_msec()/1000.0-last_saved),"citizens":1,"fauna":world.data.fauna.agents.size(),"births":world.data.fauna.births,"protocol":PROTOCOL,"build":build_identity}
			tick_peak_ms = 0
			action_peak_ms = 0
			if heartbeat_path != "":
				var heartbeat := FileAccess.open(heartbeat_path,FileAccess.WRITE)
				if heartbeat:
					heartbeat.store_string("serving")
					heartbeat.close()
		if not frozen:
			world.active = connections.values()
			var planned_move := false
			if not move_queue.is_empty():
				var peer: int = move_queue.pop_front()
				var arguments: Dictionary = pending_moves[peer]
				pending_moves.erase(peer)
				if connections.has(peer):
					planned_move = true
					var requested := Time.get_ticks_usec()
					var result: String = world.move(connections[peer],arguments.target,arguments.run,arguments.prefer)
					action_peak_ms = maxf(action_peak_ms,(Time.get_ticks_usec()-requested)/1000.0)
					answer.rpc_id(peer,{"message":"Server accepted movement" if result == "" else result})
			_advance_simulation(delta,not planned_move)
			checkpoint += delta
			if checkpoint>=float(world.data.config.save_interval): _commit()
		for peer in connected_at.keys():
			if not connections.has(peer) and Time.get_ticks_msec()-int(connected_at[peer])>5000:
				multiplayer.multiplayer_peer.disconnect_peer(peer)
				connected_at.erase(peer)
		broadcast_timer += delta
		if broadcast_timer>=0.1:
			broadcast_timer = 0
			_push_state()
	elif not serving and (connecting or connected) and multiplayer.multiplayer_peer and Time.get_ticks_msec()/1000.0-last_state>6:
		disconnect_client("Server stopped responding. Retry to reconnect; old clicks will not replay.")

	if serving: tick_peak_ms = maxf(tick_peak_ms,(Time.get_ticks_usec()-started)/1000.0)

func _advance_simulation(delta: float, allow_replan: bool = true) -> void:
	if world.data.paused:
		simulation_accumulator = 0
		return
	# Recover ordinary route-planning delay in small collision-safe steps.
	# A long host stall does not fast-forward an unattended world indefinitely.
	simulation_accumulator = minf(simulation_accumulator+delta,1.0)
	var steps := 0
	while simulation_accumulator+0.000000001>=0.05 and steps<10:
		world.tick(0.05,1 if steps==0 and allow_replan else 0)
		simulation_accumulator = maxf(0,simulation_accumulator-0.05)
		steps+=1

func _set_peer_timeout(peer: int) -> void:
	var transport := multiplayer.multiplayer_peer as ENetMultiplayerPeer
	if transport and transport.get_peer(peer): transport.get_peer(peer).set_timeout(8,2000,5000)
