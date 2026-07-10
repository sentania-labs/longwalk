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
scrolling map), NOT a sphere. There is a north edge and a south edge that do
not wrap. The map wraps only when you keep walking east or west.

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
