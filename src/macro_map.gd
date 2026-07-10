extends RefCounted
class_name MacroMapGenerator

# MacroMapGenerator produces the authoritative low-resolution planet map.
#
# Determinism contract (see CLAUDE.md and ARCHITECTURE.md):
#   The world is a pure function of (seed, position). Every per-cell value
#   is computed by sampling seeded FastNoiseLite instances at a position
#   derived only from (cell x, cell y). There is NO sequential or stateful
#   RNG in any placement decision, so generation order and visit order can
#   never change the result. Running twice with the same seed produces
#   byte-identical PNG and JSON output.
#
# World topology (see CLAUDE.md):
#   The world is a flat plane wrapped east-west (cylindrical). To make the
#   noise seamless across the east-west wrap, the x axis is mapped onto a
#   circle and sampled with 3D noise: a horizontal wrap becomes a full loop
#   around the cylinder, so x=0 and x=width-1 are neighbors with no seam.
#   The y axis (north-south) is sampled linearly and does NOT wrap; there
#   is a hard north edge and a hard south edge.

# Fixed generation parameters. These are part of the determinism contract:
# changing them changes every map, so they are pinned constants rather than
# tunable at the CLI for M1.
const DEFAULT_WIDTH := 512
const DEFAULT_HEIGHT := 256

# Elevation thresholds (noise normalized to 0..1).
const SEA_LEVEL := 0.5
const BEACH_LEVEL := 0.52
const MOUNTAIN_LEVEL := 0.72

# Temperature is derived from latitude plus a noise perturbation. This
# controls how strongly the noise nudges the clean latitude gradient.
const TEMP_NOISE_WEIGHT := 0.18
# Higher ground is colder. Elevation above sea level cools temperature by
# up to this amount at the highest peaks.
const ELEVATION_COOLING := 0.35

var width: int
var height: int
var seed_value: int

# Noise layers. Each is seeded off the world seed with a fixed offset so the
# three layers are decorrelated but still fully determined by the seed.
var _elevation_noise: FastNoiseLite
var _temperature_noise: FastNoiseLite
var _moisture_noise: FastNoiseLite

# The ordered starter biome set. Order here is the canonical order used for
# color lookup and for the JSON distribution breakdown, so it stays stable.
const BIOME_OCEAN := "ocean"
const BIOME_BEACH := "beach"
const BIOME_PLAINS := "plains"
const BIOME_FOREST := "forest"
const BIOME_DESERT := "desert"
const BIOME_TUNDRA := "tundra"
const BIOME_MOUNTAIN := "mountain"

const BIOME_ORDER := [
	BIOME_OCEAN,
	BIOME_BEACH,
	BIOME_PLAINS,
	BIOME_FOREST,
	BIOME_DESERT,
	BIOME_TUNDRA,
	BIOME_MOUNTAIN,
]

# Biome colors for the rendered PNG. Ocean and mountain get elevation-based
# shading applied on top of these base colors in _biome_color().
const BIOME_COLORS := {
	BIOME_OCEAN: Color8(30, 62, 120),
	BIOME_BEACH: Color8(214, 199, 140),
	BIOME_PLAINS: Color8(126, 176, 92),
	BIOME_FOREST: Color8(52, 110, 58),
	BIOME_DESERT: Color8(211, 182, 108),
	BIOME_TUNDRA: Color8(168, 178, 172),
	BIOME_MOUNTAIN: Color8(122, 116, 110),
}


func _init(p_seed: int, p_width: int = DEFAULT_WIDTH, p_height: int = DEFAULT_HEIGHT) -> void:
	seed_value = p_seed
	width = p_width
	height = p_height

	# Elevation: fractal (FBM) noise for continents and mountain ranges.
	_elevation_noise = FastNoiseLite.new()
	_elevation_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_elevation_noise.seed = seed_value
	# Feature scale note: with the cylinder radius = width / TAU, the number of
	# noise features across the map width is approximately width * frequency.
	# At 512 wide, frequency 0.011 yields roughly 5-6 continent-scale features.
	_elevation_noise.frequency = 0.011
	_elevation_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_elevation_noise.fractal_octaves = 5
	_elevation_noise.fractal_lacunarity = 2.0
	_elevation_noise.fractal_gain = 0.5

	# Moisture: its own decorrelated noise layer, gentler than elevation.
	_moisture_noise = FastNoiseLite.new()
	_moisture_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_moisture_noise.seed = seed_value + 1013
	_moisture_noise.frequency = 0.014
	_moisture_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_moisture_noise.fractal_octaves = 3

	# Temperature perturbation: low-frequency noise that nudges the latitude
	# gradient so isotherms are wavy, not perfectly horizontal lines.
	_temperature_noise = FastNoiseLite.new()
	_temperature_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_temperature_noise.seed = seed_value + 2027
	_temperature_noise.frequency = 0.009
	_temperature_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_temperature_noise.fractal_octaves = 2


# Sample a noise layer at cell (px, py) on the cylinder. The x axis is wrapped
# onto a circle of circumference `width` so sampling is seamless east-west.
# The radius is chosen as width / TAU so that one step in px corresponds to
# one unit of arc length, keeping the horizontal feature scale consistent
# with the vertical (py) scale.
func _sample_cylinder(noise: FastNoiseLite, px: int, py: int) -> float:
	var theta := TAU * float(px) / float(width)
	var radius := float(width) / TAU
	var nx := cos(theta) * radius
	var nz := sin(theta) * radius
	# get_noise_3d returns roughly -1..1; caller normalizes to 0..1.
	return noise.get_noise_3d(nx, float(py), nz)


func elevation_at(px: int, py: int) -> float:
	# Normalize -1..1 to 0..1.
	return (_sample_cylinder(_elevation_noise, px, py) + 1.0) * 0.5


func moisture_at(px: int, py: int) -> float:
	return (_sample_cylinder(_moisture_noise, px, py) + 1.0) * 0.5


func temperature_at(px: int, py: int, elevation: float) -> float:
	# Latitude gradient: 1.0 at the equator (map middle), 0.0 at the north
	# and south edges. height - 1 guard avoids division by zero for height 1.
	var span := float(max(height - 1, 1))
	var lat := float(py) / span                # 0 at north edge, 1 at south edge
	var equator_factor := 1.0 - absf(lat - 0.5) * 2.0   # 1 at equator, 0 at poles

	# Noise perturbation so isotherms are not perfectly clean.
	var perturb := _sample_cylinder(_temperature_noise, px, py)  # -1..1
	var temp := equator_factor + perturb * TEMP_NOISE_WEIGHT

	# Higher elevation (above sea level) is colder.
	if elevation > SEA_LEVEL:
		var land_height := (elevation - SEA_LEVEL) / (1.0 - SEA_LEVEL)
		temp -= land_height * ELEVATION_COOLING

	return clampf(temp, 0.0, 1.0)


# Biome lookup table. Combines elevation, temperature and moisture into one
# of the seven starter biomes. Documented in ARCHITECTURE.md.
func biome_at(elevation: float, temperature: float, moisture: float) -> String:
	if elevation < SEA_LEVEL:
		return BIOME_OCEAN
	if elevation < BEACH_LEVEL:
		return BIOME_BEACH
	if elevation >= MOUNTAIN_LEVEL:
		return BIOME_MOUNTAIN

	# Land below the mountain line: pick by temperature and moisture.
	if temperature < 0.25:
		# Cold land is tundra regardless of moisture.
		return BIOME_TUNDRA
	if temperature > 0.6 and moisture < 0.35:
		# Hot and dry is desert.
		return BIOME_DESERT
	if moisture > 0.55:
		# Wet and temperate/warm grows forest.
		return BIOME_FOREST
	# Everything else is open plains.
	return BIOME_PLAINS


func _biome_color(biome: String, elevation: float) -> Color:
	var base: Color = BIOME_COLORS[biome]
	if biome == BIOME_OCEAN:
		# Deeper water (lower elevation) renders darker.
		var depth := elevation / SEA_LEVEL          # 0 at deepest, ~1 near shore
		return base.darkened((1.0 - depth) * 0.5)
	if biome == BIOME_MOUNTAIN:
		# Highest peaks get a snow cap.
		var peak := (elevation - MOUNTAIN_LEVEL) / (1.0 - MOUNTAIN_LEVEL)
		if peak > 0.6:
			return Color8(236, 236, 240)
		return base.lightened(peak * 0.25)
	return base


# Generate the full map. Returns a Dictionary with the rendered Image plus the
# summary statistics used for the JSON output.
func generate() -> Dictionary:
	var image := Image.create(width, height, false, Image.FORMAT_RGB8)

	var land_tiles := 0
	var total_tiles := width * height
	# Per-biome counts, initialized in canonical order for stable JSON.
	var biome_counts := {}
	for b in BIOME_ORDER:
		biome_counts[b] = 0

	for py in range(height):
		for px in range(width):
			var elevation := elevation_at(px, py)
			var moisture := moisture_at(px, py)
			var temperature := temperature_at(px, py, elevation)
			var biome := biome_at(elevation, temperature, moisture)

			biome_counts[biome] += 1
			if biome != BIOME_OCEAN:
				land_tiles += 1

			image.set_pixel(px, py, _biome_color(biome, elevation))

	var land_fraction := float(land_tiles) / float(total_tiles)

	# Biome distribution as a fraction of land tiles (ocean excluded from the
	# land breakdown but reported separately as land_fraction above).
	var land_distribution := {}
	for b in BIOME_ORDER:
		if b == BIOME_OCEAN:
			continue
		var frac := 0.0
		if land_tiles > 0:
			frac = float(biome_counts[b]) / float(land_tiles)
		land_distribution[b] = _round6(frac)

	var summary := {
		"seed": seed_value,
		"width": width,
		"height": height,
		"total_tiles": total_tiles,
		"land_tiles": land_tiles,
		"ocean_tiles": biome_counts[BIOME_OCEAN],
		"land_fraction": _round6(land_fraction),
		"ocean_fraction": _round6(float(biome_counts[BIOME_OCEAN]) / float(total_tiles)),
		"biome_distribution_of_land": land_distribution,
	}

	return {
		"image": image,
		"summary": summary,
	}


# Round to 6 decimal places so JSON float formatting is stable and byte
# identical across runs.
func _round6(v: float) -> float:
	return roundf(v * 1000000.0) / 1000000.0
