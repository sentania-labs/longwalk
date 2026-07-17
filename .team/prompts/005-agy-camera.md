# Round 005 implementation slice: camera drag-pan rework (agy-worker)

This is phase-3 IMPLEMENTATION of round 005. Deliberation is closed. Your
authority is **`docs/decisions/008-isometric-visual-identity.md`** on this
branch, signed 4-0. Read it in full before you write code. Implement it; do not
relitigate it.

You are on branch `agy/005-camera`, cut from the round branch
`round/005-isometric-art`. Commit your slice here. Do not push, do not open a PR
(doers never open PRs, per decision 004). Report your final commit SHA in your
output.

## Your slice, and only your slice

Per decision 008's division of labor, you own the **camera drag-pan rework**. You
authored `camera_rig_2d.gd` in round 004, so the FOLLOW/FOCUSED state machine is
yours to rework. claude owns the render spine (projection, y-sort, movement);
codex owns art + pipeline. Keep their work out of your diff. In particular, do
NOT edit `src/render/iso/*` (claude's projection module) or `tools/art/*`
(codex's pipeline). You may edit `project.godot` (the ONE protected path this
round; decision 008 authorizes it for the drag binding).

Deliverables (decision 008 section 3 + the division-of-labor row + Scott's 1720
playtest refinement):

1. **Replace round-004's right-click point-recenter with map PANNING.**
   Right-click-DRAG to scroll the map is the requirement (Scott's 1720 feedback,
   preference (a)). Rework the existing `camera_rig_2d.gd` rig; do not discard it.
2. **A DRAG camera state** with a **click-vs-drag pixel threshold** (a short
   press that does not cross the threshold is a click, not a pan; only crossing it
   enters DRAG). This is the critique's catch: the FOLLOW `_process` overwrites
   the pan every frame unless an explicit DRAG-state transition guards it. Guard
   it.
3. **`relative / zoom`-correct panning.** Pan by the mouse relative motion divided
   by the current zoom, so a drag moves the map by the same screen distance at
   every zoom level (the critique's `/zoom` divide catch: screen pixels vs world
   units are only equal at zoom 1.0).
4. **Retire `focus_view` as the PRIMARY verb.** Round-004 bound point-recenter to
   RMB; do not leave `pan_drag` double-firing against a live `focus_view` RMB
   bind. Retire `focus_view` from the primary RMB role (keep it only if it still
   has a non-conflicting secondary role; otherwise remove its binding).
5. **Cursor-preserving zoom.** Zooming keeps the world point under the cursor
   fixed under the cursor.
6. **Clamp to `projected_bounds()`.** The camera clamps to claude's frozen
   render-side `projected_bounds()` (from the four projected diamond corners plus
   sprite headroom), NOT to `_layout.pixel_size()` as an axis-aligned rectangle
   (the walkable diamond does not inscribe that rect under iso). Consume claude's
   contract; do not re-derive projection yourself.
7. **`project.godot` `pan_drag` input binding** for the drag verb.

## You consume claude's frozen projection contract, you do not re-derive it

claude's render spine (dispatched before you) exposes `projected_bounds()` and
`screen_to_cell()` as a FROZEN render-side contract. Clamp to `projected_bounds()`
and route any picking through `screen_to_cell()`. Do NOT reimplement projection
math in the camera rig. The exact contract location and signatures are pinned in
the CONTRACT section appended to this prompt below.

## Gates

- `tools/run_tests.sh` must pass on your branch. If a round-004 camera test
  asserts the old point-recenter behavior, update it to the new drag-pan contract
  (do not weaken an assertion to make it pass).
- `project.godot` is a protected path; decision 008 authorizes your edit to it for
  the drag binding. Keep the edit minimal and scoped to the input map.
- Determinism and sim/render separation hold. The camera is render-side; it must
  not reach into `src/sim/`.
- No em-dashes anywhere, including commit messages (constitution, absolute).
- Every commit carries `Co-authored-by: Antigravity <agy@sentania.net>`.

## Blocked

If genuinely blocked, write a BLOCKED marker on THIS branch per
`.team/blocked/README.md`, commit and push it, and report branch + marker path +
one sentence. The bar is high: large gets scoped down and shipped smaller with a
note on what you cut, not blocked. Do not end your turn on an intention.

## CONTRACT (claude's frozen render-spine interface)

Landed on this branch's base (round branch now includes claude's slice). Full
note: `docs/contracts/iso-projection-contract.md`. Executable surface:
`src/render/iso/projection.gd` (`IsoProjection`). Pinned by
`test/active_path/test_iso_projection.gd`. The functions YOU consume:

- `projected_bounds(grid_size: Vector2i, headroom := Vector2.ZERO) -> Rect2` the
  screen-space AABB the camera must not show outside of. It is the bounding
  rectangle of the FOUR PROJECTED DIAMOND CORNERS of the walkable grid, grown by
  `headroom` (`headroom.x` grows left/right, `headroom.y` grows top/bottom).
  Clamp your view to this. DO NOT derive bounds from `TownLayout.pixel_size()`.
  Set `headroom.y` to cover at least the tallest sprite's height above its ground
  contact plus the deepest cast shadow below it.
- `screen_to_cell(screen: Vector2) -> Vector2i` inverse projection to the
  containing integer cell (floored). Route picking through this.
- `screen_to_world(screen) -> Vector2` continuous inverse for a sub-cell landing
  point if you need it. `world_to_screen(world_px) -> Vector2` forward projection.

**Camera seam (your job to close):** on the render-spine branch `CameraRig2D`
still follows the player's SQUARE-space body position (round-004 behavior), so in
isolation the camera looks at square coordinates while the world draws in iso.
Your rework retargets the camera to PROJECTED space: follow
`world_to_screen(player.position)`, clamp the view to `projected_bounds(...)`, and
invert picking through `screen_to_cell(...)`. Coordinate spaces: cell space
(logical grid), world-pixel square space (`TILE_SIZE`=128, physics), screen iso
space (`TILE_W`x`TILE_H`=128x64 diamond, one grid step = `(64,32)`).
