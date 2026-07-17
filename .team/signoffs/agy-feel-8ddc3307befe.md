---
reviewed_branch: agy/feel
reviewed_sha: 8ddc3307befe3dc095bf2605459336da37028c50
reviewed_by: claude-worker
authored_by: agy-worker
timestamp: 2026-07-17T07:12:33Z
tests_run: tools/run_tests.sh
result: signed-off
---

Reviewed read-only from a scratch worktree at `/tmp/claude-review-8ddc330`
(detached at 8ddc330). `agy/feel` already contains
`origin/round/003-village-feel`, so the branch head is the merged-with-base
result and `tools/run_tests.sh` was run against it directly. All active-path
suites pass. Left `/home/scott/claude/longwalk-worktrees/agy-feel` untouched.

## The P2 is actually fixed

Confirmed the arithmetic the orchestrator flagged. At the authored 18x14 town
and `TILE_SIZE` 128 the town is 2304x1792 world px, and a 1280x720 viewport at
zoom 0.5 spans 2560x1440, overshooting the x axis. The derived floor is
`maxf(1280/2304, 720/1792) = maxf(0.5556, 0.4018) = 0.5556`, which is the
correct direction: visible = viewport/zoom, so fitting requires
zoom >= viewport/town, and the binding axis is the max, not the min. At the
floor the viewport spans exactly 2304x1296, inside the town on both axes, so
camera limits can contain it. `_recompute_zoom_levels()` drops 0.5 (the only
hard level below the floor), giving `[0.5556, 0.75, 1.0, 1.25, 1.5, 2.0]`.

## The two things I was asked to look at

**Index remap and out-of-range read: safe, verified empirically rather than by
reading.** `_zoom_levels[_zoom_index]` is read before `_zoom_levels` is
reassigned, and `_zoom_index` is always a valid index of the *old* list because
`_set_zoom_index()` is the only other writer and it clamps. I did not want to
rest on that argument alone, so I drove it with a throwaway probe: after
`set_layout(starter)` the index is 2 and the target is 1.0 (the default zoom is
preserved through the rebuild); after forcing the index to the top (5, zoom 2.0)
and then calling `set_layout()` with a 5x4 layout, the list collapses to `[2.0]`
and the index remaps to 0, in range, no crash; growing back to the starter town
restores index 5. The list shrinking under a live index does not fault.

**Step distribution: acceptable here, latent fragility noted below.** Ratios
across the shipped ladder are 1.35, 1.33, 1.25, 1.2, 1.33. The derived floor
produces the *widest* step, not a bunched pair, so there is nothing a player
would notice. This is a property of the current dimensions rather than of the
algorithm: a town whose floor landed at, say, 0.74 would yield a `[0.74, 0.75]`
pair 1.3% apart, a wasted detent. Not a defect today, recorded as observation 2.

**The new test asserts the floor, not wherever the easing settled.** The easing
in `_process` snaps (`if abs(new_z - _target_zoom) < 0.001: new_z = _target_zoom`),
so after 100 ticks `camera.zoom.x` is exactly `_target_zoom`, and
`_set_zoom_index(-1)` clamps to index 0. The test therefore reads the floor
itself. Killed by mutation, not assumed: inverting `maxf` to `minf` fails both
new checks, and deleting the `_recompute_zoom_levels()` call from `set_layout()`
fails the width check.

## Contract invariants: re-pinned by mutation

The zoom path changed underneath `test_player_world_contract.gd`, so I
re-proved all five rather than re-reading the assertions. `git diff --stat`
before every run confirmed the mutation was actually applied (a mutation that
changes nothing showing green is not a plausible result), and the tree was
restored after each:

| mutation | killed by |
| --- | --- |
| collider size 36 -> 37 (`scenes/player.tscn`) | "player collider remains 36 by 20 pixels" |
| sprite offset -80 -> -79 | "160 px visual ends at the feet origin" |
| collider position -10 -> -11 | "player collider remains positioned relative to the feet origin" |
| `TILE_SIZE` 128 -> 127 (`src/sim/town_layout.gd`) | "fixture tile size matches TownLayout" + pixel size |
| town width 18 -> 19 | "starter-town dimensions stay fixed" + pixel size |

All five still pin what they claim.

## Standing constraints

- Sim/render separation intact. The new code reads `ProjectSettings` viewport
  dimensions inside `src/render/town/player_controller_2d.gd` and reads the town
  via `_layout.pixel_size()`, which is render reading sim, the correct
  direction. Grepping `src/sim/` for viewport, Camera, ProjectSettings, and zoom
  returns only the existing comments asserting the absence of those
  dependencies. No leak.
- No RNG introduced. No em-dashes in the diff or the commit messages.
- `Co-authored-by: Antigravity <agy@sentania.net>` present on all three commits.
- Diff touches only `player_controller_2d.gd` and `test_player_zoom.gd`, so
  cursor-anchored zoom stays cut, no building moves, no flora.
- Trailing whitespace confirmed closed:
  `git diff --check origin/round/003-village-feel...HEAD` is silent at 8ddc330.
- Per the orchestrator's instruction I did not treat the deletion of
  `.team/blocked/agy-worker-20260717T065454Z.md` as a finding against this diff;
  the orchestrator directed it and is restoring the marker at integration.

## Observations, non-blocking, not conditions of this sign-off

1. **The remap is entirely unpinned.** Replacing the whole
   `for i in range(_zoom_levels.size())` remap block with
   `_zoom_index = _zoom_levels.size() - 1` (jump to max zoom on every
   `set_layout()`) passes the full suite. The code as written is correct, I
   verified that by probe, but nothing would catch a regression that changed the
   player's zoom on layout load. Worth a test that pins index 2 / target 1.0
   after `set_layout(starter)`.
2. **The new checks sit on an exact float boundary and pass on a rounding
   coin-flip.** `camera.zoom` is a `Vector2` of 32-bit floats, so the double
   floor 0.55555555555555558 is stored as 0.55555558204650879. That rounds *up*,
   so the viewport spans 2303.99989 px and `vis_w <= town_w` holds with 0.0001 px
   to spare. It is luck rather than margin: on the y axis
   0.4017857142857143 quantizes *down* to 0.40178570151329041, which overshoots
   1792 by 0.00006 px. That is exactly why the `minf` mutation failed the height
   check even though double arithmetic gives 1792 <= 1792 exactly. Shipped
   behavior is correct because the x axis binds and happens to round up, but a
   change to town or viewport dimensions could flip this to a red suite for a
   sub-pixel reason unrelated to any real bug. An epsilon on the two comparisons
   would make the test say what it means.

Neither observation is a correctness defect in the shipped fix, so neither
blocks. Both are follow-up material for the orchestrator.

Co-authored-by: Claude <claude@sentania.net>
