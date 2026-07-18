---
reviewed_branch: codex/016-flora-d3
reviewed_sha: 3410ba70dbcbc37cbd60205aff132202eb86c853
reviewed_by: claude-worker
authored_by: codex-worker
timestamp: 2026-07-18T19:24:19Z
tests_run: tools/run_tests.sh
result: signed-off
---

D3 touch-up (second QA iteration of decision 016): deterministic rematte and
re-crop of the four flora sprites, no paid Meshy. Reviewed range 160139a..3410ba7
(one commit) in-worktree, adversarially.

Interior grey pocket: decoded flower_cluster_a.png and flower_cluster_b.png. The
new `remove_enclosed_neutral` path keys full-image neutral pixels (chroma
max-min <= 18, luminance floor min >= 96) into `background` BEFORE the
largest-connected-component keep, so it cannot orphan a legitimate subject
region. Result: the rectangular grey block behind the stems is gone (opaque
neutral-grey pixels with lum>=96 dropped to 1 stray feather pixel in flower_a and
0 in flower_b). Compared old vs new opaque sets: vivid petals (R/G up to 255) and
dark flower centres (min ~0) survive intact, green stems untouched. The luminance
floor is defensible for these four sprites: flower content is either saturated
(petals fail the chroma guard) or dark (centres/shadows fail the >=96 floor), so
no legitimate flower/bush region keys out.

Bbox clip: decoded bush_a.png and bush_b.png. The new `crop_padding: 2` in
`autocrop_and_fit` adds a 2 px fully transparent margin after fit, and no opaque
pixel touches the outermost 1 px border on any of the four sprites (border_touch
False for all). `available_size` is guarded against underflow and stays positive
for every target_size here; no odd downscale (aspect-preserving min-scale
unchanged). Manifest native_px/anchor_px recomputed from the new mattes; the
`processing` note added; provenance stays `generated`.

Seam masks: bush_b / flower_cluster_a / flower_cluster_b contact_y recomputed for
the re-cropped sprites. Each emits both `_contact` and `_cast`, and every contact
mask reads as a basal grounding pool (opaque band anchored to the bottom ~14 px,
min-y past the sprite mid-line), not a full-sprite projection.

Scope: diff touches only process_assets.py, process-village.json,
assets/village/manifest.json, the four flora PNGs, and their eight seam masks. No
`src/` change, no paid regen, no building/dirt/lane asset touched.
footprint_interaction_field.png is NOT in the diff (byte-unchanged). Both
`remove_border_background` (incl. the neutral key) and `autocrop_and_fit` stay
pure: numpy/PIL only, no randi/randf/time-seed, no order-dependent accumulator.

Suite + gate: `tools/run_tests.sh` all green (including the dirt-detail
byte-stability checks). `tools/art/village_export_gate.sh` -> VILLAGE_GATE_PASS,
all objects + seam masks resolve, and the assets/village non-mutation guard held
(processing is idempotent). No em-dashes, no backslash paths, no CRLF, no
protected-path edits.

Signed off.
