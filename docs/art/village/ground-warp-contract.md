# Ground warp contract

`ground_warp.png` is a 256 by 256, single-channel R8 texture baked by
`tools/art/bake_ground_warp.gd` with Godot 4.3's `FastNoiseLite`.

- Named layout seed: `7007`
- Fixed ground-warp layer offset: `4109`
- Effective `FastNoiseLite.seed`: `11116`
- Noise: smooth simplex, frequency `0.035`, four-octave FBM, lacunarity `2.0`, gain `0.5`
- Sampling: output texel `(x, y)` samples noise at integer coordinate `(x, y)`
- Normalization: clamp `noise * 0.5 + 0.5` to `[0, 1]`, then encode as R8

Every texel is therefore a pure function of the named seed, fixed layer
offset, and integer coordinate. The baker has no stateful RNG, time seed,
accumulator, or iteration-order dependency.
