# longwalk

A procedural planet-scale exploration game built in Godot 4 (GDScript). Windows
is the primary export target, and the project stays cross-platform-clean.

This repo is at milestone M1: a project scaffold plus a deterministic macro
planet map generator that runs headless and outputs a PNG map and a JSON
summary. See [ROADMAP.md](ROADMAP.md) for what comes next, [CLAUDE.md](CLAUDE.md)
for the load-bearing constraints, and [ARCHITECTURE.md](ARCHITECTURE.md) for the
full design.

## Quick start

Install the pinned Godot engine (downloaded, not committed):

```
tools/fetch_godot.sh
```

This installs Godot 4.3-stable into `tools/godot/`. The exact pinned version is
in `tools/godot/VERSION`.

## Generate a map

From the repo root:

```
tools/godot/godot --headless --path . \
  --script res://src/generate_map.gd -- --seed=42 --out=res://examples/map_seed42
```

- `--seed=<N>`: integer world seed.
- `--out=<prefix>`: output path prefix. Writes `<prefix>.png` and
  `<prefix>.json`.

The world is a pure function of (seed, position), so the same seed always
produces the same map, byte for byte.

## Run the tests

```
tools/run_tests.sh
```

This fetches Godot if needed and runs the determinism test headless. The test
asserts that two runs with the same seed produce byte-identical PNG and JSON,
that different seeds differ, and that the east-west wrap is seamless. This is the
exact command CI runs.

## Sample maps

`examples/` contains committed sample maps (PNG plus JSON) for several seeds.

## Layout

- `src/macro_map.gd`: the `MacroMapGenerator` class (noise layers, biome table,
  rendering).
- `src/generate_map.gd`: headless CLI entry point.
- `test/test_determinism.gd`: the determinism test CI runs.
- `tools/`: engine fetch script, test runner, pinned version.
- `examples/`: committed sample maps.
