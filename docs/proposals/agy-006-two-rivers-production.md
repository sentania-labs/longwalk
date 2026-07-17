# Proposal: 3D Pre-rendered to 2D Sprites

## 1. Approach
I recommend **Path 3: 3D pre-rendered to 2D sprites**. 

This path uses Meshy (via its API) to generate 3D models and basic rigs, poses and animates them, and then uses an offline rendering step (a Godot 3D sub-viewport or a headless Blender Python script) to render these assets from the fixed isometric angle into 2D sprite sheets. Optionally, a light 2D AI pass (img2img) can stylize the final output to perfectly match the painterly vibe. 

**Why not pure-sprite (Path 1):** We have hit a ceiling on maintaining 3D invariants (like proper scale and 8-directional animated volume) in a purely 2D pipeline. The struggles with leg alternation and anchor drift in round 005 prove that pure 2D generation cannot reliably synthesize complex physical rotations without hallucinating structure.

**Why not real-time 3D (Path 2):** Real-time 3D throws away the bespoke 2D isometric rendering spine we just built, incurs high performance and workflow overhead, and risks slipping into a generic "indie low-poly 3D" aesthetic that fails the "painterly Two Rivers" vibe requirement.

**Pipeline Stages:**
1. **Generation:** Prompt Meshy for a 3D model (a cottage or character).
2. **Rigging/Animation:** Use Meshy's auto-rigging or apply standard Mixamo/Blender walk-cycle animations.
3. **Rendering:** Run an offline script (`tools/art/render_3d_to_iso.py` using Blender headless, or a Godot scene `src/render/tools/OfflineIsoRenderer.tscn`) to capture the 8 facings and light angles, outputting a traditional 2D sprite sheet.
4. **Stylization (Optional):** Run the raw sprite sheet through a low-strength img2img pass to apply the Two Rivers painterly brushstrokes.
5. **Ingest:** The result feeds directly into the existing `generate2dsprite` and `process_assets.py` pipeline.

**Attacking the Four Defects:**
1. **Walk-cycle animation:** Solved by construction. A skeletal 3D rig mathematically cannot drift its anchor or mix up its legs. The 8 facings will perfectly align.
2. **Building-to-player scale:** Solved by a shared 3D unit scale. A meter is a meter; characters and buildings are modeled in proportion before being rendered out to 2D at a fixed pixel-per-meter ratio.
3. **Fidelity gap:** The scene quality vs usable sprite gap is bridged because the 3D render provides perfect structural and lighting groundwork, while the final asset is still a 2D sprite that can receive a final stylization pass.
4. **Runtime bug "Instance base is null":** This is a separate engine logic bug where a null reference is accessed during runtime UI or process updates. I will independently trace the GDScript execution, find the dangling reference, and patch it in `src/`.

**Small Pilot Scope (Pre-authorized):**
We will generate one Two Rivers cottage and one neutral player model via Meshy. We will rig a basic walk cycle on the player. Both will be rendered through the offline isometric camera to 2D sprites. The acceptance test is rendering this pilot side-by-side in Godot against the current `iso-five-asset-spike.png` to confirm the scale is unified and the painterly vibe survives the transition.

## 2. Risks
- **Vibe Drift:** The pre-rendered 3D might look too "clean" or plastic, missing the cozy, hand-painted feel of the Two Rivers spike. We will know if we need a post-render stylization pass immediately after the pilot.
- **Pipeline Complexity:** We are introducing a 3D modeling and rigging step into a 2D game workflow. This requires tooling to automate the rendering (e.g. headless Blender).
- **Meshy Quality Control:** Meshy's generation might produce messy topology or fail to capture the specific architectural details of a thatched Emond's Field cottage. We mitigate this by using Meshy for volume and lighting, and relying on 2D for the final texture read.
- **First-hour question:** I would spend the first hour manually running one Meshy 3D generation through a test Godot/Blender isometric camera to measure exactly how "plastic" it looks before any img2img stylization, which tells us how heavy our 2D post-processing needs to be.

## 3. Division-of-labor claim
I (Antigravity worker) am best suited to own the **3D-to-2D pipeline tooling and API integration**. Building a robust Python script to hit the Meshy API, orchestrate the download, and automate the headless rendering of the 3D model into an isometric 2D sprite sheet plays directly to my strengths in systems integration and tooling.

I will also fast-lane the **"Instance base is null" runtime bug fix**.

Because the Codex seat carries the sprite-forge mandate and has strong 2D generation context, Codex should own the **post-render stylization and final ingest**, taking the raw 3D renders I produce and ensuring they match the painterly Two Rivers spike fidelity. 

## 4. Rough estimate
- Meshy API integration and baseline 3D generation script: 4 hours
- Offline 3D-to-2D isometric rendering tool (Blender or Godot-based): 6 hours
- Null reference bug fix: 1 hour
- Pilot iteration and review: 5 hours
**Total:** ~16 hours (2 working days)
