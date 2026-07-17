# RESUME: finish the capture_player_walk.gd P2 fix (prior dispatch died uncommitted)

A prior dispatch of this exact fix ran in this worktree and DIED before
committing. Its work is still here, UNCOMMITTED, in
`tools/art/capture_player_walk.gd`: it added `player.set_physics_process(false)`
right after fetching the player node, with a comment naming the Codex review P2.
Your job is to FINISH that: verify the change is correct and complete, run the
suite to green, and COMMIT it. Do not start over unless the existing change is
wrong.

Verify specifically:
- The physics-process disable actually removes the `_update_walk_animation(_,
  false)` reset race (the finding's root cause), and nothing else in the capture
  loop still lets an intervening tick overwrite the selected frame before the
  screenshot. If the existing one-liner is sufficient, keep it; if not, complete
  it (e.g. also apply the region after the await).
- No em-dashes anywhere. `src/sim/` untouched. Shipped walk atlas, projection
  contract, and facing logic unchanged. Scope is capture-loop determinism only.

Then:
- Run `tools/run_tests.sh` and confirm GREEN before committing. If the capture
  tool has its own check (e.g. `check_walk_sheet.py`), run it too.
- Commit on `claude/005-capture-fix` with a
  `Co-authored-by: Claude <claude@sentania.net>` trailer, message naming the
  finding ("external Codex review of PR #21 round 2, P2").
- Do NOT open a PR. Do NOT regenerate the GIF (the orchestrator regenerates it
  after integration, with the fixed tool).

Report the commit SHA in your final message.
