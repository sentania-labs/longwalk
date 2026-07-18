extends SceneTree

const TownLayoutScript := preload("res://src/sim/town_layout.gd")

# All stochastic-looking fields are fixed functions of the named seed, layer
# offset, and integer texel coordinate. Lane geometry itself is authored.
const LAYOUT_SEED := 7007
const SHOULDER_WARP_OFFSET := 6203
const DENSITY_OFFSET := 9341
const TEXELS_PER_CELL := 16
const SHOULDER_WIDTH := 0.72
const SHOULDER_WARP_AMPLITUDE := 0.22
const SMIN_RADIUS := 0.28
const MASK_OUTPUT := "res://assets/village/lane_mask.png"
const DENSITY_OUTPUT := "res://assets/village/lane_density.png"


func _init() -> void:
	var layout = TownLayoutScript.build_inn_green_district()
	var pixel_width: int = layout.width * TEXELS_PER_CELL
	var pixel_height: int = layout.height * TEXELS_PER_CELL
	var mask := Image.create(pixel_width, pixel_height, false, Image.FORMAT_RG8)
	var density := Image.create(pixel_width, pixel_height, false, Image.FORMAT_R8)
	var shoulder_noise := _noise(SHOULDER_WARP_OFFSET, 0.055, 3)
	var density_noise := _noise(DENSITY_OFFSET, 0.021, 4)

	for y in range(pixel_height):
		for x in range(pixel_width):
			var sample := Vector2((float(x) + 0.5) / TEXELS_PER_CELL, (float(y) + 0.5) / TEXELS_PER_CELL)
			var distances: Array[float] = []
			for lane in layout.lanes:
				distances.append(_lane_signed_distance(sample, lane))
			distances.sort()
			var unwarped_distance: float = distances[0]
			var core := 1.0 if unwarped_distance <= 0.0 else 0.0
			var shoulder_distance := unwarped_distance
			if distances.size() > 1:
				shoulder_distance = _smooth_min(shoulder_distance, distances[1], SMIN_RADIUS)
			var warp := shoulder_noise.get_noise_2d(float(x), float(y)) * SHOULDER_WARP_AMPLITUDE
			var coverage := 1.0 - smoothstep(0.0, SHOULDER_WIDTH, shoulder_distance + warp)
			coverage = maxf(core, coverage)
			var wear_density := clampf(density_noise.get_noise_2d(float(x), float(y)) * 0.5 + 0.5, 0.0, 1.0)
			mask.set_pixel(x, y, Color(core, coverage, 0.0, 1.0))
			density.set_pixel(x, y, Color(wear_density, 0.0, 0.0, 1.0))

	var mask_error := mask.save_png(MASK_OUTPUT)
	var density_error := density.save_png(DENSITY_OUTPUT)
	if mask_error != OK or density_error != OK:
		push_error("lane mask bake failed: mask=%s density=%s" % [error_string(mask_error), error_string(density_error)])
		quit(1)
		return
	print("lane_mask image_sha256=%s" % _sha256(mask.get_data()))
	print("lane_density image_sha256=%s" % _sha256(density.get_data()))
	quit(0)


func _noise(layer_offset: int, frequency: float, octaves: int) -> FastNoiseLite:
	var noise := FastNoiseLite.new()
	noise.seed = LAYOUT_SEED + layer_offset
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = frequency
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = octaves
	noise.fractal_lacunarity = 2.0
	noise.fractal_gain = 0.5
	return noise


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()


func _lane_signed_distance(sample: Vector2, lane) -> float:
	var best := INF
	for i in range(lane.points.size() - 1):
		var a: Vector2 = lane.points[i]
		var b: Vector2 = lane.points[i + 1]
		var delta := b - a
		var t := clampf((sample - a).dot(delta) / delta.length_squared(), 0.0, 1.0)
		var half_width: float = lerpf(lane.half_widths[i], lane.half_widths[i + 1], t)
		best = minf(best, sample.distance_to(a + delta * t) - half_width)
	return best


# Polynomial smooth minimum. Its radius is bounded to 0.28 cells, below the
# authored minimum separation of distinct lane shoulders. It affects only the
# cosmetic coverage calculation, never the protected core channel.
func _smooth_min(a: float, b: float, radius: float) -> float:
	var h := maxf(radius - absf(a - b), 0.0) / radius
	return minf(a, b) - h * h * radius * 0.25
