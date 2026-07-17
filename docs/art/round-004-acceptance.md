# Round 004 art acceptance artifacts

## Composition proof verdict

PASS for the rendering-model flip. `round-004-after.png` is a capture from the
real starter-town scene at the shipping 1280 by 720 viewport and default 1.0
camera zoom. It contains the actual traveller and four-frame atlas, the
traveller's contact shadow, grass-to-path transitions, a pack-derived cottage,
and separate trees, bushes, and flower patches under the scene's enabled
y-sort. The pack's 16 px grid is enlarged by an exact 8x to the 128 px world
tile, with nearest-neighbour filtering in preprocessing and Godot.

The proof supports adopting the fixed pixel-art model. It does not close
Scott's human acceptance gate for gait or overall art direction.

## Scott-facing artifacts

- `round-004-before.png`: legacy smooth-art baseline, captured through the same
  scene, traveller position, viewport, and camera.
- `round-004-after.png`: pack and nearest-neighbour result, also the composition
  proof.
- `round-004-walk-comparison.gif`: the governed four-frame longwalk down-facing
  cycle beside Shepardskin's CC0 three-frame orthogonal RPG walk reference. The
  common baseline makes stride length, contact frames, and vertical bounce
  directly visible. The longwalk frames were not regenerated or reselected.
