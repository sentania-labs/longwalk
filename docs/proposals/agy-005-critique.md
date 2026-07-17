# Round 005 Critique - agy-worker

## claude-worker

**Steelman:**
Claude's proposal is a masterclass in isolating the isometric complexity purely to the render side. By keeping the sim completely untouched and exploiting Godot's built-in `y_sort_enabled` via projected Y coordinates, it achieves perfect isometric depth sorting for free. It elegantly diagnoses the vibe gap as a method problem and proposes "carry-forward reference" plates to maintain style coherence without the rigidity of a single massive spritesheet. If carry-forward works as advertised, this is the most maintainable architecture. I concede that Claude's Y-sort architecture is right, and I will adopt it.

**Attack 1: Facing Count (4 instead of 8)**
- **What I attack:** Claude's decision to ship only 4 diagonal facings to save cost.
- **Whose proposal:** claude-worker
- **Why it is wrong/costly:** Our click-to-move and nav-grid paths frequently produce off-axis vectors (for example, long shallow paths moving straight East or West). With only 4 facings, an actor traveling East is forced to play a SE or NE walk cycle. Because the visual stride angle is locked to the diagonal, the character's feet will explicitly slide sideways across the ground (skating) perpendicular to their actual travel vector. The cost savings are a false economy because sideways skating completely shatters the "believable grounded character" requirement this round is designed to fix.
- **What should happen instead:** Ship 8 facings to support off-axis movement believably, as proposed by codex and agy.

**Attack 2: Generation Method (Plates via carry-forward)**
- **What I attack:** Using "carry-forward reference" plates to enforce coherence.
- **Whose proposal:** claude-worker
- **Why it is wrong/costly:** The failure mode here is category-handoff drift. Image generators treat references as strong suggestions, not rigid constraints. By the third plate, the exact roof pitch, the lighting vector, and the specific palette ramp will subtly drift. When a Plate C tree is placed next to a Plate A road, their lighting vectors will not perfectly match, resulting in the exact same collage effect we currently have. I concede that my "full-sheet" proposal suffers from "can't-regenerate-one-building rigidity," but paying the cost of rigid regeneration is better than shipping a drifted collage.
- **What should happen instead:** Force the model to solve lighting and palette for the entire scene in one shared context using full-sheet generation.

**Attack 3: Camera Ownership**
- **What I attack:** Claude claiming ownership of the camera drag-pan because it is part of the "render-side isometric spine".
- **Whose proposal:** claude-worker
- **Why it is wrong/costly:** This is an architectural overreach. The camera's state machine (`FOLLOW` vs `FOCUSED` vs `DRAG`) and input handling are interaction layers, not projection math. The only isometric dependency is the inverse picking math, which is just a helper function call. The rig's internal state transitions and velocity accumulation depend entirely on the round 004 `CameraRig2D` architecture.
- **What should happen instead:** The resident who wrote the rig (agy-worker) should own the drag-pan implementation, utilizing Claude's projection math for the picking inverse.

## codex-worker

**Steelman:**
Codex presents a highly disciplined, risk-managed pipeline. It smartly mitigates the correlated extraction failures of raw full-sheet generation by using a non-runtime "style board" to visually anchor subsequent smaller category sheets. It correctly champions 8 facings for off-axis believability, and outlines a rigorous, deterministic approach for flora animation and shadow generation that strictly respects the sim/render boundary.

**Attack 1: Generation Method (Style-board-led drift)**
- **What I attack:** Using a non-runtime "style board" to visually anchor one-by-one building generation.
- **Whose proposal:** codex-worker
- **Why it is wrong/costly:** Generating buildings "one-by-one" while staring at a style board guarantees category-handoff drift. The model will create something "in the style of" the board, but the precise perspective, roof angles, shadow densities, and pixel scales will vary between invocations. This is how you get buildings that do not look like they sit on the same street. I concede that my full-sheet approach has correlated extraction failures, but a style board cannot enforce strict pixel-level coherence across separate invocations.
- **What should happen instead:** Generate the buildings together in a single full-sheet pass to lock their relative scale, perspective, and lighting perfectly.

**Attack 2: Shadow Generation (Facade Shear)**
- **What I attack:** Baking cast shadows offline by shearing the building's 2D alpha mask.
- **Whose proposal:** codex-worker
- **Why it is wrong/costly:** This is mathematically wrong for an isometric sprite. The 2D sprite already contains the 3D roof projected upwards in screen space. If you shear that 2D image, the shadow of the roof will stretch from the roof's visual position, physically disconnecting it from where the roof actually is in 3D space. This creates broken, detached shadows. Decision 006 explicitly rejected runtime facade shears for this exact visual failure; baking it offline in python does not fix the math.
- **What should happen instead:** Use a secondary generated sheet specifically for shadow masks, or extract a pure black/alpha layer provided by the generator, as proposed by agy-worker.

**Attack 3: Walk Cycle Identity Drift**
- **What I attack:** Generating the 8-facing walk cycle as separate per-facing grids.
- **Whose proposal:** codex-worker
- **Why it is wrong/costly:** Generating 8 separate grids creates identity drift. The model will struggle to keep costume details, limb proportions, and exact scale perfectly aligned across 8 separate invocations. It will look like 8 slightly different characters walking.
- **What should happen instead:** Generate the entire 8xN walk cycle on a single coherent sheet so the model is forced to maintain the character's volume and identity across all angles simultaneously.
