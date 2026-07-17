---
reviewed_branch: agy/005-camera-clampfix
reviewed_sha: 618b578f27e6a125cb51bd8deb2f86d2a98cd9d2
reviewed_by: claude-worker
authored_by: agy-worker
timestamp: 2026-07-17T19:46:17Z
tests_run: tools/run_tests.sh
result: signed-off
---

Reviewed the single commit 618b578 fixing the camera zoom-clamp ordering in
`src/render/town/camera_rig_2d.gd`.

Checks performed:

1. Ran `tools/run_tests.sh` in this worktree. All active-path suites pass,
   including the camera zoom and rig checks (min-zoom clamp, high-zoom vs
   min-zoom left clamp, follow snap-back).

2. Confirmed the reorder is correct and load-bearing. `_clamp_to_limits`
   derives `vp_size = Vector2(vp_w, vp_h) / zoom` (line 123), so it reads the
   `zoom` property directly. On a zoom-out the new `new_z` is smaller, giving a
   larger visible half-size; running the clamp with the stale pre-zoom value
   used too small a half-size and let the view leak past `_projected_bounds`.
   Moving `zoom = Vector2(new_z, new_z)` above the cursor-preserving block so
   the clamp at line 158 reads the new zoom is the right fix.

3. Confirmed the reorder does not disturb the cursor-preserving shift math.
   `shift = screen_center_offset * (1.0 / old_z - 1.0 / new_z)` uses the
   explicit `old_z`/`new_z` locals captured before the assignment, and
   `screen_center_offset` derives from `get_viewport_rect().size`, which is the
   window rect in pixels and is independent of the Camera2D `zoom` property.
   Moving the `zoom` assignment earlier therefore cannot change the computed
   shift.

4. Diff touches only `src/render/town/camera_rig_2d.gd` and is purely an
   ordering change (2 insertions, 2 deletions), no behavioral change beyond the
   fix. No em-dashes. `src/render/` is not `src/sim/`, so sim/render separation
   is not implicated; no RNG or determinism concerns.

Signed off.
