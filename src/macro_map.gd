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
const MOUNTAIN_LEVEL := 0.76

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

# --- Seed-driven world archetypes -------------------------------------------
#
# The overall character of a world (how much land, how many continents, and how
# their sizes spread) is itself derived deterministically from the seed, so
# different seeds feel meaningfully different rather than all landing on one
# universal shape. A latent selector in 0..1 is hashed from the seed and buckets
# the world into one of three archetypes:
#
#   OCEANIC          a water world: little land, only scattered small islands.
#   CONTINENTAL      the typical case: a few large continents plus smaller
#                    islands, roughly 25 to 40 percent land.
#   CONTINENT_HEAVY  a dry world: a large land fraction, fewer but bigger masses.
#
# Most seeds land in CONTINENTAL; the OCEANIC and CONTINENT_HEAVY tails are a
# deliberate minority. Every archetype parameter (count, radii, lift, size
# spread) comes from position hashes of the seed, never from per-cell RNG or
# noise sampling, so the whole archetype is a pure function of the seed and is
# byte-reproducible. See _build_archetype().
enum Archetype { OCEANIC, CONTINENTAL, CONTINENT_HEAVY }

# Selector thresholds on the 0..1 latent value. Below OCEANIC_MAX is a water
# world; at or above HEAVY_MIN is a continent-heavy world; the wide middle band
# is the typical continental case. The middle band is the majority (0.16..0.84).
const ARCHETYPE_OCEANIC_MAX := 0.16
const ARCHETYPE_HEAVY_MIN := 0.84

# Falloff shape applied across the ramp band (u is 1 at the core edge, 0 at the
# extent edge). LINEAR is a straight ramp; SMOOTH is a smoothstep (steep mid
# slope); QUADRATIC pulls land tighter to the core; EASE_OUT (1 - (1 - u)^2) is
# concave: its slope is zero at the core edge (so the mask meets the flat core
# with no ridge) and it spends a wide band of u near mask 1, which keeps the
# sea-level crossing on a GENTLE part of the ramp. With the additive continent
# bias, a gentle ramp at the coast means a gentle coastal elevation slope, which
# both widens beaches and keeps the east-west wrap edge delta well under the
# seam threshold. This is the "falloff shape" tunable.
enum FalloffShape { LINEAR, SMOOTH, QUADRATIC, EASE_OUT }
const CONTINENT_FALLOFF_SHAPE := FalloffShape.EASE_OUT

# Domain warp applied to the mask sample position so continent outlines are
# irregular (peninsulas, bays, capes) instead of stamped circles. The warp
# displaces the point at which the mask is evaluated by up to WARP_AMP cells
# using two decorrelated low-frequency noise channels, so the effective mask
# boundary follows a wandering line. Combined with wide falloff bands, this
# hands the fine coastline decision to the raw heightmap noise rather than the
# clean falloff ramp, which is what kills the stamped-circle silhouette and the
# uniform shallow-water halo ring.
const CONTINENT_WARP_AMP := 13.0
const CONTINENT_WARP_FREQUENCY := 0.014

# Per-continent anisotropy. Each continent is stretched into an ellipse with a
# seed-derived aspect ratio and orientation, so its silhouette reads as an
# elongated landmass rather than a stamped circle. The stretch is SHRINK ONLY:
# the long axis stays at the circular radius and only the short axis is pulled in
# by `aspect`, so the ellipse is always inscribed in the continent's circular
# extent. That keeps the (circular) isolation and pole checks exactly sound.
# Combined with the domain warp and the noise-driven coastline, this is what
# breaks the round "water world" look. Aspect is drawn per continent in
# [MIN, MAX]; the archetype sea-level lifts are set a little higher than a pure
# circle would need so the thinner landmasses still hit the target land fractions.
const CONTINENT_ASPECT_MIN := 1.0
const CONTINENT_ASPECT_MAX := 1.35

# Minimum guaranteed ocean gap (in cells) between the influence extents (core +
# falloff) of any two continents. Because land can only exist inside a
# continent's influence extent (the mask is 0.0 outside it), forcing the extents
# to stay this far apart guarantees a band of deep ocean between every pair of
# continents. This must exceed twice the warp amplitude so that even when the
# domain warp pushes two neighboring coasts toward each other by up to WARP_AMP
# each, a band of ocean always survives and the landmasses can never touch. This
# is the load-bearing isolation guarantee. See min_center_extent_gap().
const CONTINENT_MIN_OCEAN_GAP := 28

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
# layers are decorrelated but still fully determined by the seed. The two warp
# channels perturb the continent-mask sample position (domain warping) so coasts
# are ragged rather than circular.
var _elevation_noise: FastNoiseLite
var _temperature_noise: FastNoiseLite
var _moisture_noise: FastNoiseLite
var _warp_noise_x: FastNoiseLite
var _warp_noise_y: FastNoiseLite

# The seed-derived world archetype parameters, computed once in _init. See
# _build_archetype() for the fields.
var _archetype: Dictionary = {}

# Deterministic list of continent centers, computed once from the seed in
# _init. Each entry is {"x": int, "y": int, "core": int, "falloff": int,
# "extent": int, "aspect": float, "orient": float} where `core` is the
# full-mask radius, `falloff` is the ramp band width, `extent` is core + falloff
# (the anisotropic radius beyond which the mask is exactly 0), `aspect` is the
# elongation and `orient` is the long-axis angle in radians. See
# _build_continent_centers().
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
	# noise features across the map width is approximately width * frequency, and
	# the noise wavelength is roughly 1 / frequency cells. At 512 wide, frequency
	# 0.016 yields a wavelength near 60 cells, deliberately short relative to the
	# continent-mask falloff band so several noise oscillations occur across the
	# coastal transition. That is what lets the raw heightmap (not the mask ramp)
	# own the coastline shape, giving ragged, noise-driven coasts instead of a
	# concentric mask ring.
	_elevation_noise.frequency = 0.016
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

	# Domain-warp channels for the continent mask. Two decorrelated low-frequency
	# fields displace the mask sample position so continent outlines wander
	# (peninsulas and bays) instead of tracing a circle. They are seeded off the
	# world seed with their own fixed offsets so they stay pure functions of
	# (seed, position).
	_warp_noise_x = FastNoiseLite.new()
	_warp_noise_x.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_warp_noise_x.seed = seed_value + 3037
	_warp_noise_x.frequency = CONTINENT_WARP_FREQUENCY
	_warp_noise_x.fractal_type = FastNoiseLite.FRACTAL_FBM
	_warp_noise_x.fractal_octaves = 2

	_warp_noise_y = FastNoiseLite.new()
	_warp_noise_y.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_warp_noise_y.seed = seed_value + 4051
	_warp_noise_y.frequency = CONTINENT_WARP_FREQUENCY
	_warp_noise_y.fractal_type = FastNoiseLite.FRACTAL_FBM
	_warp_noise_y.fractal_octaves = 2

	# Derive the world archetype, then place the continent centers once, both
	# deterministically from the seed.
	_archetype = _build_archetype()
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


# Derive the world archetype parameters for this seed. A latent selector in
# 0..1 (hashed from the seed) buckets the world into OCEANIC, CONTINENTAL, or
# CONTINENT_HEAVY, and each bucket fixes the count, radius, lift, and size-spread
# knobs plus the expected land-fraction band and minimum significant landmass
# count that the landmass test asserts against. Every value is a pure function
# of the seed (position hashes, no per-cell RNG), so it is byte-reproducible.
#
# The count and radius fields are read by _build_continent_centers(); the
# `land_band_*` and `min_significant` fields are the per-seed expectations the
# test derives from this same function rather than one fixed universal number.
func _build_archetype() -> Dictionary:
	var t := float(_hash2(seed_value, 4200) % 1000000) / 1000000.0
	var kind: int
	if t < ARCHETYPE_OCEANIC_MAX:
		kind = Archetype.OCEANIC
	elif t >= ARCHETYPE_HEAVY_MIN:
		kind = Archetype.CONTINENT_HEAVY
	else:
		kind = Archetype.CONTINENTAL

	match kind:
		Archetype.OCEANIC:
			# A water world: at most one modest primary, a handful of small
			# islands, no sea-level lift so only the noise peaks surface. Little land.
			return {
				"kind": kind,
				"name": "oceanic",
				"primary_count": int(_hash2(seed_value, 51) % 2),          # 0..1
				"secondary_count": 3 + int(_hash2(seed_value, 52) % 4),    # 3..6
				"primary_core_min": 26, "primary_core_max": 40,
				"secondary_core_min": 10, "secondary_core_max": 22,
				"primary_falloff": 34, "secondary_falloff": 26,
				"lift": 0.0,
				"land_band_min": 0.005, "land_band_max": 0.20,
				"min_significant": 1,
			}
		Archetype.CONTINENT_HEAVY:
			# A dry world: two or three big continents, a few islands, a strong
			# sea-level lift so most of each plateau surfaces. Large land fraction.
			return {
				"kind": kind,
				"name": "continent_heavy",
				"primary_count": 2 + int(_hash2(seed_value, 61) % 2),      # 2..3
				"secondary_count": 2 + int(_hash2(seed_value, 62) % 3),    # 2..4
				"primary_core_min": 72, "primary_core_max": 80,
				"secondary_core_min": 18, "secondary_core_max": 30,
				"primary_falloff": 32, "secondary_falloff": 30,
				"lift": 0.20,
				"land_band_min": 0.22, "land_band_max": 0.72,
				"min_significant": 2,
			}
		_:
			# The typical continental world: a couple of large primaries plus
			# scattered smaller islands, roughly a quarter to two fifths land.
			return {
				"kind": Archetype.CONTINENTAL,
				"name": "continental",
				"primary_count": 2 + int(_hash2(seed_value, 71) % 2),      # 2..3
				"secondary_count": 3 + int(_hash2(seed_value, 72) % 4),    # 3..6
				"primary_core_min": 64, "primary_core_max": 78,
				"secondary_core_min": 13, "secondary_core_max": 27,
				"primary_falloff": 36, "secondary_falloff": 32,
				"lift": 0.13,
				"land_band_min": 0.12, "land_band_max": 0.46,
				"min_significant": 2,
			}


# Draw a deterministic integer in the inclusive range [lo, hi] from the seed and
# a fixed tag. Pure function of (seed, tag): no RNG stream, no order dependence.
func _draw_range(tag: int, lo: int, hi: int) -> int:
	if hi <= lo:
		return lo
	return lo + int(_hash2(seed_value, tag) % (hi - lo + 1))


# Draw a deterministic float in [lo, hi) from the seed and a fixed tag. Uses a
# 16-bit slice of the hash so the value is stable and reproducible.
func _draw_rangef(tag: int, lo: float, hi: float) -> float:
	var u := float(_hash2(seed_value, tag) % 65536) / 65536.0
	return lo + u * (hi - lo)


# Signed shortest separation a - b along the wrapping x axis, in (-width/2,
# width/2]. This is the single primitive that normalizes the east-west wrap for
# every continent distance (mask sampling, isolation, pole margin). It uses
# fposmod, so it is correct for ANY x, including logical positions many map
# widths outside 0..width-1 (for example a caller querying a column after
# several laps around the cylinder), not only in-range ones.
func _wrapped_dx(a: float, b: float) -> float:
	var half := float(width) * 0.5
	return fposmod(a - b + half, float(width)) - half


# Anisotropic distance from a continent center to a point, given the signed
# (dx, dy) offset (dx already wrapped). The space is rotated into the
# continent's local frame; the component perpendicular to `orient` is scaled up
# by `aspect`, so level sets are ellipses elongated along `orient`.
#
# The scaling is SHRINK ONLY: the long semi-axis (along orient) equals the
# circular radius the threshold names, and only the short semi-axis shrinks (by
# `aspect`). The ellipse is therefore strictly inscribed in the circle of that
# radius. That is the load-bearing property for isolation: because every
# continent stays inside its circular `extent`, the plain circular isolation and
# pole checks remain exactly sound (an inscribed ellipse can only be smaller,
# never poke out of the circle the gaps were reserved around), with none of the
# direction ambiguity an oriented-ellipse-to-ellipse gap test would have.
func _aniso_distance(dx: float, dy: float, aspect: float, orient: float) -> float:
	var co := cos(orient)
	var si := sin(orient)
	var rx := dx * co + dy * si          # along the long axis
	var ry := (-dx * si + dy * co) * aspect   # perpendicular, shrunk by aspect
	return sqrt(rx * rx + ry * ry)


# Circular surface distance between two points, x wrapped, y linear. Used for
# the (sound, circular) continent isolation and pole checks.
func _surface_distance(ax: float, ay: float, bx: float, by: float) -> float:
	var dx := _wrapped_dx(ax, bx)
	var dy := ay - by
	return sqrt(dx * dx + dy * dy)


# Build the deterministic list of continent centers for this seed from the
# archetype. Each center's core radius and falloff width come from the archetype
# ranges; candidate positions come from the seed hash. Larger continents are
# placed first so they claim room before the small islands. A candidate is
# accepted only if its influence extent stays CONTINENT_MIN_OCEAN_GAP away from
# every already accepted continent's extent, and its whole warped extent stays
# clear of the hard north and south poles (the y axis does not wrap). Because
# land can only exist inside a continent's extent, non-overlapping extents
# guarantee the continents are separated by ocean and form distinct landmasses.
func _build_continent_centers() -> Array:
	# Assemble the desired continents (core radius, falloff, elongation) from the
	# archetype, then sort largest-extent first so big landmasses win the
	# placement race.
	var specs: Array = []
	for i in range(int(_archetype["primary_count"])):
		var pcore := _draw_range(1000 + i, int(_archetype["primary_core_min"]), int(_archetype["primary_core_max"]))
		specs.append({
			"core": pcore, "falloff": int(_archetype["primary_falloff"]),
			"aspect": _draw_rangef(1100 + i, CONTINENT_ASPECT_MIN, CONTINENT_ASPECT_MAX),
			"orient": _draw_rangef(1200 + i, 0.0, PI),
		})
	for i in range(int(_archetype["secondary_count"])):
		var score := _draw_range(2000 + i, int(_archetype["secondary_core_min"]), int(_archetype["secondary_core_max"]))
		specs.append({
			"core": score, "falloff": int(_archetype["secondary_falloff"]),
			"aspect": _draw_rangef(2100 + i, CONTINENT_ASPECT_MIN, CONTINENT_ASPECT_MAX),
			"orient": _draw_rangef(2200 + i, 0.0, PI),
		})
	specs.sort_custom(func(a, b): return (a["core"] + a["falloff"]) > (b["core"] + b["falloff"]))

	# The warp can push a coastline outward by up to WARP_AMP cells, so keep the
	# whole extent this much further from the poles. (The extra separation for
	# the warp between two continents is already folded into MIN_OCEAN_GAP.)
	var warp_margin := CONTINENT_WARP_AMP

	var centers: Array = []
	for si in range(specs.size()):
		var core: int = specs[si]["core"]
		var falloff: int = specs[si]["falloff"]
		var aspect: float = specs[si]["aspect"]
		var orient: float = specs[si]["orient"]
		var extent := core + falloff

		# Valid north-south band once the extent is known, so no continent's
		# warped extent ever crosses the hard poles (Codex finding: keep centers
		# a full extent from the edges rather than a fixed margin). Each
		# continent is inscribed in its circular extent, so the extent radius
		# bounds it in every direction, including toward the poles.
		var cy_lo := int(ceil(float(extent) + warp_margin))
		var cy_hi := height - 1 - cy_lo
		if cy_hi < cy_lo:
			# Too tall to fit between the poles at this size; skip it. This only
			# happens for the largest archetype radii and simply yields one fewer
			# continent, which is deterministic for the seed.
			continue

		var attempt := 0
		var placed := false
		while attempt < CONTINENT_MAX_PLACEMENT_ATTEMPTS and not placed:
			# The candidate depends only on (seed, spec index, attempt), so the
			# whole placement is a pure function of the seed.
			var h := _hash2(seed_value + si * 6271, attempt * 7919 + 17)
			var cx := int(_hash2(h, 1) % width)
			var cy := cy_lo + int(_hash2(h, 2) % (cy_hi - cy_lo + 1))

			var ok := true
			for c in centers:
				# Circular isolation on the extents. Because each continent is
				# inscribed in its circular extent, keeping the extent circles
				# MIN_OCEAN_GAP apart guarantees the actual (elliptical) landmasses
				# are separated by at least that much ocean.
				var d := _surface_distance(float(cx), float(cy), float(c["x"]), float(c["y"]))
				if d < float(extent + int(c["extent"]) + CONTINENT_MIN_OCEAN_GAP):
					ok = false
					break

			if ok:
				centers.append({
					"x": cx, "y": cy, "core": core, "falloff": falloff,
					"extent": extent, "aspect": aspect, "orient": orient,
				})
				placed = true

			attempt += 1

	return centers


# Smallest surviving ocean band, in cells, between any two placed continents:
# the center separation minus both circular extents. Because each continent is
# inscribed in its extent circle, this is a lower bound on the true ocean gap
# between the landmasses. Returns INF when fewer than two continents are placed.
# The landmass test asserts this stays at or above twice the warp amplitude,
# which is what proves the domain warp can never close a gap and make two
# distinct landmasses touch.
func min_center_extent_gap() -> float:
	var worst := INF
	for i in range(_continent_centers.size()):
		for j in range(i + 1, _continent_centers.size()):
			var a: Dictionary = _continent_centers[i]
			var b: Dictionary = _continent_centers[j]
			var d := _surface_distance(float(a["x"]), float(a["y"]), float(b["x"]), float(b["y"]))
			worst = minf(worst, d - float(a["extent"]) - float(b["extent"]))
	return worst


# The seed-derived world archetype, exposed so the landmass test can compute the
# per-seed expected land band and minimum significant landmass count from the
# same source the generator uses.
func archetype() -> Dictionary:
	return _archetype


# Continent-mask value at cell (px, py), in 0..1. It is the maximum falloff
# contribution over all continents: 1.0 inside a core, ramping to 0.0 across
# the falloff band, and exactly 0.0 outside every continent's extent (which is
# what forces guaranteed ocean between continents).
func continent_mask_at(px: int, py: int) -> float:
	# Domain warp: displace the sample position by up to WARP_AMP cells using the
	# two low-frequency warp channels, so the mask boundary wanders instead of
	# tracing a circle. The warped position is what we measure distances from.
	var wx := float(px) + CONTINENT_WARP_AMP * _sample_cylinder(_warp_noise_x, px, py)
	var wy := float(py) + CONTINENT_WARP_AMP * _sample_cylinder(_warp_noise_y, px, py)

	var mask := 0.0
	for c in _continent_centers:
		var core := float(c["core"])
		var falloff := float(c["falloff"])
		var extent := float(c["extent"])
		# Anisotropic (elliptical) distance so the continent is elongated along
		# its orientation instead of a circle.
		var dx := _wrapped_dx(wx, float(c["x"]))
		var dy := wy - float(c["y"])
		var d := _aniso_distance(dx, dy, float(c["aspect"]), float(c["orient"]))
		if d >= extent:
			continue
		var contribution: float
		if d <= core:
			contribution = 1.0
		else:
			# u goes 1.0 at the core edge to 0.0 at the extent edge.
			var u := 1.0 - (d - core) / falloff
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
		FalloffShape.EASE_OUT:
			# Concave: zero slope at the core edge, gentle near mask 1, so the
			# sea-level crossing sits on a shallow part of the ramp.
			var inv := 1.0 - u
			return 1.0 - inv * inv
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


# Bias applied to the raw heightmap where the continent mask is exactly 0 (every
# cell outside all continent extents, i.e. the open ocean between continents).
# It must be deep enough that even the highest possible raw noise stays below sea
# level, so the gaps between continents are guaranteed ocean. The raw heightmap
# is normalized to 0..1, so any bias below SEA_LEVEL - 1.0 = -0.5 guarantees it;
# -0.55 leaves margin while keeping the coastal bias ramp gentle (a deeper bias
# would steepen the shoreline). This is the load-bearing "guaranteed ocean gap"
# mechanism.
const CONTINENT_OCEAN_BIAS := -0.55


# Combine a raw noise elevation with a continent mask value (both 0..1) into the
# authoritative elevation.
#
# This is an ADDITIVE continent-bias model, not a multiply. The mask's only job
# is to pick the neighborhoods where land is allowed and to guarantee the ocean
# gaps between them; the raw heightmap noise owns the actual coastline shape.
#
# The bias slides with the mask from CONTINENT_OCEAN_BIAS (deep ocean, mask 0)
# up to the archetype `lift` (mask 1):
#
#   mask == 0  -> bias = CONTINENT_OCEAN_BIAS: base + bias is always below sea
#                 level, so the open ocean between continents is guaranteed.
#   mask == 1  -> bias = lift: land is wherever the raw noise clears the
#                 lift-shifted sea level. Because the noise (not the mask) decides
#                 this, a plateau is NOT a solid disk: it has ragged coasts, bays,
#                 and interior seas, exactly as the heightmap dictates.
#   between    -> the bias slides down across the falloff band, so the coastline
#                 is the raw noise crossing a slowly moving threshold. With the
#                 noise wavelength short relative to the band, that crossing is
#                 ragged and noise-shaped, not a concentric mask ring.
#
# Because base + bias is a single smooth field (no shoreline discontinuity), the
# sub-sea floor is already textured by the raw noise, so there is no concentric
# bowl and no uniform shallow-water halo to break up separately.
func _apply_continent_mask(base: float, mask: float) -> float:
	var lift := float(_archetype["lift"])
	var bias := lerpf(CONTINENT_OCEAN_BIAS, lift, mask)
	return clampf(base + bias, 0.0, 1.0)


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
		"archetype": _archetype["name"],
		"archetype_land_band_min": _round6(float(_archetype["land_band_min"])),
		"archetype_land_band_max": _round6(float(_archetype["land_band_max"])),
		"archetype_min_significant_landmasses": int(_archetype["min_significant"]),
		"min_center_extent_gap": _round6(_finite_gap(min_center_extent_gap())),
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


# Map the min-center-extent-gap to a JSON-safe number. When fewer than two
# continents are placed the gap is INF (no pair to separate), which is not valid
# JSON, so it is reported as -1.0 to mean "not applicable (single continent)".
func _finite_gap(v: float) -> float:
	if is_inf(v) or is_nan(v):
		return -1.0
	return v
