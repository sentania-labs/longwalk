---
reviewed_branch: codex/007-village-assets
reviewed_sha: 5a70f178e88fdeae96e830d1622f3fac9616b5aa
reviewed_by: claude-worker
authored_by: codex-worker
timestamp: 2026-07-18T06:15:32Z
tests_run: tools/run_tests.sh
result: signed-off
---

Reviewed codex's round-007 asset-processing slice: the step that turns the 6
paid-Meshy raw candidates into game-ready RGBA sprites and flips them from
`generated-pending` to `generated`. Reviewed from the object store without
checking the branch out.

Background-removal quality (the load-bearing check). Decoded all 6 processed
PNGs and inspected the alpha directly. These are buildings full of legitimate
grey stone (foundations, slate roofs, chimneys), so a global grey chroma-key
would have punched holes through them. It did not: I flood-filled exterior
transparency from the border and counted enclosed transparent components. The
buildings show only 1-5 scattered single-pixel antialiasing specks, no
punched-through walls or roofs. crown_foliage (76 tiny holes, largest 8px) and
fence_section (26 holes) are genuine gaps between leaves and between fence
rails, which is correct content, not damage. Composited every sprite over
magenta and green and eyeballed them, plus a 2x nearest-neighbour zoom of the
grey-stone cottage_rear and smithy_cluster: the stone foundation, slate roof,
and chimney are fully opaque, the cutout edge is a tight ~1px antialiased band
with no visible grey halo/matte fringe, and no background bleeds through any
interior. Confirmed in code that `process_assets.py::remove_border_background`
is a genuine border flood-fill (connected-component grown from every edge
pixel with a delta + chroma gate, then largest-foreground-component keep), not
a global colour key. This is exactly the risk called out and it is handled
well.

Dims == native_px. Measured each PNG independently: inn 354x380,
cottage_front 280x280, cottage_rear 280x295, smithy_cluster 278x320,
crown_foliage 273x220, fence_section 87x96. All six match their manifest
`native_px` exactly, so the render gate's equality assertion holds. Note the
process manifest's `target_size` values are generous upper bounds; the real
dims come from `autocrop_and_fit` fitting within them, and the manifest records
the true post-crop dims. Consistent.

Anchor sanity. Every building/cottage/smithy/fence anchor is bottom-centre of
its native box (inn [177,379] of [354,380], cottage_front [140,279],
cottage_rear [140,294], smithy [139,319], fence [44,95]). crown_foliage
[137,219] of [273,220] is bottom-centre canopy-attach, correct for an
occlusion crown. Nothing floats or sinks on the iso grid.

Provenance honesty. All 6 flipped to `provenance: generated`; the 10 sliced
objects remain `slice`. `tools/art/generated_src/provenance.json` records
source task ids, ref crops, spike boxes, credits spent (18 total, balance
2970->2952), and the do-not-regenerate note. Raw candidates committed as the
durable copies under tools/art/generated_src/. Nothing dishonest either way.

Export-safety hygiene. Source PNGs live under assets/village/, no `.import`
sidecars committed, no edit to the protected export_presets.cfg (grepped the
name list, clean).

Tests. `tools/run_tests.sh` passes end to end, including the extended
test_art_manifest.py which now adversarially asserts that an enclosed grey-stone
region survives border removal (does not punch through) and that
autocrop_and_fit stays within target size, plus the full village render suite
(16 objects, dims/anchor gates green).

Signed off.
