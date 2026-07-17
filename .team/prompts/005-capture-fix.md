# Fix: capture_player_walk.gd idle animation corrupts the acceptance montage

You are on branch `claude/005-capture-fix`, branched from the round-005 head
(`3513687`). This is a single-file, fast-lane fix addressing an external Codex
review finding on PR #21. Do the fix, run the suite, commit. Do NOT open a PR
(the orchestrator integrates locally). Do NOT touch anything outside the capture
tool and, if strictly needed, a narrow helper it calls.

## The finding (Codex review round 2, P2, `tools/art/capture_player_walk.gd:58`)

> When this capture runs, the spawned player has no route, so
> `PlayerController2D._physics_process()` calls `_update_walk_animation(delta,
> false)`, which resets `_walk_frame` to zero and reapplies that atlas region.
> Because this loop selects a frame and then awaits the next process/render
> frame, any intervening physics tick overwrites the selection before the
> screenshot, causing the acceptance montage to repeat frame zero or
> nondeterministically omit frames. Disable the player's physics processing
> during capture, or apply the requested region after the wait.

## What to do

Make the per-frame capture deterministic: the frame the loop selects must be the
frame that is on screen when the screenshot is taken, every time, with no physics
tick able to reset `_walk_frame` in between. The two sanctioned approaches from
the finding:

1. Disable the player's physics processing for the duration of the capture
   (`player.set_physics_process(false)`, restore after), so no `_update_walk_
   animation(_, false)` fires; OR
2. Apply the requested atlas region AFTER the await, immediately before the
   screenshot, so any intervening tick's reset is overwritten.

Pick whichever is cleaner and more robust in this tool's actual control flow.
Prefer disabling physics processing if the capture spawns/drives the player node
directly, since it removes the race entirely rather than papering over it.

## Constraints (constitution + round 005)

- No em-dashes anywhere (code, comments, commit message). Hard repo rule.
- Sim/render separation: `src/sim/` stays untouched. This is a render-side
  capture tool.
- Do not change the shipped walk atlas, the projection contract
  (`docs/contracts/iso-projection-contract.md`), or the facing logic. Scope is
  the capture loop's determinism only.
- Run `tools/run_tests.sh` and confirm green before committing. If the capture
  tool has its own check (e.g. `check_walk_sheet.py`), run it too.
- Commit with a `Co-authored-by: Claude <claude@sentania.net>` trailer. Message
  should name the finding ("external Codex review of PR #21 round 2, P2").
- If regenerating `docs/art/player-walk-iso-spike.gif` is trivial and in-scope
  from this tool, you may regenerate it so it shows a correct cycle; if it needs
  the broader pipeline, leave it and note that in your final report (the
  orchestrator will regenerate after integration).

Commit on `claude/005-capture-fix`. Report the commit SHA and whether the GIF was
regenerated.
