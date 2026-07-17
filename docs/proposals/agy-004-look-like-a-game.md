# Proposal: Round 004 - Make it look like a game

## 1. Approach

**Asset Pack and Vibe (Requirements 2 and 3):**
I propose adopting the **Screaming Brain Studios Isometric packs** (specifically the Isometric Town, Overworld, and Floor packs) available on itch.io and OpenGameArt. These packs are 100% CC0 (Public Domain) and natively capture the 2.5D pre-rendered look of 90s isometric classics like Theme Hospital and SimCity. 
* **Flora:** The packs include abundant trees, bushes, and flowers, which we will place as static props via `town_layout.gd`, satisfying the hard flora requirement.
* **Vibe:** This fundamentally shifts the art direction from flat tiling to a rich, textured isometric world, matching the WC2/Theme Hospital reference vibe.

**Walk Cycle and Grounding (Requirements 1 and 7):**
* **Generation:** Per Scott's mandate, the codex seat will use the `$generate2dsprite` skill to generate the walk cycle, sticking to the decision 005 Option C topology (generating side first, with other rows hand-authored or prompted to match). We will heavily tune the prompt for explicit "exaggerated stride length" and "vertical bounce." 
* **Grounding and Shadow:** To satisfy the grounding requirement, we will enforce the anchor-drift QC check (max 0.05 std dev) from 004. We will add a small, semi-transparent black oval sprite as a child of the player, offset to the feet, acting as a permanent contact shadow to ground the character.

**Pathfinding (Requirement 4):**
* We will update the pure-function A* in `src/sim/nav_grid.gd` to use weighted traversal costs. `GroundTile.PATH` will have a cost of 1.0, while `GroundTile.GRASS` (and other off-road tiles) will have a cost of 3.0. This ensures the traveler naturally prefers roads, breaking away only when the destination forces it, without violating determinism.

**Right-Click Focus (Requirement 5):**
* I will add a new `focus_camera` action to `InputMap` bound to Right-Click.
* Since the camera is currently parented to the player, I will temporarily decouple its `global_position` from the player when right-click is held or clicked, lerping the camera to the mouse's world coordinates. Movement commands (click-to-move) will instantly snap the camera back to player-tracking mode.

**Conformant Building Shadows (Requirement 6):**
* Following the CorsixTH (Theme Hospital) technique, we will generate building shadows dynamically by duplicating the building sprite, tinting it black with partial transparency, and applying a shear/skew transform matrix (e.g., via a simple CanvasItem shader or Godot's built-in 2D transform) to project it along the ground plane.

## 2. Risks

* **Grid Projection Mismatch:** The Screaming Brain Studios assets use a strict 2:1 isometric projection. If our current grid logic in `src/sim/town_layout.gd` or the engine's TileMap assumes a top-down or non-isometric cell shape, we will have to rewrite the coordinate conversion math. This is the biggest risk to the schedule.
* **Shadow Sorting:** Skewing building sprites for shadows creates overlapping transparent geometry on the ground. Without a dedicated floor-shadow Y-sorting layer, shadows might render on top of the player or other props placed behind the building.
* **Camera Decoupling:** Detaching the camera from the player node to allow right-click panning could conflict with the zoom logic implemented in round 003, which assumed a strictly player-centered origin.

## 3. Division-of-labor claim

* **agy-worker (Me):** I claim the **Asset Pack Integration, Flora, and Right-Click Focus (Reqs 2, 3, 5)**. I proposed the CC0 Screaming Brain Studios pack and can execute the asset swap and flora placement. Furthermore, I owned the zoom and input controller slice in 003, making me the best fit to extend camera logic for right-click focus.
* **codex-worker:** Must own the **Walk Cycle and Grounding (Reqs 1, 7)**. Scott mandated they test the `$generate2dsprite` skill. They have the harness natively built for this and own the historical context of the art generation pipeline.
* **claude-worker:** Should own **Pathfinding and Building Shadows (Reqs 4, 6)**. Claude wrote the deterministic A* grid in round 003, making them the natural owner to implement road weights. The building shadow skew technique requires precise render-side math, which fits their analytical strengths.

## 4. Rough estimate

* **Estimate:** 12 to 16 hours. 
* **What would blow it up:** If the newly adopted isometric asset pack forces us to rewrite the foundational grid and collision math in `src/sim/` to support a new perspective angle, the time required could double. 
