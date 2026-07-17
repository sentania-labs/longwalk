---
reviewed_branch: agy/005-camera
reviewed_sha: 1aa290e10d4a71cfffa343003878d8af2fbb5610
reviewed_by: claude-worker
authored_by: agy-worker
timestamp: 2026-07-17T18:34:17Z
tests_run: tools/run_tests.sh
result: signed-off
---

Reviewed agy's round-005 camera drag-pan slice in-worktree against decision 008
section 3, Scott's 1720 refinement, and the frozen projection contract I authored.

## What I checked

- **Suite.** `tools/run_tests.sh` passes, including the reworked
  `test/active_path/test_player_zoom.gd` (DRAG hold, threshold entry,
  follow-snap through `world_to_screen`, projected-bounds clamp at two zooms,
  `pan_drag` action existence). The one `get_node()` ERROR in
  `test_smoke_grade.gd` is pre-existing and unrelated to this slice.
- **Boundary.** Diff touches only `project.godot`, `src/render/town/camera_rig_2d.gd`,
  and its test. No `src/sim/` edit, no edit to my `src/render/iso/*` module. The
  `project.godot` change is minimal: `focus_view` renamed to `pan_drag` on the
  same RMB bind (button_index 2), so the double-fire the critique flagged cannot
  recur. No em-dashes in the diff. `focus_view`/`FOCUSED`/`_focus_point` are
  fully retired (grep clean across src/test/scenes/project.godot).
- **Contract consumed correctly.** agy calls `IsoProjection.projected_bounds(Vector2i(width,height), Vector2(300,400))`
  and `IsoProjection.world_to_screen(player.position)` only; it does not
  re-derive projection math. grid_size passes the cell grid (not pixel_size),
  headroom is sane. Clamp is against `_projected_bounds`, not `pixel_size()` -
  the critique's camera-bounds catch is resolved. Min-zoom is also recomputed
  from `_projected_bounds.size`.
- **Decision 008 section 3 items.** DRAG state present; click-vs-drag pixel
  threshold (5px) gates entry so a pure RMB click no longer breaks FOLLOW;
  `position -= event.relative / zoom` pan is present and correct at all zooms;
  FOLLOW `_process` only overwrites position while `_state == FOLLOW`, so a
  drag is no longer stomped every frame.

## Cursor-preserving zoom + threshold verdict

I scrutinized the zoom-to-cursor path specifically. The math is correct:
`shift = (cursor - vp/2) * (1/old_z - 1/new_z)` is exactly the Camera2D
pos correction that holds the world point under the cursor fixed, and it
telescopes correctly across the multi-frame lerp (the per-frame old->new deltas
sum to 1/z_initial - 1/z_final).

Reservation (noted, not blocking): the shift is applied only while
`_state == State.DRAG`. So zoom-to-cursor holds the cursor point fixed once the
user has entered free-pan, but a wheel-zoom in plain FOLLOW mode anchors on the
player (the FOLLOW branch re-pins position to `world_to_screen(player)` and the
shift is gated out). This is defensible - in FOLLOW you cannot both keep the
player centered and hold an arbitrary cursor point, so player-anchored zoom is
the sane FOLLOW behavior, and cursor-anchored zoom kicks in exactly where the
new free-pan feature lives. It is a feel decision Scott's visual gate will
exercise; if FOLLOW-mode zoom-to-cursor is wanted, it is a small follow-up. The
`Vector2.ZERO` sentinel can only misfire when the cursor sits on the exact
viewport top-left pixel (0,0), degrading that single zoom to center-anchored -
negligible in practice. The DRAG threshold and the `_process` FOLLOW clamp are
both correct.

Signed off: the drag-pan headline requirements are correctly and testably
implemented, and the one reservation is a defensible feel choice, not a defect.
