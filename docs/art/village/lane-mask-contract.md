# Lane mask contract

The lane data textures are baked offline by `tools/art/bake_lane_mask.gd` from
the authored `TownLayout.lanes` geometry. Both are 256 by 224 pixels, which is
16 texels per 16 by 14 district cell.

- Named layout seed: `7007`
- Shoulder-warp layer offset: `6203` (effective seed `13210`)
- Density layer offset: `9341` (effective seed `16348`)
- Shoulder warp: smooth simplex FBM, frequency `0.055`, three octaves,
  amplitude `0.22` cell
- Density: smooth simplex FBM, frequency `0.021`, four octaves
- Shoulder width: `0.72` cell
- Shoulder-only smooth-minimum radius: `0.28` cell
- `lane_mask.png`: RG8, R is the unwarped protected core, G is cosmetic
  shoulder coverage
- `lane_density.png`: R8 independent low-frequency wear density
- `lane_mask.png` pre-upload `Image` byte SHA-256 (decision 012 narrowed
  half_widths, ~0.70 scale):
  `677c1829b876dd383cc9780f1f2f54c05dcd0e46e33ab379a07e4983e7c0c326`
- `lane_density.png` pre-upload `Image` byte SHA-256:
  `eb2996df775e53ee16a25a400bcb89a8580c6c7c71c9cd834dffde52d88e5fc6`

The core uses unwarped signed distance and is forced into coverage before the
density field exists. Shoulder warp and bounded smooth-minimum therefore
cannot reduce or bulge the protected core, and density cannot reduce it. Both
PNG imports are pinned to lossless mode with mipmaps disabled and numeric data
treated as non-sRGB.
