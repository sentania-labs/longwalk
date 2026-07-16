# longwalk

An isometric / top-down 2.5D persistent-world RPG built in Godot 4 (GDScript),
in the visual spirit of Warcraft 2, SimCity, and Theme Hospital, with an
Ultima Online feel: you play a person roaming a persistent world and
developing skills (hunting, boat-building, and similar). Windows is the
primary export target, and the project stays cross-platform-clean.

longwalk pivoted direction on 2026-07-15, away from a runtime procedural
planet-scale exploration game and toward a finite, authored map. The prior
M1 (macro planet map generator) and M2 (walkable 3D world streamed from it)
work is parked, not deleted, under `src/legacy_procedural/` (see that
directory's `README.md`). See [ROADMAP.md](ROADMAP.md) for the milestone
ladder, [CLAUDE.md](CLAUDE.md) for the load-bearing constraints, and
[ARCHITECTURE.md](ARCHITECTURE.md) for the full design.

The current milestone, "M3: starter-town prototype" (title screen, character
creation, a hand-authored starter town, a couple of scheduled NPCs, one
interactable shopkeeper), is in progress across several dispatches. This
dispatch delivered the docs pivot, the parking of the old code, and the AI
art pipeline scaffold; the starter-town scene work itself is not in yet.

## Quick start

Install the pinned Godot engine (downloaded, not committed):

```
tools/fetch_godot.sh
```

This installs Godot 4.3-stable into `tools/godot/`. The exact pinned version is
in `tools/godot/VERSION`.

Run the project (needs a display); it currently opens a placeholder scene,
since the starter town has not landed yet:

```
tools/godot/godot --path .
```

## Game art

All game art is AI-generated, not downloaded asset packs. See
[`tools/art/README.md`](tools/art/README.md) for the generation pipeline;
prompts and style config are committed so any asset is regenerable.

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

## Run the tests

```
tools/run_tests.sh
```

There are no active-path tests yet; the starter-town prototype work in a
later dispatch will add them. The parked M1/M2 procedural-world test suite
still runs headless and stays green, but only manually:

```
tools/run_legacy_procedural_tests.sh
```

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

## Sample maps (parked)

`examples/` contains committed sample maps (PNG plus JSON) from the parked
M1 procedural generator, for several seeds. See
`src/legacy_procedural/README.md` for how to regenerate them.

## Layout

- `src/legacy_procedural/`: the parked M1/M2 procedural planet generator and
  walkable 3D world (macro map generator, sim layer, render layer, scenes).
  Not wired into the active project. See its `README.md`.
- `scenes/`: the active runnable scenes. Currently just a placeholder
  `main.tscn` until the starter-town prototype lands.
- `tools/art/`: the AI art generation pipeline (prompts, style config,
  generation script, committed output).
- `test/legacy_procedural/`: the parked test suite matching
  `src/legacy_procedural/`, runnable via `tools/run_legacy_procedural_tests.sh`.
  Not part of the active CI gate.
- `tools/`: engine and export-template fetch scripts, test runner, pinned
  version.
- `examples/`: committed sample maps from the parked generator.
