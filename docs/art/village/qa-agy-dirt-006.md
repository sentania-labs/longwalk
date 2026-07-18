# Multimodal QA Pass 6: Dirt-Surface Fidelity vs Spike

**Verdict:** NOT-CONFUSABLE

## Resolved Items (Pass 5 Tells)

1. **High Contrast / Muddy Tone:** CLOSED. At all zooms, the broad dark, smeary muddy patches are gone. The dirt plate now successfully reads as a dry, dusty, low-contrast tan with crisp speckles, closely matching the spike's texture and tone.
2. **Visible Tiling / Repetition:** IMPROVED-BUT-PRESENT. At 1x and 2x, the contrast of the mid-band motifs has been attenuated, but distinct rock clusters (specifically a prominent brown rock flanked by grey stones) still visibly repeat identically across the paths and intersections (clearly visible on the bottom-left, right, and top-left branches in the raw ground renders).
3. **Grid Seams:** CLOSED. At 1x and 2x, the straight-edge luminance seams across the paths and above the small blacksmith building are completely gone. The dirt/grass transitions are now organic and wavy, with no grid boundaries cutting the earth.

## New Tells (Introduced by Re-tune)

- None. The lifted fine-band frequency introduces crisp speckling that matches the spike's dry dust, without introducing synthetic digital noise.

## Pass 4 Regression Check

- **Flat Dirt Core:** PASS (No regression). The core remains rich with fine earthy speckle and does not read as visually dead flat or plastic.
- **Retinted Grass Morphology:** PASS (No regression). The dirt shoulders remain earthy and pebbly.
- **Aliasing / Shimmer / Synthetic Noise:** PASS (No regression). At 0.5x, comparing the pans shows the fine speckle remains stable under the grass; there is no digital static crawl.

## Remediation

- **Dominant remaining tell:** Tiling / rock-cluster repetition. The identical cloned rock clusters break the hand-painted illusion of the spike.
- **Remediation direction:** Further winsorize or clamp the mid-band outliers (the distinct prominent rocks) in the plate baking step (`tools/art/bake_dirt_detail.gd`). Tightening the outlier clamp (e.g., from +/- 2.5 sigma to a tighter threshold) should flatten the recognizable repeating rock motifs into the uniform pebbly dirt floor, eliminating the clone-stamp effect without requiring a new paid generation.
