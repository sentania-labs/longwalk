---
reviewed_branch: agy/006-blender-cleanup
reviewed_sha: d5c8c1b0df2b9e58ab8e1f0bcc4a9e4fb84b1152
reviewed_by: codex-worker
authored_by: agy-worker
timestamp: 2026-07-17T22:57:49Z
tests_run: tools/run_tests.sh
result: changes-requested
---

I confirmed the reviewed SHA is the branch head, inspected the complete diff,
and checked the downstream `build_player_walk.py` consumer. The diff contains
no em-dashes, does not touch `src/sim/` or another protected path, uses
repository-relative forward-slash paths, and carries the required Antigravity
co-author trailer. The four cleaned binary assets add about 125 MiB on disk,
which is not independently blocking but compounds the raw-source footprint
already flagged for production escalation.

I ran `tools/run_tests.sh`. The Python art-pipeline tests passed, but the suite
did not complete: Godot remained in its headless import step for more than five
minutes after reporting errors while scanning Blender's bundled
`StinsonBeach.tex`, and I terminated my run. Another pre-existing test run in
the same worktree had remained at that import step for more than 27 minutes,
so this requires investigation before sign-off.

I also ran the documented Blender 4.0.2 sanity command. It rendered pose 0,
then `render_frame()` raised `AttributeError: 'NodeOutputFileSlotFile' object
has no attribute 'name'` in the rename loop. Blender nevertheless exited with
status 0. The output directory contains 30 files only because files from the
earlier author run were still present. Every filename retains a frame suffix,
such as `SE_0_color_0000.png` and `SE_5_uv_0025.png`; none matches the promised
`{facing}_{pose_idx}_{pass}.png` contract. The downstream pipeline therefore
cannot rely on the documented producer names.

Changes required:

1. Fix the Blender 4.0-compatible post-render rename, make a failed render or
   rename produce a nonzero command result, clear or otherwise isolate stale
   sanity output, and demonstrate exactly 30 fresh contracted filenames for
   the SE sanity run.
2. Validate the asserted native +Y orientation and rotation direction by
   rendering and visually checking at least two additional, distinguishable
   facings, including NE at zero rotation and one direction that establishes
   the sign of rotation. Record the evidence. A single SE render does not
   establish that the eight labels in the atlas map are correct.
3. Restore a completing `tools/run_tests.sh` run. In particular, prevent the
   committed Blender distribution or cleaned source assets from leaving Godot
   indefinitely in its import scan.

The absent Blender shadow socket is not a blocker for this slice. Decision 009
makes the deterministic offline-derived mask the shipped shadow and treats a
Blender cast-shadow pass as a cross-check. `SANITY.md` accurately discloses
that only five render passes are available. The documentation should continue
to avoid implying that the optional Blender shadow pass is guaranteed.
