# QA Report: Ground Treatment (agy-worker, pass 2)

**VERDICT: NOT-CONFUSABLE**

The shift from per-cell diamond tiles to a continuous shader-quad with district plates has successfully eliminated the checkerboard tile grid. The grass now reads as a continuous surface. However, the ground treatment still fails the confusability bar against the spike, primarily due to how the dirt lanes are shaped and blended. 

## Per-zoom ground assessment

* **0.5x (Macro structure):** The rigid, engineered geometry of the dirt lanes is glaringly obvious. They form perfect diagonal lines of uniform width, intersecting at sharp angles. The spike's paths meander organically with varying widths; the village lanes look like a mathematical mask.
* **1x (Mid-range):** The straightness of the lane edges remains the dominant tell. While the domain warp breaks up a perfect pixel-straight line, it looks exactly like what it is: a straight line with noise displacement applied. It does not feel organically worn. 
* **2x (Detail):** Up close, the transition between dirt and grass is a relatively hard edge (even if wavy). The spike features soft, varied fading where dirt patches gradually blend into the grass. The village dirt texture revealed by the mask looks uniformly solid, lacking the patchy, hand-painted variation of the spike's dirt trails.

## Ranked remaining ground gaps (NOT-CONFUSABLE)

1. **Path macro-shape (Rigid mask vs Organic flow):** The underlying lane mask is too geometric. The paths are straight, uniform-width bands with sharp intersections. To match the spike, the paths need irregular widths, meandering curves, and an organic flow rather than strict diagonal/orthogonal axes. The current edge warp is micro-noise, not macro-shaping.
2. **Transition blending (Hard noise-cut vs Soft fade):** The boundary between the dirt and grass plates is too distinct. The spike has a soft, gradual transition with patchy dirt fading into the grass. The current implementation relies on a hard mask edge (even with domain warp), missing the painted, worn-in blending.
3. **Path texture uniformity:** Because the dirt is a continuous plate revealed through a lane mask, the dirt inside the path lacks the localized patchiness and varying density seen in the spike's hand-painted trails. 

## Out of scope (already triaged)
* No PC/NPCs (known).
* Halo cutouts on sliced props (still present, e.g., on the signpost and bushes).
* Sparse composition (contact shadows are now present and improve grounding, but the layout remains strictly gridded).
