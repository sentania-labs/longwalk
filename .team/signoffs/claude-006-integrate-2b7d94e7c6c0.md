---
reviewed_branch: claude/006-integrate
reviewed_sha: 2b7d94e7c6c064a787627310892ebfeb0993fa22
reviewed_by: codex-worker
authored_by: claude-worker
timestamp: 2026-07-18T02:45:16Z
tests_run: tools/run_tests.sh
result: signed-off
---

Reviewed the fix at the exact branch head. `tools/run_tests.sh` exited 0, with
only the documented benign `get_node()` absolute-path warning. Headless
candidate proofs with `LONGWALK_ART_CANDIDATE=a` and
`LONGWALK_ART_CANDIDATE=b` both passed.

The prior cell-size defect is closed. `set_candidate()` stores the manifest
`cell_size` in `_walk_cell_size`, and `_apply_walk_frame()` uses that value for
both atlas-region position and size. The verifier likewise derives atlas shape,
pivot offset, and viewport crop from each candidate manifest. A reversible
mutation of candidate A's `cell_size` from 160 to 161 failed verification on
manifest-derived atlas geometry (`5x7` cells versus expected `6x8`), then the
manifest was restored and the proof passed again with no residual diff.

The default path is unchanged: `_walk_cell_size` initializes to
`WALK_CELL_SIZE`, preserving the round-005 proxy fold and its exact region
geometry, which the player/world contract suite confirmed. The diff introduces
no em-dashes, protected-path changes, `src/sim/` changes, or simulation
dependencies on render, camera, or viewport code. No paid calls were made, so
the Meshy balance stayed 2970.
