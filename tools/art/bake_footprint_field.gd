extends SceneTree

const TownLayoutScript := preload("res://src/sim/town_layout.gd")

const TEXELS_PER_CELL := 16
const APRON_RADIUS_CELLS := 0.85
const DOOR_RADIUS_CELLS := 0.72
const DISTANCE_RANGE_CELLS := 2.0
const OUTPUT := "res://assets/village/footprint_interaction_field.png"

# Door positions are render metadata keyed by the same kit id as the manifest.
# Coordinates are normalized across the placement footprint, with positive Y
# facing the authored front edge. They do not belong in the sim layout.
const DOORS := {
	"inn": Vector2(0.50, 1.0),
	"cottage_front": Vector2(0.50, 1.0),
	"cottage_rear": Vector2(0.50, 1.0),
	"smithy_cluster": Vector2(0.68, 1.0),
}


func _init() -> void:
	var layout = TownLayoutScript.build_inn_green_district()
	var image := bake(layout)
	var error := image.save_png(OUTPUT)
	if error != OK:
		push_error("footprint field bake failed: %s" % error_string(error))
		quit(1)
		return
	print("footprint_field image_sha256=%s layout_sha256=%s" % [_sha256(image.get_data()), layout_fingerprint(layout)])
	quit(0)


static func bake(layout) -> Image:
	var width: int = layout.width * TEXELS_PER_CELL
	var height: int = layout.height * TEXELS_PER_CELL
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	var buildings: Array = []
	for placement in layout.placements:
		if placement.blocks and DOORS.has(placement.id) and placement.kind != "tree":
			buildings.append(placement)
	buildings.sort_custom(func(a, b): return a.id < b.id)
	for y in range(height):
		for x in range(width):
			var sample := Vector2((x + 0.5) / TEXELS_PER_CELL, (y + 0.5) / TEXELS_PER_CELL)
			var signed_distance := INF
			var door_distance := INF
			for placement in buildings:
				var minimum := Vector2(placement.cell)
				var maximum := minimum + Vector2(placement.footprint)
				signed_distance = minf(signed_distance, _box_signed_distance(sample, minimum, maximum))
				var door_uv: Vector2 = DOORS[placement.id]
				var door := minimum + door_uv * Vector2(placement.footprint)
				door_distance = minf(door_distance, sample.distance_to(door))
			var coverage := 1.0 - smoothstep(0.0, APRON_RADIUS_CELLS, maxf(signed_distance, 0.0))
			var encoded_distance := clampf(0.5 + signed_distance / (2.0 * DISTANCE_RANGE_CELLS), 0.0, 1.0)
			var threshold_wear := 1.0 - smoothstep(0.0, DOOR_RADIUS_CELLS, door_distance)
			# R coverage, G signed distance, B independent threshold wear, A opaque.
			image.set_pixel(x, y, Color(coverage, encoded_distance, threshold_wear, 1.0))
	return image


static func layout_fingerprint(layout) -> String:
	var rows: Array[String] = ["%dx%d" % [layout.width, layout.height]]
	for placement in layout.placements:
		if placement.blocks and DOORS.has(placement.id) and placement.kind != "tree":
			var door: Vector2 = DOORS[placement.id]
			rows.append("%s:%d,%d:%d,%d:%.3f,%.3f" % [placement.id, placement.cell.x, placement.cell.y, placement.footprint.x, placement.footprint.y, door.x, door.y])
	rows.sort()
	return _sha256("\n".join(rows).to_utf8_buffer())


static func _box_signed_distance(point: Vector2, minimum: Vector2, maximum: Vector2) -> float:
	var center := (minimum + maximum) * 0.5
	var half_size := (maximum - minimum) * 0.5
	var delta := (point - center).abs() - half_size
	return Vector2(maxf(delta.x, 0.0), maxf(delta.y, 0.0)).length() + minf(maxf(delta.x, delta.y), 0.0)


static func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()
