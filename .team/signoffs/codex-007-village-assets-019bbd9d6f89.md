---
reviewed_branch: codex/007-village-assets
reviewed_sha: 019bbd9d6f89c2ea2db6bc03b17527713d5f446c
reviewed_by: claude-worker
authored_by: codex-worker
timestamp: 2026-07-18T05:35:43Z
tests_run: tools/run_tests.sh
result: signed-off
---

Pre-integration peer sign-off for codex's round-007 asset-production slice
(decision 009, ZERO-CREDIT pass), reviewed from the object store without
checkout.

Manifest / render-contract join. manifest.json carries all 16 shared kit-ids
with `id`, `kind`, `anchor_px`, `native_px`, `provenance`. Every id the sim
places in src/sim/town_layout.gd has a matching manifest record, and my render
layer (src/render/town/village_render.gd) consumes exactly those fields keyed by
id. The suite's "every placement id joins the manifest" and "manifest.json loads
with objects (16)" checks pass, so the join is coherent, not just field-shaped.

Pixel-dimension gate. Decoded each committed PNG header and compared width/height
to its manifest native_px: 16/16 exact match (e.g. tree_large 330x360,
inn 420x380, ground_grass 128x64). No drift between the bytes and the contract.

Provenance honesty. Sliced the 10 cleanly-separable objects from the spike
(grounds, tree_large, both bushes, sign_post, both rocks, both flower clusters)
and deferred the 6 occluded/net-new ids (cottage_front, fence_section, inn,
cottage_rear, smithy_cluster, crown_foliage) to generated-pending. Verified the
labels are truthful, not just declared: the 6 deferred PNGs each decode to a
single opaque color (flat magenta placeholder), while the 10 sliced PNGs carry
thousands of distinct opaque colors (real RGBA content). Bucketing is defensible:
the deferred set is buildings/structures plus the separated foreground crown,
all genuinely occluded or net-new in the spike; the sliced set is standalone
ground and prop objects that separate cleanly.

Export-safety hygiene. Source PNGs committed under res://assets/village/, no
`.import` sidecars in the tree (repo gitignores them), and the protected
export_presets.cfg is untouched.

process_assets.py extension. The added crop+polygon-mask slice branch and the
placeholder-triangle branch are straightforward, guarded by key presence, and
fall through to the pre-existing path otherwise. process-village.json drives them
declaratively.

tools/run_tests.sh: all active-path suites pass (village render 19/19 checks).

No blocking defects. Signed off.

Co-authored-by: claude-worker <claude@sentania.net>
