# CLAUDE.md, longwalk

Load-bearing architecture constraints for the longwalk project. Every
dispatch into this repo must honor these. This file is a summary. The full
design writeup lives in [ARCHITECTURE.md](ARCHITECTURE.md), and the milestone
ladder lives in [ROADMAP.md](ROADMAP.md).

longwalk is an isometric / top-down 2.5D persistent-world RPG built in Godot 4
(GDScript), in the visual spirit of Warcraft 2, SimCity, and Theme Hospital,
with an Ultima Online feel: the player is a person roaming a persistent world
and developing skills (hunting, boat-building, and similar). Windows is the
primary export target, but the project stays cross-platform-clean: no
Windows-only paths, no backslash path separators in code, no
platform-specific APIs, and no CRLF line-ending assumptions.

## Pivot notice (2026-07-15)

longwalk changed direction on 2026-07-15, away from a runtime procedural
planet-scale exploration game and toward a finite, authored map: possibly
generated once offline as a starting point, then hand-curated and frozen,
rather than derived live from a seed at runtime. The M1/M2 runtime procedural
generator and the walkable 3D world it streamed are parked, not deleted, under
`src/legacy_procedural/` (see that directory's README.md) and
`test/legacy_procedural/`. Nothing in those directories is wired into the
active project. Game art is AI-generated; see `tools/art/` for the generation
pipeline and prompts, not downloaded asset packs.

## Determinism (still load-bearing, now for the authoring path)

There is NO sequential or stateful RNG in any placement decision anywhere in
this codebase, including any offline map-authoring tool. If a draft map is
generated (in whole or in part) from a seed before being hand-curated, that
generation step must be a pure function of (seed, position): every value
sampled depends only on the world seed and the integer coordinates of the
cell, and generation or visit order can never change the result. This is no
longer a runtime requirement for the shipped game (the map is authored and
frozen, not regenerated on every play session), but it is what makes
regenerating or re-rolling a draft map for curation reproducible instead of a
one-off accident. The parked `src/legacy_procedural/macro_map.gd` demonstrates
the established pattern (seeded `FastNoiseLite` instances keyed off the world
seed, each layer at `world_seed + fixed_offset` so layers are decorrelated but
still fully determined by the one seed) and is the likely starting point if
this tooling gets built. Do not introduce `randi()`, `randf()`,
`RandomNumberGenerator` with an unseeded or time-based seed, or any
accumulator that depends on iteration order, anywhere generation logic is
reused or extended.

`test/legacy_procedural/test_determinism.gd` still asserts byte-identical
output for the parked generator; run it manually via
`tools/run_legacy_procedural_tests.sh` if you touch that code. It is not part
of the active CI gate (`tools/run_tests.sh`), since nothing in the active
project depends on it yet.

## World topology (parked, was a runtime requirement, may inform authoring)

The parked procedural world modeled a flat plane wrapped east-west
(cylindrical) with sphere-consistent polar crossings, so that a future flight
mechanic could cross a pole the way a real globe works, not a torus wrap. That
constraint no longer applies to the shipped game: the authored map is finite
and does not need to be a seamless cylinder. If the authoring tool reuses the
parked generator to produce a draft map, the cylindrical wrap logic in
`src/legacy_procedural/macro_map.gd` is still there and still correct, but the
final authored/curated map is not required to preserve wrap-seamlessness once
it is frozen and cropped to a finite play area.

## Ecology and fauna direction (future sim-layer scope, not designed yet)

The sim layer is growing toward an ecology system: flora regrows unless
overharvested, and fauna hunt, reproduce, and migrate, modeled all the way
down to something as small as a fish, each as a minimal agent. This is not
designed yet. It is recorded here so future dispatches (starting with NPC
schedules, which run as sim-layer ticks) build with this direction in mind.
See ROADMAP.md for how this supersedes the old M5 "fauna (deferred)" note.

## Persistence design (documented only, not implemented yet)

Three layers, described in full in ARCHITECTURE.md:

- (a) Authored baseline layer: the frozen, hand-curated map data (whatever its
  origin, hand-built or offline-generated-then-curated) ships as static game
  data. No runtime computation, no stored player state.
- (b) Delta / override layer: records only the cells where the world has
  changed from the authored baseline (for example the player dug a hole or
  chopped a tree). Everything not in this layer falls back to the baseline.
- (c) Entity layer: things that are not derivable from position at all
  (inventory items, saved characters, quest state).

Implementation of persistence is a later milestone. Do not implement it
before then.

## Simulation/rendering separation (hard rule)

The world simulation and generation core must be strictly separated from
rendering and input. Generation and simulation code lives in its own module
tree and has zero dependencies on viewport, camera, or UI nodes. It must be
runnable headless.

Rationale: local saves are the current persistence model, but a lab-hosted
server backend (a continuous world simulation that clients connect to) is an
explicit planned evolution, targeted around the ecology/fauna milestone. This
separation is what makes lifting the simulation onto a server a move, not a
rewrite. NPC schedules (an upcoming dispatch) run as sim-layer ticks, so this
constraint matters more now than it did under the old procedural-world plan,
not less.

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
