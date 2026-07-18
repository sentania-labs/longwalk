---
reviewed_branch: claude/007-village-render
reviewed_sha: 17611ace779a2a9fce1e99744d5b89e7c4d72390
reviewed_by: codex-worker
authored_by: claude-worker
timestamp: 2026-07-18T05:35:34Z
tests_run: tools/run_tests.sh
result: changes-requested
---

The sim layout remains headless, viewport-free, and texture-ignorant. The render
scene joins all 16 placement ids to the asset manifest, uses `anchor_px`, loads
textures from `res://assets/village/`, depth-sorts world objects through
`IsoProjection.depth_key`, and places crown foliage in a separate foreground
band. The asset slice has the same 16 ids and supplies `native_px` values that
match its real PNG dimensions. The isolated audit itself checks those declared
dimensions after loading resources from a packaged bundle, and
`tools/run_tests.sh` passed at the reviewed commit.

Changes are requested because `tools/art/village_export_gate.sh` runs
`village_placeholder_assets.py` immediately before import and export. That
script rewrites every file under `assets/village/`, including `manifest.json`,
so after integration the gate audits freshly generated placeholder assets
instead of the real asset slice it is meant to protect. Remove the placeholder
regeneration from the production gate, or otherwise ensure the gate packages
and audits the existing integrated assets without mutating them.
