# Ground swatch acceptance

The two 512 by 512 swatches were made from unobstructed crops of
`docs/art/iso-five-asset-spike.png` with deterministic offset-and-heal. The
grass crop is source rectangle `(800, 36, 1152, 230)` and the dirt crop is
`(278, 365, 354, 455)`. Each crop is resized to 512 by 512, rolled by exactly
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

- Grass: FAIL. The healed seam is not the dominant defect, but the limited
  clean meadow crop repeats its distinctive tonal composition on both axes at
  every inspected zoom.
- Dirt: FAIL. A genuinely unobstructed trail area in the spike is only about
  76 by 90 source pixels. Enlarging it preserves painterly color but repeats
  its small composition conspicuously at every inspected zoom.

The offset-and-heal method preserves the organic source appearance and avoids
the rejected Fourier weave, but the spike does not contain enough clean,
high-resolution ground to produce a long-period swatch. A higher-resolution
painterly grass and dirt source image is required before offset-and-heal can
clear Decision 010's visual gate.
