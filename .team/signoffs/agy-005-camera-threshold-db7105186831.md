---
reviewed_branch: agy/005-camera-threshold
reviewed_sha: db71051868311df6550a280e26d14afa15075691
reviewed_by: claude-worker
authored_by: agy-worker
timestamp: 2026-07-17T20:45:00Z
tests_run: tools/run_tests.sh
result: signed-off
---

Reviewed the camera pan drag-threshold fix (Codex r4 P2).

Tests: `tools/run_tests.sh` green in this worktree, including the new
assertions "Drag release enters FREE state", "Subsequent drag press stays in
FREE state", and "Sub-threshold motion does not enter DRAG state". (The
`get_node()` ERROR line in test_smoke_grade is a pre-existing, unrelated log;
every check in that suite still PASSes.)

Logic, traced against the full state machine:

- Root cause confirmed. Before the fix, `_state` stayed `DRAG` after a
  `pan_drag` release, so the second gesture's `if _state != State.DRAG`
  threshold guard was skipped and any motion panned immediately.
- The fix adds a `FREE` state and, on `pan_drag` release from `DRAG`, sets
  `_state = FREE`. A subsequent sub-threshold gesture now re-enters the
  `_state != DRAG` branch, sees distance < `DRAG_THRESHOLD`, and stays `FREE`
  without panning; a real drag (> threshold) still transitions to `DRAG` and
  pans. Correct.
- No regression on a bare click in FOLLOW: press keeps `_pan_active` true but
  state FOLLOW; sub-threshold motion stays FOLLOW; release checks
  `_state == DRAG` (false), so no spurious FOLLOW to FREE transition.
- Cursor-preserving zoom guard extended to `DRAG or FREE`. This preserves the
  prior post-drag zoom behavior: pre-fix the post-release state was `DRAG` (so
  the shift applied); post-fix it is `FREE`, so `or FREE` keeps the shift
  applying. FOLLOW and center_on_player are unaffected: in FOLLOW the guard is
  false and `_process` overrides position to the player anyway.

Constitution: change is render-layer only (no sim/render violation), no RNG,
no em-dashes. Diff touches `src/render/town/camera_rig_2d.gd` plus its test
`test/active_path/test_player_zoom.gd`; the test extension is the coverage for
this fix and belongs with the slice.

Signed off.
