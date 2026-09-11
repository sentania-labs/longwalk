# Longwalk: the hearth corner

A local Godot 4.3 art prototype: one slate-roof cottage, an oak, weathered
fencing, berry shrubs, stacked firewood, and a traveler, arranged two ways.
The camera stays rotatable and can tilt down near eye level.

This is software under Scott's explicit local-prototype exception to full
SDLC/CI. His build authorization: "okay - let's go". No PR, CI, deployment,
server implementation, or adoption into the main project is part of this work.

From the repository root:

```sh
tools/godot/godot --headless --editor --path prototypes/hearth_corner --import --quit
tools/godot/godot --path prototypes/hearth_corner
```

Left-click open ground to walk. Right-drag orbits and tilts. Move the pointer
into the edge zone to pan with a gradual start and stop. Right-click and
Center traveler now glide the view instead of jumping. Space centers the
traveler; Q/E turn 45 degrees. Scroll zooms. Camera controls expose edge-pan
enable/speed, elevation, zoom, angle lock, and automatic orbit. Reset restores
the original view. Courtyard and Lane-side reuse the same assets in two layouts.

Buildings remain exterior scenery. Navigation uses conservative prop footprints.
Shrubs are decorative; tree collision covers the trunk. There are no saves,
server, NPC behavior, or building interiors in this art experiment.

## Art source

The cottage, oak, fence and shrub image references were reused from the existing
Longwalk art experiments, then converted to full 3D with Meshy 7. The firewood
reference was generated with built-in image_gen, saved under reference/ together
with its manually written prompt. No asset relies on a source outside this folder.
Shallow generated shrub clusters are crossed into a three-dimensional foliage volume. The existing Meshy traveler from d5c8c1b is reused. A local pose adjustment lowers
upper and lower arms, relaxes the idle stance, and places the supporting foot on the ground; this is a
prototype correction to the older walk clip, not a newly authored animation set.

See reference/generation.json for task IDs, prompts, and credit accounting. The
five initial image-to-3D generations and one tree revision cost 180 credits total (balance 3000 to 2820). Models
are GLB, with 2K textures, matte materials, and bounded requested geometry.
No new dependency or engine version was introduced.

## Local verification

```sh
xvfb-run -a tools/godot/godot --path prototypes/hearth_corner \
  --audio-driver Dummy -- --capture-dir=/tmp/longwalk-hearth-check
```

This runs both layouts and captures eight angles plus the low character view.
It checks walk routes, arm posture, edge zones, and smooth recentering. Windows
exports need Scott's Windows playtest; the matching Linux artifact can be run
locally without an editor.
