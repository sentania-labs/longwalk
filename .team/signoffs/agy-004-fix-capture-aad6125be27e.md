---
reviewed_branch: agy/004-fix-capture
reviewed_sha: aad6125be27e1b9d7ff96ed502dd43b91f661b13
reviewed_by: claude-worker
authored_by: agy-worker
timestamp: 2026-07-17T16:32:45Z
tests_run: tools/run_tests.sh
result: signed-off
---

Layer-1 pre-integration sign-off for the round-004 walk-capture fix, the sole
Codex P2 on round PR #20. The reparent in the camera slice removed the player's
child `Camera2D`, so `tools/art/capture_player_walk.gd` was calling a node that
no longer exists.

What I checked:

1. `tools/run_tests.sh` in this worktree: all active-path suites pass, including
   the zoom/rig suite. (The pre-existing `get_node absolute paths` ERROR in
   `test_smoke_grade.gd` is unrelated to this diff and that suite still PASSes.)

2. Proved the fix rather than only reading it:
   - `CameraRig2D` is the real node: `starter_town.gd:_build_camera_rig` names it
     `"CameraRig2D"` and adds it to `_world` (which is `$World`,
     `starter_town.gd:41`), so `town.get_node("World/CameraRig2D")` resolves.
   - `camera_rig_2d.gd:1` `extends Camera2D`, so `.zoom` is valid.
   - The `_process` lerp at `camera_rig_2d.gd:102` is guarded by
     `is_equal_approx(zoom.x, _target_zoom)`; with both set to 1.0 the block is
     skipped, so the rig cannot stomp zoom during the capture frame delays.
   - Ran the capture tool end-to-end per `tools/art/README.md`
     (`xvfb-run ... --script res://tools/art/capture_player_walk.gd`): exit 0,
     printed `wrote res://docs/art/player-walk-option-c-capture.png`, and the
     output is a valid 640x640 (CELL*4) RGBA montage. Only audio/vsync
     environment warnings, no script errors.
   - Ran a throwaway diagnostic to confirm the zoom-hold semantics: in the
     actual starter-town layout `setup()` leaves `_target_zoom` at 1.0, so the
     hold is a no-op here, but it is correct defensive code. When
     `_recompute_zoom_levels` yields a min zoom above 1.0 (small town / large
     viewport), `_target_zoom` would be above 1.0 and the `_process` lerp would
     otherwise drift the capture off 1:1; setting both `_target_zoom` and `zoom`
     to 1.0 forecloses that. Harmless where unneeded, correct where needed.

3. Constitution: no em-dashes in the diff or commit message (grep clean); the
   change is render-side tooling only, nothing under `src/sim/`; determinism
   unaffected (no RNG touched).

4. The README prose change (`camera` -> `camera rig`) accurately matches the
   code change.

Note: the worktree carried an uncommitted modified
`docs/art/player-walk-option-c-capture.png` (author validation output, and my
own capture run regenerated it); I restored it with `git checkout --` and it is
not part of the reviewed commit or this marker.

Reviewed commit is clean and works end-to-end. Signed off.

Co-authored-by: claude-worker <claude@sentania.net>
