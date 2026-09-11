extends SceneTree
func _initialize() -> void:
	var actors := []
	for i in range(16):
		actors.append({"id":Crypto.new().generate_random_bytes(32).hex_encode(),"position":[float(i)*11.23,0.0,float(i)*7.16],"area":"outside","moving":true,"running":true})
	var payload := {"sequence":1,"boot":"a".repeat(24),"actors":actors,"clock":900.0,"elapsed":42.0,"revision":20,"saved_generation":21,"vitals":[100.0,57.3,153.8],"citizen":{"position":[4.0,0.0,4.0],"activity":"market","moving":false}}
	var packet := var_to_bytes(payload).compress(FileAccess.COMPRESSION_DEFLATE)
	assert(packet.size()<1250,"Motion packet must leave room for ENet/RPC headers: "+str(packet.size()))
	var link = load("res://src/net/world_link.gd").new()
	link.local_id = actors[0].id
	var person := {"position":[0,0,0]}
	preload("res://src/sim/workshop.gd").ensure(person)
	var facts := {"person":person,"cut":true,"gathering":{},"paused":false,"error":"","config":{},"backups":[]}
	link.details(facts)
	assert(link.snapshot.is_empty(),"Do not expose half of the initial snapshot")
	link.state(packet)
	assert(link.snapshot.person.stamina == 57.3 and link.snapshot.person.practice.running == 153.8)
	payload.sequence = 0
	payload.vitals = [100.0,1.0,1.0]
	link.state(var_to_bytes(payload).compress(FileAccess.COMPRESSION_DEFLATE))
	assert(link.snapshot.person.stamina == 57.3)
	link.free()
	print("SNAPSHOT PACKETS PASSED: 16 moving players in ",packet.size()," bytes; reliable facts merge; stale motion rejected")
	quit()
