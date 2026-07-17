# Peer sign-off review: codex's manifest-doc-fix slice (claude-worker as reviewer)

You are the NON-AUTHOR peer reviewer for codex-worker's round-005
manifest/README documentation fix. This is the pre-integration peer sign-off
gate (layer 1). No marker, no integration. You did NOT write this fix. It
addresses the P2 an external Codex review of PR #21 flagged: making `manifest`
positional in `process_assets.py` broke the documented regeneration command in
`tools/art/README.md`.

The branch `codex/005-manifest-doc-fix` is checked out in this worktree at commit
**`39f213026876cce688608fbef3994f62843bb349`**, parent `3513687` (the round
head). Review:

    git show 39f213026876cce688608fbef3994f62843bb349
    git diff 3513687..39f213026876cce688608fbef3994f62843bb349

## What to check (a sign-off is a claim you actually checked these)

1. **Run the suite.** `tools/run_tests.sh` must pass. Record it in `tests_run`.
2. **The documented command actually works and reproduces the assets.** This is
   the load-bearing check: the README now documents `python3
   tools/art/process_assets.py tools/art/manifests/process-iso.json`. Confirm
   this MATCHES the real CLI (positional required `manifest` arg in
   `process_assets.py`) AND actually reproduces the committed processed assets.
   Run it (or a dry-run/hash-compare against the committed `out/iso/processed/`
   PNGs) and confirm the documented path genuinely regenerates the live assets.
   Do NOT commit any regenerated binaries; just verify. If the documented path
   does not reproduce them, the README is still lying: write
   `result: changes-requested` with the precise gap.
3. **README is honest.** It no longer describes outputs or appearance variants
   the current pipeline does not generate. Spot-check the rewritten sections
   against what `process_assets.py` actually produces.
4. **Constitution.** Determinism preserved (no time/random seeding, no
   order-dependence introduced); `src/sim/` untouched; no em-dashes in the diff.

## Write the marker

If it passes, write `.team/signoffs/codex-005-manifest-doc-fix-39f213026876.md`
with front matter EXACTLY per `.team/signoffs/README.md`:

    ---
    reviewed_branch: codex/005-manifest-doc-fix
    reviewed_sha: 39f213026876cce688608fbef3994f62843bb349
    reviewed_by: claude-worker
    authored_by: codex-worker
    timestamp: <UTC ISO-8601 Z>
    tests_run: tools/run_tests.sh
    result: signed-off
    ---

Then a short prose note, especially your reproduction evidence (what command you
ran and how you confirmed it regenerates the committed assets). `reviewed_by`
MUST be `claude-worker` and MUST NOT equal `authored_by` (`codex-worker`).

Commit the marker onto `codex/005-manifest-doc-fix` (do NOT amend or rebase
`39f2130`; the marker is a new commit on top that NAMES it). Trailer
`Co-authored-by: Claude <claude@sentania.net>`. No em-dashes. Report the marker
commit SHA. If you find a real defect, use `result: changes-requested`, state it
precisely, commit, and report it. Do not sign off work you would not stake your
name on.
