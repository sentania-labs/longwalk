---
reviewed_branch: codex/016-flora
reviewed_sha: f196cf819948b229eeb38203ec4c0e55e97e4044
reviewed_by: claude-worker
authored_by: codex-worker
timestamp: 2026-07-18T18:25:36Z
tests_run: tools/run_tests.sh
result: signed-off
---

Reviewed the decision 016 D3 flora rematte finish (`3000e93..f196cf8`, one
commit) adversarially against the decision record and the sign-off checklist.

**Clean recipe, not a re-contamination.** The five `provenance: slice` flora
(`tree_large`, `bush_a`, `bush_b`, `flower_cluster_a`, `flower_cluster_b`) are
now produced by `remove_border_background` off
`tools/art/generated_src/<id>.src.png`, the same recipe as the buildings and
`crown_foliage`. The old polygon `crop`/`polygon` slice entries are gone from
`process-village.json`. Decoded every output PNG: all four corners are alpha 0,
interiors are cleanly opaque, and the octagonal alpha-mask edge is gone. No
visible neutral-grey halo: the only residual neutral pixels on the outer feather
ring sit at alpha 2-4 (< 2% opacity, imperceptible), and the new `decontaminate_rgb`
path propagates subject RGB outward under the feather so filtering cannot reveal
the grey source background. Leaves/petals/berries are intact (largest-component
keep did not amputate small parts).

**Seam masks re-baked from the NEW sprites.** Every regen flora emits both
`_contact` and `_cast` under `assets/village/seams/`, and both read as basal
grounding pools confined to the bottom ~11-14 rows of each sprite (e.g.
`tree_large_contact` rows 346-359 of 360), not full-sprite projections.
`crown_foliage` correctly emits NO ground contact/cast mask (its seams glob is
empty). Manifest ordering is correct: the `remove_border_background` matte
entries run before the `derive_shadows` entries that read the committed PNGs.

**Manifest correctness.** `manifest.json` flora entries flipped `provenance` off
`slice` to `generated` with recomputed `native_px`/`anchor_px`; the per-kit
`flora_kits` tonal targets are data for the render-side D4 pass, not applied to
sprite pixels here.

**Division boundary respected.** This is codex's OFFLINE slice only. No
`ground.gdshader` / CanvasModulate / `village_render.gd` change; no render-side
tonal grade baked into the sprite RGB (decontamination only propagates existing
subject RGB, it does not tone-map). No `src/sim/`, protected-path, or
`export_presets.cfg` edits.

**Determinism + byte stability.** `remove_border_background` + `derive_shadows`
stay pure (no randi/randf/time seed, no order-dependent accumulator). Re-ran
`process_assets.py` over the manifest: the committed flora and seam PNGs
reproduce byte-for-byte (clean `git status`). The BUILDING-derived
`footprint_interaction_field.png` is byte-unchanged (not in the diff at all;
flora does not feed it), and its byte-stability test still passes unchanged.

**Tests + gate.** `tools/run_tests.sh` is fully green, including the extended
manifest test (the new decontamination feather/neutral-RGB assertions) and the
footprint-field byte-stability test. `tools/art/village_export_gate.sh` passes:
all 20 manifest objects and all declared seam masks resolve through
ResourceLoader, with the non-mutation guard intact.

**Style.** No em-dashes, no CRLF, no backslash paths.

The flora look clean and the footprint field is byte-unchanged. Signed off.
