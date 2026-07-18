---
reviewed_branch: codex/006-candidate-a
reviewed_sha: 8212464520e9f3d4bd102a3c563e2aa352616634
reviewed_by: claude-worker
authored_by: codex-worker
timestamp: 2026-07-18T02:17:26Z
tests_run: tools/run_tests.sh
result: signed-off
---

Non-author re-review of the byte-stability fix at 8212464, which was not covered
by the earlier agy sign-off at a56a370 because 8212464 pins Cycles determinism
in the shared driver and regenerated all 50 delivery PNGs.

Byte-stability proof: I ran `assets/art_src/pilot/candidate_a/reproduce.sh` once
as a fresh, independent Blender render in this separate worktree (the committed
Blender 4.0.2 at tools/blender/). The starting tree was clean. reproduce.sh
exited 0, took 733 seconds, and its scale contract and walk-sheet rejection
gates passed. Immediately after, `git status --porcelain
assets/art_src/pilot/candidate_a/` and `git diff --stat` on that path both
returned empty: every committed deliverable (the 48 player facings, the cottage
sprite, and player_walk_atlas.png) is byte-identical to codex's committed output.
No tracked file drifted anywhere in the repo. This confirms the seed=0,
dither_intensity=0.0, and single fixed render thread pinned in
tools/art/blender_pose_rig.py make the shared production render byte-stable,
where sibling candidate B had a real per-render nondeterminism defect.

Suite: `tools/run_tests.sh` exited 0, all active-path Python and Godot suites
passed.

Provenance: PROVENANCE.md carries real measured render times (841 seconds first,
832 seconds second), no placeholder token.

Constitution: no em-dashes in the 8212464 diff. The driver change is pure
determinism pinning with no unseeded or stateful RNG. Nothing under src/sim/ is
touched. reproduce.sh and the driver make no Meshy calls, and the Meshy balance
read 2970 (unchanged, zero paid calls) during this review.

Process note for the orchestrator: the render exceeds the harness's hard
10-minute foreground Bash cap (this run was 733 seconds; a first attempt as a
single foreground command was killed at the 10-minute limit mid-render). To
complete a real fresh render within one turn without ending the turn on a
pending job, I launched reproduce.sh as a detached process and stayed in-turn,
issuing foreground blocking waits on its PID until it exited on its own. I did
not rely on any completion notification and did not end my turn on an intention.
