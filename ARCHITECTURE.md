# ARCHITECTURE.md, longwalk

Design writeup for longwalk. This is a design document. See
[ROADMAP.md](ROADMAP.md) for the milestone ladder and
[CLAUDE.md](CLAUDE.md) for the load-bearing constraints.

No em-dashes are used anywhere in this repo, including this document.

## 0. Pivot notice (2026-07-15)

longwalk changed direction on 2026-07-15: from a runtime procedural
planet-scale exploration game to an isometric / top-down 2.5D
persistent-world RPG on a finite, authored map (in the visual spirit of
Warcraft 2, SimCity, and Theme Hospital, with an Ultima Online feel). Section
2 below describes the M1/M2 runtime procedural generator and walkable 3D
world as they were before the pivot; that code is parked, not deleted, under
`src/legacy_procedural/` (see that directory's `README.md`) and
`test/legacy_procedural/`. It is kept as a written record and as a plausible
starting point for an offline map-authoring tool, not as a description of the
active game. Section 2a describes the current direction. Sections 3 through 6
(persistence, origin shifting, sim/render boundary, CI runner choice) are
reframed for the new direction where the pivot changes them, and otherwise
still apply.

## 1. Engine and tooling

- Engine: Godot 4.3-stable (pinned in `tools/godot/VERSION`, exact build
  `4.3.stable.official.77dcf97d8`).
- The engine binary is not committed. `tools/fetch_godot.sh` downloads the
  pinned Linux x86_64 build from the official GitHub release and unpacks it into
  `tools/godot/`. The binary and a `tools/godot/godot` convenience symlink are
  gitignored.
- Simulation code and tests run headless with no display server, so the same
  commands work locally, in CI, and in future automation.

## 2. Parked: the runtime procedural macro planet map (pre-pivot)

Source (now parked, see `src/legacy_procedural/README.md`):
`src/legacy_procedural/macro_map.gd` (the `MacroMapGenerator` class) and
`src/legacy_procedural/generate_map.gd` (the headless CLI entry point).

Before the pivot, longwalk generated an entire wrapping planet live from a
seed: a macro map (elevation, temperature, moisture, a seven-biome lookup
table, a continent-mask layer that forced distinct ocean-separated
continents) as the authoritative low-resolution source of truth, with a
walkable 3D world streamed from it in local chunks. The generator was a pure
function of (seed, position): seeded `FastNoiseLite` instances keyed off the
world seed (elevation at `seed`, moisture at `seed + 1013`, temperature
perturbation at `seed + 2027`), continent lobes placed by a deterministic
position hash rather than any per-cell RNG, and an east-west cylindrical wrap
(the x axis mapped onto a circle and sampled with 3D noise) so the map
wrapped seamlessly with no seam at the edges. Running the generator twice
with the same seed produced byte-identical PNG and JSON output.

The full technical detail (noise parameters, the continent-mask lobe and
falloff math, the biome lookup thresholds, the JSON summary schema, the CLI
invocation) is preserved in git history at the commit before this pivot, and
in the parked source itself, which is still runnable headless
(`tools/run_legacy_procedural_tests.sh`). It is not repeated here since it no
longer describes the shipped game; consult the parked code and its README
directly if you need the exact numbers.

## 2a. Current direction: the authored map

The world is now a finite, authored map rather than an infinite procedurally
streamed one. The likely production path: generate a draft map once offline
(possibly reusing or forking the parked generator in section 2, since its
determinism model is still useful for reproducibly re-rolling a draft), then
hand-curate and freeze it into static game data that ships with the game.
Nothing about the map is computed at runtime.

Rendering moves from the parked first/third-person 3D `CharacterBody3D` world
to an isometric / top-down 2.5D view, tile- or region-based rather than
chunk-streamed across an unbounded plane. Exact rendering and tile
representation choices (tile size, isometric projection parameters, town
layout format) are not decided yet; they land with the starter-town prototype
work (see ROADMAP.md, "M3: starter-town prototype"). This section will be
filled in as that work lands.

Game art is AI-generated. See `tools/art/README.md` for the generation
pipeline: prompts and configuration are committed so art is regenerable, and
it is the source of truth for how to regenerate or extend the art set. Art is
not downloaded from asset packs.

### Ecology and fauna direction (future sim-layer scope)

The sim layer is growing toward an ecology system, not scripted spawners:
flora regrows over time unless a region is overharvested, and fauna hunt,
reproduce, and migrate as agents, modeled all the way down to something as
small as a fish, each a minimal independent agent rather than a hand-placed
encounter. This is not designed yet, this note only records the direction so
work that starts sooner, most immediately NPC schedules, is built in a way
that composes with it later (for example: NPCs and fauna both running as
sim-layer ticks on the same simulation clock, rather than NPCs being special-
cased outside whatever ecology system comes later).

## 3. Three-layer persistence design (planned, not yet implemented)

The world state is stored in three layers, queried top-down so the cheapest
layer answers when it can. This design predates the pivot but still applies;
only layer (a) changes in kind.

### 3.1 Layer (a): authored baseline layer

Before the pivot this was a "formula layer," computed from (seed, position)
with no stored state at all. After the pivot the map is authored and frozen
rather than regenerated at runtime, so this layer is now the shipped,
hand-curated map data (tile ids, terrain, static placed objects) read as
static game data. It still costs zero save-file disk and is identical on
every machine, since it ships with the game rather than being computed or
stored per player. Save files never store this layer.

### 3.2 Layer (b): delta / override layer

Records only cells that have diverged from the authored baseline. Data shape: a
sparse map keyed by cell coordinate, most naturally bucketed by chunk or region
so that loading an area loads one delta blob:

```
deltas: {
  region_key (for example "cx,cy"): {
    cell_key (local or global coordinate): <override payload>
  }
}
```

The override payload is whatever distinguishes the changed cell from its
baseline value: a replaced tile or object id, a removed-tree flag, a modified
resource-node state. A cell absent from the delta layer means "ask the
baseline layer." This keeps saves proportional to how much the player has
changed, not to how much world they have explored. Deltas live in the save
file (or in the server's persistent world state, see section 5), never in the
shipped game data.

Query order for a cell: check the delta layer first, and if there is no entry,
fall back to the baseline layer.

### 3.3 Layer (c): entity layer

For things that are not derivable from position at all: inventory contents,
saved characters and their stats and skills (hunting, boat-building, and
similar), quest and dialog state, NPC and fauna agent state, placed objects
that carry their own identity and internal state. Unlike the delta layer,
which is keyed by world position and answers "what is at this cell," the
entity layer is keyed by entity id and answers "what is this thing and where
is it now." An entity can move, so its position is a property of the entity,
not the key. The entity layer is a serialized list or table of records, saved
and loaded whole (or streamed by region for entities that are spatially
anchored).

The distinction in one line: the delta layer patches the authored world at
fixed positions, the entity layer stores objects whose existence and state are
not a function of position at all.

## 4. Origin-shifting plan (planned, revisit scope when the town/world scale is known)

Not implemented. Single-precision floats lose sub-unit resolution at large
magnitudes, which shows up as visible jitter in rendering and physics once a
player is thousands of units from the origin. This was written for the
parked large streamed 3D world; an isometric/top-down 2.5D authored map is
likely to be tile-addressed (integer tile coordinates) and much smaller in
extent than an unbounded procedural planet, which may make this concern
moot, or may not, depending on how large the authored world and its persistent
server-side simulation grow. Revisit once the town/world scale is decided
rather than assuming the original plan still applies as written.

The original plan, kept for reference: keep the player near the numerical
origin by periodically re-basing the world origin. When the player crosses a
threshold distance from the current origin, subtract a shift vector from the
player, the camera, and every active rendered and physics object, moving the
whole active scene back toward zero. The player's logical world coordinate (a
64-bit or integer-plus-fraction quantity) keeps accumulating, but the float
coordinates handed to the renderer and physics engine stay small. This is
commonly called a floating origin or camera-relative rendering.

## 5. Simulation/rendering module boundary

The world simulation and generation core must be strictly separated from
rendering and input. This is a hard rule, not just a style preference, so it
is worth naming the module split explicitly: generation and simulation code
lives under a `sim/` (or `core/`) directory tree, and rendering, camera, and
UI code lives under a separate `render/` (or `ui/`) directory tree. Code in
`sim/`/`core/` must have zero imports from `render/`/`ui/`, no dependency on
`Viewport`, `Camera3D`/`Camera2D`, or any UI node, and must run headless with
no display server, the same way the parked `src/legacy_procedural/macro_map.gd`
does today.

Rationale: local saves are the current persistence model, but a lab-hosted
server backend, a continuous world simulation that clients connect to over
the network, is an explicit planned evolution targeted around the
ecology/fauna milestone (see section 2a). A server has no viewport, no
camera, and no player input; it only runs simulation and streams results to
clients. If simulation code never depends on rendering or input in the first
place, lifting it onto a headless server process is a move of the `sim/`
tree, not a rewrite. Rendering and UI code call into `sim/`/`core/`
(one-directional dependency), never the reverse. NPC schedules (an upcoming
dispatch) are the first concrete sim-layer tick work under this rule.

## 6. CI runner choice

The headless test workflow runs on `ubuntu-latest` (a GitHub-hosted runner)
rather than the sentania-labs self-hosted runners. The self-hosted runners do
not have Godot pre-installed, and this job needs to download the pinned
Godot binary fresh. A GitHub-hosted runner can do that with no runner
provisioning changes. The workflow caches the binary by pinned version to
avoid re-downloading on every run. All jobs are fork-gated per the
sentania-labs standard so PR jobs never run for forks.

There are no active-path tests as of this pivot dispatch (the starter-town
prototype work in a later dispatch will add them); the parked
`test/legacy_procedural/` suite still runs headless and stays green, but only
manually via `tools/run_legacy_procedural_tests.sh`, not as part of the CI
gate.
