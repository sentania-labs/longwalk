# Round 005 implementation slice: art generation + pipeline (codex-worker)

This is phase-3 IMPLEMENTATION of round 005. Deliberation is closed. Your
authority is **`docs/decisions/008-isometric-visual-identity.md`** on this
branch, signed 4-0. Read it in full before you write code. Implement it; do not
relitigate it.

You are on branch `codex/005-art-pipeline`, cut from the round branch
`round/005-isometric-art`. Commit your slice here. Do not push, do not open a PR
(doers never open PRs, per decision 004). Report your final commit SHA in your
output.

## Your slice, and only your slice

Per decision 008's division of labor, you own **art generation + the full art
pipeline**. claude owns the render spine (projection, y-sort, movement); agy owns
the camera. Keep their work out of your diff. In particular, do NOT edit
`src/render/iso/*`, `src/render/town/camera_rig_2d.gd`, or `project.godot`.

Deliverables (decision 008 sections 4, 5, 7 and the division-of-labor row):

1. **BOARD-LED generation (Q-A, 4-0).** A non-runtime dressed **style board** as
   the single visible coherence reference. Then compact **category sheets** where
   cell geometry is shared, with large/collision-sensitive **individual
   buildings** generated against that same board, and the **8-facing walk** as
   per-facing grids tied to one accepted neutral character master. NOT full-sheet
   generation (that was agy's proposal and was voted down 4-0). Regenerate-never-
   relaunder at category and per-facing granularity: no frame is ever chosen
   because it looks better in a direction.
2. **8 facings (converged, no ballot).** Per-facing walk grids. Frame-selection
   policy is blind code committed BEFORE final generation: quantize projected
   `atan2` motion to eight fixed 45deg sectors with a documented boundary
   convention, immutable facing ids, six-frame cycle advanced by accumulated
   distance traveled (not wall-clock), neutral frame at rest. Mirroring only if
   declared in the manifest before generation. (The runtime frame-SELECTION at
   play time is claude's render spine; you own the sheet layout, the manifest,
   and the generation-time facing policy that the sheet is built to.)
3. **NEW `tools/art/ingest_generated_sheet.py`** (create it; there is no
   `ingest_kenney_roguelike.py` to rename, it was dropped with the round-004 art
   slice). Manifest-driven: prompt provenance, grid geometry, cell roles, magenta
   key, per-cell ground-contact anchors, expected dims, output ids. It REJECTS
   missing provenance, wrong grid, edge-touch, empty cells, and undeclared
   runtime assets.
4. **Make `process_assets.py` and `build_player_walk.py` manifest-driven.** Drop
   hard-coded asset lists and the cardinal Option-C policy. The processor may
   normalize by declared feet/contact anchor but NEVER choose aesthetically
   preferred frames.
5. **OFFLINE-DERIVED shadows (Q-C, 4-0), with agy's constraint binding.** Derive
   contact + cast shadow masks deterministically from the cleaned accepted alpha
   under one shared fixed light vector, in `process_assets.py`. Each shadow is a
   pure function of the art it grounds. The processor MUST NOT naively shear the
   full iso sprite alpha: the cast source is the **ground-contact silhouette**
   (the bottom footprint slice of the mask at the contact line), projected along
   the fixed light vector on the ground plane; upward-projected roof pixels are
   EXCLUDED so no shadow begins detached at the roof's screen position (this is
   exactly the failure decision 006 rejected). Add a separate tighter
   contact-darkening pass so objects stay grounded even where a long cast shadow
   crosses a similar-valued road.
6. **Retarget `check_walk_sheet.py`** (and its test `test_check_walk_sheet.py`)
   for the iso 8-facing sheet.
7. **Author the walk-preview / before-after GIF producers fresh** (there is no
   `build_walk_comparison.py` to rename). These produce Scott's acceptance
   artifacts: the iso walk-cycle GIF and before/after vibe screenshots.

## Sprite-forge mandate (binds the codex seat specifically)

Scott's mandate: exercise `$generate2dsprite` / `$generate2dmap` in generation.
The retro must report whether those skills helped, so actually run them and note
the result. This is why generation lives with your seat.

## The manifest/anchor contract is frozen by claude

claude's render spine (dispatched before you) defines the ground-contact anchor
convention your generated sprites must satisfy: where the contact point sits in a
cell and how per-cell ground-contact anchors are expressed. Read claude's frozen
contract note and generate against it. **Do not invent a competing anchor
convention.** The exact contract location and signatures are pinned in the
CONTRACT section appended to this prompt below.

## De-risk: the five-asset composition spike FIRST, before a full town

Scott's visual acceptance gate is a taste gate no automated check substitutes
for. De-risk it by producing ONE building + the player + a contact shadow
composed in the real engine EARLY (the five-asset spike), as your first
acceptance artifact, rather than generating a full town and discovering the vibe
is wrong late. Produce that spike artifact and the walk-cycle GIF; the
orchestrator holds them for Scott's acceptance rather than you deciding the vibe.

## Gates

- `tools/run_tests.sh` must pass on your branch (Python pipeline tests included).
- No third-party asset pack appears in any merged result (decision 007). The
  reference folder is the bar and reference-only.
- Determinism holds: shadow derivation and any generation-time policy are pure
  functions of their inputs, no unseeded RNG, no iteration-order accumulator.
- No em-dashes anywhere, including commit messages (constitution, absolute).
- Every commit carries `Co-authored-by: Codex <codex@sentania.net>`.
- Image generation can be slow and is Scott-gated. Prioritize landing the
  pipeline code + manifests + the five-asset spike artifact. If full-town
  generation will not finish in your cap, ship the pipeline and the spike and
  note in your output exactly what art remains to generate, rather than blocking.

## Blocked

If genuinely blocked, write a BLOCKED marker on THIS branch per
`.team/blocked/README.md`, commit and push it, and report branch + marker path +
one sentence. The bar is high: large gets scoped down and shipped smaller with a
note on what you cut, not blocked. Do not end your turn on an intention.

## CONTRACT (claude's frozen render-spine interface)

Landed on this branch's base (round branch now includes claude's slice). Full
note: `docs/contracts/iso-projection-contract.md`. Executable surface:
`src/render/iso/projection.gd` (`IsoProjection`). The conventions YOUR sprites and
manifests must satisfy:

**Frozen 8-facing row order** (from `facing_octant(screen_motion)`; screen space
is y-down so `+y` is toward the camera / "south"). Generate the walk sheet rows in
EXACTLY this id order:

| id | direction | screen motion |
| --- | --- | --- |
| 0 | E  | `+x` |
| 1 | SE | down-right |
| 2 | S  | `+y` (toward camera) |
| 3 | SW | down-left |
| 4 | W  | `-x` |
| 5 | NW | up-left |
| 6 | N  | `-y` (away from camera) |
| 7 | NE | up-right |

Sectors center on each id direction, +/- 22.5deg. Six-frame cycle per row,
advanced by accumulated distance (runtime wiring lands with your atlas); neutral
frame at rest. Mirroring only if declared in your manifest before generation.

**Ground-contact anchor** (world objects anchored at their ground CONTACT point,
projected to screen, drawn UPWARD from it):

- **Actor:** contact is the `CharacterBody2D` origin (the feet); sprite drawn
  upward via `offset = (0, -80)`. The neutral character master and each walk frame
  must place the feet/contact at a declared, consistent per-cell anchor.
- **Building footprint:** contact is the center of the footprint's FRONT (max
  screen-Y) edge, one full footprint-height below the top-left origin cell. A
  generated iso building sprite must place its ground-contact line at this
  projected point, drawn upward from it. Declare each asset's per-cell
  ground-contact anchor in its manifest; `ingest_generated_sheet.py` validates it
  and `process_assets.py` may normalize by it. This anchor is what the
  OFFLINE-DERIVED shadow's ground-contact silhouette is sliced at.

Coordinate spaces: cell space (logical grid), world-pixel square space
(`TILE_SIZE`=128), screen iso space (`TILE_W`x`TILE_H`=128x64 diamond, 2:1). Do
not invent a competing anchor or facing convention; these are frozen.
