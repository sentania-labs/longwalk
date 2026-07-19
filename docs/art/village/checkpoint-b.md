# Checkpoint B: the grounded-building demo tile

Decision 018 section 5. The smallest falsifiable proof that "built on the ground"
is a RULE the system derives, not a patch painted per scene: ONE 32x32-cell tile
rendered from TWO sim snapshots of IDENTICAL geometry + seed, differing only in
state and time (age-1 low-use vs age-40 high-use). The ground responds, the field
stays a field, and the door/lane stay clean, because the INPUTS differ, not
because a different code path or a painted patch was used.

## What is in the tile

- One cottage (5x4 footprint), door on the south (lane-facing) edge, garden flank
  west, service flank east.
- A short lane running east-west below the cottage, with a compacted door
  approach from the door to the lane.
- An authored sunflower field (upper-right): a warm dark cultivated-soil bed,
  coherent clumps / short staggered rows, soft coverage-broken edges, a clean
  crop-free access corridor opening toward the lane, and NO crops in the yard or
  the travel core. The spike shows no field, so this grammar is the team's
  authored contribution (spec Part B).
- A wild edge (top + left border): dense mixed tufts, bushes, and berries.
- Yard: the quiet open grass between them.

## The three bands + evolution (the actual proof)

Around every footprint the kernel derives, per texel, the spec Part A stack:
a contact seam (a thin dark toe hugging the stone at ~0.37x of local ground
luminance), an altered-ground apron (feature-relative width, per-face adjacency:
compressed clean on the door/lane face, wide and planted on the garden flank,
bare on the service flank), and a concave coverage-based recovery back to open
ground. Precedence is resolved PER SAMPLE (footprint > lane/access >
foundation-apron > yard > field/wild), not a single edge enum.

`age`, `traffic`, and `disturbance` parameterize the band shape and the derived
foundation planting. Compare the two captures: the age-40 tile has a wider,
darker apron and a planted west flank; the age-1 tile has a narrow apron and bare
corners. Same geometry, same seed, different state.

## Files

- `src/render/town/composition_kernel.gd` - pure, headless-capable derivation
  kernel + visual policy. Edge-oriented SDFs, per-sample precedence, clamped-ratio
  darkening, feature-relative apron, positional-hash flora scatter with canonical
  tuple conflict resolution. Generalizes decision-016 `bake_footprint_field.gd` /
  `bake_lane_mask.gd` and subsumes decision-017 foundation vegetation onto one
  shared derived-instance contract.
- `src/render/town/composition_tile_renderer.gd` - render-side consumption:
  composites the stylized cottage and flora onto the derived ground raster.
- `tools/art/bake_checkpoint_b.gd` - the offline bake + byte-difference
  assertion. Builds the in-tool literal snapshot (no `src/sim/` dependency),
  renders the two states, emits the captures, and asserts (a) unchanged inputs
  are byte-identical and (b) the two states are observably different, plus the
  field-grammar invariants. Exits nonzero on failure.
- `tools/art/checkpoint_b.sh` - wrapper (fetches Godot, runs the bake).

## Run

    tools/art/checkpoint_b.sh

or directly:

    tools/godot/godot --headless --path . --script tools/art/bake_checkpoint_b.gd

Captures land in `tools/art/out/checkpoint_b/`:
`tile_young_age1.png`, `tile_mature_age40.png`,
`compare_young_vs_mature.png` (young left / cool tag, mature right / warm tag),
`field_zone_legend.png` (field outline + access-gap markers).

## Scope and divergence (for orchestrator / codex reconciliation)

Checkpoint B is OFFLINE: headless CPU derivation, no viewport, no runtime path,
no persistence store. `age`/`traffic`/`disturbance` are explicit literal
arguments and the sim-shaped snapshot is an in-tool literal fixture; there is NO
`src/sim/` change (that is codex's gated full-milestone slice).

Divergence from decision 018's channel contract, deliberate for the offline tile:
this kernel derives the FINAL ground RGBA in ground space rather than emitting
codex's two response textures consumed by `ground.gdshader`, because there is no
shader/viewport offline and the screen-space seam reconstruction (the 1-2px
floor) does not apply. The per-sample precedence, edge-oriented SDFs,
clamped-ratio darkening, feature-relative apron, and positional-hash scatter all
match section 2; codex's channel split can wrap this kernel without changing the
policy. The flora and cottage marks are drawn stylized-procedural (colored from
the team's authored palette) rather than stamped from the 1024x1024 generation
kits, which are building/flora clusters, not single field sunflowers; the offline
proof is about the ground response and the field grammar, not the building art.
