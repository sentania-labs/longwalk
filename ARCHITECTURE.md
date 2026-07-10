# ARCHITECTURE.md, longwalk

Design writeup for longwalk. This is a design document. Where it describes
persistence and origin shifting, those are plans for later milestones and are
explicitly out of scope for M1. See [ROADMAP.md](ROADMAP.md) for the milestone
ladder and [CLAUDE.md](CLAUDE.md) for the load-bearing constraints.

No em-dashes are used anywhere in this repo, including this document.

## 1. Engine and tooling

- Engine: Godot 4.3-stable (pinned in `tools/godot/VERSION`, exact build
  `4.3.stable.official.77dcf97d8`).
- The engine binary is not committed. `tools/fetch_godot.sh` downloads the
  pinned Linux x86_64 build from the official GitHub release and unpacks it into
  `tools/godot/`. The binary and a `tools/godot/godot` convenience symlink are
  gitignored.
- The generator and the tests run headless with no display server, so the same
  commands work locally, in CI, and in future automation.

## 2. Macro planet map generation pipeline

Source: `src/macro_map.gd` (the `MacroMapGenerator` class) and
`src/generate_map.gd` (the headless CLI entry point).

### 2.1 Determinism model

The macro map is a pure function of (seed, position). There is no stateful RNG.
Each cell value is produced by sampling seeded `FastNoiseLite` instances at a
coordinate derived only from the cell position. Three noise layers are used, one
per field, each seeded from the world seed plus a fixed offset so they are
decorrelated but reproducible:

- elevation noise: `seed`
- moisture noise: `seed + 1013`
- temperature perturbation noise: `seed + 2027`

Because nothing depends on iteration order, generating the map row-major,
column-major, or in random access order all give the same result. Running twice
with the same seed produces byte-identical PNG and JSON.

### 2.2 East-west wrap through cylindrical noise sampling

The world is a cylinder: it wraps east-west and has hard north and south edges.
To make the noise seamless across the wrap, the x axis is mapped onto a circle
and sampled with 3D noise. For a cell at column `px` on a map of `width`
columns:

```
theta  = TAU * px / width
radius = width / TAU
nx     = cos(theta) * radius
nz     = sin(theta) * radius
value  = noise.get_noise_3d(nx, py, nz)
```

Walking from `px = 0` to `px = width - 1` traverses almost the entire circle, and
the next step wraps back to `theta = 0`, so the east and west edges are
neighbors on the circle with no seam. The radius is `width / TAU` so that one
step in `px` corresponds to one unit of arc length, keeping horizontal feature
scale consistent with the vertical (`py`) scale. The `py` (north-south) axis is
sampled linearly and does not wrap.

Feature scale note: with `radius = width / TAU`, the number of noise features
across the map width is approximately `width * frequency`. At 512 columns wide,
the elevation base frequency of 0.011 yields roughly 5 to 6 continent-scale
features. Frequencies that are too high alias between adjacent edge cells and
reintroduce a visible seam, so they are pinned deliberately.

The generator logs the maximum absolute elevation difference between column 0
and column width-1 across all rows. The determinism test asserts this stays
below 0.05, which confirms the wrap is continuous (measured around 0.02 for the
sample seeds).

### 2.3 Field layers

Map size is fixed at 512 wide by 256 tall for M1 (a 2:1 ratio, the standard for
a horizontally wrapping world map).

Elevation. Fractal (FBM) simplex-smooth noise, 5 octaves, lacunarity 2.0, gain
0.5, base frequency 0.011. Sampled on the cylinder and normalized from the
native -1..1 range to 0..1. This is the raw heightmap (`base_elevation_at`); it
produces coastlines and mountain interiors but, on its own, one connected
blobby landmass with fringe islands. The continent-mask layer below shapes it
into distinct continents. The authoritative `elevation_at` is the raw
heightmap after the mask is applied.

### 2.3a Continent-mask layer

Raw layered noise alone does not produce truly isolated continents, which
undermines region diversity and long-term exploration. A continent-mask layer
sits beneath the heightmap to force distinct, ocean-separated continents.

A small list of continent centers is derived deterministically from the world
seed. Center positions, per-continent core radii, and the continent count come
from a 64-bit position hash of `(seed, slot index, attempt)`, not from any
per-cell RNG or noise sampling, so they honor the pure function of (seed,
position) rule: the centers are a fixed list recomputed identically on every
run. The count is a seed-determined value in a tunable range (default 4 to 6).

Each center has a core radius (mask 1.0 inside) and a falloff band of width
`CONTINENT_FALLOFF_WIDTH` over which the mask ramps from 1.0 down to 0.0 using
a tunable falloff shape (linear, smoothstep, or quadratic; default smoothstep).
Beyond core + falloff the mask is exactly 0.0. The per-cell mask is the maximum
contribution over all centers.

Distances use the cylinder surface metric: the x separation is the shorter way
around the wrap (`min(dx, width - dx)`), the y separation is linear, and the
two combine as `sqrt(dx*dx + dy*dy)`. Because the cylinder radius is
`width / TAU`, one wrapped column equals one unit of distance, matching the
noise geometry, so the mask has no seam at the east-west wrap.

The mask combines with the raw heightmap as `elevation = clamp(lifted * mask)`
where `lifted` domes the noise gently toward land in proportion to the mask
(`CONTINENT_DOME_STRENGTH`). Where the mask is 0.0 the elevation is forced to
0.0 (guaranteed deep ocean); inside a core the noise (slightly domed) governs
land and coastline. Continent centers are placed by a deterministic rejection
loop that keeps each continent's influence extent (core + falloff) at least
`CONTINENT_MIN_OCEAN_GAP` away from every other continent's extent. Since land
can only exist inside a continent's extent, non-overlapping extents guarantee a
band of ocean between every pair of continents, so their landmasses are always
disconnected. All of these parameters (count range, radii, falloff width and
shape, min-ocean-gap, dome strength) are pinned constants in `src/macro_map.gd`
and are part of the determinism contract for M1.

Temperature. Derived from latitude, not from a free noise field, so the poles
are reliably cold and the equator reliably warm:

```
lat            = py / (height - 1)          # 0 at north edge, 1 at south edge
equator_factor = 1 - abs(lat - 0.5) * 2     # 1 at the equator, 0 at both poles
temp           = equator_factor + perturb * 0.18
```

`perturb` is a separate low-frequency noise layer (range -1..1) so the isotherms
are wavy rather than perfectly horizontal bands. Temperature is then cooled by
elevation: land above sea level loses up to 0.35 of temperature at the highest
peaks, so high ground trends colder. The result is clamped to 0..1.

Moisture. Its own decorrelated FBM simplex-smooth noise layer, 3 octaves, base
frequency 0.014, normalized to 0..1. Independent of elevation and temperature.

### 2.4 Biome lookup table

The starter biome set is seven categories: ocean, beach, plains, forest, desert,
tundra, mountain. Selection combines the three fields:

```
if elevation < 0.50            -> ocean       (below sea level)
elif elevation < 0.52          -> beach       (just above the waterline)
elif elevation >= 0.72         -> mountain    (high ground)
elif temperature < 0.25        -> tundra      (cold land, any moisture)
elif temperature > 0.60 and moisture < 0.35 -> desert   (hot and dry)
elif moisture > 0.55           -> forest      (wet, temperate or warm)
else                           -> plains      (the default open land)
```

The thresholds (`SEA_LEVEL`, `BEACH_LEVEL`, `MOUNTAIN_LEVEL`, and the
temperature and moisture cutoffs) are pinned constants in `src/macro_map.gd`.
Changing them changes every map, so they are part of the determinism contract
rather than CLI-tunable for M1.

### 2.5 Rendering and coloring

Each biome has a base color. Ocean cells are shaded by depth (deeper water
renders darker toward the abyss, lighter near the shore). Mountain cells are
lightened with height and gain a snow cap on the highest peaks. The rendered
map is saved as an RGB8 PNG via `Image.save_png`, which is deterministic for
identical pixel data.

### 2.6 JSON summary

Alongside the PNG, the generator writes a JSON summary with, at minimum, the
land fraction (0..1) and a biome distribution breakdown. Fields:

```
seed, width, height, total_tiles, land_tiles, ocean_tiles,
land_fraction, ocean_fraction,
biome_distribution_of_land,  # biome name -> fraction of land tiles (ocean excluded)

# Continent / landmass metrics (from the continent-mask layer).
continent_center_count,        # number of continent centers placed for this seed
land_component_count,          # total land connected components (any size)
significant_landmass_count,    # components at or above significant_landmass_min_size
significant_landmass_min_size, # the size cutoff for "significant" (cells)
largest_landmass_tiles,        # cell count of the largest landmass
largest_landmass_fraction,     # largest landmass as a fraction of total land
landmass_sizes                 # descending list of significant landmass sizes (cells)
```

The landmass metrics come from a connected-component analysis of the land
tiles (4-connectivity, flood fill). The analysis respects the east-west wrap:
columns 0 and width-1 are neighbors, while the north and south edges are not.
A land component count above 1 means the map has genuinely separate landmasses
(they are separated by ocean, since the only non-land tile is ocean). This is
how the continent-mask layer's isolation is measured, and
`test/test_landmass.gd` asserts that the default parameters yield several
distinct landmasses above a minimum size for the sample seeds.

`JSON.stringify` is called with key sorting on, so the keys are emitted in
alphabetical order regardless of insertion order. All fractions are rounded to
6 decimal places, so the JSON text is byte-stable across runs.

### 2.7 CLI invocation

Generate a map (from the repo root, after `tools/fetch_godot.sh`):

```
tools/godot/godot --headless --path . \
  --script res://src/generate_map.gd -- --seed=<N> --out=res://examples/map_seed<N>
```

The `--` separates Godot's own arguments from the script arguments. `--seed=<N>`
is an integer world seed. `--out=<prefix>` is an output path prefix; the
generator writes `<prefix>.png` and `<prefix>.json`. Run the determinism test:

```
tools/godot/godot --headless --path . --script res://test/test_determinism.gd
# or the wrapper that fetches Godot first:
tools/run_tests.sh
```

## 3. Three-layer persistence design (planned, M4)

Not implemented in M1. The world state is stored in three layers, queried
top-down so the cheapest layer answers when it can.

### 3.1 Layer (a): deterministic formula layer

No stored state. This is exactly what the macro map generator (and future
detail generators) compute from (seed, position). For any cell, the baseline
answer is recomputed on demand. Because it is a pure function, it costs zero
disk and is identical on every machine for a given seed. Save files never store
this layer.

### 3.2 Layer (b): delta / override layer

Records only cells that have diverged from the formula baseline. Data shape: a
sparse map keyed by cell coordinate, most naturally bucketed by chunk so that
loading a region loads one delta blob:

```
deltas: {
  chunk_key (for example "cx,cy"): {
    cell_key (local or global coordinate): <override payload>
  }
}
```

The override payload is whatever distinguishes the changed cell from its formula
value: a replaced tile or block id, a removed-tree flag, a dug-out marker, a
modified height. A cell absent from the delta layer means "ask the formula
layer." This keeps saves proportional to how much the player has changed, not to
how much world they have explored. Deltas live in the save file (one region file
per chunk bucket is a natural on-disk layout), never in the shipped game data.

Query order for a cell: check the delta layer first, and if there is no entry,
fall back to the formula layer.

### 3.3 Layer (c): entity layer

For things that are not derivable from position at all: inventory contents,
saved characters and their stats, quest and dialog state, placed objects that
carry their own identity and internal state. Unlike the delta layer, which is
keyed by world position and answers "what is at this cell," the entity layer is
keyed by entity id and answers "what is this thing and where is it now." An
entity can move, so its position is a property of the entity, not the key. The
entity layer is a serialized list or table of records, saved and loaded whole
(or streamed by region for entities that are spatially anchored).

The distinction in one line: the delta layer patches the deterministic world at
fixed positions, the entity layer stores objects whose existence and state are
not a function of position at all.

## 4. Origin-shifting plan (planned, M2 onward)

Not implemented in M1 (there is no walkable world yet). Single-precision floats
lose sub-unit resolution at large magnitudes, which shows up as visible jitter
in rendering and physics once the player is thousands of units from spawn.

Plan: keep the player near the numerical origin by periodically re-basing the
world origin. When the player crosses a threshold distance from the current
origin, subtract a shift vector from the player, the camera, and every active
rendered and physics object, moving the whole active scene back toward zero. The
player's logical world coordinate (a 64-bit or integer-plus-fraction quantity)
keeps accumulating, but the float coordinates handed to the renderer and physics
engine stay small. This is commonly called a floating origin or camera-relative
rendering. Chunk streaming (M3) integrates with this: chunk world positions are
tracked in the large logical coordinate space and converted to shifted local
coordinates when instanced.

## 5. Simulation/rendering module boundary

The world simulation and generation core must be strictly separated from
rendering and input. This is a hard rule, not just a style preference, so it
is worth naming the module split explicitly: generation and simulation code
lives under a `sim/` (or `core/`) directory tree, and rendering, camera, and
UI code lives under a separate `render/` (or `ui/`) directory tree. Code in
`sim/`/`core/` must have zero imports from `render/`/`ui/`, no dependency on
`Viewport`, `Camera3D`/`Camera2D`, or any UI node, and must run headless with
no display server, the same way `src/macro_map.gd` and
`test/test_determinism.gd` do today.

Rationale: local saves are the current persistence model through M4, but a
lab-hosted server backend, a continuous world simulation that clients connect
to over the network, is an explicit planned evolution targeted around the
fauna milestone (M5+). A server has no viewport, no camera, and no player
input; it only runs simulation and generation and streams results to clients.
If simulation code never depended on rendering or input in the first place,
lifting it onto a headless server process is a move of the `sim/` tree, not a
rewrite. Rendering and UI code call into `sim/`/`core/` (one-directional
dependency), never the reverse.

## 6. CI runner choice

The determinism workflow runs on `ubuntu-latest` (a GitHub-hosted runner) rather
than the sentania-labs self-hosted runners. The self-hosted runners do not have
Godot pre-installed, and this job needs to download the pinned Godot binary
fresh. A GitHub-hosted runner can do that with no runner provisioning changes.
The workflow caches the binary by pinned version to avoid re-downloading on
every run. All jobs are fork-gated per the sentania-labs standard so PR jobs
never run for forks.
