# CLAUDE.md, longwalk

Load-bearing architecture constraints for the longwalk project. Every
dispatch into this repo must honor these. This file is a summary. The full
design writeup lives in [ARCHITECTURE.md](ARCHITECTURE.md), and the milestone
ladder lives in [ROADMAP.md](ROADMAP.md).

longwalk is a procedural planet-scale exploration game built in Godot 4
(GDScript). Windows is the primary export target, but the project stays
cross-platform-clean: no Windows-only paths, no backslash path separators in
code, no platform-specific APIs, and no CRLF line-ending assumptions.

## Determinism (hard rule)

The world is a pure function of (seed, position). There is NO sequential or
stateful RNG in any placement decision. Every placement (terrain elevation,
temperature, moisture, biome, and later flora and entities) is computed by
sampling a value that depends only on the world seed and the integer
coordinates of the cell. Generation order and visit order can never change the
result.

The established pattern (see `src/macro_map.gd`) is seeded `FastNoiseLite`
instances keyed off the world seed. Each layer uses `world_seed + fixed_offset`
so the layers are decorrelated but still fully determined by the one seed.
Positions are turned into noise coordinates deterministically (see the
cylinder mapping below). Do not introduce `randi()`, `randf()`, `RandomNumber
Generator` with an unseeded or time-based seed, or any accumulator that depends
on iteration order.

Consequence and test: running the generator twice with the same seed produces
byte-identical PNG and JSON. This is asserted by `test/test_determinism.gd`,
which is what CI runs. Any change that breaks byte-for-byte reproducibility for
a fixed seed is a regression.

## Hierarchical multi-scale generation

The macro planet map (continents, elevation, temperature, moisture, biomes) is
the authoritative low-resolution source of truth. Local and chunk-level detail
layers (future milestones) generate on demand from the same seed and must agree
with what the macro map says at that location. A chunk that falls inside an
ocean cell on the macro map must generate as ocean, not land. Detail layers
refine the macro map, they never contradict it.

## World topology

The world is a flat plane wrapped east-west (cylindrical, like a horizontally
scrolling map) with sphere-consistent polar crossings at the north and south
edges. There is no true-sphere geometry anywhere; the flat map plus two rules
gives sphere semantics:

- East-west: the map wraps. Walking all the way around in x is one full loop.
- North-south: crossing the top edge at longitude x re-enters from the top
  edge at longitude (x + width/2) heading south, mirrored at the south edge.
  This is how crossing over a pole works on a real globe, NOT a torus wrap.

The polar traversal mechanic itself only becomes reachable when flight exists
(far future milestone), but the generator constraint that makes it seamless is
in place NOW: the top and bottom `polar_cap_rows()` rows (a per-seed,
era-scaled depth, see the hydrological eras section in ARCHITECTURE.md) are
uniform featureless ice (flat elevation, one biome), so the polar crossing
seam has nothing to mismatch. Terrain variation begins only below the cap band. A cap can sit over
polar ocean (sea ice, Arctic-style) or over a landmass that reaches the pole
(land ice, Antarctica-style); the underlying split is reported in the JSON
summary, but the surface stays uniform either way. Cap cells count as neither
land nor ocean in the stats and are excluded from landmass connected-component
analysis. `test/test_polar_caps.gd` asserts the cap-band uniformity per seed.

To keep noise seamless across the east-west wrap, the x axis is mapped onto a
circle and sampled with 3D noise: walking all the way around in x is one full
loop around the cylinder, so the column at x=0 and the column at x=width-1 are
neighbors with no seam. The y axis (north-south) is sampled linearly and does
not wrap. See `_sample_cylinder()` in `src/macro_map.gd`.

## Origin shifting (planned, not implemented in M1)

Float precision degrades far from the origin. Once there is a walkable world
(M2 onward), positions thousands of units from spawn will lose sub-unit
precision and cause jitter in rendering and physics. The plan is to periodically
re-base the world origin under the player and shift all rendered and physics
objects back toward zero (a floating-origin, also called camera-relative
rendering, approach). This is documented in ARCHITECTURE.md. It is NOT
implemented in M1 because there is no walkable world yet.

## Persistence design (documented only, not implemented in M1)

Three layers, described in full in ARCHITECTURE.md:

- (a) Formula layer: computed from (seed, position) with no stored state. This
  is what the macro map generator produces today.
- (b) Delta / override layer: records only the cells where the world has changed
  from the deterministic baseline (for example the player dug a hole or chopped
  a tree). Everything not in this layer falls back to the formula.
- (c) Entity layer: things that are not derivable from position at all
  (inventory items, saved characters, quest state).

Implementation of persistence is a later milestone (M4). Do not implement it
before then.

## Simulation/rendering separation (hard rule)

The world simulation and generation core must be strictly separated from
rendering and input. Generation and simulation code lives in its own module
tree and has zero dependencies on viewport, camera, or UI nodes. It must be
runnable headless.

Rationale: local saves are the current persistence model through M4, but a
lab-hosted server backend (a continuous world simulation that clients connect
to) is an explicit planned evolution, targeted around the fauna milestone
(M5+). This separation is what makes lifting the simulation onto a server a
move, not a rewrite.

## Style rule: no em-dashes

Do not use em-dashes anywhere. Not in code comments, not in docs, not in commit
messages. Use commas, periods, parentheses, or a plain hyphen instead. This is a
hard rule across the whole repo.

## Workspace conventions

- This bootstrap commit is the ONLY dispatch authorized to push directly to the
  default branch. Every dispatch after this one uses a feature branch plus a
  pull request.
- A Codex review gate must pass before any PR merges.
- CI is fork-gated per the sentania-labs standard: PR jobs run only for branches
  in this repo, never for forks. See `.github/workflows/ci.yml`.
- The default branch is `main`.
- The Godot engine version is pinned in `tools/godot/VERSION`. Use
  `tools/fetch_godot.sh` to install it. Do not commit the binary.
