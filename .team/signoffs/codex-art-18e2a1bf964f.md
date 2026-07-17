---
reviewed_branch: codex/art
reviewed_sha: 18e2a1bf964f5207d469339abe6133ea839f4e1a
reviewed_by: claude-worker
authored_by: codex-worker
timestamp: 2026-07-17T06:45:00Z
tests_run: tools/run_tests.sh
result: signed-off
---

Re-review of the fix for the defect I refused on at `1ca9a0e`
(`.team/signoffs/codex-art-1ca9a0ea4b38.md`): visible blue speckle on the boots
at hue 220-260, the antialiased blend of the magenta and cyan markers, which
neither the old recolor windows nor `marker_residue_mask` could see.

## What I checked, independently, not by trusting the new test

- Pulled `18e2a1b` into a scratch worktree and ran `marker_blend_residue_mask`
  (the new detector added in this commit) against the shipping atlases at the
  prior SHA `1ca9a0e`: 466 flagged pixels on each of moss, slate_blue, and
  burgundy. Red on the exact defect I named, using an independent invocation
  of the function against the old build output, not the old count I did by
  hand. (Close to but not identical to the 469/471/469 quoted in the request;
  same order of magnitude, same conclusion, and the discrepancy doesn't change
  the verdict.)
- Ran the same detector against the atlases as rebuilt at `18e2a1b`: 0 flagged
  pixels on all three. Green after the fix.
- Cropped and rendered the densest cluster from the prior atlas at 10x next to
  the same region in the fixed atlas: the blue speckle on the boot outline is
  gone. What's left there is ordinary leather shading, and both detectors
  (`marker_residue_mask` and `marker_blend_residue_mask`) agree: zero flagged
  pixels in that crop post-fix.
- Independently recomputed the tunic-pixel-changed check the new test performs
  (same hue/saturation mask, same before/after comparison) rather than reading
  the test's own assertion: 0 of 23860 tunic pixels changed by boot recoloring.
- Reran the full build (`python3 tools/art/build_player_walk.py`) and diffed
  output hashes before and after: byte-identical, worktree clean. Determinism
  holds.
- `tools/run_tests.sh` passes in the worktree, all active-path suites.
- `git diff round/003-village-feel..18e2a1b -- tools/art/check_walk_sheet.py`
  is empty: the gate is untouched, as before.
- No em-dashes in the diff. `Co-authored-by: Codex` present.

## Why this closes the refusal

The new discriminator (`red_green_balance` plus `blue_dominant`, on top of the
existing hue/saturation/value/alpha thresholds) is exactly the kind of
non-hue-window separator I flagged as necessary in the prior refusal, since a
naive hue widen was shown to eat the slate_blue tunic (hue 210) and a plain
hue window can't tell a magenta+cyan blend from a blue costume by hue alone.
It reaches the 220-260 gap without touching the tunic, verified independently
above, not just by the new test passing.

Signing at this SHA.
