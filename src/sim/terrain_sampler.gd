extends RefCounted
class_name TerrainSampler

# Preloaded rather than referenced by global class name so this module resolves
# in a headless `--script` run (the global class cache is only built by the
# editor). The alias avoids clashing with the MacroMapGenerator global name.
const MacroMapGen := preload("res://src/macro_map.gd")

# TerrainSampler turns the authoritative low-resolution macro map into a smooth,
# walkable local heightfield. It is a SIM-side module: it has zero dependency on
# Viewport, Camera, or any UI node and runs headless. A separate render-side
# module (see src/render/) builds the actual Godot mesh and collision from what
# this sampler returns.
#
# Determinism contract (same as MacroMapGenerator, see CLAUDE.md):
#   The surface height at a world position is a pure function of
#   (world seed, position). It is the macro elevation bilinearly interpolated
#   between macro cells, plus a NEW local-detail noise layer seeded off the
#   world seed with a fixed offset. There is no stateful RNG and nothing depends
#   on iteration order, so two samplers built from the same seed return
#   byte-identical values for the same position, in any order.
#
# Hierarchical multi-scale rule (see CLAUDE.md):
#   This layer REFINES the macro map, it never contradicts it. The bilinear
#   base keeps macro-cell centers exactly on the authoritative elevation, so a
#   position inside an ocean cell stays ocean and a position inside a land cell
#   stays land. The detail layer only adds modest sub-macro-cell variation.
#
# World topology (see CLAUDE.md):
#   The world is a cylinder: it wraps east-west and has hard north and south
#   edges. The x axis wraps modulo the macro width; the detail noise is sampled
#   on the same cylinder mapping the macro layer uses, so there is no seam at
#   the wrap. The y (north-south) axis is clamped, it does not wrap.

# --- World scale ------------------------------------------------------------
# World units spanned by one macro cell. The macro grid is coarse (512x256 by
# default), so each cell covers a sizeable patch of walkable ground.
const MACRO_CELL_SIZE := 24.0

# World units for the full 0..1 elevation range. Sea level (elevation 0.5) maps
# to world Y = 0, so ocean floor is negative Y and land is positive Y. This
# keeps the numbers small and centered, which is friendly to the floating
# origin work.
const HEIGHT_SCALE := 140.0

# --- Local-detail noise -----------------------------------------------------
# Fixed offset added to the world seed for the detail layer, following the
# exact pattern macro_map.gd uses for its decorrelated layers (seed, seed+1013,
# seed+2027). 5077 keeps this layer independent of all three macro layers while
# staying fully determined by the one world seed.
const DETAIL_SEED_OFFSET := 5077

# Detail amplitude in elevation-01 units. Kept small so the detail never turns
# a deep-ocean cell into land or a solid-land cell into ocean: it only wiggles
# the surface within a fraction of the sea-to-peak range (about 3.5 world units
# at the current HEIGHT_SCALE). The macro map stays authoritative.
const DETAIL_AMPLITUDE01 := 0.025

# Detail noise spatial frequency. Chosen so the primary wavelength is roughly
# 20 world units, smaller than one macro cell (MACRO_CELL_SIZE), which is what
# gives sub-macro-cell variation.
const DETAIL_FREQUENCY := 0.05

var _generator: MacroMapGen
var _detail_noise: FastNoiseLite

# Cached from the generator so the render side does not reach into it directly.
var macro_width: int
var macro_height: int
var world_width_units: float

# Sea level in world Y (always 0 by construction, exposed for readability).
const SEA_LEVEL_Y := 0.0


func _init(generator: MacroMapGen) -> void:
	_generator = generator
	macro_width = generator.width
	macro_height = generator.height
	world_width_units = float(macro_width) * MACRO_CELL_SIZE

	# Local-detail layer: a fractal noise seeded off the world seed with a fixed
	# offset, exactly the pattern established in macro_map.gd. Pure function of
	# (seed, position).
	_detail_noise = FastNoiseLite.new()
	_detail_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_detail_noise.seed = generator.seed_value + DETAIL_SEED_OFFSET
	_detail_noise.frequency = DETAIL_FREQUENCY
	_detail_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_detail_noise.fractal_octaves = 3
	_detail_noise.fractal_lacunarity = 2.0
	_detail_noise.fractal_gain = 0.5


# Wrap a macro column index into 0..macro_width-1 (east-west wrap).
func _wrap_col(px: int) -> int:
	return ((px % macro_width) + macro_width) % macro_width


# Bilinearly interpolated macro elevation (0..1) at a world position, WITHOUT
# the local-detail layer. Macro-cell centers sit at world (px + 0.5, py + 0.5)
# times MACRO_CELL_SIZE, so subtracting 0.5 lands integer cell centers exactly
# on the authoritative macro sample. The x axis wraps; the y axis clamps to the
# hard poles.
func macro_elevation01(wx: float, wz: float) -> float:
	var fx := wx / MACRO_CELL_SIZE - 0.5
	var fy := wz / MACRO_CELL_SIZE - 0.5

	var x0 := int(floor(fx))
	var y0 := int(floor(fy))
	var tx := fx - float(x0)
	var ty := fy - float(y0)

	var y0c := clampi(y0, 0, macro_height - 1)
	var y1c := clampi(y0 + 1, 0, macro_height - 1)
	var x0w := _wrap_col(x0)
	var x1w := _wrap_col(x0 + 1)

	var e00 := _generator.elevation_at(x0w, y0c)
	var e10 := _generator.elevation_at(x1w, y0c)
	var e01 := _generator.elevation_at(x0w, y1c)
	var e11 := _generator.elevation_at(x1w, y1c)

	var top := lerpf(e00, e10, tx)
	var bottom := lerpf(e01, e11, tx)
	return lerpf(top, bottom, ty)


# Local-detail contribution (range roughly -1..1) sampled on the same cylinder
# mapping the macro layer uses, so it is seamless across the east-west wrap.
func _detail_raw(wx: float, wz: float) -> float:
	var theta := TAU * wx / world_width_units
	var radius := world_width_units / TAU
	var nx := cos(theta) * radius
	var nz := sin(theta) * radius
	return _detail_noise.get_noise_3d(nx, wz, nz)


# Final elevation (0..1) at a world position: macro base plus local detail,
# clamped. Pure function of (seed, position).
func elevation01_at(wx: float, wz: float) -> float:
	var base := macro_elevation01(wx, wz)
	var detail := _detail_raw(wx, wz) * DETAIL_AMPLITUDE01
	return clampf(base + detail, 0.0, 1.0)


# Surface height in world Y at a world position. Sea level is Y = 0.
func height_at(wx: float, wz: float) -> float:
	return (elevation01_at(wx, wz) - MacroMapGen.SEA_LEVEL) * HEIGHT_SCALE


# True where the surface is below sea level (ocean / swimmable water).
func is_water(wx: float, wz: float) -> bool:
	return height_at(wx, wz) < SEA_LEVEL_Y


# Convert a world position to the nearest macro cell (with east-west wrap and
# north-south clamp). Used for biome lookup, which stays at macro resolution.
func world_to_macro(wx: float, wz: float) -> Vector2i:
	var px := _wrap_col(int(round(wx / MACRO_CELL_SIZE - 0.5)))
	var py := clampi(int(round(wz / MACRO_CELL_SIZE - 0.5)), 0, macro_height - 1)
	return Vector2i(px, py)


# Center of a macro cell in world coordinates.
func macro_to_world_center(px: int, py: int) -> Vector3:
	var wx := (float(px) + 0.5) * MACRO_CELL_SIZE
	var wz := (float(py) + 0.5) * MACRO_CELL_SIZE
	return Vector3(wx, height_at(wx, wz), wz)


# Biome string at a world position, resolved at macro resolution so it agrees
# with the authoritative macro map. Uses the macro (non-detail) elevation for
# the classification, matching what the macro generator itself would report.
func biome_at(wx: float, wz: float) -> String:
	var cell := world_to_macro(wx, wz)
	var elevation := _generator.elevation_at(cell.x, cell.y)
	var moisture := _generator.moisture_at(cell.x, cell.y)
	var temperature := _generator.temperature_at(cell.x, cell.y, elevation)
	return _generator.biome_at(elevation, temperature, moisture)
