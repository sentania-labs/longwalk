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
#   The y axis (north-south) is sampled linearly and does NOT wrap in the
#   noise. The north and south edges are sphere-consistent polar crossings:
#   crossing the top edge at longitude x re-enters from the top edge at
#   longitude (x + width/2) heading south, mirrored at the south edge. The
#   top and bottom POLAR_CAP_ROWS rows are uniform featureless ice so that
#   crossing seam has nothing to mismatch (see the polar cap section below).

# Fixed generation parameters. These are part of the determinism contract:
# changing them changes every map, so they are pinned constants rather than
# tunable at the CLI for M1.
const DEFAULT_WIDTH := 512
const DEFAULT_HEIGHT := 256

# Elevation thresholds (noise normalized to 0..1). NEUTRAL_SEA_LEVEL is the
# geological reference level: the elevation field is tuned around it, and the
# per-seed hydrological era (see the world-eras section below) sets the actual
# `sea_level` above or below it. Land that sits between the era sea level and
# the neutral level on an ice-age world is exposed former seabed.
const NEUTRAL_SEA_LEVEL := 0.5
# Beaches span this band of elevation above the era sea level.
const BEACH_BAND := 0.02
const MOUNTAIN_LEVEL := 0.76

# --- Hydrological eras (issue #4) --------------------------------------------
#
# Each seed gets a hydrological era that explains its character geologically:
# the sea level is derived per seed (a position hash, honoring the purity
# rule), so an ICE_AGE world has its water locked up in enlarged polar caps
# and a lowered sea that exposes former ocean floor as vast lowland basins,
# while a WARM world runs a higher sea and trends toward a water world. The
# wide middle is TEMPERATE, close to the neutral level.
#
# The era latent is an independent draw from the archetype latent, but it is
# BIASED by the archetype so worlds read as geologically coherent: a
# continent-heavy (dry) world skews strongly toward ice age (a supercontinent
# dry world is a deep ice age with the water in the caps), an oceanic world
# skews toward the warm era. The tails stay open, so a warm supercontinent
# world is possible, just rare.
#
# What falls out of the lowered sea nearly free on ice-age worlds:
#   - Exposed seabed biomes on land between the era sea level and the neutral
#     level: marsh fringes near the waterline, salt flats where dry, dry basin
#     plains otherwise.
#   - Remnant hypersaline inland seas: water deep inside a continent (high
#     continent mask) is an old ocean reduced to a dead sea, not open ocean.
#   - Era-scaled polar caps: ice-age worlds get deep cap bands, warm worlds
#     thin ones. The cap-band uniformity invariant of issue #2 is preserved;
#     only the band depth varies per seed.
#
# Everything is a pure function of the seed (position hashes, no per-cell
# RNG), so the era is byte-reproducible. See _build_era().
enum Era { ICE_AGE, TEMPERATE, WARM }

# Era selector thresholds on the (archetype-biased) 0..1 latent.
const ERA_ICE_MAX := 0.33
const ERA_WARM_MIN := 0.67

# Era sea-level and cap-depth ranges. Severity (a second per-seed hash) slides
# each era between its mild and deep extreme: a deeper ice age has a lower sea
# AND a thicker cap (the water has to go somewhere), a warmer warm era has a
# higher sea and a thinner cap.
#   ICE_AGE:   sea 0.465 down to 0.435, cap rows 18 up to 25
#   TEMPERATE: sea 0.490 up to 0.510,   cap rows 10 up to 14
#   WARM:      sea 0.520 up to 0.545,   cap rows 8 down to 5
# The lowest possible sea (0.435) must stay above 1.0 + CONTINENT_OCEAN_BIAS
# so the guaranteed-ocean gap between continents survives every era; the
# highest possible sea (0.545) must stay below POLAR_ICE_ELEVATION so the cap
# is solid ice in every era. Both margins are asserted by test_world_eras.gd.

# Exposed-seabed classification on ice-age worlds (land between the era sea
# level and the neutral level): a wet cell within this band of the waterline
# is marsh fringe; otherwise dry cells are salt flats and the rest is dry
# basin plains.
const EXPOSED_MARSH_BAND := 0.015
const EXPOSED_MARSH_MOISTURE_MIN := 0.5
const EXPOSED_SALT_MOISTURE_MAX := 0.35

# A water cell this deep inside a continent (continent mask at or above this)
# on an ice-age world is a remnant hypersaline sea, not open ocean.
const HYPERSALINE_MASK_MIN := 0.75

# --- Polar cap bands (issue #2) ----------------------------------------------
#
# The world is sphere-traversable at the poles: crossing the north edge at
# longitude x re-enters from the north edge at longitude (x + width/2), heading
# south, and mirrored at the south edge. That preserves sphere semantics on the
# east-west wrapped flat map with no true-sphere geometry anywhere. The
# traversal mechanic itself only matters once flight exists (far future), but
# the GENERATOR constraint lands now, because it is cheap today and expensive
# to retrofit: the top and bottom polar_cap_rows() rows are uniform featureless
# ice, so the polar crossing seam has nothing to mismatch. Terrain variation
# begins only below the cap band. The band DEPTH is era-scaled (deep caps on
# ice-age worlds, thin ones on warm worlds, see the world-eras section above);
# the uniformity invariant holds at every depth. test/test_polar_caps.gd
# asserts the uniformity per seed.
#
# Within the band the surface is a flat ice sheet at POLAR_ICE_ELEVATION,
# above sea level so the cap is solid, walkable ice. The UNDERLYING
# elevation (what the mask plus noise would have produced) is still computed
# and reported in the JSON: cap cells whose underlying elevation reaches sea
# level are land ice (an Antarctica-style cap over a landmass), the rest are
# sea ice (an Arctic-style cap over polar ocean). The distinction is stats
# and flavor only; the surface stays uniform either way.
#
# Cap cells are their own category in the summary: they count as neither land
# nor ocean, and they are excluded from the landmass connected-component
# analysis, so a continent that runs under the cap cannot merge with another
# one through the pole band and the archetype landmass invariants keep their
# meaning.
#
# POLAR_ICE_ELEVATION sits above the highest possible era sea level (0.545)
# so the cap is solid, walkable ice in every era.
const POLAR_ICE_ELEVATION := 0.56

# --- Continent-mask layer (see issue #1) ------------------------------------
#
# Raw layered noise alone produces one connected blobby landmass with fringe
# islands. To force distinct, isolated continents we place a deterministic set of
# continent lobes (derived from the world seed, honoring the pure function of
# (seed, position) rule) and apply a distance falloff around each. The falloff is
# combined with the noise heightmap so that land only survives near a lobe and
# guaranteed deep ocean separates the continents.
#
# The lobes are grouped: each continent is a chain of several overlapping lobes
# sharing a `group` id, so a continent reads as one large, elongated, irregular
# landmass rather than a single compact rounded island. Lobes in the same group
# merge; different groups keep a guaranteed ocean gap. See the "Lobed continent
# groups" section below and _build_continent_centers().
#
# The lobe list is a short deterministic list computed once from the seed (a
# position hash, NOT a per-cell RNG sample). Every per-cell mask value is then a
# pure function of (seed, position): the distance from the cell to the fixed
# lobes. Nothing depends on iteration order.
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

# --- Lobed continent groups -------------------------------------------------
#
# A single hashed center plus falloff always reads as one compact rounded island,
# no matter how much the noise ragged-ises its coast. To make continents read as
# large, elongated, irregular landmasses, each continent is built from a CHAIN of
# several overlapping lobes (each lobe is a position-hashed center with its own
# core, falloff, aspect and orientation, the same primitives as before) that
# share a `group` id. Lobes in the same group are placed close enough to overlap,
# so their combined mask merges into one landmass rather than a string of visibly
# separate circles.
#
# The isolation guarantee (CONTINENT_MIN_OCEAN_GAP below) now applies BETWEEN
# groups only: two lobes of the SAME group may sit arbitrarily close (that is how
# they merge), while any two lobes of DIFFERENT groups keep the guaranteed ocean
# band. Small scattered single-lobe "archipelago" groups are sprinkled between the
# continents; being their own group, they too keep the ocean gap, so an
# archipelago island can never bridge two continents into one component.
#
# A chain walks from an anchor lobe: each subsequent lobe is offset from the
# previous one by a hashed direction (wandering around the group's base axis, so
# the chain elongates instead of folding into a blob) and a hashed distance of
# STEP_MIN..STEP_MAX times the lobe's core radius. Because the step is a fraction
# of the core, consecutive cores overlap and the mask stays at 1.0 across the
# join, so the lobes fuse. Everything is a pure function of (seed, group, lobe
# index, attempt): no per-run randomness in the chaining or the archipelagos.
const LOBE_CHAIN_STEP_MIN_FRAC := 0.45
const LOBE_CHAIN_STEP_MAX_FRAC := 0.95
const LOBE_CHAIN_ANGLE_SPREAD := 1.15

# Anchor lobes (the first lobe of a group and every archipelago lobe) keep their
# center at least this far from the hard north and south poles. This is a small
# margin, NOT a full-extent clearance: a large continent's extent is deliberately
# allowed to run past a pole and clip at the map edge, so land reaches high
# latitude and the map no longer sits inside an enclosing ocean ring. Clipping
# only ever removes land at the edge, so it cannot affect the (circular, extent
# based) isolation guarantee between groups. The polar cap bands (POLAR_CAP_ROWS
# above) sit on top of whatever terrain reaches those high latitudes: land that
# runs under a cap becomes land ice, so we simply do not hold land away from the
# poles. Chained (non-anchor) lobes may wander past this margin and clip too.
const CONTINENT_POLE_MARGIN := 16

# Minimum guaranteed ocean gap (in cells) between the influence extents (core +
# falloff) of any two continents from DIFFERENT groups. Because land can only
# exist inside a lobe's influence extent (the mask is 0.0 outside it), forcing the
# extents of different groups to stay this far apart guarantees a band of deep
# ocean between every pair of continents (and around every archipelago island).
# This must exceed twice the warp amplitude so that even when the domain warp
# pushes two neighboring coasts toward each other by up to WARP_AMP each, a band
# of ocean always survives and the landmasses can never touch. This is the load
# bearing isolation guarantee, now scoped between groups. See
# min_center_extent_gap().
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

# The seed-derived hydrological era, computed once in _init after the
# archetype (the era latent is biased by the archetype kind). Fields:
# {"kind": Era, "name": String, "sea_level": float, "cap_rows": int}.
# See _build_era().
var _era: Dictionary = {}

# The authoritative sea level for this seed, cached from the era. Everything
# that used to reference a fixed sea-level constant (biome classification,
# temperature cooling, the sim-side sampler and spawn finder) reads this.
var sea_level: float = NEUTRAL_SEA_LEVEL

# Deterministic list of continent lobes, computed once from the seed in _init.
# Each entry is {"x": float, "y": float, "core": int, "falloff": int,
# "extent": int, "aspect": float, "orient": float, "group": int} where `core` is
# the full-mask radius, `falloff` is the ramp band width, `extent` is core +
# falloff (the anisotropic radius beyond which the mask is exactly 0), `aspect` is
# the elongation, `orient` is the long-axis angle in radians, and `group` ties the
# lobe to its continent (lobes sharing a group merge into one landmass; different
# groups keep the ocean gap). See _build_continent_centers(). The name keeps
# "centers" for continuity; every entry is one lobe center.
var _continent_centers: Array = []

# Number of distinct continent groups (continents plus archipelago islands),
# computed once in _init from the lobe list. Reported in the JSON summary.
var _continent_group_count: int = 0

# The ordered starter biome set. Order here is the canonical order used for
# color lookup and for the JSON distribution breakdown, so it stays stable.
const BIOME_OCEAN := "ocean"
const BIOME_BEACH := "beach"
const BIOME_PLAINS := "plains"
const BIOME_FOREST := "forest"
const BIOME_DESERT := "desert"
const BIOME_TUNDRA := "tundra"
const BIOME_MOUNTAIN := "mountain"
const BIOME_ICE := "ice"
# Exposed former seabed (ice-age worlds only, see the world-eras section).
const BIOME_MARSH := "marsh"
const BIOME_SALT_FLAT := "salt_flat"
const BIOME_BASIN := "basin"
# Remnant dead sea deep inside a continent (ice-age worlds only). A water
# biome: counts with ocean, not land.
const BIOME_HYPERSALINE := "hypersaline_sea"

const BIOME_ORDER := [
	BIOME_OCEAN,
	BIOME_BEACH,
	BIOME_PLAINS,
	BIOME_FOREST,
	BIOME_DESERT,
	BIOME_TUNDRA,
	BIOME_MOUNTAIN,
	BIOME_ICE,
	BIOME_MARSH,
	BIOME_SALT_FLAT,
	BIOME_BASIN,
	BIOME_HYPERSALINE,
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
	BIOME_ICE: Color8(226, 234, 242),
	BIOME_MARSH: Color8(94, 124, 92),
	BIOME_SALT_FLAT: Color8(233, 227, 205),
	BIOME_BASIN: Color8(173, 160, 122),
	BIOME_HYPERSALINE: Color8(70, 120, 118),
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

	# Derive the world archetype and its hydrological era, then place the
	# continent centers once, all deterministically from the seed. The era is
	# built after the archetype (its latent is biased by the archetype kind)
	# and adjusts the archetype's expected land band (a lowered sea exposes
	# seabed as extra land, a raised sea drowns some).
	_archetype = _build_archetype()
	_era = _build_era()
	sea_level = float(_era["sea_level"])
	_apply_era_to_archetype()
	_continent_centers = _build_continent_centers()

	var groups := {}
	for c in _continent_centers:
		groups[int(c["group"])] = true
	_continent_group_count = groups.size()


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
# CONTINENT_HEAVY, and each bucket fixes the group tiers (how many continent
# groups of each size class, how many lobes each, and the lobe radii), the
# sea-level lift, the archipelago sprinkle, plus the expected land-fraction band
# and minimum significant landmass count the landmass test asserts against. Every
# value is a pure function of the seed (position hashes, no per-cell RNG), so it
# is byte-reproducible.
#
# Dramatic size variance within one world comes from the tier structure: a "super"
# tier group (many lobes, larger cores) reads as a near-supercontinent, a "mid"
# tier group or two as mid-size continents, and a "small" tier plus the
# archipelago dots as the tail. The tiers are read by _build_continent_centers();
# the `land_band_*` and `min_significant` fields are the per-seed expectations the
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
			# A water world: no supercontinent, at most a small mid group, a couple
			# of small groups, and a scatter of archipelago dots. No sea-level lift,
			# so only the noise peaks surface. Little land.
			return {
				"kind": kind,
				"name": "oceanic",
				"tiers": [
					{"tag": "mid", "groups": int(_hash2(seed_value, 5001) % 2),        # 0..1
						"lobes_min": 1, "lobes_max": 2, "core_min": 16, "core_max": 24, "falloff": 22},
					{"tag": "small", "groups": 1 + int(_hash2(seed_value, 5002) % 2),  # 1..2
						"lobes_min": 1, "lobes_max": 2, "core_min": 10, "core_max": 18, "falloff": 18},
				],
				"archipelago": {"count": 4 + int(_hash2(seed_value, 5003) % 4),        # 4..7
					"core_min": 7, "core_max": 12, "falloff": 15},
				"lift": 0.0,
				"land_band_min": 0.002, "land_band_max": 0.20,
				"min_significant": 1,
				# A water world is scattered small islands with no dominant mass, so no
				# size-hierarchy floor is asserted (0.0 disables the check).
				"min_largest_fraction": 0.0,
			}
		Archetype.CONTINENT_HEAVY:
			# A dry world: a big multi-lobe supercontinent, two mid continents, a
			# small one or two, and a few islands, with a strong sea-level lift so
			# most of each plateau surfaces. Large land fraction.
			return {
				"kind": kind,
				"name": "continent_heavy",
				"tiers": [
					{"tag": "super", "groups": 1,
						"lobes_min": 5, "lobes_max": 6, "core_min": 40, "core_max": 52, "falloff": 30},
					{"tag": "mid", "groups": 2,
						"lobes_min": 2, "lobes_max": 4, "core_min": 30, "core_max": 42, "falloff": 28},
					{"tag": "small", "groups": 1 + int(_hash2(seed_value, 6003) % 2), # 1..2
						"lobes_min": 1, "lobes_max": 2, "core_min": 18, "core_max": 28, "falloff": 24},
				],
				"archipelago": {"count": 2 + int(_hash2(seed_value, 6004) % 3),       # 2..4
					"core_min": 8, "core_max": 14, "falloff": 16},
				"lift": 0.30,
				"land_band_min": 0.22, "land_band_max": 0.82,
				"min_significant": 2,
				# Size hierarchy: the supercontinent dominates, so the largest landmass
				# holds a clear share of all land (observed min 0.33 across a 120-seed
				# sweep; the floor is set below that so it is a real but non-brittle
				# invariant, proving the world is not N equal-size masses).
				"min_largest_fraction": 0.20,
			}
		_:
			# The typical continental world: one multi-lobe near-supercontinent, a
			# mid continent or two, a small one or two, and scattered islands,
			# roughly a quarter to two fifths land.
			return {
				"kind": Archetype.CONTINENTAL,
				"name": "continental",
				"tiers": [
					{"tag": "super", "groups": 1,
						"lobes_min": 4, "lobes_max": 5, "core_min": 34, "core_max": 48, "falloff": 28},
					{"tag": "mid", "groups": 1 + int(_hash2(seed_value, 7002) % 2),   # 1..2
						"lobes_min": 2, "lobes_max": 3, "core_min": 26, "core_max": 36, "falloff": 26},
					{"tag": "small", "groups": 1 + int(_hash2(seed_value, 7003) % 2), # 1..2
						"lobes_min": 1, "lobes_max": 2, "core_min": 17, "core_max": 26, "falloff": 22},
				],
				"archipelago": {"count": 4 + int(_hash2(seed_value, 7004) % 4),       # 4..7
					"core_min": 8, "core_max": 13, "falloff": 16},
				"lift": 0.21,
				"land_band_min": 0.12, "land_band_max": 0.46,
				"min_significant": 2,
				# Size hierarchy: the near-supercontinent dominates, so the largest
				# landmass holds a clear share of all land (observed min 0.24 across a
				# 120-seed sweep; the floor is set below that so it is a real but non
				# brittle invariant, proving the world is not N equal-size masses).
				"min_largest_fraction": 0.20,
			}


# Derive the hydrological era for this seed. The era latent is an independent
# hash draw, remapped by the archetype kind so the distribution is biased
# (continent-heavy worlds skew toward ice age, oceanic worlds toward warm)
# while both tails stay reachable for every archetype. A second severity hash
# slides the era between its mild and deep extreme: severity moves the sea
# level away from neutral and the cap depth with it, so a deeper ice age has
# both a lower sea and a thicker polar cap. Pure function of the seed.
func _build_era() -> Dictionary:
	var u := float(_hash2(seed_value, 9100) % 1000000) / 1000000.0
	var sev := float(_hash2(seed_value, 9200) % 1000000) / 1000000.0
	match int(_archetype["kind"]):
		Archetype.CONTINENT_HEAVY:
			# Compress toward 0 (ice age); warm needs u above ~0.89.
			u = u * 0.75
		Archetype.OCEANIC:
			# Compress toward 1 (warm); ice age needs u below ~0.11.
			u = 0.25 + u * 0.75
		_:
			pass

	if u < ERA_ICE_MAX:
		return {
			"kind": Era.ICE_AGE,
			"name": "ice_age",
			"sea_level": 0.465 - 0.03 * sev,
			"cap_rows": 18 + int(sev * 7.999),
		}
	if u >= ERA_WARM_MIN:
		return {
			"kind": Era.WARM,
			"name": "warm",
			"sea_level": 0.52 + 0.025 * sev,
			"cap_rows": 8 - int(sev * 3.999),
		}
	return {
		"kind": Era.TEMPERATE,
		"name": "temperate",
		"sea_level": 0.49 + 0.02 * sev,
		"cap_rows": 10 + int(sev * 4.999),
	}


# Widen the archetype's expected land band for the era before the landmass
# test reads it: a lowered ice-age sea exposes former seabed as extra land, a
# raised warm sea drowns low coastal land. The bands stay honest per-seed
# expectations derived from the same source the generator uses.
func _apply_era_to_archetype() -> void:
	match int(_era["kind"]):
		Era.ICE_AGE:
			# The lowered sea exposes seabed (more land), but the deep ice-age
			# cap also swallows high-latitude land as land ice (which counts as
			# neither land nor ocean), so the band widens at BOTH ends.
			_archetype["land_band_max"] = minf(float(_archetype["land_band_max"]) + 0.20, 0.95)
			_archetype["land_band_min"] = maxf(float(_archetype["land_band_min"]) - 0.06, 0.0)
		Era.WARM:
			_archetype["land_band_min"] = maxf(float(_archetype["land_band_min"]) - 0.06, 0.0)
		_:
			# Temperate sea wanders slightly around neutral; widen both edges a
			# little so the band tolerates the wander.
			_archetype["land_band_min"] = maxf(float(_archetype["land_band_min"]) - 0.03, 0.0)
			_archetype["land_band_max"] = minf(float(_archetype["land_band_max"]) + 0.05, 0.95)


# True when this seed's era is an ice age (lowered sea, exposed seabed,
# hypersaline remnant seas, deep polar caps).
func is_ice_age() -> bool:
	return int(_era["kind"]) == Era.ICE_AGE


# The number of rows in each polar cap band for this seed (era-scaled).
func polar_cap_rows() -> int:
	return int(_era["cap_rows"])


# The seed-derived hydrological era, exposed for the era test and the JSON
# summary.
func era() -> Dictionary:
	return _era


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


# A deterministic unit float in [0, 1) from a hash value and a sub-key. Used to
# turn the 64-bit lobe/chain hashes into angles, step fractions, aspects and
# orientations without a per-cell RNG.
func _unit_from_hash(h: int, k: int) -> float:
	return float(_hash2(h, k) % 65536) / 65536.0


# Build the deterministic list of continent lobes for this seed from the
# archetype tiers. Each tier contributes some number of continent GROUPS; each
# group is a chain of overlapping lobes (see _place_group) that fuse into one
# landmass. Groups are placed largest first so the big continents claim room. A
# whole group is accepted only if EVERY one of its lobes keeps its extent
# CONTINENT_MIN_OCEAN_GAP away from every already-placed lobe of a DIFFERENT
# group; lobes within the same group are never checked against each other (that is
# how they merge). Finally, small single-lobe archipelago groups are sprinkled
# between the continents, each still isolated so it cannot bridge two continents.
# Because land can only exist inside a lobe's extent, isolated groups guarantee
# distinct, ocean-separated landmasses.
func _build_continent_centers() -> Array:
	# Flatten the archetype tiers into one group-spec per group to place, then sort
	# largest expected first so the big continents win the placement race.
	var group_specs: Array = []
	var tiers: Array = _archetype["tiers"]
	for ti in range(tiers.size()):
		var tier: Dictionary = tiers[ti]
		for gi in range(int(tier["groups"])):
			group_specs.append({
				"tier": ti, "gi": gi,
				"lobes_min": int(tier["lobes_min"]), "lobes_max": int(tier["lobes_max"]),
				"core_min": int(tier["core_min"]), "core_max": int(tier["core_max"]),
				"falloff": int(tier["falloff"]),
			})
	group_specs.sort_custom(func(a, b):
		return (a["core_max"] + a["falloff"]) * a["lobes_max"] > (b["core_max"] + b["falloff"]) * b["lobes_max"])

	var lobes: Array = []
	var group_id := 0
	for gs in group_specs:
		var chain := _place_group(gs, group_id, lobes)
		if not chain.is_empty():
			lobes.append_array(chain)
			group_id += 1

	# Archipelago: scattered single-lobe groups between the continents. Each is its
	# own group and is isolated from every other group, so it stays a small
	# separate island and can never merge two continents into one component.
	var arch: Dictionary = _archetype["archipelago"]
	for ai in range(int(arch["count"])):
		var lobe := _place_archipelago(ai, group_id, lobes, arch)
		if not lobe.is_empty():
			lobes.append(lobe)
			group_id += 1

	return lobes


# Place one continent group: a chain of overlapping lobes sharing `group_id`. The
# chain geometry is a pure function of (seed, tier, group index, attempt); the
# whole chain is resampled (new attempt) until every lobe clears the ocean gap
# against all already-placed lobes of other groups, or the attempt cap is hit (in
# which case the group is dropped, deterministically, yielding one fewer
# continent). Returns the accepted chain, or [] if it could not be placed.
func _place_group(gs: Dictionary, group_id: int, existing: Array) -> Array:
	var group_key := seed_value + (int(gs["tier"]) + 1) * 100003 + int(gs["gi"]) * 7649
	var lobe_count := int(gs["lobes_min"]) + int(_hash2(group_key, 900) % (int(gs["lobes_max"]) - int(gs["lobes_min"]) + 1))
	var attempt := 0
	while attempt < CONTINENT_MAX_PLACEMENT_ATTEMPTS:
		var chain := _build_chain(gs, group_id, group_key, attempt, lobe_count)
		if _chain_isolated(chain, existing):
			return chain
		attempt += 1
	return []


# Build a candidate chain of `lobe_count` lobes for a group, from an anchor lobe
# that walks in a wandering-but-directional path. Pure function of (group_key,
# attempt): the anchor position, the base axis, and every per-lobe offset, core,
# aspect and orientation come from hashes. Non-anchor lobes may wander past the
# pole margin; their extent then clips at the map edge, which is intended.
func _build_chain(gs: Dictionary, group_id: int, group_key: int, attempt: int, lobe_count: int) -> Array:
	var base_h := _hash2(group_key, attempt * 7919 + 17)
	var anchor_x := float(_hash2(base_h, 1) % width)
	var y_span: int = max(height - 2 * CONTINENT_POLE_MARGIN, 1)
	var anchor_y := float(CONTINENT_POLE_MARGIN + int(_hash2(base_h, 2) % y_span))
	var base_angle := _unit_from_hash(base_h, 3) * TAU

	var chain: Array = []
	var prev_x := anchor_x
	var prev_y := anchor_y
	for i in range(lobe_count):
		var lh := _hash2(base_h, 100 + i)
		var core := int(gs["core_min"]) + int(lh % (int(gs["core_max"]) - int(gs["core_min"]) + 1))
		var falloff: int = int(gs["falloff"])
		var aspect := CONTINENT_ASPECT_MIN + _unit_from_hash(lh, 5) * (CONTINENT_ASPECT_MAX - CONTINENT_ASPECT_MIN)
		var orient := _unit_from_hash(lh, 6) * PI
		var cx := prev_x
		var cy := prev_y
		if i > 0:
			# Offset from the previous lobe by a fraction of this lobe's core, so
			# the cores overlap and the mask stays 1.0 across the join. The
			# direction wanders around the group's base axis so the chain elongates.
			var step_frac := LOBE_CHAIN_STEP_MIN_FRAC + _unit_from_hash(lh, 7) * (LOBE_CHAIN_STEP_MAX_FRAC - LOBE_CHAIN_STEP_MIN_FRAC)
			var step := float(core) * step_frac
			var ang := base_angle + (_unit_from_hash(lh, 8) - 0.5) * 2.0 * LOBE_CHAIN_ANGLE_SPREAD
			cx = prev_x + cos(ang) * step
			cy = prev_y + sin(ang) * step
		chain.append({
			# x is normalized onto the cylinder; y stays linear and may fall outside
			# [0, height) so a large lobe's extent clips at the pole.
			"x": fposmod(cx, float(width)), "y": cy,
			"core": core, "falloff": falloff, "extent": core + falloff,
			"aspect": aspect, "orient": orient, "group": group_id,
		})
		prev_x = cx
		prev_y = cy
	return chain


# True if every lobe in `chain` keeps its circular extent CONTINENT_MIN_OCEAN_GAP
# clear of every lobe in `existing`. `existing` only ever holds lobes of other
# (already-placed) groups, so same-group lobes are never separated: this is what
# lets a group's lobes overlap and merge while different groups stay isolated.
func _chain_isolated(chain: Array, existing: Array) -> bool:
	for lobe in chain:
		for e in existing:
			var d := _surface_distance(float(lobe["x"]), float(lobe["y"]), float(e["x"]), float(e["y"]))
			if d < float(lobe["extent"]) + float(e["extent"]) + float(CONTINENT_MIN_OCEAN_GAP):
				return false
	return true


# Place one archipelago island: a single small lobe that is isolated from every
# already-placed lobe (continents and prior archipelagos). Pure function of
# (seed, archipelago index, attempt). Archipelago lobes stay fully inside the
# poles (they are small dots, no clipping) and get their own group so they can
# never bridge two continents. Returns the lobe, or {} if it could not be placed.
func _place_archipelago(ai: int, group_id: int, existing: Array, arch: Dictionary) -> Dictionary:
	var akey := seed_value + 800000 + ai * 6271
	var attempt := 0
	while attempt < CONTINENT_MAX_PLACEMENT_ATTEMPTS:
		var h := _hash2(akey, attempt * 7919 + 17)
		var core := int(arch["core_min"]) + int(_hash2(h, 10) % (int(arch["core_max"]) - int(arch["core_min"]) + 1))
		var falloff: int = int(arch["falloff"])
		var extent := core + falloff
		var y_lo := extent
		var y_hi := height - 1 - extent
		if y_hi < y_lo:
			return {}
		var cx := float(_hash2(h, 1) % width)
		var cy := float(y_lo + int(_hash2(h, 2) % (y_hi - y_lo + 1)))
		var lobe := {
			"x": cx, "y": cy, "core": core, "falloff": falloff, "extent": extent,
			"aspect": CONTINENT_ASPECT_MIN + _unit_from_hash(h, 5) * (CONTINENT_ASPECT_MAX - CONTINENT_ASPECT_MIN),
			"orient": _unit_from_hash(h, 6) * PI, "group": group_id,
		}
		if _chain_isolated([lobe], existing):
			return lobe
		attempt += 1
	return {}


# Smallest surviving ocean band, in cells, between any two placed lobes of
# DIFFERENT groups: the center separation minus both circular extents. Because
# each lobe is inscribed in its extent circle, this is a lower bound on the true
# ocean gap between distinct landmasses. Same-group pairs are skipped (they are
# meant to overlap and merge). Returns INF when fewer than two groups are placed.
# The landmass test asserts this stays at or above twice the warp amplitude, which
# is what proves the domain warp can never close a gap and make two distinct
# landmasses touch.
func min_center_extent_gap() -> float:
	var worst := INF
	for i in range(_continent_centers.size()):
		for j in range(i + 1, _continent_centers.size()):
			var a: Dictionary = _continent_centers[i]
			var b: Dictionary = _continent_centers[j]
			if int(a["group"]) == int(b["group"]):
				continue
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


# True when row py lies inside the north or south polar cap band. The band
# depth is era-scaled (polar_cap_rows), the uniformity within it is not.
func in_polar_cap(py: int) -> bool:
	var rows := polar_cap_rows()
	return py < rows or py >= height - rows


# Elevation the mask plus noise would produce at (px, py), ignoring the polar
# cap flattening. This is what the cap covers: inside the band it classifies a
# cap cell as land ice (at or above the era sea level, a cap over a landmass)
# or sea ice (a cap over polar ocean) for the JSON summary. Outside the band
# it equals elevation_at.
func underlying_elevation_at(px: int, py: int) -> float:
	var base := base_elevation_at(px, py)
	var mask := continent_mask_at(px, py)
	return _apply_continent_mask(base, mask)


# Authoritative elevation at (px, py): the raw noise heightmap combined with
# the continent mask. Land only survives near a continent center; between
# continents the mask forces the elevation below sea level, guaranteeing deep
# ocean. Everything downstream (temperature, biome, rendering) uses this.
#
# Inside a polar cap band the surface is a flat ice sheet at
# POLAR_ICE_ELEVATION regardless of the underlying terrain: the band must be
# featureless so the sphere-consistent polar crossing (see the polar cap
# section above) has nothing to mismatch.
func elevation_at(px: int, py: int) -> float:
	if in_polar_cap(py):
		return POLAR_ICE_ELEVATION
	return underlying_elevation_at(px, py)


# Bias applied to the raw heightmap where the continent mask is exactly 0 (every
# cell outside all continent extents, i.e. the open ocean between continents).
# It must be deep enough that even the highest possible raw noise stays below
# sea level IN EVERY ERA, so the gaps between continents are guaranteed ocean.
# The raw heightmap is normalized to 0..1 and the lowest era sea level is 0.435
# (a deep ice age), so any bias below 0.435 - 1.0 = -0.565 guarantees it; -0.60
# leaves margin while keeping the coastal bias ramp reasonably gentle (a deeper
# bias steepens the shoreline). This is the load-bearing "guaranteed ocean gap"
# mechanism; test_world_eras.gd asserts the margin against the era ranges.
const CONTINENT_OCEAN_BIAS := -0.60


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

	# Higher elevation (above the era sea level) is colder.
	if elevation > sea_level:
		var land_height := (elevation - sea_level) / (1.0 - sea_level)
		temp -= land_height * ELEVATION_COOLING

	return clampf(temp, 0.0, 1.0)


# Authoritative biome at cell (px, py). Polar cap cells are always ice (the
# cap band is uniform and featureless by construction); everywhere else the
# biome comes from the elevation/temperature/moisture lookup table. Callers
# that need the biome for a position should use this rather than composing
# biome_at themselves, so the cap rule is applied in exactly one place.
func biome_for_cell(px: int, py: int) -> String:
	if in_polar_cap(py):
		return BIOME_ICE
	var elevation := elevation_at(px, py)
	var moisture := moisture_at(px, py)

	if elevation < sea_level:
		# Water. On an ice-age world, water deep inside a continent (high
		# continent mask) is an old ocean reduced to a remnant dead sea.
		if is_ice_age() and continent_mask_at(px, py) >= HYPERSALINE_MASK_MIN:
			return BIOME_HYPERSALINE
		return BIOME_OCEAN

	if is_ice_age() and elevation < NEUTRAL_SEA_LEVEL:
		# Exposed former seabed: land the lowered ice-age sea uncovered. Wet
		# cells near the waterline are marsh fringe, dry cells are salt flats,
		# the rest is dry basin plains.
		if elevation < sea_level + EXPOSED_MARSH_BAND and moisture >= EXPOSED_MARSH_MOISTURE_MIN:
			return BIOME_MARSH
		if moisture < EXPOSED_SALT_MOISTURE_MAX:
			return BIOME_SALT_FLAT
		return BIOME_BASIN

	var temperature := temperature_at(px, py, elevation)
	return biome_at(elevation, temperature, moisture)


# Biome lookup table. Combines elevation, temperature and moisture into one
# of the seven non-ice starter biomes against this seed's era sea level. Ice
# and the era biomes (exposed seabed, hypersaline seas) are not produced here:
# they are position and era rules, applied by biome_for_cell. Documented in
# ARCHITECTURE.md.
func biome_at(elevation: float, temperature: float, moisture: float) -> String:
	if elevation < sea_level:
		return BIOME_OCEAN
	if elevation < sea_level + BEACH_BAND:
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
	if biome == BIOME_ICE:
		# Featureless by design: no shading, so the cap band renders as one
		# uniform color with nothing for the polar crossing seam to mismatch.
		return base
	if biome == BIOME_OCEAN:
		# Deeper water (lower elevation) renders darker.
		var depth := elevation / sea_level          # 0 at deepest, ~1 near shore
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

	# Polar cap accounting: cap cells are neither land nor ocean. The
	# underlying elevation splits them into land ice (cap over a landmass)
	# and sea ice (cap over polar ocean) for the summary.
	var ice_tiles := 0
	var land_ice_tiles := 0

	# Land mask for the connected-component analysis: 1 where the cell is land
	# (any biome that is not ocean and not polar cap ice), 0 otherwise. Cap
	# cells stay 0 so landmasses cannot connect through the pole band. Indexed
	# py * width + px.
	var land_mask := PackedByteArray()
	land_mask.resize(total_tiles)

	for py in range(height):
		for px in range(width):
			var elevation := elevation_at(px, py)
			var biome := biome_for_cell(px, py)

			biome_counts[biome] += 1
			if biome == BIOME_ICE:
				ice_tiles += 1
				if underlying_elevation_at(px, py) >= sea_level:
					land_ice_tiles += 1
			elif biome != BIOME_OCEAN and biome != BIOME_HYPERSALINE:
				land_tiles += 1
				land_mask[py * width + px] = 1

			image.set_pixel(px, py, _biome_color(biome, elevation))

	var land_fraction := float(land_tiles) / float(total_tiles)

	var landmass := _analyze_landmasses(land_mask, land_tiles)

	# Biome distribution as a fraction of land tiles. Water biomes are excluded
	# (ocean is reported as ocean_fraction, hypersaline seas via their own
	# field) and so is polar cap ice (neither land nor ocean, reported via the
	# ice_* fields).
	var land_distribution := {}
	for b in BIOME_ORDER:
		if b == BIOME_OCEAN or b == BIOME_ICE or b == BIOME_HYPERSALINE:
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
		"era": _era["name"],
		"sea_level": _round6(sea_level),
		"hypersaline_tiles": biome_counts[BIOME_HYPERSALINE],
		"polar_cap_rows": polar_cap_rows(),
		"ice_tiles": ice_tiles,
		"land_ice_tiles": land_ice_tiles,
		"sea_ice_tiles": ice_tiles - land_ice_tiles,
		"ice_fraction": _round6(float(ice_tiles) / float(total_tiles)),
		"biome_distribution_of_land": land_distribution,
		"archetype": _archetype["name"],
		"archetype_land_band_min": _round6(float(_archetype["land_band_min"])),
		"archetype_land_band_max": _round6(float(_archetype["land_band_max"])),
		"archetype_min_significant_landmasses": int(_archetype["min_significant"]),
		"archetype_min_largest_fraction": _round6(float(_archetype["min_largest_fraction"])),
		"min_center_extent_gap": _round6(_finite_gap(min_center_extent_gap())),
		"continent_center_count": _continent_centers.size(),
		"continent_group_count": _continent_group_count,
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
