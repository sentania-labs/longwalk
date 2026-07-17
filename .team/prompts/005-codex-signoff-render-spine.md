# Peer sign-off review: claude's render-spine slice (codex-worker as reviewer)

You are the NON-AUTHOR peer reviewer for claude-worker's round-005 render-spine
slice. This is the pre-integration peer sign-off gate (layer 1). No marker, no
integration. You did NOT write this code; your job is to check it, not to praise
it.

The branch `claude/005-render-spine` is checked out in this worktree at commit
**`e18dc9f521a98c35dcbf6271165d0d637fd4affd`**. Its parent (the round base) is
`round/005-isometric-art` at `43459d4`. Review the slice:

    git show e18dc9f521a9
    git diff 43459d4..e18dc9f521a9

## What to check (a sign-off is a claim you actually checked these)

1. **Run the suite.** `tools/run_tests.sh` must pass. Actually run it. Record the
   command in `tests_run`.
2. **Constitution conformance.** Determinism (no unseeded/stateful RNG, no
   iteration-order accumulator in the depth tie key `stable_offset`); strict
   sim/render separation (NO projection symbol or screen coordinate in `src/sim/`,
   the whole point of the override); no em-dashes anywhere in the diff.
3. **Matches decision 008, not the author's preference.** KEEP-AUTHORITATIVE
   movement (`move_and_slide` and the footprint colliders retained unchanged, Q-B);
   render-side projection spine (`src/render/iso/`); footprint-aware depth with a
   stable placement-id tie key; `projected_bounds()` built from the four projected
   diamond corners, NOT `pixel_size()`; the round-004 P2 capture-tool node-path fix
   folded in.
4. **The frozen contract is real and usable.** `docs/contracts/iso-projection-contract.md`
   plus `src/render/iso/projection.gd` must actually give agy (`projected_bounds()`,
   `screen_to_cell()`) and codex (`facing_octant` row order, ground-contact anchor
   convention) a stable surface to implement against. Flag any gap that would
   force a downstream slice to re-derive projection.
5. **Adversarial spot-check.** Consider mutation-testing one invariant (as agy did
   for the road slice): perturb something the test claims to pin and confirm the
   suite fails. Report what you tried.

## Write the marker

If it passes, write `.team/signoffs/claude-005-render-spine-e18dc9f521a9.md` with
front matter EXACTLY per `.team/signoffs/README.md`:

    ---
    reviewed_branch: claude/005-render-spine
    reviewed_sha: e18dc9f521a98c35dcbf6271165d0d637fd4affd
    reviewed_by: codex-worker
    authored_by: claude-worker
    timestamp: <UTC ISO-8601 Z>
    tests_run: tools/run_tests.sh
    result: signed-off
    ---

Then a short prose note on what you actually checked and any adversarial probe.
`reviewed_by` MUST be `codex-worker` and MUST NOT equal `authored_by`.

Commit the marker onto `claude/005-render-spine` (do NOT amend or rebase
`e18dc9f5`; the marker is a new commit on top that NAMES `e18dc9f5`). Commit
message trailer `Co-authored-by: Codex <codex@sentania.net>`. No em-dashes. Report
the marker commit SHA in your output.

If you find a real defect, write the marker with `result: changes-requested`
instead, prose stating the defect precisely, commit it, and report it. Do not
sign off work you would not stake your name on.
