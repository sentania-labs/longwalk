# Isometric projection contract

Frozen render-side interface for round 005 (decision
[008](../decisions/008-isometric-visual-identity.md)). The render spine slice
(claude-worker) owns and freezes it; the camera slice (agy-worker) and the art
slice (codex-worker) implement against it. The executable surface is
`src/render/iso/projection.gd` (`IsoProjection`); the depth and edge behavior is
pinned by `test/active_path/test_iso_projection.gd`.

Decision 007 and 008 keep the sim square-grid and projection-ignorant: every
symbol here is render-side, and no screen coordinate or projection call may enter
`src/sim/`.

## Coordinate spaces

- **Cell space** is the sim's logical grid `(column x, row y)`. Cells may be
  fractional; the center of cell `(3, 4)` is `Vector2(3.5, 4.5)`. This is what
  `TownLayout` and `NavGrid` speak.
- **World-pixel space (square)** is the authoritative physics space
  (`CharacterBody2D`, `StaticBody2D` colliders), one cell = `TILE_SIZE` (128) px
  square, unchanged from round 004. Decision 008 Q-B keeps movement and collision
  here.
- **Screen space (isometric)** is what the render layer draws in. A cell renders
  as a `TILE_W` x `TILE_H` (128 x 64, 2:1) diamond. A single grid-axis step moves
  the screen point by `(HALF_W, HALF_H) = (64, 32)`.

## Frozen functions (consumed by agy's camera)

- `cell_to_screen(cell: Vector2) -> Vector2` project a (possibly fractional) cell
  to its screen point. `(0,0)` maps to screen origin; `+x` goes down-right, `+y`
  down-left.
- `world_to_screen(world_px: Vector2) -> Vector2` continuous square-pixel to
  screen; equals `cell_to_screen(world_px / TILE_SIZE)`.
- `screen_to_cell(screen: Vector2) -> Vector2i` inverse projection to the
  containing integer cell (floored, matching `NavGrid.world_to_cell`). This is
  the ONLY inversion used in gameplay, at the input boundary (a click's screen
  point to the cell to route to).
- `screen_to_world(screen: Vector2) -> Vector2` continuous inverse to square
  pixels, for callers that need the sub-cell landing point.
- `projected_bounds(grid_size: Vector2i, headroom := Vector2.ZERO) -> Rect2` the
  screen-space AABB the camera must not show outside of. It is the bounding
  rectangle of the FOUR PROJECTED DIAMOND CORNERS of the walkable grid, grown by
  `headroom` (`headroom.x` grows left and right, `headroom.y` grows top and
  bottom). **Do not derive camera bounds from `TownLayout.pixel_size()`**: under
  iso the walkable diamond does not inscribe that axis-aligned rectangle (the
  critique's camera-bounds catch, decision 008 point 3). `headroom.y` should
  cover at least the tallest sprite's height above its ground contact plus the
  deepest cast shadow below it, so a tall building at the back edge is not
  clipped.

### Camera seam note

On the render-spine branch the interactive `CameraRig2D` still follows the
player's square-space body position (round 004 behavior), so in isolation the
camera looks at square coordinates while the world draws in iso. agy's drag-pan
rework retargets the camera to projected space: follow
`world_to_screen(player.position)`, clamp the view to `projected_bounds(...)`,
and invert picking through `screen_to_cell(...)`. The acceptance-capture tool
(`tools/art/capture_player_walk.gd`) sets up its own camera in projected space,
so the spike artifact does not wait on the camera rework.

## Facing ids (consumed by codex's walk sheet)

`facing_octant(screen_motion: Vector2) -> int` quantizes SCREEN-space motion to
eight fixed 45deg sectors, or `FACING_NEUTRAL` (-1) below the deadzone (hold last
facing, show idle frame). Callers project sim motion into screen space first
(e.g. `world_to_screen(pos) - world_to_screen(prev)`), not the raw square
velocity. This is decision 008 point 1's blind frame-selection code.

Frozen row order for the generated 8-facing walk sheet (screen space is y-down,
so `+y` is toward the camera / "south"):

| id | direction | screen motion |
| --- | --- | --- |
| 0 | E  | `+x` |
| 1 | SE | down-right |
| 2 | S  | `+y` (toward camera) |
| 3 | SW | down-left |
| 4 | W  | `-x` |
| 5 | NW | up-left |
| 6 | N  | `-y` (away from camera) |
| 7 | NE | up-right |

Sectors are centered on each id direction, spanning +/- 22.5deg; a motion exactly
on a boundary rounds to the neighbouring sector away from zero.

Runtime wiring of the player controller to these eight rows (six-frame cycle
advanced by accumulated distance, neutral at rest) lands with codex's 8-facing
atlas; until then the controller renders the existing 4-facing sheet as its
display proxy. The `facing_octant` convention above is frozen now so codex
generates rows in this order.

## Ground-contact anchor (consumed by codex's iso sprites)

World objects in the depth-sorted layer are anchored at their ground CONTACT
point, projected into screen space, and drawn UPWARD from it.

- **Actor (player):** contact is the `CharacterBody2D` origin (the feet, decision
  003), i.e. `world_to_screen(body.position)`. The sprite is drawn upward via its
  existing `offset = (0, -80)`.
- **Building footprint:** contact is `building_contact_cell(origin_cell,
  footprint)` = the center of the footprint's FRONT (max screen-Y) edge, one full
  footprint-height below the top-left origin cell. A generated iso building sprite
  must place its ground-contact line at this projected point, drawn upward from
  it. A multi-cell building is anchored here for both draw position and depth key.

## Depth sorting

The world-object layer is drawn back-to-front by depth key, larger drawing in
FRONT. Godot's bare `y_sort_enabled` cannot express the stable tie key or a
multi-cell footprint anchor, so depth is a manual `z_index` rank instead.

- `depth_key(contact_cell: Vector2, placement_id: String) -> float` =
  `cell_to_screen(contact_cell).y + stable_offset(placement_id)`.
- `stable_offset(placement_id: String) -> float` is a deterministic sub-pixel tie
  key in `[0, 0.5)` (pure function of the id string: no RNG, no time, no
  iteration order). Every cell on one iso anti-diagonal projects to the SAME
  screen Y, so exact ties are frequent; the tie key decides them deterministically
  rather than leaving them to tree order. Its magnitude stays well under the
  minimum non-zero row gap (`HALF_H` = 32 px), so it never reorders objects at
  distinct depths.

The occlusion contract is exact for an actor in front of or behind a footprint,
and defers to the stable tie key for an actor level with the front edge. Perfect
per-cell occlusion for an actor tucked alongside a tall multi-cell building is out
of scope this round; the behavior is pinned with the actor at every footprint edge
in `test_iso_projection.gd`.
