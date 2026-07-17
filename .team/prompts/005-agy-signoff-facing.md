# Peer sign-off review: claude's facing fix (agy-worker as reviewer)

You are the NON-AUTHOR peer reviewer for claude-worker's round-005 facing fix,
which addresses the one P1 the external Codex review raised on round PR #21. This
is the pre-integration peer sign-off gate. No marker, no integration. You did NOT
write this fix.

The branch `claude/005-facing-fix` is checked out in this worktree at commit
**`ef83d300a6ddec7232e8acd0f146ecf48faa2061`**, parent `63ecca8` (the integrated
round head). Review:

    git show ef83d300
    git diff 63ecca8..ef83d300

## The defect being fixed

`player_controller_2d.gd _update_facing()` selected the walk facing by comparing
square-space `direction.x` vs `direction.y`, but the sprite is drawn through the
iso projection, so a `+y` grid step (projects down-left) wrongly showed
`Facing.DOWN`. The fix routes facing through `IsoProjection.facing_octant(
IsoProjection.cell_to_screen(direction))` and folds the eight octants onto the
four proxy rows (full 8-facing atlas is Scott-gated follow-up).

## What to check (a sign-off is a claim you actually checked these)

1. **Run the suite.** `tools/run_tests.sh` must pass, including the updated
   regression test in `test/active_path/test_player_world_contract.gd`. Record it.
2. **The fix is correct.** Projecting the velocity direction through
   `cell_to_screen` gives the screen-motion direction because the projection is
   linear with no constant term. Confirm the octant->facing fold in
   `_OCTANT_TO_FACING` is sensible: pure toward-camera (`+y`, S) maps to DOWN,
   pure away (`-y`, N) to UP, and the sideways/diagonal octants to LEFT/RIGHT
   consistent with their on-screen lean. Confirm the `FACING_NEUTRAL` deadzone is
   handled (hold last facing).
3. **Scoped + constitution.** The diff touches only the facing selection and its
   test. No `move_and_slide`/collision change, no `src/sim/` edit, no camera or
   art-pipeline edit, no em-dashes. The regression test actually pins the defect
   (a `+y` step no longer selects DOWN).
4. **Adversarial spot-check.** Consider perturbing the fold table or reverting to
   the square-space comparison and confirming the new test fails.

## Write the marker

If it passes, write `.team/signoffs/claude-005-facing-fix-ef83d300a6dd.md`:

    ---
    reviewed_branch: claude/005-facing-fix
    reviewed_sha: ef83d300a6ddec7232e8acd0f146ecf48faa2061
    reviewed_by: agy-worker
    authored_by: claude-worker
    timestamp: <UTC ISO-8601 Z>
    tests_run: tools/run_tests.sh
    result: signed-off
    ---

Then a short prose note on what you checked and your fold-correctness verdict.
`reviewed_by` MUST be `agy-worker`, MUST NOT equal `authored_by` (`claude-worker`).

Commit the marker onto `claude/005-facing-fix` (do NOT amend/rebase `ef83d300`;
new commit on top naming `ef83d300`). Trailer
`Co-authored-by: Antigravity <agy@sentania.net>`. No em-dashes. Report the marker
SHA. If you find a real defect, use `result: changes-requested`, state it, commit,
report. Do not sign off work you would not stake your name on.
