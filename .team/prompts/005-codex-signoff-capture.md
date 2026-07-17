# Peer sign-off review: claude's capture-fix slice (codex-worker as reviewer)

You are the NON-AUTHOR peer reviewer for claude-worker's round-005 capture-tool
determinism fix. This is the pre-integration peer sign-off gate (layer 1). No
marker, no integration. You did NOT write this fix. You are the natural reviewer:
this fix addresses the exact P2 race an external Codex review of PR #21 flagged
in `tools/art/capture_player_walk.gd`.

The branch `claude/005-capture-fix` is checked out in this worktree at commit
**`2be134d772da7ad2cae468002416720d9d316599`**, parent `3513687` (the round
head). Review:

    git show 2be134d772da7ad2cae468002416720d9d316599
    git diff 3513687..2be134d772da7ad2cae468002416720d9d316599

## What to check (a sign-off is a claim you actually checked these)

1. **Run the suite.** `tools/run_tests.sh` must pass. Record it in `tests_run`.
2. **The fix actually removes the race.** The commit disables the player's
   physics processing (`player.set_physics_process(false)`) so
   `_update_walk_animation(_, false)` no longer resets `_walk_frame` to zero
   between the loop's region selection and the screenshot. Confirm: (a) nothing
   else in the capture loop drives the player node or re-applies an atlas region
   after the await, so no other path can still overwrite the selected frame; and
   (b) disabling physics processing does not break the capture itself (the node
   still renders the region the loop set). If a real defect remains, write
   `result: changes-requested` with the precise failure rather than signing off.
3. **Constitution + boundary.** No `src/sim/` edit; shipped walk atlas, iso
   projection contract (`docs/contracts/iso-projection-contract.md`), and facing
   logic unchanged; no em-dashes in the diff. Scope is capture-loop determinism
   only.

## Write the marker

If it passes, write `.team/signoffs/claude-005-capture-fix-2be134d772da.md` with
front matter EXACTLY per `.team/signoffs/README.md`:

    ---
    reviewed_branch: claude/005-capture-fix
    reviewed_sha: 2be134d772da7ad2cae468002416720d9d316599
    reviewed_by: codex-worker
    authored_by: claude-worker
    timestamp: <UTC ISO-8601 Z>
    tests_run: tools/run_tests.sh
    result: signed-off
    ---

Then a short prose note on what you checked, especially your verdict on whether
any other path can still overwrite the selected frame. `reviewed_by` MUST be
`codex-worker` and MUST NOT equal `authored_by` (`claude-worker`).

Commit the marker onto `claude/005-capture-fix` (do NOT amend or rebase
`2be134d`; the marker is a new commit on top that NAMES it). Trailer
`Co-authored-by: Codex <codex@sentania.net>`. No em-dashes. Report the marker
commit SHA. If you find a real defect, use `result: changes-requested`, state it
precisely, commit, and report it. Do not sign off work you would not stake your
name on.
