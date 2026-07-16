# src/legacy_procedural, parked runtime procedural world

This directory holds the M1/M2 runtime procedural planet generator and the
walkable 3D world that streamed from it. It is parked, not deleted: Scott's
direction as of 2026-07-15 changed longwalk from a runtime procedural
planet-scale exploration game to an isometric / top-down 2.5D persistent-world
RPG built on a finite, authored map. See CLAUDE.md and ARCHITECTURE.md for the
current direction, and ROADMAP.md for how M1/M2 map onto this parked code.

Nothing in this directory is wired into the active project. `project.godot`
points `run/main_scene` at a placeholder `scenes/main.tscn`, not at anything
here.

## What is here

- `macro_map.gd`, `generate_map.gd`: the deterministic macro planet map
  generator (elevation, temperature, moisture, biomes, continent-mask
  layer, cylindrical east-west wrap). A pure function of (seed, position),
  runs headless.
- `sim/`: the M2 simulation layer (terrain sampler, coastal spawn finder).
  Zero rendering dependency, runs headless.
- `render/`: the M2 walkable-world render layer (chunk streaming, a
  first/third-person `CharacterBody3D` controller, camera rig, water,
  day/night).
- `scenes/`: the M2 `main.tscn` and `player.tscn` that wired the render layer
  together.

The matching test suite is parked alongside it at
`test/legacy_procedural/`, runnable manually via
`tools/run_legacy_procedural_tests.sh`. It is not part of the CI gate
(`tools/run_tests.sh`) anymore.

## Why parked instead of deleted

Per Scott: "git will save what we might want." Two concrete reasons this code
may come back:

- The determinism model and cylindrical wrap here are a plausible starting
  point for an offline draft-map authoring tool: generate a candidate map
  once from a seed, then hand-curate and freeze it, rather than deriving the
  world live at runtime. If that tool gets built, it likely forks or reuses
  `macro_map.gd` rather than starting from scratch.
- The sim/render separation, determinism discipline, and world-topology rules
  demonstrated here (see ARCHITECTURE.md) remain load-bearing constraints for
  the new direction too; this code is a working reference for that pattern.

## Running it

Unchanged in spirit from before the pivot, just moved:

```
tools/godot/godot --headless --path . \
  --script res://src/legacy_procedural/generate_map.gd -- --seed=42 --out=res://examples/map_seed42

tools/run_legacy_procedural_tests.sh
```
