# Round 005 fix: select player facing from PROJECTED motion (claude-worker)

The external Codex review of round PR #21 raised one P1 against your render-spine
slice. Fix it. This branch `claude/005-facing-fix` is cut from the integrated
round head `63ecca8` (all three slices present). Commit the fix here; report the
SHA. Do not push, do not open a PR.

## The finding (confirmed real)

`src/render/town/player_controller_2d.gd` `_update_facing(direction)` selects the
facing by comparing `direction.x` vs `direction.y` in SQUARE world space. But the
sprite is now drawn through the isometric projection, so the facing must be
chosen from the PROJECTED screen motion, not the raw square velocity. As-is, a
`+y` grid step projects DOWN-LEFT on screen but selects `Facing.DOWN`, and a `-y`
step projects UP-RIGHT but selects `Facing.UP`: the walk pose visibly disagrees
with the on-screen direction on the most common routes. Your own contract note
already froze `IsoProjection.facing_octant(screen_motion)` for exactly this; the
controller was just never wired to it.

## The fix (minimal, render-side, yours to own)

Route facing selection through PROJECTED motion. Compute the screen-space motion
vector (e.g. `IsoProjection.world_to_screen(position) -
IsoProjection.world_to_screen(previous_position)`, or project the velocity
direction) and select the facing from that. The current sprite is still the
4-facing proxy (the full 8-facing atlas is Scott-gated follow-up), so it is fine
to map the projected motion down to the existing 4 `Facing` values, OR to use
`facing_octant` and fold the 8 octants onto the 4 available rows, whichever is
cleaner. The REQUIREMENT is only that the chosen facing matches the projected
on-screen direction. Do not add the full 8-facing atlas here; that is not this
fix.

Keep the change scoped to the facing selection. Do not touch movement/collision
(`move_and_slide` stays authoritative), the sim, the camera, or the art pipeline.

## Gates

- Add or update a test that pins the corrected behavior: a `+y` square step
  selects the facing whose screen direction is down-left (not `DOWN`), a `-y` step
  up-right (not `UP`), etc. This is the regression guard for the exact defect.
- `tools/run_tests.sh` must pass.
- No em-dashes. Every commit carries `Co-authored-by: Claude <claude@sentania.net>`.
- Determinism and sim/render separation hold; facing selection is render-side.

Do not end your turn on an intention. Your durable artifact is the commit.
