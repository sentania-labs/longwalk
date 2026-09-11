extends Node
const PASSWORD = preload("res://src/admin/password.gd")
var control: RefCounted
var listener := TCPServer.new()
var clients: Array = []
var password_job: Thread
var password_context := {}
var next_login := 0.0

func start(admin: RefCounted) -> bool:
	control=admin
	return listener.listen(8888,"*")==OK

func _exit_tree() -> void:
	if password_job and password_job.is_started(): password_job.wait_to_finish()
	listener.stop()

func _process(_delta: float) -> void:
	if password_job and not password_job.is_alive():
		var derived: String=password_job.wait_to_finish()
		password_job=null
		_finish_password(derived)
	var accepted := 0
	while listener.is_connection_available() and accepted<4:
		var stream:=listener.take_connection()
		if clients.size()>=16: stream.disconnect_from_host()
		else: clients.append({"stream":stream,"input":PackedByteArray(),"output":PackedByteArray(),"offset":0,"age":Time.get_ticks_msec(),"waiting":false,"headers":{}})
		accepted+=1
	for client in clients.duplicate():
		var stream: StreamPeerTCP=client.stream
		stream.poll()
		if stream.get_status()!=StreamPeerTCP.STATUS_CONNECTED or Time.get_ticks_msec()-client.age>60000:
			stream.disconnect_from_host(); clients.erase(client); continue
		if not client.output.is_empty():
			var remaining: PackedByteArray=client.output.slice(client.offset,mini(client.offset+16384,client.output.size()))
			var sent:=stream.put_partial_data(remaining)
			if sent[0]!=OK: stream.disconnect_from_host(); clients.erase(client); continue
			client.offset+=sent[1]
			if client.offset>=client.output.size(): stream.disconnect_from_host(); clients.erase(client)
			continue
		if client.waiting: continue
		var available:=stream.get_available_bytes()
		if available>0:
			var received:=stream.get_partial_data(mini(available,32768))
			if received[0]!=OK: stream.disconnect_from_host(); clients.erase(client); continue
			client.input.append_array(received[1])
		if client.input.size()>24576: _reply(client,413,{"message":"Request too large"}); continue
		var source: String=client.input.get_string_from_utf8()
		var boundary:=source.find("\r\n\r\n")
		if boundary<0:
			if client.input.size()>8192 or Time.get_ticks_msec()-client.age>5000: _reply(client,400,{"message":"Incomplete request"})
			continue
		var lines:=source.substr(0,boundary).split("\r\n")
		var request:=lines[0].split(" ")
		if request.size()!=3 or request[2] not in ["HTTP/1.0","HTTP/1.1"]: _reply(client,400,{"message":"Invalid request"}); continue
		var headers: Dictionary={}
		var bad:=false
		for i in range(1,lines.size()):
			var colon:=lines[i].find(":")
			if colon<=0: bad=true; break
			var key:=lines[i].substr(0,colon).to_lower()
			if headers.has(key): bad=true; break
			headers[key]=lines[i].substr(colon+1).strip_edges()
		client.headers=headers
		if bad or headers.has("transfer-encoding") or not str(headers.get("content-length","0")).is_valid_int(): _reply(client,400,{"message":"Invalid request headers"}); continue
		var size:=int(headers.get("content-length",0))
		if size<0 or size>16384: _reply(client,413,{"message":"Request too large"}); continue
		# Header positions are byte offsets for this deliberately ASCII-only header parser.
		var header_bytes:=source.substr(0,boundary+4).to_utf8_buffer().size()
		if header_bytes>8192: _reply(client,400,{"message":"Headers too large"}); continue
		if client.input.size()<header_bytes+size: continue
		if not _host_allowed(str(headers.get("host",""))): _reply(client,403,{"message":"Use the server IP or configured admin origin"}); continue
		var method: String=request[0]
		var path: String=request[1]
		if method=="GET": _get(client,path); continue
		if method!="POST": _reply(client,405,{"message":"Method not allowed"}); continue
		var origin: String=headers.get("origin","")
		var authority: String=headers.get("host","")
		if origin not in ["http://"+authority,"https://"+authority] or not str(headers.get("content-type","")).begins_with("application/json"):
			_reply(client,403,{"message":"Same-origin JSON request required"}); continue
		var payload=JSON.parse_string(client.input.slice(header_bytes,header_bytes+size).get_string_from_utf8())
		if not payload is Dictionary: _reply(client,400,{"message":"JSON object required"}); continue
		_post(client,path,payload)

func _host_allowed(host: String) -> bool:
	if host=="" or "@" in host or "/" in host: return false
	var hostname:=host.get_slice(":",0)
	if host.begins_with("["): hostname=host.get_slice("]",0).trim_prefix("[")
	if hostname=="localhost" or hostname.is_valid_ip_address(): return true
	var allowed: String=control.configuration.get("admin_origin","")
	return allowed!="" and host==allowed.trim_prefix("https://")

func _cookie_name() -> String: return "lw_admin_"+str(control.account.get("salt","setup")).left(12)
func _session(client: Dictionary) -> Dictionary:
	for part in str(client.headers.get("cookie","")).split(";"):
		var pair:=part.strip_edges().split("=",true,1)
		if pair.size()==2 and pair[0]==_cookie_name(): return control.session(pair[1])
	return {}
func _get(client: Dictionary, path: String) -> void:
	if path in ["/","/app.js","/style.css"]:
		var name: String="index.html" if path=="/" else path.trim_prefix("/")
		var content_type: String="text/html" if path=="/" else "text/javascript" if path.ends_with(".js") else "text/css"
		_send(client,200,FileAccess.get_file_as_bytes("res://web/"+name),content_type)
		return
	if path=="/api/session":
		var principal:=_session(client)
		_reply(client,200,{"setup":control.account.is_empty(),"authenticated":not principal.is_empty(),"name":principal.get("name",""),"error":control.storage_error})
		return
	if path=="/api/release": _reply(client,200,control.link.handshake.release_info()); return
	if path!="/api/status": _reply(client,404,{"message":"Not found"}); return
	if _session(client).is_empty(): _reply(client,401,{"message":"Sign in to administer the world"}); return
	_reply(client,200,control.status())

func _post(client: Dictionary, path: String, data: Dictionary) -> void:
	if path in ["/api/setup","/api/login"]:
		if password_job or Time.get_ticks_msec()/1000.0<next_login: _reply(client,429,{"message":"Please wait before signing in again"}); return
		if path=="/api/setup" and (not control.account.is_empty() or control.storage_error!=""): _reply(client,403,{"message":"Admin setup is unavailable"}); return
		if path=="/api/login" and control.account.is_empty(): _reply(client,403,{"message":"Create the administrator first"}); return
		var name=data.get("name","")
		var password=data.get("password","")
		if not name is String or not password is String or name.length()<1 or name.length()>40 or password.length()<12 or password.length()>256:
			_reply(client,400,{"message":"Use a name up to 40 characters and a password of 12 to 256 characters"}); return
		var expression:=RegEx.new()
		expression.compile("^[A-Za-z0-9_.-]+$")
		if not expression.search(name): _reply(client,400,{"message":"Admin names use letters, digits, dot, dash or underscore"}); return
		var salt: String=Crypto.new().generate_random_bytes(16).hex_encode() if path=="/api/setup" else control.account.salt
		password_context={"client":client,"setup":path=="/api/setup","name":name,"salt":salt}
		password_job=Thread.new()
		client.waiting=true
		next_login=Time.get_ticks_msec()/1000.0+3
		password_job.start(PASSWORD.derive.bind(password,salt))
		return
	var principal:=_session(client)
	if principal.is_empty(): _reply(client,401,{"message":"Sign in to administer the world"}); return
	if path=="/api/logout":
		for key in control.sessions.keys():
			if control.sessions[key]==principal: control.sessions.erase(key)
		_reply(client,200,{"ok":true,"message":"Signed out"},_cookie_name()+"=; HttpOnly; SameSite=Strict; Path=/; Max-Age=0")
		return
	if path!="/api/action": _reply(client,404,{"message":"Not found"}); return
	if not data.get("action") is String or not data.get("arguments",{}) is Dictionary: _reply(client,400,{"message":"Invalid action"}); return
	var result: Dictionary=control.execute(principal,data.action,data.get("arguments",{}))
	_reply(client,200 if result.ok else 409,result)

func _finish_password(digest: String) -> void:
	var ctx:=password_context
	password_context={}
	var client: Dictionary=ctx.client
	var accepted:=false
	if ctx.setup: accepted=control.create_account(ctx.name,ctx.salt,digest)
	else:
		accepted=ctx.name==control.account.name and Crypto.new().constant_time_compare(digest.to_utf8_buffer(),str(control.account.hash).to_utf8_buffer())
		if not control.audit(str(control.account.name) if accepted else "anonymous","login",{},"accepted" if accepted else "rejected"): accepted=false
	if not accepted: _reply(client,401,{"message":"Sign-in failed. Check credentials and administration storage."}); return
	var session_value: String=control.login_session()
	var secure: String="; Secure" if str(client.headers.get("origin","")).begins_with("https://") else ""
	_reply(client,200,{"ok":true,"message":"Signed in"},_cookie_name()+"="+session_value+"; HttpOnly; SameSite=Strict; Path=/; Max-Age=28800"+secure)

func _reply(client: Dictionary, code: int, data: Dictionary, cookie: String = "") -> void:
	_send(client,code,JSON.stringify(data).to_utf8_buffer(),"application/json",cookie)
func _send(client: Dictionary, code: int, data: PackedByteArray, content_type: String, cookie: String = "") -> void:
	var headers: String="HTTP/1.1 %d Response\r\nContent-Type: %s; charset=utf-8\r\nContent-Length: %d\r\nConnection: close\r\nCache-Control: no-store\r\nX-Content-Type-Options: nosniff\r\nContent-Security-Policy: default-src 'self'; script-src 'self'; style-src 'self'; object-src 'none'; base-uri 'none'; frame-ancestors 'none'\r\n" % [code,content_type,data.size()]
	if cookie!="": headers+="Set-Cookie: "+cookie+"\r\n"
	client.output=(headers+"\r\n").to_utf8_buffer()
	client.output.append_array(data)
	client.input=PackedByteArray()
	client.waiting=false
