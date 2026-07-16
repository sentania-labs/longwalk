# ROADMAP.md, longwalk

Milestone ladder for longwalk. Each milestone builds on the constraints in
[CLAUDE.md](CLAUDE.md) and the design in [ARCHITECTURE.md](ARCHITECTURE.md).

## Pivot notice (2026-07-15)

longwalk changed direction on 2026-07-15: from a runtime procedural
planet-scale exploration game to an isometric / top-down 2.5D
persistent-world RPG on a finite, authored map. M1 and M2 below describe what
was actually delivered before the pivot; that code is parked, not deleted,
under `src/legacy_procedural/` and `test/legacy_procedural/` (see
`src/legacy_procedural/README.md`). M3 is redefined below to describe the
current direction's first prototype milestone; the old M3 ("chunked
streaming") and M4 ("persistence" against the procedural world) no longer
describe planned work as written and are superseded.

## M1: project scaffold and macro planet map generator (parked)

- Godot 4.3 project scaffold, headless-capable, cross-platform-clean.
- Deterministic macro planet map generator, runnable headless.
- Layered noise elevation, latitude-plus-noise temperature, noise moisture, and
  a seven-biome lookup table (ocean, beach, plains, forest, desert, tundra,
  mountain).
- East-west cylindrical wrap, verified seamless.
- Output: a rendered PNG map plus a JSON summary (land fraction and biome
  distribution).
- Determinism test asserting byte-identical PNG and JSON for a fixed seed.
- Sample maps committed under `examples/`.

Status: delivered, then parked at the 2026-07-15 pivot. See
`src/legacy_procedural/README.md`.

## M2: walkable chunk (parked)

- Heightmap-to-mesh terrain rendering for a single local area, sourced from the
  macro map so the local terrain agrees with the macro biome and elevation.
- Character controller: walk, run, swim, sleep.
- Switchable first-person and third-person camera.
- Began the origin-shifting work described in ARCHITECTURE.md.

Status: delivered as a 3D walkable world (sim layer: terrain sampler with
bilinear macro upsampling plus a local-detail noise pass, and a deterministic
coastal spawn finder; render layer: chunk streaming, a CharacterBody3D
controller with walk/run/swim/sleep, a first/third person camera, a sea-level
water plane, and a minimal day/night), then parked at the 2026-07-15 pivot
along with M1. The sim/render module separation demonstrated here remains the
pattern for all future milestones (see CLAUDE.md).

## M3: starter-town prototype (current milestone)

The first milestone under the new direction: prove out the isometric /
top-down 2.5D authored-world approach end to end with a small, hand-authored
starter town.

- Title screen.
- Character creation.
- A hand-authored starter town (finite, not streamed).
- 2 to 3 NPCs on simple schedules (sim-layer ticks, per the sim/render
  separation rule).
- One interactable shopkeeper.
- AI-generated art for the town and characters (see `tools/art/README.md`).

Scope note for dispatch sequencing: the dispatch that wrote this roadmap
entry originally (docs pivot, parking the old code, art pipeline scaffold)
built none of the above; it was the groundwork.

Status after the second dispatch (title screen, character creation, starter
town): delivered. `scenes/title_screen.tscn` (New Game / Quit; no Continue
option since there is no save system yet, that is M4 territory) flows into
`scenes/character_creation.tscn` (name entry plus a choice of three tunic
color presets) and lands in `scenes/starter_town.tscn`: a hand-authored
18x14 tile town (`src/sim/town_layout.gd`, zero RNG, pure data) with a
general store and two cottages, a path network, an invisible town boundary,
and 8-directional player movement with collision, using processed
AI-generated art (see `tools/art/README.md`). A `shopkeeper_plot` reserved
plot is marked in the layout data (walkable, no building sprite yet) for the
next dispatch. NPCs and the interactable shopkeeper are NOT built in this
dispatch; that is the following dispatch's job, using the reserved plot and
the sim/render separation these scenes already establish.

## M4 and beyond: not yet planned in detail

Persistence (the three-layer design in ARCHITECTURE.md, adapted for an
authored baseline instead of a formula layer), further town/world content,
and skill systems (hunting, boat-building, and similar) follow the
starter-town prototype. Not broken into milestones yet.

## Ecology and fauna direction (supersedes the old "M5 and beyond: fauna" note)

The sim layer is growing toward an ecology system: flora regrows unless
overharvested, and fauna hunt, reproduce, and migrate, modeled all the way
down to something as small as a fish, each as a minimal agent, rather than
scripted spawners. Not designed yet, recorded here only as the direction
future sim-layer work (starting with NPC schedules in M3) should keep in
mind. See ARCHITECTURE.md section 2a.
