extends RefCounted
class_name MacroMapGenerator

# MacroMapGenerator produces the authoritative low-resolution planet map.
#
# Determinism contract (see CLAUDE.md and ARCHITECTURE.md):
#   The world is a pure function of (seed, position). Every per-cell value
#   is computed by sampling seeded FastNoiseLite instances (and a fixed,
#   seed-derived list of continent centers) at a position derived only from
#   (cell x, cell y). There is NO sequential or stateful RNG in any placement
#   decision, so generation order and visit order can never change the result.
#   Running twice with the same seed produces byte-identical PNG and JSON.
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

# --- Continent-mask layer (see issue #1) ------------------------------------
#
# Raw layered noise alone produces one connected blobby landmass with fringe
# islands. To force distinct, isolated continents we place a small set of
# continent centers (derived deterministically from the world seed, honoring
# the pure function of (seed, position) rule) and apply a distance falloff
# around each. The falloff is combined with the noise heightmap so that land
# only survives near a center and guaranteed deep ocean separates the centers.
#
# The center positions are a short deterministic list computed once from the
# seed (a position hash, NOT a per-cell RNG sample). Every per-cell mask value
# is then a pure function of (seed, position): the distance from the cell to
# the fixed centers. Nothing depends on iteration order.
#
# Distances are measured on the cylinder surface: the x axis wraps east-west,
# so the x separation is the shorter of the two ways around. Because the
# cylinder radius is width / TAU, one column of arc equals one unit of
# distance, so the wrapped column delta is directly the x distance. The y axis
# does not wrap. This matches the noise sampling geometry, so the mask has no
# seam at the wrap.

# Number of continent centers to place. The actual count for a given seed is a
# deterministic value in this inclusive range (the "continent count / range"
# tunable from the issue).
const CONTINENT_COUNT_MIN := 4
const CONTINENT_COUNT_MAX := 6

# Core radius range (in cells) of a continent. Inside the core radius the mask
# is fully 1.0 (land there is governed by the noise heightmap plus the dome).
# The per-continent radius is a deterministic value in this range.
const CONTINENT_CORE_RADIUS_MIN := 16
const CONTINENT_CORE_RADIUS_MAX := 30

# Width (in cells) of the falloff band outside the core, over which the mask
# ramps from 1.0 down to 0.0. Beyond core + falloff the mask is exactly 0.0,
# which forces guaranteed ocean.
const CONTINENT_FALLOFF_WIDTH := 30

# Falloff shape applied across the ramp band. LINEAR is a straight ramp,
# SMOOTH is a smoothstep (gentle coasts, sharper mid-slope), QUADRATIC pulls
# land tighter to the core. This is the "falloff shape" tunable.
enum FalloffShape { LINEAR, SMOOTH, QUADRATIC }
const CONTINENT_FALLOFF_SHAPE := FalloffShape.SMOOTH

# Minimum guaranteed ocean gap (in cells) between the influence extents (core +
# falloff) of any two continents. Because land can only exist inside a
# continent's influence extent (the mask is 0.0 outside it), forcing the
# extents to stay this far apart guarantees a band of deep ocean between every
# pair of continents, so their landmasses are always disconnected. This is the
# "isolation / min-ocean-gap" tunable.
const CONTINENT_MIN_OCEAN_GAP := 22

# How strongly a continent core is domed up toward land. 0.0 leaves the raw
# noise untouched inside the core (so a core can be mostly ocean by chance);
# higher values bias the core toward land so each continent reliably yields a
# substantial landmass while still keeping noisy coastlines.
const CONTINENT_DOME_STRENGTH := 0.30

# Keep continent centers this far from the north and south edges so continents
# are not clipped by the hard poles.
const CONTINENT_EDGE_MARGIN := 24

# Safety cap on placement attempts. Placement is a deterministic rejection loop
# (candidate positions come from the seed hash, not an RNG stream), so this
# only bounds work; it never introduces order dependence.
const CONTINENT_MAX_PLACEMENT_ATTEMPTS := 4096

# A land connected component must be at least this many cells to count as a
# "significant" landmass in the JSON summary and the landmass test.
const LANDMASS_MIN_SIZE := 200

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

# Deterministic list of continent centers, computed once from the seed in
# _init. Each entry is {"x": int, "y": int, "core": int, "extent": int} where
# `core` is the full-mask radius and `extent` is core + falloff (the radius
# beyond which the mask is exactly 0). See _build_continent_centers().
var _continent_centers: Array = []

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

	# Place the continent centers once, deterministically from the seed.
	_continent_centers = _build_continent_centers()


# --- Deterministic integer hashing -----------------------------------------
#
# A 64-bit avalanche mix (splitmix64 style). Used to turn (seed, index)
# tuples into continent positions. This is a pure function: the same inputs
# always give the same output, with no RNG stream and no order dependence.
# GDScript ints are 64-bit and both multiplication overflow and the shifts are
# deterministic, so the mix is reproducible on the x86_64 runners used for
# generation and CI. (The right shift is arithmetic here, which is fine: we
# only need a well spread, fully deterministic hash, not a cryptographic one.)
const _MIX_C1 := -4658895280553007687   # 0xBF58476D1CE4E5B9 as a signed 64-bit int
const _MIX_C2 := -7723592293110705685   # 0x94D049BB133111EB as a signed 64-bit int
const _MIX_C3 := -7046029254386353131   # 0x9E3779B97F4A7C15 as a signed 64-bit int (golden ratio)

func _mix64(x: int) -> int:
	x = (x ^ (x >> 30)) * _MIX_C1
	x = (x ^ (x >> 27)) * _MIX_C2
	x = x ^ (x >> 31)
	return x


# Combine two integers into a non-negative 63-bit hash.
func _hash2(a: int, b: int) -> int:
	var h: int = _mix64(a * _MIX_C3 + _mix64(b))
	return h & 0x7FFFFFFFFFFFFFFF


# Build the deterministic list of continent centers for this seed. Candidate
# positions and radii come from the seed hash; a candidate is accepted only if
# its influence extent stays CONTINENT_MIN_OCEAN_GAP away from every already
# accepted continent's extent. Because land can only exist inside a
# continent's extent, non-overlapping extents guarantee the continents are
# separated by ocean and therefore form distinct landmasses.
func _build_continent_centers() -> Array:
	var centers: Array = []

	var span := CONTINENT_COUNT_MAX - CONTINENT_COUNT_MIN + 1
	var target := CONTINENT_COUNT_MIN + int(_hash2(seed_value, 9001) % span)

	var y_span := maxi(height - 2 * CONTINENT_EDGE_MARGIN, 1)
	var radius_span := CONTINENT_CORE_RADIUS_MAX - CONTINENT_CORE_RADIUS_MIN + 1

	var attempt := 0
	while centers.size() < target and attempt < CONTINENT_MAX_PLACEMENT_ATTEMPTS:
		# The candidate depends only on (seed, slot index, attempt), so the
		# whole placement is a pure function of the seed.
		var slot := centers.size()
		var h := _hash2(seed_value + slot * 6271, attempt * 7919 + 17)
		var cx := int(_hash2(h, 1) % width)
		var cy := CONTINENT_EDGE_MARGIN + int(_hash2(h, 2) % y_span)
		var core := CONTINENT_CORE_RADIUS_MIN + int(_hash2(h, 3) % radius_span)
		var extent := core + CONTINENT_FALLOFF_WIDTH

		var ok := true
		for c in centers:
			var cx_other: int = c["x"]
			var cy_other: int = c["y"]
			var extent_other: int = c["extent"]
			var d := _surface_distance(cx, cy, cx_other, cy_other)
			if d < float(extent + extent_other + CONTINENT_MIN_OCEAN_GAP):
				ok = false
				break

		if ok:
			centers.append({"x": cx, "y": cy, "core": core, "extent": extent})

		attempt += 1

	return centers


# Distance between two cells on the cylinder surface. The x axis wraps, so the
# x separation is the shorter way around; the y axis does not wrap. With the
# cylinder radius = width / TAU, one wrapped column of separation equals one
# unit of distance, matching the noise sampling geometry.
func _surface_distance(x0: int, y0: int, x1: int, y1: int) -> float:
	var dx := absi(x0 - x1)
	dx = mini(dx, width - dx)
	var dy := y0 - y1
	return sqrt(float(dx * dx + dy * dy))


# Continent-mask value at cell (px, py), in 0..1. It is the maximum falloff
# contribution over all continents: 1.0 inside a core, ramping to 0.0 across
# the falloff band, and exactly 0.0 outside every continent's extent (which is
# what forces guaranteed ocean between continents).
func continent_mask_at(px: int, py: int) -> float:
	var mask := 0.0
	for c in _continent_centers:
		var cx: int = c["x"]
		var cy: int = c["y"]
		var core: int = c["core"]
		var extent: int = c["extent"]
		var d := _surface_distance(px, py, cx, cy)
		if d >= float(extent):
			continue
		var contribution: float
		if d <= float(core):
			contribution = 1.0
		else:
			# u goes 1.0 at the core edge to 0.0 at the extent edge.
			var u := 1.0 - (d - float(core)) / float(CONTINENT_FALLOFF_WIDTH)
			contribution = _falloff_shape(u)
		if contribution > mask:
			mask = contribution
	return mask


# Apply the selected falloff shape to a ramp parameter u in 0..1 (1 near the
# core, 0 at the extent edge).
func _falloff_shape(u: float) -> float:
	match CONTINENT_FALLOFF_SHAPE:
		FalloffShape.LINEAR:
			return u
		FalloffShape.QUADRATIC:
			return u * u
		_:
			# SMOOTH: smoothstep.
			return u * u * (3.0 - 2.0 * u)


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


# Raw layered-noise elevation at (px, py), normalized to 0..1, before the
# continent mask is applied. This is the underlying heightmap.
func base_elevation_at(px: int, py: int) -> float:
	# Normalize -1..1 to 0..1.
	return (_sample_cylinder(_elevation_noise, px, py) + 1.0) * 0.5


# Authoritative elevation at (px, py): the raw noise heightmap combined with
# the continent mask. Land only survives near a continent center; between
# continents the mask forces the elevation below sea level, guaranteeing deep
# ocean. Everything downstream (temperature, biome, rendering) uses this.
func elevation_at(px: int, py: int) -> float:
	var base := base_elevation_at(px, py)
	var mask := continent_mask_at(px, py)
	return _apply_continent_mask(base, mask)


# Combine a raw noise elevation with a continent mask value (both 0..1).
#
#   mask == 0  -> result is 0 (guaranteed deep ocean between continents)
#   mask == 1  -> the core, where land follows the raw noise, gently domed up
#                 toward land so each continent yields a substantial landmass
#   between    -> land is pulled down toward ocean as the mask falls off
#
# The dome lifts the noise toward 1.0 in proportion to the mask before the
# multiply, so cores reliably clear sea level while coastlines stay noisy.
func _apply_continent_mask(base: float, mask: float) -> float:
	var dome := CONTINENT_DOME_STRENGTH * mask
	var lifted := base * (1.0 - dome) + dome     # lerp(base, 1.0, dome)
	return clampf(lifted * mask, 0.0, 1.0)


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

	# Land mask for the connected-component analysis: 1 where the cell is land
	# (any non-ocean biome), 0 where it is ocean. Indexed py * width + px.
	var land_mask := PackedByteArray()
	land_mask.resize(total_tiles)

	for py in range(height):
		for px in range(width):
			var elevation := elevation_at(px, py)
			var moisture := moisture_at(px, py)
			var temperature := temperature_at(px, py, elevation)
			var biome := biome_at(elevation, temperature, moisture)

			biome_counts[biome] += 1
			if biome != BIOME_OCEAN:
				land_tiles += 1
				land_mask[py * width + px] = 1

			image.set_pixel(px, py, _biome_color(biome, elevation))

	var land_fraction := float(land_tiles) / float(total_tiles)

	var landmass := _analyze_landmasses(land_mask, land_tiles)

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
		"continent_center_count": _continent_centers.size(),
		"land_component_count": landmass["component_count"],
		"significant_landmass_count": landmass["significant_count"],
		"significant_landmass_min_size": LANDMASS_MIN_SIZE,
		"largest_landmass_tiles": landmass["largest_tiles"],
		"largest_landmass_fraction": _round6(landmass["largest_fraction"]),
		"landmass_sizes": landmass["significant_sizes"],
	}

	return {
		"image": image,
		"summary": summary,
	}


# Connected-component analysis of the land mask. Uses 4-connectivity and
# respects the east-west wrap: columns 0 and width-1 are neighbors, the north
# and south edges are not. Returns component counts, the largest landmass size
# and fraction of total land, and the descending list of sizes for components
# at or above LANDMASS_MIN_SIZE (bounded so the JSON stays small and stable).
func _analyze_landmasses(land_mask: PackedByteArray, land_tiles: int) -> Dictionary:
	var component_of := PackedInt32Array()
	component_of.resize(width * height)
	component_of.fill(-1)

	var sizes: Array = []
	var stack := PackedInt32Array()

	for start_py in range(height):
		for start_px in range(width):
			var start := start_py * width + start_px
			if land_mask[start] == 0 or component_of[start] != -1:
				continue

			# Flood fill this component with an explicit stack (iterative so we
			# do not blow the call stack on large continents).
			var component_id: int = sizes.size()
			var size := 0
			stack.clear()
			stack.push_back(start)
			component_of[start] = component_id

			while not stack.is_empty():
				var idx: int = stack[stack.size() - 1]
				stack.remove_at(stack.size() - 1)
				size += 1

				var px := idx % width
				var py := idx / width

				# 4-connected neighbors. East-west wraps, north-south does not.
				var neighbors := PackedInt32Array()
				neighbors.push_back(py * width + ((px - 1 + width) % width))
				neighbors.push_back(py * width + ((px + 1) % width))
				if py > 0:
					neighbors.push_back((py - 1) * width + px)
				if py < height - 1:
					neighbors.push_back((py + 1) * width + px)

				for n in neighbors:
					if land_mask[n] == 1 and component_of[n] == -1:
						component_of[n] = component_id
						stack.push_back(n)

			sizes.append(size)

	# Sort sizes descending. Equal sizes are interchangeable in the reported
	# list, so the output is stable regardless of the sort's tie handling.
	sizes.sort_custom(func(a, b): return a > b)

	var significant_sizes: Array = []
	for s in sizes:
		if s >= LANDMASS_MIN_SIZE:
			significant_sizes.append(s)

	var largest_tiles := 0
	if sizes.size() > 0:
		largest_tiles = int(sizes[0])
	var largest_fraction := 0.0
	if land_tiles > 0:
		largest_fraction = float(largest_tiles) / float(land_tiles)

	return {
		"component_count": sizes.size(),
		"significant_count": significant_sizes.size(),
		"significant_sizes": significant_sizes,
		"largest_tiles": largest_tiles,
		"largest_fraction": largest_fraction,
	}


# Round to 6 decimal places so JSON float formatting is stable and byte
# identical across runs.
func _round6(v: float) -> float:
	return roundf(v * 1000000.0) / 1000000.0
