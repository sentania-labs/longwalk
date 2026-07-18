# Round 006 Candidate A: review the byte-stability fix, sign or request changes

You are the **claude-worker** acting as the non-author peer reviewer of Candidate
A, in worktree `/home/scott/claude/lw-006-cand-a`, on branch
`codex/006-candidate-a` at commit **8212464** ("Make shared production renders
byte-stable"). A is authored by codex-worker, so you (claude) are a valid
non-author reviewer.

## Why this re-review exists

Candidate A was signed off earlier by agy-worker at **a56a370** (marker
`.team/signoffs/codex-006-candidate-a-a56a3705d3cb.md`). AFTER that sign-off,
codex committed **8212464**, which pins Cycles determinism (seed, dither,
threads) in the SHARED render driver `tools/art/blender_pose_rig.py` and
**regenerated every one of the 50 delivery PNGs** (all finished player frames,
the cottage sprite, and `player_walk_atlas.png` all changed bytes). agy's
sign-off does not cover 8212464, and agy's original review did not do a strict
per-pixel byte diff. So the current head is UNSIGNED and must be reviewed at
8212464 before it can be integrated. The sibling candidate B had a real
1-pixel/1-channel nondeterminism defect caught exactly this way, so treat this
as a genuine determinism audit, not a rubber stamp.

## Verify, do not trust the commit message

The whole point of this re-review is byte-level determinism, so you must
actually re-render, not read the diff and nod:

1. Confirm Blender present in this worktree (it is, at `tools/blender/`).
2. Run `assets/art_src/pilot/candidate_a/reproduce.sh` to completion.
3. Run it a SECOND time as an independent Blender process into a scratch
   location, and `md5sum`-diff every finished player sprite (all 48), the
   cottage sprite, and `player_walk_atlas.png` between the two runs. They MUST be
   byte-identical. There must be ZERO drifting pixels.
4. Confirm the committed deliverables at 8212464 match a fresh reproduce
   byte-for-byte (the committed atlas is the canonical output).
5. Confirm PROVENANCE.md has a real measured render time (no
   PLACEHOLDER_RENDER_TIME or similar placeholder remains).
6. Run `tools/run_tests.sh`, confirm exit 0.
7. Constitution conformance: no em-dashes anywhere in the diff, no unseeded or
   stateful RNG, nothing under `src/sim/` touched.

## Candidate A uses NO Meshy

Candidate A is the deterministic NPR/composite baseline. It never calls Meshy.
A free `meshy_check_balance` should read **2970**; you make ZERO paid calls.
There is no retexture ledger to audit for A (that is candidate B). If you see any
Meshy call in A's pipeline, that is itself a finding.

## Deliver a marker (and ONLY a marker)

Write `.team/signoffs/codex-006-candidate-a-8212464520e9.md` with front matter
per `.team/signoffs/README.md`:

    reviewed_branch: codex/006-candidate-a
    reviewed_sha: 8212464520e9f3d4bd102a3c563e2aa352616634
    reviewed_by: claude-worker
    authored_by: codex-worker
    timestamp: <UTC ISO-8601 Z>
    tests_run: tools/run_tests.sh
    result: signed-off   # or changes-requested

Prose note: state exactly what you re-rendered and diffed, that byte-stability
now holds across two independent Blender processes (or precisely which pixels
still drift if any do), that the committed deliverables match a fresh reproduce,
the PROVENANCE render time is real, and the suite exit code. NO em-dashes in the
marker.

## HARD RULES

- **ZERO paid Meshy calls.** Balance must stay 2970. A free check is fine.
- **Commit ONLY the marker** on `codex/006-candidate-a`. Do not modify A's
  deliverables or driver; you are the reviewer, not the author. If you find a
  real defect (any drifting pixel, a placeholder render time, an em-dash, a
  broken reproduce, a failing suite), write `changes-requested` with the
  specifics instead of fixing it.
- Do NOT background the render and end your turn on a "monitor" or completion
  intention. Run the renders INLINE, then write and commit the marker in the SAME
  turn. Your turn is complete ONLY when `git log --oneline -1` shows your marker
  commit with a clean `git status`.
- Do NOT rebase the branch. Review 8212464 as it stands.
