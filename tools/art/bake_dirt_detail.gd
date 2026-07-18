extends SceneTree

# Deterministic dirt-detail contract: named layout seed 7007, fixed new layer
# offsets 12109 and 14503, and the committed 1024x1024 grass plate as input.
# R is a zero-mean shoulder-detail field whose majority component is the grass
# luminance high-pass at BOX_BLUR_RADIUS source texels. G is a zero-mean broad
# core-drift field prefiltered at CORE_BLUR_RADIUS source texels. Every noise
# sample is a fixed function of (seed, layer offset, integer texel). No stateful
# RNG, time seed, accumulator, or visit-order input participates in the bake.
# Expected decoded image_sha256:
# 9a0d28cd2a50c7c9d754bae3b4acc33d9d8962f630ff197adf1f37ae88bf6f94
const LAYOUT_SEED := 7007
const SHOULDER_DETAIL_OFFSET := 12109
const CORE_DRIFT_OFFSET := 14503
const RESOLUTION := 1024
const BOX_BLUR_RADIUS := 12
const CORE_BLUR_RADIUS := 64
const GRASS_INPUT := "res://assets/village/ground_grass_plate.png"
const OUTPUT := "res://assets/village/ground_dirt_detail.png"


func _init() -> void:
	var grass := Image.load_from_file(GRASS_INPUT)
	if grass == null or grass.is_empty():
		push_error("dirt detail could not load grass plate: %s" % GRASS_INPUT)
		quit(1)
		return
	if grass.get_width() != RESOLUTION or grass.get_height() != RESOLUTION:
		push_error("dirt detail grass plate must be %dx%d" % [RESOLUTION, RESOLUTION])
		quit(1)
		return
	grass.convert(Image.FORMAT_RGB8)

	var luminance := PackedFloat32Array()
	luminance.resize(RESOLUTION * RESOLUTION)
	for y in range(RESOLUTION):
		for x in range(RESOLUTION):
			var color := grass.get_pixel(x, y)
			luminance[y * RESOLUTION + x] = color.r * 0.2126 + color.g * 0.7152 + color.b * 0.0722
	var high_pass := _subtract(luminance, _box_blur_wrapped(luminance, BOX_BLUR_RADIUS))
	_standardize(high_pass)

	var shoulder_noise := _noise(SHOULDER_DETAIL_OFFSET, 0.018, 4)
	var core_noise := _noise(CORE_DRIFT_OFFSET, 0.0022, 2)
	var shoulder := PackedFloat32Array()
	var core := PackedFloat32Array()
	shoulder.resize(RESOLUTION * RESOLUTION)
	core.resize(RESOLUTION * RESOLUTION)
	for y in range(RESOLUTION):
		for x in range(RESOLUTION):
			var index := y * RESOLUTION + x
			var fbm := shoulder_noise.get_noise_2d(float(x), float(y))
			var speckle := maxf((fbm - 0.62) / 0.38, 0.0)
			# Painted high-pass remains the clear majority. The procedural terms
			# only break repetition and add sparse worn-earth flecks.
			shoulder[index] = high_pass[index] * 0.78 + fbm * 0.17 + speckle * 0.05
			core[index] = core_noise.get_noise_2d(float(x), float(y))
	_standardize(shoulder)
	core = _box_blur_wrapped(core, CORE_BLUR_RADIUS)
	_standardize(core)

	var image := Image.create(RESOLUTION, RESOLUTION, false, Image.FORMAT_RG8)
	for y in range(RESOLUTION):
		for x in range(RESOLUTION):
			var index := y * RESOLUTION + x
			var r := clampf(0.5 + shoulder[index] * 0.18, 0.0, 1.0)
			var g := clampf(0.5 + core[index] * 0.16, 0.0, 1.0)
			image.set_pixel(x, y, Color(r, g, 0.0, 1.0))
	var error := image.save_png(OUTPUT)
	if error != OK:
		push_error("dirt detail save failed: %s" % error_string(error))
		quit(1)
		return
	print("ground_dirt_detail image_sha256=%s" % _sha256(image.get_data()))
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


# Separable wrapped box blur. Each output depends only on the immutable input
# and its integer coordinate; the temporary pass is not fed back into itself.
func _box_blur_wrapped(source: PackedFloat32Array, radius: int) -> PackedFloat32Array:
	var horizontal := PackedFloat32Array()
	var result := PackedFloat32Array()
	horizontal.resize(source.size())
	result.resize(source.size())
	var width := radius * 2 + 1
	for y in range(RESOLUTION):
		var total := 0.0
		for offset in range(-radius, radius + 1):
			total += source[y * RESOLUTION + posmod(offset, RESOLUTION)]
		for x in range(RESOLUTION):
			horizontal[y * RESOLUTION + x] = total / width
			total -= source[y * RESOLUTION + posmod(x - radius, RESOLUTION)]
			total += source[y * RESOLUTION + posmod(x + radius + 1, RESOLUTION)]
	for x in range(RESOLUTION):
		var total := 0.0
		for offset in range(-radius, radius + 1):
			total += horizontal[posmod(offset, RESOLUTION) * RESOLUTION + x]
		for y in range(RESOLUTION):
			result[y * RESOLUTION + x] = total / width
			total -= horizontal[posmod(y - radius, RESOLUTION) * RESOLUTION + x]
			total += horizontal[posmod(y + radius + 1, RESOLUTION) * RESOLUTION + x]
	return result


func _subtract(a: PackedFloat32Array, b: PackedFloat32Array) -> PackedFloat32Array:
	var result := PackedFloat32Array()
	result.resize(a.size())
	for index in range(a.size()):
		result[index] = a[index] - b[index]
	return result


func _standardize(values: PackedFloat32Array) -> void:
	var mean := 0.0
	for value in values:
		mean += value
	mean /= values.size()
	var variance := 0.0
	for value in values:
		variance += (value - mean) * (value - mean)
	var deviation := sqrt(variance / values.size())
	for index in range(values.size()):
		values[index] = (values[index] - mean) / deviation


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()
