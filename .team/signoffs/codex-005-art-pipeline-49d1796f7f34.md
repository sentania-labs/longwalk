---
reviewed_branch: codex/005-art-pipeline
reviewed_sha: 49d1796f7f3419b6fdb4f73b4a9f1b9a4ac98f89
reviewed_by: claude-worker
authored_by: codex-worker
timestamp: 2026-07-17T18:44:50Z
tests_run: tools/run_tests.sh
result: signed-off
---

Reviewed codex-worker's round-005 art-generation and pipeline slice in-worktree.
I authored the frozen iso-projection contract this art generates against, so this
review is scoped to code, pipeline, constitution, and contract conformance, not
aesthetic acceptance (that is Scott's separate gate).

Tests: ran `tools/run_tests.sh` in full. The three Python art tests
(`test_build_player_walk.py`, `test_art_manifest.py`, `test_check_walk_sheet.py`)
and every active-path Godot suite pass ("All active-path test suites passed").
The lone `get_node absolute path` line in `test_smoke_grade.gd` is a pre-existing
benign engine log; its checks all PASS.

Shadow determinism (verdict: clean). `derive_shadows` in `process_assets.py`
casts from the ground-contact silhouette only: it slices the bottom
`footprint_slice` rows ending at `contact_y`, zeroing everything above, so
roof and wall alpha never enter the mask. It projects that footprint along a
fixed `light_vector` using `np.maximum` accumulation, which is order-independent,
with no `randi/randf/RandomNumberGenerator`, no time seed, and no iteration-order
accumulator. `test_art_manifest.py` proves this directly: with a sprite whose
upper rectangle is a roof, it asserts the cast source over the roof rows is
identically zero ("roof pixels leaked into cast source") while the footprint rows
cast. This is decision 008 Q-C, and the naive full-alpha shear that decision 006
rejected is not present.

Contract conformance (verdict: conforms). The 8-facing row order in
`player-walk-policy.json`, `player-walk-e.generated.json`, and
`build_player_walk.py` FACING_IDS is E,SE,S,SW,W,NW,N,NE = ids 0..7, matching the
frozen table in `docs/contracts/iso-projection-contract.md`. `build_player_walk.py`
rejects any deviation from immutable row-major order and rejects mirroring not
declared before generation. Per-cell anchors are the ground-contact convention:
player target_anchor [80,159] is bottom-center of the 160 cell (feet), cottage
[320,430] is its ground-contact line. `ingest_generated_sheet.py` rejects missing
provenance (prompt/style_board/generator), wrong sheet dimensions, wrong grid
(rows x cols x cell size and cell-count mismatch), duplicate slots/ids, out-of-
range anchors, empty cells, edge-touch cells, and undeclared runtime assets.

No laundering (verdict: clean). `process_assets.py` and `build_player_walk.py`
dropped the hard-coded asset lists and the cardinal Option-C policy; both are now
manifest-driven. Normalization only re-anchors by declared feet/contact anchor and
scale; no code picks a frame because it looks better. The walk grid is validated
and ingested as one unit.

No third-party pack (decision 007): no Kenney/OpenGameArt/itch asset is tracked;
the README only references asset packs to state art is NOT downloaded from them.
No reference folder is shipped. No em-dashes in the code diff, docs, or commit
messages.

Remaining art (per codex's `docs/art/round005-art-pipeline-result.md`, honest
partial scope): this round ships the five-asset early taste spike (style board,
one 2x2 cottage, one neutral player master, one complete six-frame east walk
grid, plus the composed spike/GIF/before-after). Still Scott-gated: seven
remaining per-facing walk grids, the compact flora category sheet, and the
remaining individual town buildings. The manifest, ingest, normalization, shadow,
atlas, rejection, GIF, comparison, and Godot spike producers are ready for those
inputs, with no mirrored or aesthetically selected fill. Partial-but-honest,
which this round accepts.

Co-authored-by: Claude <claude@sentania.net>
