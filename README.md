# longwalk

A procedural planet-scale exploration game built in Godot 4 (GDScript). Windows
is the primary export target, and the project stays cross-platform-clean.

M1 delivered a project scaffold plus a deterministic macro planet map generator
that runs headless and outputs a PNG map and a JSON summary. M2 adds a walkable
3D world streamed from that macro map: you spawn on a coast, walk, run, swim, and
sleep. See [ROADMAP.md](ROADMAP.md) for the milestone ladder, [CLAUDE.md](CLAUDE.md)
for the load-bearing constraints, and [ARCHITECTURE.md](ARCHITECTURE.md) for the
full design.

## Quick start

Install the pinned Godot engine (downloaded, not committed):

```
tools/fetch_godot.sh
```

This installs Godot 4.3-stable into `tools/godot/`. The exact pinned version is
in `tools/godot/VERSION`.

## Play the walkable world (M2)

Run the game from the repo root (needs a display):

```
tools/godot/godot --path .
```

This opens a minimal menu where you enter a world seed and press Explore. To
skip the menu (or run a specific seed headlessly for scripting), pass the seed
on the command line:

```
tools/godot/godot --path . -- --seed=42
```

The world you walk is streamed from the same macro map the generator produces,
so land renders as land and ocean as ocean for that seed. Spawn is a
deterministic coastal point on the largest landmass for the seed.

### Controls

- Move: `W` `A` `S` `D`
- Sprint (run): hold `Shift`
- Jump / swim up: `Space`
- Swim: automatic when you are over water and at or below the surface
- Sleep (fade to black, advance the day/night clock to morning): `R`
- Toggle first-person / third-person camera: `C`
- Look: mouse
- Look with the keyboard instead of the mouse: yaw left/right with `Q` / `E`, pitch up/down with the `Up` / `Down` arrow keys
- Release / recapture the mouse cursor: `Esc`

## Windows playtest build

Every pull request into `main` runs a CI job that exports a Windows build and
uploads it as a downloadable artifact, so you can play the latest branch on
Windows without a local Godot setup.

To grab it:

1. Open the pull request on GitHub and click the Checks tab (or the "CI" run at
   the bottom of the PR).
2. Open the CI workflow run and scroll to the Artifacts section at the bottom of
   the run summary.
3. Download `longwalk-windows-playtest`. It unzips to `longwalk.exe`, a single
   self-contained executable (the game data is embedded in the exe). Double-click
   it to play.

Building the Windows export locally (needs a display only to play, not to
export) is documented under "Export the Windows build" below.

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

This fetches Godot if needed and runs the headless test suite: the M1 macro map
determinism test (byte-identical PNG and JSON for a seed, seamless east-west
wrap), the M2 sim determinism test (the terrain sampler and spawn finder are a
pure function of seed and position), and the M2 game smoke test (the world boots
and streams terrain sanely). This is the exact command CI runs.

## Export the Windows build

CI produces the Windows playtest artifact automatically (see above). To export
it yourself, first install the pinned Godot export templates (downloaded, not
committed), then export headless:

```
tools/fetch_export_templates.sh
tools/godot/godot --headless --import .
tools/godot/godot --headless --export-release "Windows Desktop" build/windows/longwalk.exe
```

`tools/fetch_export_templates.sh` downloads the pinned
`Godot_v<version>_export_templates.tpz` from the official Godot release and
installs the Windows x86_64 templates into
`~/.local/share/godot/export_templates/<version>/` (only the Windows templates,
since the full multi-platform archive is several gigabytes). Set
`GODOT_TEMPLATES_ROOT` to install them elsewhere. The export preset is
`export_presets.cfg` (`Windows Desktop`, `x86_64`, PCK embedded in the exe).

## Sample maps

`examples/` contains committed sample maps (PNG plus JSON) for several seeds.

## Layout

- `src/macro_map.gd`: the `MacroMapGenerator` class (noise layers, biome table,
  rendering).
- `src/generate_map.gd`: headless CLI entry point.
- `src/sim/`: headless simulation layer (terrain sampler, spawn finder). Zero
  rendering or input dependency.
- `src/render/`: the walkable-world render layer (terrain streaming, player,
  camera, water, day/night, game entry). Depends on `src/sim/`, never the
  reverse.
- `scenes/`: the runnable scenes (`main.tscn`, `player.tscn`).
- `test/`: the headless tests CI runs.
- `tools/`: engine and export-template fetch scripts, test runner, pinned
  version.
- `examples/`: committed sample maps.
