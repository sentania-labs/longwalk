---
reviewed_branch: codex/007-lane-impl
reviewed_sha: 560b657591bdd5a429cd0a974b694ddc3ab6c028
reviewed_by: claude-worker
authored_by: codex-worker
timestamp: 2026-07-18T08:41:02Z
tests_run: tools/run_tests.sh
result: signed-off
---

Layer-1 peer review of codex's foundational lane-geometry slice for
decision 011 (signed 4-0). I ran `bash tools/run_tests.sh` in this worktree at
the reviewed SHA: exit 0, every suite passed, including all 40 village-render
checks.

## Sim contract (`src/sim/town_layout.gd`)

- `LanePath` is texture-free and viewport-free: `points` /`half_widths` only,
  and the file carries no Viewport/Camera/UI/Sprite reference (grep clean, sole
  "Viewport" hit is the headless-guarantee comment). Sim stays headless-runnable.
- The straight-X fill (`lane_y = 8` / `lane_x = 8` across the full district) is
  gone. Lanes are three hand-authored `PackedVector2Array` waypoint + width
  literals. No `randi`/`randf`/RNG/seed participates in the geometry: fully
  deterministic authored data, matching the 2026-07-15 pivot and the critique
  consensus that the meander is authored, not noise-driven.
- PATH is DERIVED, not authored: `_rasterize_lanes` walks every cell and marks
  PATH by conservative cell-square intersection (`_cell_square_intersects_lane`
  subdivides each segment 16x and tests `_segment_rect_distance <= maxf(width)`),
  not center-in-halfwidth. Blocking-footprint cells are skipped first, so PATH
  never lands under a blocker. Tests confirm connectivity (all approaches +
  entrances route to the junction) and no PATH under blocking footprints.

## Offline bake (`tools/art/bake_lane_mask.gd`) + committed masks

- Pure function of (fixed seed, integer texel, authored geometry): FastNoiseLite
  keyed off `LAYOUT_SEED + offset` per layer (7007 + 6203 shoulder, 7007 + 9341
  density), same established pattern as `bake_ground_warp.gd`. No unseeded/time RNG.
- Protected core is warp-EXEMPT: `core` derives from the UNWARPED signed distance
  (`<= 0.0`); warp and smin apply only to `shoulder_distance`; `coverage =
  maxf(core, coverage)` so neither warp, smin, nor the separate density channel
  can reduce or bulge the core. The `core > coverage + 0.001` scan passes over the
  whole image.
- Shoulder-only smin: `_smooth_min` is applied to `shoulder_distance` only, radius
  `SMIN_RADIUS = 0.28` cell, below the authored lane separation, and mathematically
  bounded (max distance pull ~0.07 cell). It never touches the core channel.
- Channels are separated (RG8 mask + independent R8 density), per the consensus
  that rejected codex's own RGB pack. Fingerprints in
  `docs/art/village/lane-mask-contract.md` match the committed PNG pre-upload
  `Image` bytes (both SHA-256 assertions pass). Both `.import` files pin
  `compress/mode=0` (lossless) and `mipmaps/generate=false`; RG8/R8 data formats
  are not sRGB-transferred by Godot.

## Tests (`test/active_path/test_village_render.gd`)

- The old full-row/full-column junction assertion is replaced by entrances +
  building approaches + junction connectivity + no-PATH-under-footprints.
- Actual A* preference is asserted, not just connectivity: `find_path` between
  cottage fronts stays on the curved lane (grass steps = 0) with a bounded
  weighted cost (10.414 <= 15.0).
- Determinism (geometry + ground), fingerprint match, width-varies, and
  core-never-reduced assertions are all present and green.

## Constitution + decision conformance

Determinism, sim/render separation, cross-platform (`res://`, forward slashes),
and no em-dashes (diff scanned, none). Conforms to decision 011 as converged and
touches no render/shader file, so there is no decision-010 regression risk in
this slice.

## Non-blocking observations (for claude's render slice, not defects here)

- The contract test loads the source PNGs via `Image.load_from_file`, which emits
  a benign "will not work on export" warning; that is fingerprinting the committed
  source bytes, not the runtime sample path. The render slice will load the
  imported texture resource instead.
- Godot's texture importer has no explicit non-sRGB flag for these; the RG8/R8
  formats guarantee it by data type. Satisfied by format, as pinned as the
  importer allows.

None of these block. Signed off.
