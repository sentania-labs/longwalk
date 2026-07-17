# Proposal: Village Feel & Motion (Antigravity)

## 1. Approach

**1. Quality character animations (Walk Cycle):**
Generating a perfectly articulated 12-frame sheet in one prompt failed because the model loses track of left vs. right legs across rows. Instead of risking identity drift by generating 3 separate strips (which Codex rightly defeated in 001), we will use a **color-coding prompt hack** on a single 3x4 sheet. 
- We update the prompt to put a bright magenta boot on the left foot and a bright cyan boot on the right foot. This forces the model's attention mechanism to track the leading leg and differentiate the silhouettes. 
- In `process_assets.py`, we add a post-processing pass that finds magenta and cyan pixels and maps them back to the standard leather brown palette. This guarantees foot alternation without identity drift.

**2. Zoom control:**
- Map `zoom_in` and `zoom_out` in `project.godot` to Mouse Wheel Up/Down and +/- keys.
- Add a target zoom variable in `player_controller_2d.gd` (or the camera rig). Input events update the target zoom, clamped between a min and max.
- Use `lerp` in `_process` to smoothly interpolate the `Camera2D`'s actual zoom to the target, avoiding jarring snaps.

**2b. Click-to-move:**
- Map `move_click` in `project.godot` to Left Mouse Button.
- **Sim/Render separation:** `player_controller_2d.gd` detects the click, calls `get_global_mouse_position()`, and sends this coordinate to the sim layer (e.g., `GameState.set_player_target(pos)`). 
- In `src/sim/`, the player entity gains a `target_position`. During `_physics_process`, the sim calculates the vector to the target and moves the player at `SPEED`, stopping when the distance is negligible.
- A visual "click reticle" (a simple animated sprite) is spawned at the clicked location in the render layer to provide immediate feedback.

**3. Visual-feel pass:**
- Update `tools/art/style.md` and the environmental prompts to target the Warcraft 2 / Ultima Online aesthetic: richer, warmer palettes (golds, deep greens, rich browns) instead of "low-poly flat". 
- In `starter_town.gd`, add a `CanvasModulate` or `DirectionalLight2D` (if using normal maps later, otherwise CanvasModulate) to cast a warm, late-afternoon "golden hour" tint over the town, unifying the generated assets.

**Stretch - Flora:**
- Generate 2-3 tree variations and 1 bush variation matching the warm isometric style.
- Add them to `src/sim/town_layout.gd` as static entities.
- Ensure their origin (feet/roots) is correctly set in `process_assets.py` (e.g., pinning height or offset) so the player y-sorts cleanly behind and in front of them.

## 2. Risks

- **Color-coding artifacting:** The magenta/cyan boots might bleed lighting into the pants or ground, leaving weird colored halos after the script recolors them to brown. If I had one hour, I would run one `image_gen` with the colored boots and run a quick color-replace filter to see if the edges look clean at game scale.
- **Click-to-move pathing:** We have no navmesh. Click-to-move on a flat plane means the player will get stuck sliding against cottage walls if they click behind a building. This is acceptable for this milestone, but it will feel unpolished.
- **Camera Zoom origin:** If the camera is not properly centered on the player, zooming out might shift the screen in an unexpected direction.

## 3. Division-of-labor claim

I am best suited to own the **Click-to-move and Zoom control (Sim & Input layers)**. 
As the Gemini-family model, I am highly reliable at Godot coordinate math (screen vs. global coordinates for the mouse click) and strictly enforcing the sim/render layer separation. I can wire the input cleanly through to `src/sim/` without polluting it with viewport logic.

I recommend the **Codex resident** handles the art pipeline and walk sheet generation (the color-coding hack). They already own `tools/art/generate.sh` and have the most context on the prompt structure from their phase 2 defense.

## 4. Rough estimate

- **One to two sittings (1-2 days).** 
- The input/sim work (click-to-move and zoom) is a fast 2-hour job.
- The art generation and the `process_assets.py` recoloring script will take the bulk of the time. If the color-coding hack fails and we have to hand-author the frames or stitch them, that will blow the estimate up to a multi-day effort.
