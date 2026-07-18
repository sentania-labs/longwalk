# Ground PLATE sampling note (round 007, decision 010 PLATE fallback)

The tileable-swatch approach failed the 8x8 zoom gate three times. The last
failure was source-structural: the generative model injects quasi-regular
texture into any "seamless field", so no seam-only heal removes it, and that
faint structure reads as a repeat only under high-frequency TILING. Decision 010
pre-authorized the PLATE fallback 4-0. The shader-quad pipeline is unchanged; the
only thing that changed is the ground-texture SAMPLING FREQUENCY: the grass/dirt
painterly fields are now sampled ONCE across the district as a plate
(`paint_uv = cell / grid_size * plate_repeat`), not tiled per cell. Sampled once,
their structure is just texture detail, not a periodic tell.

## Repeat count

`plate_repeat = 1.0`: the plate covers the whole 16x14 district exactly once. No
tiling, so there is NO tile-boundary seam anywhere (UV stays in 0..1 and the
plate samplers are `repeat_disable`). Values above 1.0 re-tile the plate and can
reintroduce a faint seam (the paint UV is not warped, only the lane mask is), so
the default is the fewest possible repeats: one.

## Source texels per screen pixel

The plate is 1024x1024, sampled with `filter_linear_mipmap` + `textureGrad`.
Like every texture in this repo it imports with Godot's default settings (no
`.import` is committed anywhere in the project, and `project.godot` is a
protected path, so no project-wide mipmap default is set here), which means mips
are off and the sampler falls back to base-level linear today; the captures
below were rendered under exactly that default regime, so they match a clean
checkout. The `filter_linear_mipmap` declaration is future-proof: it uses a mip
chain the day one exists. Its U axis runs along the district's cell-x edge (16 cells,
projected length `sqrt(1024^2 + 512^2) ~= 1145 px` at 1x) and its V axis along the
cell-y edge (14 cells, `sqrt(896^2 + 448^2) ~= 1002 px` at 1x). Density scales
linearly with zoom:

| zoom | screen px along U / V | source texels/screen-px | read |
| ---- | --------------------- | ----------------------- | ---- |
| 0.5x | ~573 / ~501           | ~1.79 / ~2.04           | minified ~2x, clean on this low-frequency painterly field (see 0.5x capture) |
| 1x   | ~1145 / ~1002         | ~0.89 / ~1.02           | ~1:1, essentially native |
| 2x   | ~2290 / ~2004         | ~0.45 / ~0.51           | ~2 screen px per source texel, mild painterly softening, no aliasing |

At 2x each source texel covers roughly two screen pixels, so the field softens
slightly but stays painterly (see `village-inn-green-2x.png`); there is no repeat
structure and no seam to expose. If integration decides 2x is too soft, bumping
`plate_repeat` to ~2.0 restores ~1:1 density at 2x at the cost of tiling the plate
2x2 (four copies across the whole district, still far below the old 16x14 swatch
tiling); prefer leaving it at 1.0 unless QA flags softness.

## Provisional plates

`assets/village/ground_grass_plate.png` and `ground_dirt_plate.png` are, on this
branch, copies of the supervised paid painterly fields at
`.pka/round007/ground-source/source-{grass,dirt}.png` (1024x1024, provenance
generated). Integration swaps codex's real `ground_plate` assets over them and
re-runs this same honest gate. Captures here are representative because they use
the real paid fields, not flat placeholders.
