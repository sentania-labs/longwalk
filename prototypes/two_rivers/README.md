# Longwalk: Two Rivers region

A standalone Godot 4.3 art and navigation prototype covering 1024 by 1024 metres.
Nineteen buildings, three market stalls, eight field plots, four bridges, and a
wooded countryside surround a compact village. Thatched and slate buildings coexist.

Regime: software, under Scott's explicit local-prototype exception to full SDLC/CI.
Authorization: "Ok. So scale up the village with the feel with the two updated two
rivers pieces as inspiration, so a rather large map area." Area steering, verbatim:
"go with 1024x1024 meter". Existing prototypes and their packaged builds are retained.

Click open ground to walk. Shift-click runs to the destination. WASD pans relative
to the camera, Q/E rotates, minus zooms out and equals zooms in. Right-drag rotates
and tilts; mouse-wheel zooms. Space centers and follows the traveler. Manual panning
or clicking the region map turns following off. Camera controls expose follow,
edge pan and speed, elevation, zoom, angle lock and automatic orbit. Landmark buttons
frame the village, farms, and river crossings. R resets the view. Escape quits.

The run/walk speeds are prototype defaults, not a stamina or progression system.
Running skill, stamina efficiency, and constitution belong to the proposed play roadmap.
The map is finite authored scenery. It has no server, saves, interiors, NPC schedules,
or active ecosystem. Farm-border foliage/fences are decorative; buildings, village
back fences, trees and water constrain navigation. Bridges use a sampled deck profile
from their actual mesh. Foliage and the human model remain art placeholders.

Run from the repository root:

```sh
tools/godot/godot --headless --editor --path prototypes/two_rivers --import --quit
tools/godot/godot --path prototypes/two_rivers
```

Local scene check and screenshot capture:

```sh
xvfb-run -a tools/godot/godot --path prototypes/two_rivers \
  --audio-driver Dummy -- --capture-dir=/tmp/two-rivers-check
```

References and new building provenance live under reference/art-generation.
Eight new Meshy7 models cost 240 credits in total. The running animation comes free
from the previous character rig. Existing cottage, shrub, fence and firewood models
are reused. Terrain textures are generated art; the terrain control map is authored
data baked from fixed positions. All coordinate scattering is deterministic.

The shared-chat review produced reference/foundation-supplement.md and
reference/roadmap-proposal.md. These are proposals supplementing the foundation,
not silent replacements for protected architecture or constitution documents.

The next proposed milestone, conditional on the village playtest, is a Docker-hosted
authoritative server with two clients, reconnect, and one persistent world change.
