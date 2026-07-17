# Peer sign-off review: agy's camera slice (claude-worker as reviewer)

You are the NON-AUTHOR peer reviewer for agy-worker's round-005 camera drag-pan
slice. This is the pre-integration peer sign-off gate (layer 1). No marker, no
integration. You did NOT write this camera code. You DID write the render-spine
projection contract agy consumes, so you are the right reviewer: check that agy
consumed `projected_bounds()` / the projection surface correctly.

The branch `agy/005-camera` is checked out in this worktree at commit
**`1aa290e10d4a71cfffa343003878d8af2fbb5610`**, parent `05c1dc0` (the round base,
which includes your render spine). Review:

    git show 1aa290e
    git diff 05c1dc0..1aa290e

## What to check (a sign-off is a claim you actually checked these)

1. **Run the suite.** `tools/run_tests.sh` must pass. Record it in `tests_run`.
2. **Constitution + boundary.** No `src/sim/` edit; no edit to your
   `src/render/iso/*` module; no em-dashes in the diff. `project.godot` edit is
   authorized by decision 008 and must be minimal (the `pan_drag` binding).
3. **Matches decision 008 section 3 + Scott's 1720 refinement.** DRAG state with a
   click-vs-drag pixel threshold; `relative / zoom`-correct pan; `focus_view`
   retired as the primary RMB verb; cursor-preserving zoom; camera clamps to your
   `projected_bounds()` and NOT to `pixel_size()`.
4. **Contract consumed correctly.** agy calls `IsoProjection.projected_bounds(...)`
   and `world_to_screen(...)`. Confirm the `grid_size` and `headroom` it passes are
   sane and that it does not re-derive projection math itself.
5. **Adversarial spot-check on the parts that look thin.** In particular scrutinize
   the **cursor-preserving zoom**: it applies the cursor-shift only while
   `_state == State.DRAG` and uses `_zoom_center_screen != Vector2.ZERO` as a
   sentinel. Decide whether zoom-to-cursor actually holds the world point under
   the cursor fixed during a normal (non-dragging) zoom, and whether the
   `Vector2.ZERO` sentinel can misfire. Also check the DRAG threshold and the
   `_process` FOLLOW clamp. If any of these is a real behavioral defect (not just
   a style nit), write `result: changes-requested` with the precise defect rather
   than signing off. If they are acceptable for this round's scope (Scott's visual
   gate will exercise the feel), sign off and note the reservation.

## Write the marker

If it passes, write `.team/signoffs/agy-005-camera-1aa290e10d4a.md` with front
matter EXACTLY per `.team/signoffs/README.md`:

    ---
    reviewed_branch: agy/005-camera
    reviewed_sha: 1aa290e10d4a71cfffa343003878d8af2fbb5610
    reviewed_by: claude-worker
    authored_by: agy-worker
    timestamp: <UTC ISO-8601 Z>
    tests_run: tools/run_tests.sh
    result: signed-off
    ---

Then a short prose note on what you checked and your zoom/threshold verdict.
`reviewed_by` MUST be `claude-worker` and MUST NOT equal `authored_by`
(`agy-worker`).

Commit the marker onto `agy/005-camera` (do NOT amend or rebase `1aa290e`; the
marker is a new commit on top that NAMES `1aa290e`). Trailer
`Co-authored-by: Claude <claude@sentania.net>`. No em-dashes. Report the marker
commit SHA. If you find a real defect, use `result: changes-requested`, state it
precisely, commit, and report it. Do not sign off work you would not stake your
name on.
