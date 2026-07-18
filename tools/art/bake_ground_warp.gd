extends SceneTree

# Deterministic ground-warp contract: named layout seed 7007, fixed layer
# offset 4109, 256x256 R8 output. Texel (x, y) samples FastNoiseLite at integer
# coordinate (x, y), and maps noise [-1, 1] to byte [0, 255]. No stateful RNG,
# time seed, accumulator, or visit-order input participates in the bake.
const LAYOUT_SEED := 7007
const LAYER_OFFSET := 4109
const RESOLUTION := 256
const OUTPUT := "res://assets/village/ground_warp.png"


func _init() -> void:
	var noise := FastNoiseLite.new()
	noise.seed = LAYOUT_SEED + LAYER_OFFSET
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.035
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 4
	noise.fractal_lacunarity = 2.0
	noise.fractal_gain = 0.5
	var image := Image.create(RESOLUTION, RESOLUTION, false, Image.FORMAT_R8)
	for y in range(RESOLUTION):
		for x in range(RESOLUTION):
			var normalized := clampf(noise.get_noise_2d(float(x), float(y)) * 0.5 + 0.5, 0.0, 1.0)
			image.set_pixel(x, y, Color(normalized, 0.0, 0.0, 1.0))
	var error := image.save_png(OUTPUT)
	if error != OK:
		push_error("ground warp save failed: %s" % error_string(error))
		quit(1)
	else:
		quit(0)
