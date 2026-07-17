# Player and world contract

This contract is the shared baseline for the decision 003 art, navigation, and
visual-feel slices. The executable fixture is
`test/fixtures/player_world_fixture.gd`, and
`test/active_path/test_player_world_contract.gd` checks it against the real
player scene and starter-town layout.

## Player origin and feet anchor

The `Player` `CharacterBody2D` origin `(0, 0)` is the point on the ground
directly beneath the player, between the feet. It is all of the following:

- the world position used for navigation and cell placement;
- the player's Y-sort key;
- the ground-contact line used by sprite authors and animation processing.

Visual animation may move or replace the visual child, but it must never move
the `CharacterBody2D` to create bobbing or pose motion.

Every shipping animation cell is 160 by 160 pixels. Pixel rows are zero based,
so row 159 is the feet-contact row. Opaque sole pixels may occupy row 159 but
must not be clipped by it. The cell boundary immediately below row 159 maps to
the player origin. With a centered `Sprite2D`, this is the existing
`offset = Vector2(0, -80)` contract: the cell spans local y coordinates
`[-160, 0]` and is drawn upward from the origin.

The anchor-drift gate measures the lowest grounded sole pixel against row 159
in each source frame, before mirroring and recoloring. Empty padding below the
sole changes the anchor and fails the contract even if every cell has the right
dimensions.

Current one-pose compatibility textures are 66 by 160 pixels after their
content crop. They obey the same 160 px height and ground-contact line and are
centered horizontally. They do not redefine the animation-cell width.

## World scale

The scale is fixed for this round:

| Quantity | Shipping value |
| --- | --- |
| Town tile | 128 by 128 world pixels |
| Animation cell | 160 by 160 source pixels |
| Player display scale | `Vector2.ONE` |
| Animation cell on screen at zoom 1.0 | 160 by 160 pixels |
| Player origin within a navigated tile | tile center |

There is no asset-to-world rescaling hidden in the player scene. At zoom 1.0,
one source pixel is one world pixel and one screen pixel. Camera zoom may change
the final screen footprint, but it must not change the node origin, sprite
anchor, cell size, navigation conversion, or collider geometry.

A 160 px player cell is intentionally taller than a 128 px tile. Only the feet
are grounded at the tile center. The upper 160 px are visual overhang and do not
expand the navigation footprint. Collision remains the existing 36 by 20 px
rectangle positioned at `(0, -10)` relative to the feet origin.

## Shared starter-town fixture

All three slices use `PlayerWorldFixture`, not a private copy of these values.
It builds the real `TownLayout.build_starter_town()` and pins:

- layout size: 18 by 14 cells;
- world size: 2304 by 1792 pixels;
- street row: 7;
- player spawn cell: `(9, 7)`;
- player spawn world position: `(1216, 960)`, the center of that cell;
- unchanged building placements and footprints from
  `TownLayout.build_starter_town()`.

The fixture deliberately does not duplicate building data. Consumers inspect
the real authored layout returned by `build_layout()`, and the contract test
pins its current placements. This keeps navigation, collision, captures, and
feel work on one authored town while making any building move an explicit test
change. Decision 003 forbids such a move during this round.

Texture paths, sprite lookup, anchors, and camera state remain render-side.
The fixture may read both sim and render artifacts to test their agreement, but
it is test code and is not a dependency of `src/sim/`.
