---
reviewed_branch: codex/016-bake
reviewed_sha: d0c861c9550baf2478eb4fc2c9920ed5c492e19a
reviewed_by: claude-worker
authored_by: codex-worker
timestamp: 2026-07-18T17:53:56Z
tests_run: tools/run_tests.sh
result: signed-off
---

Layer-1 review of the offline bake half of decision 016 (impl slice 1). The
render integration is a separate later slice and was intentionally out of scope;
I did not down-vote the bake for not sampling the field or wiring the shadow
layer. I engaged this decision in the critique round, so I checked the bake
against the converged synthesis, not codex's original runtime-vs-offline
preference.

Determinism / byte-stability. `tools/art/bake_footprint_field.gd::bake()` is a
pure function of `build_inn_green_district()`: box signed-distance and door
distance are plain geometry, buildings are sorted by id, and the min/smoothstep
reductions are order-independent. No `randi`/`randf`/`RandomNumberGenerator`,
no iteration-order accumulator. The `derive_shadows` extension in
`process_assets.py` is likewise pure (alpha slice, fixed light-vector shear,
Gaussian/max filters). I re-baked both offline: the committed
`footprint_interaction_field.png` reproduced byte-identically
(sha b08e2bad...), and re-running the village manifest reproduced all 26 seam
PNGs byte-identically (only Godot `.import` sidecars appeared, which I removed).
`test/active_path/test_footprint_field_bake.gd` is not a stub: it bakes twice,
asserts byte-identity, and pins both the decoded-field SHA (e5c916cf...) and the
layout fingerprint SHA against the manifest.

Field semantics vs contract. Baker output, `docs/art/village-seam-bake.md`, and
`manifest.json` agree: 256x224 RGBA8, 16 texels/cell, R = apron coverage,
G = signed distance encoded as clamp(0.5 + d/4.0, 0, 1), B = deterministic
door-wear, A opaque. The bake reads only the texture-free layout (cell,
footprint, id, blocks, kind) and the render-side DOORS metadata; `lane_density`
is never touched, so the field is genuinely lane-independent. Door metadata
lives in the baker/manifest, not `src/sim/`, so no sim/render violation.

derive_shadows extension. The new `operation: derive_shadows` branch in
`process_manifest` calls the pre-existing `derive_shadows()` (basal-alpha slice,
one shared light vector [12,6], short cast) rather than forking a second shadow
pipeline. Every kit with a shadow record has both `_contact` and `_cast` masks
present under `assets/village/seams/`, each sized to its source sprite;
`test_art_manifest.py` enforces that pairing and sizing, and
`village_export_audit.gd` resolves every declared seam through `ResourceLoader`.
`crown_foliage` is correctly excluded from contact masks per the contract.

Cross-platform. No em-dashes, no backslash paths, no CRLF in any changed text
file.

Flora rematte (D3) is a known blocked item with its committed marker in this
tree; the flora seam masks baked from current sprites are in scope and present,
so I did not treat the deferred rematte as a defect of this slice.

Suite result: tools/run_tests.sh passed in-worktree, including
test_footprint_field_bake.gd and test_art_manifest.py. Signed off.
