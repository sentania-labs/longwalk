---
reviewed_branch: codex/contract
reviewed_sha: 9113d639954583d06bbfca924a5d317c4bd21fb5
reviewed_by: claude-worker
authored_by: codex-worker
timestamp: 2026-07-17T04:58:40Z
tests_run: tools/run_tests.sh
result: signed-off
---

Reviewed the shared player/world contract against the tree, not against its own
prose. I authored the nav slice this contract claims to document, so the
specific failure I went looking for was a contract that contradicts integrated
code or that documents geometry it merely asserts.

Every claimed value checks out against the real artifacts:

- `offset = Vector2(0, -80)` and the 36 by 20 collider at `(0, -10)`: match
  `scenes/player.tscn` exactly.
- 18 by 14 layout, 128 px tiles: match `src/sim/town_layout.gd`
  (`build_starter_town()` and `TILE_SIZE`). World size 2304 by 1792 follows.
- Spawn cell `(9, 7)` at world `(1216, 960)`: `starter_town.gd` derives the
  spawn as `Vector2i(int(width / 2.0), 7)`, which is `(9, 7)` given the pinned
  18-wide layout, centered to `(1216, 960)`. The cell is walkable: street row 7
  carries no building footprint at x=9.
- 66 by 160 compatibility textures: confirmed by reading the PNG headers of all
  three processed variants.
- Four authored building placements: match the hand-placed data exactly.

The test is real, not decorative. It instantiates `scenes/player.tscn` and reads
actual node values rather than restating fixture literals. I proved failures can
fail by mutation, checking `git diff --stat` before each run so a no-op mutation
could not read as a pass:

1. Sprite offset `-80` to `-70` in the real scene: red on "160 px visual ends at
   the feet origin".
2. Collider `36x20` to `36x21` in the real scene: red on "player collider
   remains 36 by 20 pixels".
3. Town width 18 to 19 in the real sim layout: red on both "starter-town
   dimensions stay fixed" and "starter-town pixel size follows the fixed scale".

Each mutation showed a real one-line diff before the run and each reverted to a
clean tree afterward. Baseline and full suite green: all four active-path
suites pass, and the new suite is wired into `tools/run_tests.sh`.

Sim/render separation holds, and more strongly than the contract claims for
itself. The fixture preloads only `src/sim/town_layout.gd`; the render read
(`scenes/player.tscn`) lives in the test file, not the fixture. Direction is
test to sim throughout, and `src/sim/` has zero references to the fixture, to
`test/`, to `scenes/`, or to `src/render/`.

Sufficiency for the downstream slices: adequate. The feel slice gets the world
scale it binds to (128 px tile, 160 px cell, `Vector2.ONE` display scale, one
source pixel to one world pixel at zoom 1.0, and the rule that zoom may not
move the origin, anchor, cell size, or collider). The art slice gets the feet
anchor and, for the anchor-drift gate, the half that was actually missing:
which row is the contact row (159, zero based) and that empty padding below the
sole fails even when cell dimensions are right. The gate's numeric threshold
(max anchor-y stdev 0.05) is not restated here, but it does not need to be:
it is already recorded in `docs/decisions/004-round-branch-integration-and-voting-model.md`,
which the art slice is dispatched against. Neither slice needs to ask codex a
question.

No em-dashes in any of the four files. Nothing here re-litigates decision 003;
the contract explicitly defers to it on the frozen town.

Co-authored-by: Claude <claude@sentania.net>
