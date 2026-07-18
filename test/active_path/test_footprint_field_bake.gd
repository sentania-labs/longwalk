extends SceneTree

const Baker := preload("res://tools/art/bake_footprint_field.gd")
const TownLayoutScript := preload("res://src/sim/town_layout.gd")
const EXPECTED_FIELD_SHA := "e5c916cf1c294deef7c985a2f5b4b08b9964bc45ebb0ea129fcb0610bc18f684"
const EXPECTED_LAYOUT_SHA := "b0d1209c7f376cced1b5e25f24b63073997c550da1cd783768fdff8b4dc51529"


func _init() -> void:
	var layout = TownLayoutScript.build_inn_green_district()
	var first := Baker.bake(layout)
	var second := Baker.bake(layout)
	assert(first.get_size() == Vector2i(256, 224))
	assert(first.get_data() == second.get_data(), "same layout and params must produce byte-identical fields")
	assert(_sha256(first.get_data()) == EXPECTED_FIELD_SHA, "field bytes drifted; rebake and review the seam contract")
	assert(Baker.layout_fingerprint(layout) == EXPECTED_LAYOUT_SHA, "layout-derived bytes drifted; rebake and review the seam contract")
	print("footprint field byte-stability and layout-drift tests passed.")
	quit(0)


static func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()
