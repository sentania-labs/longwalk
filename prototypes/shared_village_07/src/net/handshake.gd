extends Node
# Frozen transport v1: keep this node path, signatures and RPC annotations stable.
# Game RPCs are not used until this separate negotiation succeeds.
var link: Node
var admitted := {}

func release_info() -> Dictionary:
	var config: Dictionary=link.admin.configuration if link.admin else {}
	var result: Dictionary={"transport":1,"protocol":link.PROTOCOL,"baseline":link.version,"build":link.build_identity,"manifest_url":config.get("manifest_url",""),"recommended_build":config.get("recommended_build","")}
	if FileAccess.file_exists("res://release_manifest.json"):
		var manifest=JSON.parse_string(FileAccess.get_file_as_string("res://release_manifest.json"))
		if manifest is Dictionary: result["art_sha256"]=manifest.get("art_sha256","")
	return result

@rpc("any_peer","call_remote","reliable")
func negotiate(offer: Dictionary) -> void:
	if not link.serving: return
	var peer:=multiplayer.get_remote_sender_id()
	if admitted.has(peer): return
	var info:=release_info()
	var exact: String=link.admin.configuration.get("minimum_build","")
	var required: bool=offer.get("transport")!=1 or offer.get("protocol")!=link.PROTOCOL or offer.get("baseline")!=link.version or (exact!="" and offer.get("build")!=exact)
	if info.get("art_sha256","")!="" and offer.get("art_sha256","")!=info.art_sha256: required=true
	var optional: bool=not required and info.recommended_build!="" and offer.get("build")!=info.recommended_build
	info["update"]="required" if required else "optional" if optional else "none"
	info["message"]="Update required before joining this world" if required else "An optional client update is available" if optional else "Compatible"
	if not required: admitted[peer]=true
	decision.rpc_id(peer,info)

@rpc("authority","call_remote","reliable")
func decision(result: Dictionary) -> void:
	if link.serving: return
	link.update_info=result
	if result.get("update")=="required":
		link.disconnect_client("Update required: "+str(result.get("protocol",""))+". Open Connection settings for release information.")
		return
	link.hello.rpc_id(1,link.version+"|"+link.PROTOCOL,link.token)
	if result.get("update")=="optional": link.notice.emit("An optional client update is available in Connection settings")
