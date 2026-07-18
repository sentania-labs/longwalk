# Multimodal QA Pass 5: Dirt-Surface Fidelity vs Spike

**Verdict:** NOT-CONFUSABLE

## Resolved Items (Pass 4 Tells)

1. **Flat Dirt Core:** CLOSED. The core clearing no longer reads as visually dead flat. It clearly samples a rich dirt plate with earthy structure and gravel, eliminating the stark contrast between the textured shoulders and flat core.
2. **Retinted Grass Morphology:** CLOSED. The shoulders now correctly read as earthy and pebbly rather than retinted grass, as the dirt plate's own luminance provides the substrate instead of the grass tufts.
3. **Aliasing / Shimmer / Synthetic Noise:** CLOSED. At 0.5x, comparing the pans shows the high-frequency noise has been successfully softened. The dirt sits stably under the grass shimmer ceiling, and the digital static crawl is gone.

## New Tells (Introduced by Re-tune)

1. **High Contrast / Muddy Tone (Dominant)** - Visible at all zooms
   While the dirt now has structure, the contrast of the plate is too high and the shadow values are too dark compared to the spike. The spike dirt reads as a dry, dusty, low-contrast tan with crisp speckles. The new dirt plate has broad, dark, smeary patches that make it look like wet, chunky river mud rather than a dry, worn path.
2. **Visible Tiling / Repetition** - Visible at 1x, 2x
   Because the new dirt plate is rich and has very distinct, high-contrast rocks (e.g., specific prominent grey and brown stones), the tiling repeats these identical rock clusters noticeably across the paths and intersections (especially obvious in `ground-1x` and `ground-2x`). This breaks the illusion of a unique, hand-painted scene.
3. **Grid Seams** - Visible at 1x, 2x
   There are faint but visible straight-edge grid boundaries (tile seams) across the dirt paths where the texture or luminosity does not perfectly match across tiles (e.g., visible above the small blacksmith building in `village-inn-green-2x.png`), abruptly interrupting the organic flow of the earth.

## Remediation

- **Tone/Contrast:** Flatten the contrast of the dirt plate and lift the dark values to match the dry, dusty tan of the spike. Reduce the "wet mud" look by making the large tonal drifts more subtle.
- **Repetition/Seams:** With a higher-detail plate, introduce rotation, macro-variation, or a secondary noise mask to break up the recognizable repeating rock clusters. Ensure tile blending completely eliminates straight-edge luminosity seams.
