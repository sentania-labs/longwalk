# Proposal: Round 007 Village Production

## APPROACH

**Art Production Method**
We will generate the village assets using a hybrid 3D-to-2D pipeline to ensure both isometric consistency and painterly texture. We will spend approximately 20-40 Meshy credits to generate 3D base models for 3-4 building variants (cottage, general store, blacksmith), a couple of tree variants, and key props (anvil, grindstone, fences). 

We will feed these meshes into the round-006 Blender headless render pipeline (`blender_pose_rig.py`). This guarantees the models are rendered perfectly to our isometric spine projection (decision 007/008) with uniform lighting and correct scale (`scale-contract`, 32*sqrt(6) px/m). To achieve the high-fidelity, mossy, painterly look of the spike, we will configure the Blender shader to use a stylized material (or apply a lightweight, automated Stable Diffusion img2img pass on the Blender renders if Blender shaders are insufficient).

**Village Composition & Layout**
We will retain the compositional model in `src/render/town/starter_town.gd` and `src/sim/town_layout.gd`. The layout will be defined by placing individual iso-rendered sprites for buildings and props onto the grid, rather than rendering one massive static scene. We will extend `TownLayout` to support a `PropPlacement` or treat trees/props as generic structures. This preserves our dynamic depth sorting (`_update_iso_display()`), physics footprint logic, and allows for rapid layout curation.

**Free/Disincorporated Camera**
In `src/render/town/starter_town.gd`, we will introduce a flag (or check GameState) to skip `_spawn_player()` entirely. We will modify `src/render/town/camera_rig_2d.gd` so that if `_player` is null upon setup, it defaults to `State.FREE` and initializes its position to the center of `_projected_bounds`. The existing pan/drag logic will naturally take over, providing the disincorporated free-cam with zero gutted code.

**Export-Safe Asset Story**
Authored art will live in `res://assets/art/town/` (a new directory strictly outside of any `.gdignore` tree). Godot will automatically generate `.import` files for these PNGs. Code in `starter_town.gd` will load them via standard `load("res://assets/art/town/...")`. To guarantee this cannot regress, we will add a static analysis check in `tools/run_tests.sh` that bans `Image.load` and `FileAccess.get_file_as_image()` for game assets. Furthermore, we will add an integration test that runs during CI to verify that a packaged PCK export successfully resolves these `.import` files.

**Round-006 Reuse**
- `scale-contract` + decision-010 render-scale math to size the Meshy/Blender exports.
- `blender_calibration.py` and `blender_pose_rig.py` to project the Meshy models directly to our exact isometric spine.
- The `acceptance-harness` to generate a side-by-side screenshot of the running game for the confusable-with-spike test.

**First-Buildable Milestone**
A Windows `.exe` export of the village featuring 4 buildings, 3 trees, and a few props placed via `town_layout.gd`. The scene is navigated via a free-cam (drag to pan), has no player character, and visually matches the spike's painterly isometric style and projection exactly.

## RISKS

- **Art Fidelity:** The biggest risk is that the Meshy -> Blender pipeline produces models that look too "clean" or "plasticky," missing the hand-painted, weathered charm of the spike. If the Blender shader isn't enough, introducing a Stable Diffusion img2img pass adds pipeline complexity and makes deterministic, reproducible asset generation harder. I would want to test a single building through this pipeline in the first hour to see if we can hit the bar.
- **Export Safety:** Relying on dynamic file loading during development can lead to silent export failures. The standard `load()` mitigates this, but we must ensure CI actually tests a packaged export (PCK) to catch these issues before they merge.
- **Depth Sorting & Footprints:** Props and trees may have footprints that don't fit neatly into the 1x1 or 2x2 grid cell contact sorting, which could lead to occlusion bugs when objects are clustered tightly.

## DIVISION-OF-LABOR CLAIM

I (agy) am best suited to own the **Art Production Pipeline** (Meshy -> Blender -> stylized render). My multimodal capabilities allow me to visually evaluate the generated assets directly against the spike image and tune the pipeline parameters, lighting, or prompts to match the style exactly.

Claude or Codex would be better suited to own the structural Godot wiring, specifically the export-safe asset enforcement, CI tests, and layout data structure extensions, as they excel at engine architecture and static analysis implementation.

## ROUGH ESTIMATE

- 1-2 days to dial in the Meshy+Blender pipeline and produce the first batch of assets (buildings, trees, props) that hit spike fidelity.
- 1 day to hook up the layout data, free-cam, and export checks.
- **Blow-up factor:** If Meshy struggles to produce buildings that match the specific proportions of the spike, or if the "painterly" look requires complex 2D overpainting that cannot be automated for a village scale, forcing a pivot to pure 2D generative approaches.
