---
reviewed_branch: agy/feel
reviewed_sha: 20a324051d0c9c3f1fd23c43c997f176c229d500
reviewed_by: claude-worker
authored_by: agy-worker
timestamp: 2026-07-17T05:42:18Z
tests_run: tools/run_tests.sh
result: signed-off
---

Re-review of the zoom plus visual-feel slice after my refusal at `8491a5c`. I
raised three findings there. All three are closed, and I proved the two
substantive ones closed by re-running the exact mutations that defeated the
earlier test, not by reading the new assertions and believing them.

I ran everything on the merged-with-base result (`round/003-village-feel` merged
with `agy/feel`, merge clean) in a scratch worktree of my own, removed
afterward. I did not edit agy's worktree.

## Finding 1, trailing whitespace: closed

`git diff --check round/003-village-feel...agy/feel` is silent across
`test/active_path/*`, `src/render/*`, `tools/run_tests.sh`, and `project.godot`.
Per the dispatch, I judged only agy's own files and left the dispatcher-generated
`.team/markers/*` hits alone.

## Finding 2, the test did not pin cell size: closed, proved by mutation

At `8491a5c` I set `sprite.scale = Vector2(3, 3)` on every zoom, which changes
the on-screen cell size, and agy's test still printed "All zoom checks passed."
I re-ran that same mutation against the new test. It now goes red:

    ERROR: FAIL: Sprite scale (cell size) stayed pinned
    1 zoom check(s) FAILED.

The mutation showed a real one-line diff (`git diff --stat`: 1 file, 1 insertion)
before the run, so a no-op could not read as a pass, and the tree was clean again
after.

All five invariants named at `docs/contracts/player-world-contract.md:51` are now
pinned across a zoom change: node origin (`player.position`), sprite anchor
(`sprite.offset`), cell size (`sprite.scale`), navigation conversion (both
directions, `world_to_cell` and `cell_to_world_center`), and collider geometry
(`collider.shape` and `collider.position`). Cell size maps to `sprite.scale`
correctly: the contract fixes player display scale at `Vector2.ONE` with a 160 px
animation cell at zoom 1.0, so scale is what governs the on-screen cell.

## Finding 3, the CanvasModulate inverted the smoke hue: closed

I re-derived the arithmetic myself rather than trusting the test's own printout.
The grade is `Color(1.0, 0.95, 0.88)` (`starter_town.gd:59`, unchanged). Agy sets
`smoke.modulate = Color(1/1.0, 1/0.95, 1/0.88)` = `(1, 1.0526, 1.1364)`
(`starter_town.gd:128`). CanvasModulate multiplies the canvas, so the smoke's
effective color is `authored * modulate * grade`, and the two factors cancel to
exactly `(1, 1, 1)`. Effective hue equals authored hue: 197.1, 190.0, and 200.0
degrees across the three gradient stops. That is cyan-blue. It reads cool, and the
cottages around it still take the full warm grade, so the deliberate cool-against-warm
contrast Scott called out survives and the warm sunset grade decision 003 wants is
untouched.

Removing the compensation reproduces my original finding precisely and the new
test catches it:

    Stop 0: authored hue = 197.1 deg, effective hue = 42.7 deg
    ERROR: FAIL: Stop 0 effective hue remains cool
    3 smoke grade check(s) FAILED.

197.1 to 42.7 is a 154.4 degree shift, blue-grey to orange, which is the ~155
degrees I measured at `8491a5c`. Clean `git diff --stat` before and after.

I judged the property, not my own preferred remedy. The one thing I considered
flagging and did not: the grade literal is duplicated at `starter_town.gd:59` and
`:127`, which is a coupling smell. It is not a defect, because the test reads the
real `CanvasModulate.color` off the instantiated scene rather than a literal, so
changing line 59 alone turns the suite red rather than silently drifting. That is
the property that matters and it holds.

## scratch.gd

Gone. `git ls-tree -r --name-only agy/feel` has no match, and the file is absent
from the merged tree. Its hue arithmetic now lives in
`test/active_path/test_smoke_grade.gd`, which is the right home and is wired into
`tools/run_tests.sh`.

## Standing constraints, confirmed not regressed

The `8491a5c..agy/feel` diff touches five non-marker files, so this was cheap to
re-confirm rather than re-derive:

- Sim/render separation holds. `src/sim/` is untouched by the fix commits. The
  dependency runs render to sim (`starter_town.gd` preloads `src/sim/town_layout.gd`
  and `src/sim/nav_grid.gd`), never the reverse. Tile variants are still
  `hash(Vector2i(x, y))` at `starter_town.gd:82`, a pure function of position with
  no RNG anywhere. Contact shadows and the grade are render-side.
- Cursor-anchored zoom stays cut: no `mouse` or `get_global_mouse_position`
  reference in `player_controller_2d.gd`.
- `project.godot` untouched since `8491a5c`, so InputMap actions only and no
  remapping UI.
- Easing stays delta-correct. The only change to `player_controller_2d.gd` is the
  removal of one trailing blank line; the easing I verified at 30, 60, and 240 fps
  is byte-identical.
- No building moves, no flora cut. No em-dashes. Both commits carry
  `Co-authored-by: Antigravity <agy@sentania.net>`.
- `tools/run_tests.sh` green on the merged-with-base result: all active-path
  suites pass, including the new `test_smoke_grade.gd`.

Signed off.

Co-authored-by: Claude <claude@sentania.net>
