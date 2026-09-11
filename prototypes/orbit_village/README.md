# Longwalk camera study

Local, disposable Godot 4.3 prototype for comparing a fixed isometric angle
with a rotating orthographic camera. This is a separate project; it does not
change the main game's boot scene or simulation.

Regime: software. Scott explicitly waived the full SDLC/CI cycle for this
prototype: "since we are prototyping we can probably skip the full SLDC/CI
approach". Local execution and camera/movement checks are retained. No PR,
release, deployment, or production architecture adoption is implied.

From the repository root:

```sh
tools/godot/godot --editor --path prototypes/orbit_village --import --quit
tools/godot/godot --path prototypes/orbit_village
```

Right-drag rotates and tilts freely, down to 1 degree above horizontal.
Right-click without dragging centers the map on the clicked ground. Space or
Center traveler centers on the character. Q/E and the arrow buttons turn 45 degrees. The fixed
angle toggle holds the current angle. Slow automatic orbit provides a hands-off
comparison. Click open ground to walk. Wheel or slider zooms; the view-height
slider changes elevation. Zoom now reaches a close character view. Reset restores
the initial map center and view. Escape quits.

The scene uses a textured ground plane, two existing Meshy cottage instances,
one existing Meshy animated traveler, and simple fence geometry. There is no
server, persistence, building interior, or final art claim. Navigation is a
small presentation fixture with conservative building clearances. Foreground
buildings can obscure the traveler; rotate to regain sight. This intentionally
exposes an interaction that a future production camera would need to address.

For local rendered verification:

```sh
xvfb-run -a tools/godot/godot --path prototypes/orbit_village \
  --audio-driver Dummy -- --capture-dir=/tmp/longwalk-orbit-captures
```

This captures four camera angles and an eye-level view. Checks cover the building
detour, animated movement, fixed-angle lock, automatic orbit, reset, low-angle
tilt, right-click centering, left-click walking after centering, and distinguishing
an orbit drag from a right-click.

## Existing asset sources

No new paid generation was used. Meshy connectivity was verified with the
read-only balance tool. Cottage and character bytes were recovered from Git
commit `d5c8c1b`:

- `assets/art_src/pilot/cleaned/cottage.glb`
- `assets/art_src/pilot/cleaned/player_walk.glb`

Their historical generation record is
`d5c8c1b:assets/art_src/pilot/PROVENANCE.md`. These are the older pilot assets,
not new models derived from the richer village style board.

Ground texture bytes were copied from the existing local artifacts
`.pka/round007/ground-source/source-grass.png` and `source-dirt.png`.
These filenames establish their source location, not a fresh authorship or
license verification. Paths and noise are fixed functions of position.
