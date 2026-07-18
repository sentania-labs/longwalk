---
reviewed_branch: codex/007-ground-impl
reviewed_sha: aa2d5177e50a9d7d4c8e2344d035e8face4a5c7e
reviewed_by: claude-worker
authored_by: codex-worker
timestamp: 2026-07-18T07:44:30Z
tests_run: tools/run_tests.sh
result: signed-off
---

Adversarial review of the decision 010 PLATE fallback slice (round 007 ground
sub-round), reviewed in-worktree at aa2d517 against round head 053906a.

## 1. Manifest honesty (native_px vs real pixels): PASS

Decoded every ground PNG with PIL and compared to the manifest `native_px`:

- ground_grass_plate.png -> (1024, 1024) RGB   == manifest [1024,1024]  kind ground_plate  provenance generated
- ground_dirt_plate.png  -> (1024, 1024) RGB   == manifest [1024,1024]  kind ground_plate  provenance generated
- ground_warp.png        -> (256, 256)  RGB    == manifest [256,256]    kind ground_warp   provenance generated
- shadow_decal.png       -> (256, 128)  RGBA   == manifest [256,128]    kind shadow        provenance generated

All four match exactly. No native_px mismatch to fail the export gate at
integration. Both plate `source` fields carry the paid nano-banana task ids
(grass 019f7414-c219-75c8-ac2e-dc6f33b3c97f, dirt 019f7415-90bb-78e0-a533-9b758d723b74).

## 2. Plates are the real paid painterly fields: PASS

sha256 of the committed plates is byte-identical to the supervised paid sources
(read from codex's worktree .pka/round007/ground-source/, my worktree does not
carry round007 .pka):

- grass a685b506653a953ea2f5699d63a1cb3d9401dd3ad63de2c5e18c09f0bee9c249  (plate == source-grass.png)
- dirt  2e004cfbca8bfbe9f088c9dcdc34eb44ec05a4e9fd69e38402eb64c227eb4d1b  (plate == source-dirt.png)

No accidental re-crop/re-bake corrupted them; the manifest `processing` note
("preserved full source at native resolution; no crop, offset, heal, or
flattening") is accurate.

## 3. Warp is deterministic + real: PASS

tools/art/bake_ground_warp.gd is a seeded CPU bake: FastNoiseLite seed =
LAYOUT_SEED(7007) + LAYER_OFFSET(4109), sampled at integer texel coords, mapped
[-1,1] -> byte [0,255], written to a 256x256 R8 image. No randi/randf, no
unseeded RandomNumberGenerator, no time seed, no order-dependent accumulator.
Pure function of (seed, position), matching the constitution's determinism rule.
ground_warp.png is real baked output, not a placeholder.

## 4. Retirement is clean: PASS

The cumulative net diff 053906a..aa2d517 adds only the plates/warp/shadow, docs,
manifest rows, the warp baker, and the test. The failed tile assets
(ground_grass_tile.png, ground_dirt_tile.png), tools/art/bake_ground_swatches.py,
and the codex-worker blocked marker were introduced and then removed within the
range, so they net to zero (verified via per-commit `git log --stat`). grep for
`bake_ground_swatches`, `ground_grass_tile`, `ground_dirt_tile`, contact-sheet,
8x8, and zoom-gate references across *.py/*.gd/*.json returned nothing: no
dangling references. test_art_manifest.py now asserts the four ground records by
kind/native_px/provenance and decodes each PNG to confirm size. The
ground-swatch-contactsheet.png remains only as a historical doc artifact of the
retired approach, not a live gate; acceptable.

## 5. Blocked marker removed: PASS

.team/blocked/ carries only README.md; the codex-worker swatch block is gone
(resolved by the plate pivot).

## 6. Style rule (no em-dashes): PASS

`git diff 053906a..aa2d517 | grep` for em-dash found none.

## 7. Tests: PASS

tools/run_tests.sh -> exit 0, "All active-path test suites passed."
test_art_manifest.py reported "art manifest tests passed"; test_village_render.gd
confirms "manifest.json loads with objects (20)" and all 19 render checks pass.

Verdict: signed-off. The slice is honest, deterministic, and clean.
