# Longwalk: the village lane

Local Godot 4.3 art study: three homes using two cottage shapes, meadow/path/leaf-soil
transitions, planted foundations, and a refreshed carpenter with real idle and walk clips.

Regime: software. Scott explicitly waived full SDLC/CI for local prototypes.
Build authorization, verbatim: "approved", for the proposed three-home lane,
ground transitions, cottage variation, and replacement idle/walk animations.
This standalone prototype preserves the earlier hearth corner for comparison.

Run from the repository root:

```sh
tools/godot/godot --headless --editor --path prototypes/village_lane --import --quit
tools/godot/godot --path prototypes/village_lane
```

Left-click open ground to walk. WASD pans relative to the camera; Q/E rotate
45 degrees. Minus zooms out and equals zooms in (hold to repeat). Right-drag
rotates and tilts. Move the pointer to
a screen edge to pan smoothly. Scroll zooms, Space centers the traveler, Q/E turn
45 degrees, R resets, Escape quits. Home buttons frame each cottage. Camera controls
expose elevation, zoom, edge-pan enable and speed, angle lock, and automatic orbit.

Buildings are exterior scenery with conservative navigation footprints. No interiors,
saves, server, or ecology are implemented in this presentation experiment.

The new cottage and character references and terrain atlas were generated with
built-in image generation. Terrain panels are cropped from that atlas. The shader
blends offset texture samples and position-based masks to soften repetition and
connect ground wear with the authored building and tree positions.
The cottage and character are Meshy 7 textured GLBs. Animation clips share one new
rig and crossfade between idle and walking. Planar hip travel is removed from clips
so click navigation controls position. No procedural arm-pose overrides are used.
Existing oak, fencing, shrub, firewood, and original cottage come from hearth_corner.
Reference provenance and credit accounting are in reference/generation.json.

Local visual verification:

```sh
xvfb-run -a tools/godot/godot --path prototypes/village_lane \
  --audio-driver Dummy -- --capture-dir=/tmp/longwalk-lane-check
```

The capture run checks routes to all three approaches, actual clip selection and
movement, smooth centering, and screen-edge panning. It saves four lane views,
an idle closeup, and six walking frames for visual inspection.
Windows requires Scott's playtest; the matching Linux export is run locally.
