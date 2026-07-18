# Ground and Lanes Treatment Proposal

## 1. Approach
**Method: Splat-mapped Single Ground Plane via CanvasItem Shader (Hybrid)**

Instead of placing individual rigid tile sprites or maintaining a static generated plate, we render a single, continuous `Polygon2D` plane covering the entire village. A Godot `CanvasItem` shader applies the painterly textures, handles the organic blending, and introduces the wander. 

**Data Flow & Sim/Render Boundary:**
*   `src/sim/town_layout.gd` remains strictly viewport-free and texture-ignorant. It maintains the exact same discrete `GRASS` / `PATH` grid semantics.
*   In `village_render.gd::_build_ground()`, the render layer reads `_layout.ground` and constructs a small, deterministic Godot `Image` (e.g., 16x14 pixels, one pixel per cell), coloring cells based on the terrain type (e.g., Red channel for path weight).
*   This Image is loaded into an `ImageTexture` (the "blend mask") and passed to a new `ground_splat.gdshader` attached to the `Polygon2D`. 
*   The shader takes the blend mask along with `ground_grass.png` and `ground_lane.png` as repeating tile uniforms. 

**Wander and Blend:**
To make the paths organically wander (breaking the straight tile band), the shader applies a deterministic domain warp to the mask's UV coordinates before sampling. We will pass a pre-computed or CPU-generated `FastNoiseLite` texture (seeded deterministically by the layout coordinates) to the shader. The noise offsets the mask UV, making the path boundaries wander organically outside strict grid lines. The GPU's linear filtering of the small mask texture natively produces a smooth, painterly blend between grass and dirt.

**Contact Shadows:**
To ground objects and remove the floating feeling, we introduce a dedicated shadow pass. We add a `shadow_decal.png` (a soft, alpha-gradient black ellipse) to the manifest. In `_build_objects()`, we draw a shadow `Sprite2D` for each placement, scaled relative to its `footprint`. To prevent shadows from rendering over adjacent vertical objects, all shadows are drawn into a `_shadow_layer` node, strictly ordered above `_ground_layer` but below all depth-sorted vertical objects in `_world`.

## 2. Risks
*   **Texture Tiling Math:** `ground_grass.png` and `ground_lane.png` are currently 128x64 isometric diamond slices. Sampling them seamlessly as repeating textures across a continuous shader plane requires mapping screen coordinates back to isometric space within the shader, rather than a simple 2D repeating rect. If the math causes artifacting, we might have to pre-process the diamonds into rectangular seamless textures.
*   **Sim/Render Leakage (Visual vs Semantic mismatch):** Because the shader UV-warps the blend mask to make paths wander organically, the visual edge of the path will not strictly align with the `PATH` cell boundary in the sim. The noise amplitude must be tuned carefully so the path looks organic but doesn't visually misrepresent the sim's navigational cost (e.g., a player walking on what looks like a path shouldn't be charged a grass penalty).
*   **Determinism:** We must ensure the noise texture used for UV warping is 100% deterministic across platforms. Using a CPU-generated `FastNoiseLite` with a fixed seed to populate the noise texture avoids GPU-specific precision variances.
*   **Export Gate:** The `ImageTexture` generation happens dynamically in memory, so it doesn't violate the export gate. We must ensure `shadow_decal.png` and the `.gdshader` file are properly included in the resource paths.

## 3. Division-of-labor claim
I am best suited to own the structural Godot side of this approach: writing the `ground_splat.gdshader`, doing the isometric UV mapping math, wiring the `ImageTexture` data flow in `village_render.gd`, and implementing the `_shadow_layer` contact shadows.

If the isometric UV math over the existing diamond tiles proves too brittle, or if the tiles don't repeat seamlessly in the shader, a peer (Claude/Codex) with better tooling for image manipulation might be better suited to crop/generate rectangular tileable grass and dirt textures from the spike to replace the diamond PNGs.

## 4. Rough estimate
**Order of magnitude:** 1-2 days.
Writing the shader, plumbing the `ImageTexture`, and setting up the shadow layer is straightforward (3-5 hours). The majority of the time will be spent tuning the isometric UV sampling math to tile the diamond PNGs perfectly without seams, and tuning the noise warp amplitude so the wandering paths look exactly like the spike without deviating too far from the sim grid. If the diamond tiles refuse to tile cleanly in the shader, extracting new rectangular seamless tiles will add another half-day.
