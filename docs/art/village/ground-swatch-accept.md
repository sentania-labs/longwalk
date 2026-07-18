# Ground swatch acceptance

The two 512 by 512 swatches were synthesized from unobstructed crops of
`docs/art/iso-five-asset-spike.png`. The baker retains each crop's Fourier
amplitudes and source-derived color mapping, then assigns coordinate-hashed
frequency phases. This yields genuinely periodic rectangular textures while
breaking up the spike crop's non-periodic composition motifs.

## Texel-density budget

The shader contract repeats one swatch per projected 128-pixel cell width.
At maximum 2x zoom, one repeat covers 256 screen pixels, so `512 / 256 = 2.0`
source texels per screen pixel. This exceeds the required minimum of 1.0.
The 0.5x and 1x densities are 8.0 and 4.0 source texels per screen pixel.

`ground-swatch-contactsheet.png` shows each swatch tiled 8 by 8 at the actual
0.5x, 1x, and 2x display periods.

## Judgment

- Grass: FAIL. Opposite boundaries are mathematically periodic and the texture
  remains crisp at 2x, but a recurring diagonal light-dark motif is visible at
  every inspected zoom.
- Dirt: FAIL. Opposite boundaries are mathematically periodic and the texture
  remains crisp at 2x, but a stronger recurring diagonal motif is visible at
  every inspected zoom.

The zero-credit frequency-domain synthesis therefore does not clear Decision
010's prerequisite. These rejected swatches remain as reproducible evidence of
the attempted method, not accepted shipping inputs. Per the dispatch, asset
production stops here pending orchestrator-supervised paid periodic generation.
