# Composed Scene QA #004 (agy-worker)

**Verdict:** NOT-CONFUSABLE

**What Scott's eye would catch first:**
The hard pixel edges where building foundations meet the ground plane (especially the house on the far right and the large inn in the top center), completely lacking the blending flora and dirt buildup seen in the spike.

## D1: Object grounding/contact shadow
**PASS**
- The specific defect of the bright washed-out patch on the smithy props under the awning has been fixed. The ground and props (anvil, grindstone) under the awning now read as grounded and normally lit, properly shaded by the awning.
- Objects across the scene generally cast consistent drop shadows (e.g., the tree, the houses, the fences), providing a basic level of grounding.

## D2: Object-terrain worn transition
**TELL**
- The building foundations intersect the terrain with a hard pixel edge. For example, the foundation of the house on the far right, and the front foundation of the large inn in the top center, simply rest flat against the ground texture.
- They lack the blending weeds, small stones, or dirt buildup hugging the foundations that anchor the buildings in the spike, making them appear pasted onto the ground plane.

## D3: Flora integration/cutout edges
**TELL**
- The flora assets are not integrated into the ground plane. Specifically, the base of the sunflowers in the center and the yellow flower patch on the bottom right terminate with hard cutout edges against the dirt.
- They lack ambient occlusion or roots blending into the terrain, reinforcing the "pasted on" look rather than growing out of the ground.

## D4: Scene-level lighting coherence
**PASS**
- The scene-level lighting is coherent. All assets (the tree on the left, the houses, the smithy) receive light from the top-left and cast shadows to the bottom-right consistently.
- There are no glaring mismatches in contrast, saturation, or light direction across the composited sprites.
