# Peer sign-off review: codex's art-pipeline slice (claude-worker as reviewer)

You are the NON-AUTHOR peer reviewer for codex-worker's round-005 art-generation +
pipeline slice. Pre-integration peer sign-off gate (layer 1). No marker, no
integration. You did NOT write this pipeline. You DID author the frozen
iso-projection contract (facing row order, ground-contact anchor) that codex
generated against, so you are the right reviewer for contract conformance.

The branch `codex/005-art-pipeline` is checked out here at commit
**`49d1796f7f3419b6fdb4f73b4a9f1b9a4ac98f89`**, parent `05c1dc0` (round base with
your render spine). Review:

    git show 49d1796
    git diff 05c1dc0..49d1796 -- ':!*.png' ':!*.gif'   # code first, skip binaries

## Scope of THIS review

This is a CODE / PIPELINE / CONSTITUTION / CONTRACT review, NOT an aesthetic
judgment. Whether the generated art looks good enough is Scott's separate visual
acceptance gate, not yours. Do not sign off or reject on vibe. Check:

1. **Run the suite.** `tools/run_tests.sh` must pass, including the Python art
   tests (`test/art/test_art_manifest.py`, `test_check_walk_sheet.py`,
   `test_build_player_walk.py`). Record it in `tests_run`.
2. **Determinism (constitution, load-bearing here).** The OFFLINE-DERIVED shadow
   masks must be a pure function of the cleaned accepted alpha under a fixed light
   vector: no unseeded/stateful RNG, no iteration-order accumulator in
   `process_assets.py`. The cast source must be the GROUND-CONTACT SILHOUETTE (the
   bottom footprint slice at the contact line), projected along the fixed light
   vector, with upward-projected roof pixels EXCLUDED (decision 008 Q-C; the
   failure decision 006 rejected). Verify the shadow code does this and does not
   naively shear the full sprite alpha.
3. **Contract conformance.** The 8-facing row order in the manifests/policy
   matches the frozen order in `docs/contracts/iso-projection-contract.md`
   (E,SE,S,SW,W,NW,N,NE = ids 0..7). The per-cell ground-contact anchors match the
   anchor convention. `ingest_generated_sheet.py` actually rejects missing
   provenance, wrong grid, edge-touch, empty cells, undeclared runtime assets
   (spot-check its validation).
4. **Manifest-driven, no laundering.** `process_assets.py` / `build_player_walk.py`
   dropped hard-coded asset lists and the cardinal Option-C policy; the processor
   may normalize by declared feet/contact anchor but NEVER chooses an
   aesthetically preferred frame. No frame is picked because it looks better.
5. **No third-party pack (decision 007).** No Kenney/third-party asset appears in
   any tracked result; the reference folder is not shipped.
6. **No em-dashes** anywhere in the diff (code, docs, commit messages).

Note: this branch is off `05c1dc0` so it does not contain agy's camera changes;
that is expected. The 8-facing walk may be partial (E facing spike only) if codex
scoped generation to the five-asset spike for Scott's early gate; if so, confirm
codex's result report (`docs/art/round005-art-pipeline-result.md`) states exactly
what art remains to generate. Partial-but-honest is acceptable this round; silent
truncation is not.

## Write the marker

If it passes, write `.team/signoffs/codex-005-art-pipeline-49d1796f7f34.md`:

    ---
    reviewed_branch: codex/005-art-pipeline
    reviewed_sha: 49d1796f7f3419b6fdb4f73b4a9f1b9a4ac98f89
    reviewed_by: claude-worker
    authored_by: codex-worker
    timestamp: <UTC ISO-8601 Z>
    tests_run: tools/run_tests.sh
    result: signed-off
    ---

Then a short prose note: what you checked, the shadow-determinism verdict, the
contract-conformance verdict, and what art remains (per codex's report).
`reviewed_by` MUST be `claude-worker`, MUST NOT equal `authored_by`
(`codex-worker`).

Commit the marker onto `codex/005-art-pipeline` (do NOT amend/rebase `49d1796`;
new commit on top naming `49d1796`). Trailer
`Co-authored-by: Claude <claude@sentania.net>`. No em-dashes. Report the marker
SHA. If you find a real defect (determinism break, contract violation, laundered
frame selection, shipped third-party pack), use `result: changes-requested`,
state it precisely, commit, and report. Do not sign off work you would not stake
your name on.
