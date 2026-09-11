extends RefCounted
const PASSWORD = preload("res://src/admin/password.gd")
const PERMISSIONS = {
	"admin":["inspect","pause","clock","settings","backup","restore","skill","teleport","teleport_self","ticket","revoke","release_settings"],
	"mod":["inspect","teleport_self"]
}
var link: Node
var directory := ""
var account := {}
var configuration := {"manifest_url":"","recommended_build":"","minimum_build":"","admin_origin":""}
var sessions := {}
var tickets := {}
var staff := {}
var audit_sequence := 0
var audit_tail: Array = []
var storage_error := ""

func initialize(owner_link: Node, world_directory: String) -> bool:
	link = owner_link
	directory = world_directory.path_join("administration")
	if DirAccess.make_dir_recursive_absolute(directory)!=OK: storage_error="Cannot open administration storage"; return false
	if FileAccess.file_exists(directory.path_join("account.json")):
		account = _read("account.json")
		if not account.has("salt") or not account.has("hash") or not account.has("name"): storage_error="Administrator account record is invalid"; return false
	if FileAccess.file_exists(directory.path_join("release.json")):
		configuration = _read("release.json")
		if not configuration.has("manifest_url"): storage_error="Release settings record is invalid"; return false
	var files := DirAccess.get_files_at(directory)
	files.sort()
	for file in files:
		if file.begins_with("audit-") and file.ends_with(".json"):
			audit_sequence = maxi(audit_sequence,file.trim_prefix("audit-").trim_suffix(".json").to_int())
	for i in range(maxi(0,files.size()-100),files.size()):
		if files[i].begins_with("audit-"):
			var record := _read(files[i])
			if record.is_empty(): storage_error="Audit record is invalid"; return false
			audit_tail.append(record)
	return true

func _read(name: String) -> Dictionary:
	var value = JSON.parse_string(FileAccess.get_file_as_string(directory.path_join(name)))
	if not value is Dictionary or not value.get("payload") is String or value.get("checksum") != value.payload.sha256_text(): return {}
	var data = JSON.parse_string(value.payload)
	return data if data is Dictionary else {}

func _write(name: String, data: Dictionary) -> bool:
	var path := directory.path_join(name)
	var payload := JSON.stringify(data)
	var file := FileAccess.open(path+".pending",FileAccess.WRITE)
	if not file: storage_error="Administration storage is not writable"; return false
	file.store_string(JSON.stringify({"payload":payload,"checksum":payload.sha256_text()}))
	file.flush()
	var result := file.get_error()
	file.close()
	if result!=OK or _read(name+".pending")!=data: storage_error="Administration record failed verification"; return false
	if DirAccess.rename_absolute(path+".pending",path)!=OK: storage_error="Administration record could not be published"; return false
	storage_error=""
	return true

func audit(actor: String, operation: String, data: Dictionary, outcome: String) -> bool:
	var record := {"sequence":audit_sequence+1,"utc":Time.get_datetime_string_from_system(true),"actor":actor,"action":operation,"details":data,"outcome":outcome}
	var name := "audit-%012d.json" % (audit_sequence+1)
	if FileAccess.file_exists(directory.path_join(name)) or not _write(name,record): return false
	audit_sequence+=1
	audit_tail.append(record)
	if audit_tail.size()>100: audit_tail.pop_front()
	return true

func create_account(name: String, salt: String, digest: String) -> bool:
	if not account.is_empty(): return false
	var value := {"name":name,"salt":salt,"hash":digest,"iterations":PASSWORD.ITERATIONS}
	if not audit(name,"create_admin",{},"intent") or not _write("account.json",value): return false
	account=value
	return audit(name,"create_admin",{},"completed")

func login_session() -> String:
	var value := Crypto.new().generate_random_bytes(32).hex_encode()
	sessions[value] = {"name":account.name,"role":"admin","expires":Time.get_unix_time_from_system()+28800}
	return value

func session(value: String) -> Dictionary:
	if not sessions.has(value): return {}
	if sessions[value].expires<Time.get_unix_time_from_system(): sessions.erase(value); return {}
	return sessions[value]

func staff_for(peer: int) -> Dictionary:
	if not staff.has(peer): return {}
	if staff[peer].expires<Time.get_unix_time_from_system(): staff.erase(peer); return {}
	return staff[peer]

func redeem(peer: int, code: String) -> Dictionary:
	var key := code.sha256_text()
	if not tickets.has(key): return {"ok":false,"message":"Invalid or expired staff code"}
	var ticket: Dictionary = tickets[key]
	tickets.erase(key)
	if ticket.expires<Time.get_unix_time_from_system() or ticket.peer!=peer or not link.connections.has(peer): return {"ok":false,"message":"Staff code does not match this connection"}
	if not audit(ticket.name,"staff_redeem",{"player":link.connections[peer],"role":ticket.role},"completed"): return {"ok":false,"message":storage_error}
	staff[peer] = {"name":ticket.name,"role":ticket.role,"expires":Time.get_unix_time_from_system()+3600}
	return {"ok":true,"message":"Staff mode enabled for this connection: "+ticket.role,"role":ticket.role}

func status() -> Dictionary:
	var players := []
	if link.world:
		for ident in link.world.data.players:
			var person: Dictionary = link.world.data.players[ident]
			var peer := 0
			for connected_peer in link.connections:
				if link.connections[connected_peer]==ident: peer=connected_peer
			players.append({"id":ident,"name":person.get("name","Player"),"online":peer!=0,"area":person.get("area","outside"),"position":person.position,"role":staff_for(peer).get("role","")})
	return {"build":link.build_identity,"protocol":link.PROTOCOL,"baseline":link.version,"frozen":link.frozen,"error":link.error,"admin_error":storage_error,"paused":link.world.data.paused if link.world else true,"clock":link.world.data.get("clock",900) if link.world else 0,"config":link.world.data.config if link.world else {},"players":players,"backups":link.store.records("backup-") if link.store else [],"metrics":link.metrics,"audit":audit_tail.slice(maxi(0,audit_tail.size()-30)),"release":configuration}

func execute(principal: Dictionary, operation: String, arguments: Dictionary, peer: int = 0) -> Dictionary:
	var role: String = principal.get("role","")
	if operation not in PERMISSIONS.get(role,[]): return {"ok":false,"message":"This staff role cannot perform that action"}
	if operation in ["restore","skill","teleport","teleport_self","revoke","release_settings"] and arguments.get("confirmed")!=true: return {"ok":false,"message":"Confirm this action first"}
	if link.frozen and operation not in ["restore","inspect","ticket","revoke","release_settings"]: return {"ok":false,"message":"World storage is frozen. Recover it through the portal first."}
	var ident: String = arguments.get("player","") if arguments.get("player","") is String else ""
	if operation=="teleport_self":
		if peer==0 or not link.connections.has(peer): return {"ok":false,"message":"Self teleport requires an in-world staff session"}
		ident=link.connections[peer]
	if operation in ["inspect","skill","teleport","teleport_self","ticket","revoke"] and not link.world.data.players.has(ident): return {"ok":false,"message":"Choose an existing player"}
	var details := {"player":ident}
	for key in ["skill","level","x","z","area","paused","minutes","role","reason"]:
		if arguments.has(key): details[key]=arguments[key]
	if not audit(principal.name,operation,details,"intent"): return {"ok":false,"message":storage_error}
	var previous: Dictionary = link.world.data.duplicate(true)
	var result := _apply(principal,operation,arguments,ident)
	if not result.ok and operation not in ["restore","backup"]:
		link.world.data=previous
		link.world.apply_resource()
	if not audit(principal.name,operation,details,result.message):
		link.frozen=true
		link.error="Audit outcome could not be saved; inspect administration storage before continuing"
		result={"ok":false,"message":link.error}
	link._push_state()
	return result

func _apply(principal: Dictionary, operation: String, args: Dictionary, ident: String) -> Dictionary:
	if operation=="inspect":
		return {"ok":true,"message":"Player inspected","player":link.world.data.players[ident].duplicate(true)}
	if operation=="ticket":
		if args.get("role") not in ["admin","mod"]: return _fail("Choose admin or mod")
		var peer := 0
		for candidate in link.connections:
			if link.connections[candidate]==ident: peer=candidate
		if peer==0: return _fail("Player must be connected before staff authorization")
		var code := Crypto.new().generate_random_bytes(16).hex_encode()
		tickets[code.sha256_text()]={"peer":peer,"name":principal.name,"role":args.role,"expires":Time.get_unix_time_from_system()+120}
		return {"ok":true,"message":"Enter this one-use code in that client's Staff interface within two minutes","code":code}
	if operation=="revoke":
		for candidate in link.connections:
			if link.connections[candidate]==ident: staff.erase(candidate)
		for key in tickets.keys():
			if link.connections.get(tickets[key].peer,"")==ident: tickets.erase(key)
		return {"ok":true,"message":"Staff access revoked"}
	if operation=="release_settings":
		var values := {}
		for key in ["manifest_url","recommended_build","minimum_build","admin_origin"]:
			var value = args.get(key,"")
			if not value is String or value.length()>512 or "\n" in value or "\r" in value: return _fail("Invalid release setting")
			if key.ends_with("url") and value!="" and not value.begins_with("https://"): return _fail("Release manifest must use HTTPS")
			if key=="admin_origin" and value!="" and (not value.begins_with("https://") or value.trim_suffix("/").count("/")!=2): return _fail("Admin origin must be an HTTPS origin without a path")
			values[key]=value.trim_suffix("/") if key=="admin_origin" else value
		if not _write("release.json",values): return _fail(storage_error)
		configuration=values
		return {"ok":true,"message":"Release settings saved"}
	if operation=="skill":
		if args.get("skill") not in ["running","woodcraft","observation"]: return _fail("Unknown skill")
		var level = args.get("level")
		if not _number(level) or level<0 or level>10 or level!=floor(level): return _fail("Choose a whole skill level from 0 to 10")
		link.world.data.players[ident].practice[args.skill]=float(level*level*100)
		return _saved("Skill level saved")
	if operation in ["teleport","teleport_self"]:
		var x = args.get("x")
		var z = args.get("z")
		var area = args.get("area","outside")
		if not _number(x) or not _number(z) or absf(x)>510 or absf(z)>510 or area not in ["outside","workshop"]: return _fail("Invalid teleport destination")
		if area=="workshop" and (absf(x)>7 or absf(z)>5): return _fail("Destination is outside the workshop")
		var target := Vector3(x,0,z)
		var grid = link.world.nav if area=="outside" else link.world.interior
		if grid.is_point_solid(link.world.cell(target)): return _fail("Teleport destination is blocked")
		for other in link.world.active:
			if other!=ident and link.world.data.players[other].area==area and link.world.position(other).distance_to(target)<1.35: return _fail("Teleport destination is occupied")
		link.world.stop(ident)
		for pending_peer in link.connections:
			if link.connections[pending_peer]==ident:
				link.pending_moves.erase(pending_peer)
				link.move_queue.erase(pending_peer)
		link.world.data.players[ident].area=area
		link.world.data.players[ident].position=[x,link.world.ground(target) if area=="outside" else 0,z]
		return _saved("Teleport saved")
	if operation=="pause":
		if not args.get("paused") is bool: return _fail("Choose paused or running")
		if link.world.data.paused==args.paused: return {"ok":true,"message":"World already in requested state"}
	var message: String=link._admin(operation,args)
	var success := message in ["World pause updated","World time updated","Settings saved","Backup restored; world remains paused"] or message.begins_with("Backup saved:")
	return {"ok":success,"message":message}

func _saved(message: String) -> Dictionary:
	return {"ok":true,"message":message} if link._commit() else _fail(link.error)
static func _number(value: Variant) -> bool: return (value is float or value is int) and is_finite(float(value))
static func _fail(message: String) -> Dictionary: return {"ok":false,"message":message}
