# Ground plate acceptance

The tileable-swatch approach failed its 8 by 8 zoom gate three times. The
paid source fields contain faint quasi-regular structure throughout their
images. Seam-only offset-and-heal processing could hide a boundary, but it
could not remove source-wide structure. Repeating either small swatch made
that structure conspicuous at gameplay zoom levels.

Decision 010 pre-authorized a bounded plate fallback for this outcome. The
district now uses `ground_grass_plate.png` and `ground_dirt_plate.png`, each
sampled once across the district at low or no repeat. The old ground tiles,
their tiling baker, and the 8 by 8 contact-sheet gate are retired.

## Plate production

Both plates preserve the complete 1024 by 1024 paid source field at native
resolution:

- `ground_grass_plate.png` is an unchanged copy of
  `.pka/round007/ground-source/source-grass.png`, nano-banana task
  `019f7414-c219-75c8-ac2e-dc6f33b3c97f`.
- `ground_dirt_plate.png` is an unchanged copy of
  `.pka/round007/ground-source/source-dirt.png`, nano-banana task
  `019f7415-90bb-78e0-a533-9b758d723b74`.

No crop was needed. Neither source has a corner vignette strong enough to
justify discarding paid pixels. No offset, seam healing, global flattening,
or other image processing was applied, preserving the organic painterly look.
`ground_warp.png` remains available to break up residual structure in plate
mode, and `shadow_decal.png` remains unchanged.

## Judgment

- Grass: ACCEPT as a bounded district plate. Its faint structure reads as
  organic detail when sampled once instead of as a repeated motif.
- Dirt: ACCEPT as a bounded district plate. Its subtle marks no longer form a
  repeated grid because the renderer does not tile the image 8 by 8.

The manifest and art test enforce `ground_plate` kind and exact 1024 by 1024
native dimensions for both assets.
