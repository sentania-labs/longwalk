# Ground swatch acceptance

The two 512 by 512 swatches were made from the supervised paid source fields
`.pka/round007/ground-source/source-grass.png` and
`.pka/round007/ground-source/source-dirt.png` with deterministic
offset-and-heal. The grass crop is source rectangle `(256, 192, 768, 704)`
and the dirt crop is `(256, 256, 768, 768)`. Each crop is used at native
resolution, rolled by exactly
256 pixels on both axes, then healed only within the 96-pixel-wide central
seam cross. Healing clones fixed translations from the same organic crop,
using offsets `(137, 173)` for grass and `(151, 181)` for dirt, with a cubic
smoothstep feather. No RNG or iteration-dependent choice is used. Pixels
outside the seam cross are unchanged from the half-offset crop.

## Texel-density budget

The shader contract repeats one 512-pixel swatch per projected 128-pixel cell
width. At maximum 2x zoom, one repeat covers 256 screen pixels, so
`512 / 256 = 2.0` source texels per screen pixel. This exceeds the required
minimum of 1.0. The 0.5x and 1x densities are 8.0 and 4.0 source texels per
screen pixel.

`ground-swatch-contactsheet.png` shows each swatch tiled 8 by 8 at the actual
0.5x, 1x, and 2x display periods.

## Judgment

- Grass: FAIL. The source is high resolution and painterly, but the 8 by 8
  panels reveal a recurring horizontal tonal band and repeated bright texture
  groupings. The seam heal is not the dominant defect.
- Dirt: FAIL. The source field contains recurring stamped marks arranged on a
  fine grid. The grid is conspicuous at 0.5x and remains legible at 1x and 2x,
  so offset-and-heal cannot remove it without modifying pixels globally.

The offset-and-heal method preserves the source appearance and introduces no
new global structure, but it cannot remove regular structure already present
throughout a source while obeying the seam-only constraint. These sources do
not clear Decision 010's visual gate.
