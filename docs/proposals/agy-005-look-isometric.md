# Proposal: Round 005 (Isometric Art & Camera)

## 1. Approach

This proposal addresses the five contested requirements for the round 005 visual identity rebuild:

**1. Generation method for coherent isometric sheets**
I propose **full-sheet coherent generation**. We will prompt the generation tools to output complete, grid-aligned spritesheets (e.g., an entire character's 8-facing walk cycle on one image, or a full village set). The vibe gap in previous attempts comes from the model losing context between invocations; a single-sheet generation enforces a shared palette, consistent lighting, and uniform proportions across all tiles/frames. 

**2. Isometric facing count + frame-selection policy**
We will target **8 facings** (N, NE, E, SE, S, SW, W, NW). While 4 diagonal facings is the minimum for isometric, 8 is the standard for UO/AoE-style fluidity and is necessary for a believable character moving off-axis. 
*Frame-selection policy*: Strict code-first slicing. The generator will be prompted to produce an 8xN grid. The ingest script will blindly slice row `i` for facing `i` and column `j` for frame `j`. We will not hand-pick frames; if the sheet is misaligned, we regenerate the sheet or refine the prompt, we do not launder the indices.

**3. Repurposing the ingest pipeline**
The generic pipeline (`process_assets.py`, `build_player_walk.py`, `build_walk_comparison.py`, `capture_art_acceptance.gd`) survives untouched as they operate on extracted frames. We will rename `ingest_kenney_roguelike.py` to `ingest_generated_sheet.py` and rewrite it to slice our AI-generated full-sheets based on a configured cell size (e.g., 64x64 or 128x128), outputting the individual frames into the structure the generic tools expect.

**4. Isometric shadows and the camera amendment**
*Shadows*: We will use a secondary generated sheet for shadow masks (or extract a pure black/alpha layer if the generator provides it), applying it identically to decision 006's approach but tailored to the isometric silhouettes.
*Camera picking*: The render-side picking will be amended. `screen_to_world` will apply the inverse isometric transform: `world_x = (screen_x / half_width + screen_y / half_height) / 2`, `world_y = (screen_y / half_height - screen_x / half_width) / 2`. 

**5. Camera: drag-pan**
I will rework the `CameraRig2D` from round 004. We will add a `pan_drag` action to `project.godot`'s input map bound to the Right Mouse Button. When `pan_drag` is held, `_input(event: InputEventMouseMotion)` will subtract `event.relative` from the camera's screen-space `global_position`. Dragging will immediately break any active FOLLOW focus. Click-to-recenter is parked for later.

## 2. Risks
- **Generation Alignment:** The biggest risk to the strict code-first slicing policy is the AI generator failing to respect a rigid grid. If the character drifts across frames, the blind slice will wobble. We might need a center-of-mass alignment step in `ingest_generated_sheet.py` to stabilize it, which complicates the "no laundering" rule.
- **Y-Sorting in Isometric:** Isometric depth sorting requires perfect origin placement at the contact point (the feet/base). If our generated assets have varying amounts of empty space at the bottom, the Y-sort will break.
- **Camera space vs World space:** Drag-panning is safe because we pan in screen space, but mapping the screen center back to a grid tile to see what we're looking at (e.g. for debug or future loading) requires the isometric math to be perfectly aligned with the visual tilemap.

## 3. Division-of-labor claim
- **agy-worker (Me):** I am best suited to own the **Camera drag-pan, the isometric picking amendment, and the ingest pipeline repurposing**. I wrote the round 004 camera rig, so I have the exact context needed to rework the state machine for drag-panning and update the picking math. I also have strong Python context for the ingest script rewrite.
- **codex-worker:** Best suited for **Sprite-forge generation**. Per the mandate, Codex has the `$generate2dsprite` skills and should lead the prompt engineering and iteration to produce the full-sheet coherent assets.
- **claude-worker:** Best suited for **Render-side integration**. Claude is strong on Godot node hierarchies and should wire up the Isometric TileMap, apply the shadow masks, and configure the Y-sort origins.

## 4. Rough estimate
- **Order of magnitude:** 1 to 2 days (calendar time).
- **What blows it up:** The AI generator simply cannot produce a 64-frame walk cycle on a strict grid. If we have to abandon full-sheet generation because the model refuses to keep the frames aligned, we fall back to per-asset generation and the time spent building a shared-palette/lighting harness will easily add 3-4 days.
