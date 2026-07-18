# Peer review: in-engine pilot-art integration (round 006, step 4)

You are the **non-author** peer reviewer. The author is claude-worker. You are
codex-worker. Review commit **`ae74a8a`** (message "Wire pilot candidate art
into the iso spine (round 006)"), the current head of branch
`claude/006-integrate`, in this worktree (`lw-006-integrate`). It sits on the
round head `84e54f8` (round/006-two-rivers with both byte-stable candidates A+B
integrated).

This is a **layer-1 pre-PR sign-off**. Do NOT open a PR. Your only write to the
tree is the sign-off marker described at the end.

## Hard constraints

- **NO Meshy. Zero paid calls.** This slice is pure engine wiring; Meshy balance
  must stay **2970**. Do not invoke any meshy_* tool that costs credits.
- **Do NOT background any work and end your turn on an intention.** Run the suite
  and the headless proof in the FOREGROUND, this turn, to completion. Then write
  the marker and commit it. Nothing re-invokes you after your turn ends. A review
  that ends on "I will commit the marker after the render finishes" is a failed
  review that leaves no artifact.
- Commit ONLY the marker. Do not rebase, do not amend `ae74a8a`, do not add any
  other file. A changed reviewed SHA invalidates the marker.

## What the change does (author's claim, verify it)

- `src/render/town/candidate_art.gd`: reads `LONGWALK_ART_CANDIDATE` once (values
  `a`, `b`, or unset/`current`); raw off-disk loaders (`Image.load`/`FileAccess`)
  because the candidate authoring dirs carry `.gdignore` and are not import-scanned.
- `player_controller_2d.gd`: `set_candidate()` drives the true 8-facing x 6-pose
  atlas; facing/frame counts, cell size, contact anchor come from the manifest,
  not hardcoded; each iso octant indexes its own atlas row (no proxy fold); pivot
  on the authored contact anchor. Default (no candidate) keeps the round-005
  4-facing proxy fold.
- `starter_town.gd`: swaps the placeholder cottage for the candidate finished
  sprite, pivots on `cottage_scale.json` `contact_px` per the
  `building_contact_cell` anchor contract. Default facade path unchanged.
- `tools/art/verify_candidate_integration.gd`: stands up the real town under each
  candidate, asserts all 8x6 frames resolve to in-bounds opaque atlas regions and
  the player+cottage pivots conform.

## What to check before signing off

1. **Suite green.** Run `tools/run_tests.sh` in this worktree; confirm exit 0.
   (The `get_node() with absolute paths` ERROR line is a known benign Godot
   warning, not a failure.)
2. **Headless proof passes for BOTH candidates.** Run
   `LONGWALK_ART_CANDIDATE=a tools/godot/godot --headless --path . --script tools/art/verify_candidate_integration.gd`
   and the same with `=b`. Both must PASS (8 facings x 6 frames resolve; pivots
   conform). Do not trust the commit message; run it.
3. **Default behavior unchanged.** With `LONGWALK_ART_CANDIDATE` unset the town
   must be byte-for-byte the round-005 experience (4-facing proxy fold, placeholder
   cottage). Confirm the default path is genuinely untouched, not just claimed.
4. **8-facing indexing is real, not a fold.** Confirm each of the 8 iso octants
   maps to its own atlas row and the counts/anchor are read from the manifest, not
   hardcoded. Consider mutating one index or count and confirming the proof bites,
   then reverting.
5. **Cottage pivot conforms** to `cottage_scale.json` `contact_px` /
   `building_contact_cell` contract.
6. **Scale contract passes** for the four candidate scale manifests
   (`check_scale_contract.py`). The author claims sprites are authored
   meter-correct (player 1.75 m, `32*sqrt(6)` px/m upright) so NO runtime scaling
   is applied. Verify no scaling fudge was introduced.
7. **No em-dashes** anywhere in the diff (grep U+2014).
8. **No protected paths** touched (the diff is `src/render/town/*.gd` +
   `tools/art/verify_candidate_integration.gd`; none are in
   `.github/protected-paths.txt`; confirm).
9. **sim/render separation:** nothing under `src/sim/` is touched; no
   camera/viewport dependency leaks anywhere it should not.

Prefer proving assertions by mutation where cheap (as in prior sign-offs), not by
reading alone.

## Write the marker

Create exactly one file and commit only it:

`.team/signoffs/claude-006-integrate-ae74a8a5fd0f.md`

Front matter, then a prose note recording what you actually checked and any
mutation probes:

```markdown
---
reviewed_branch: claude/006-integrate
reviewed_sha: ae74a8a5fd0fd76bf97ffa1c0f2a6d10aa4467f2
reviewed_by: codex-worker
authored_by: claude-worker
timestamp: <UTC ISO-8601 Z>
tests_run: tools/run_tests.sh
result: signed-off        # or changes-requested
---

<what you checked; suite + both-candidate proof results; mutation probes;
constitution conformance; scale-contract result; balance stayed 2970>
```

`result: signed-off` only if everything above holds. If anything fails, write
`result: changes-requested` with the specific defect (I route the fix back to
the author, claude). Either way, commit ONLY the marker, in one commit, with your
`Co-authored-by: Codex` trailer, and end your turn with it committed.
