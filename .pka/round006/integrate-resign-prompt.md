# Re-review: candidate atlas cell size now manifest-driven (round 006, step 4)

You (codex-worker) signed the prior integration commit `ae74a8a`
**changes-requested** at `.team/signoffs/claude-006-integrate-ae74a8a5fd0f.md`:
cell size was asserted-against-a-hardcode rather than driving atlas regions. The
author (claude) fixed it in **`2b7d94e`** ("Make candidate atlas cell size
genuinely manifest-driven"), now the head of `claude/006-integrate` in this
worktree (`lw-006-integrate`). Re-review the new head and, if it holds, sign off.

You are the non-author reviewer (author is claude-worker).

## The fix to verify

- `player_controller_2d.gd`: adds `var _walk_cell_size := WALK_CELL_SIZE`;
  `set_candidate()` now stores `_walk_cell_size = Vector2(cell, cell)` from the
  manifest instead of asserting equality with the constant; `_apply_walk_frame()`
  computes the region `Rect2` from `_walk_cell_size`.
- `tools/art/verify_candidate_integration.gd`: removes `const CELL := 160`, derives
  `var cell := int(manifest["cell_size"])` per candidate, and threads it through
  the shape check, the pivot-offset check, and the viewport crop.

Confirm the manifest cell size genuinely drives region math on the candidate path,
and that the **default (no candidate) path is unchanged** (`_walk_cell_size`
defaults to `WALK_CELL_SIZE`, so the round-005 proxy fold is byte-for-byte the same).

## Hard constraints

- **NO Meshy. Zero paid calls.** Balance must stay **2970**.
- **Do NOT background work / end your turn on an intention.** Run the suite and
  BOTH proofs in the FOREGROUND this turn, then write and commit the marker.
- Commit ONLY the marker. Do not amend `2b7d94e`.

## Checks before signing off

1. `tools/run_tests.sh` exits 0 (benign `get_node() absolute paths` warning aside).
2. `LONGWALK_ART_CANDIDATE=a` and `=b` headless
   `tools/art/verify_candidate_integration.gd` both PASS.
3. The prior defect is genuinely closed: cell geometry is manifest-derived on the
   candidate path, hardcoded only for the default proxy. Prove by mutation if
   cheap (e.g. a manifest cell_size that does not divide the atlas is now caught by
   geometry). Restore any mutation and confirm no diff.
4. Default path byte-for-byte unchanged; no em-dashes; no protected paths; nothing
   under `src/sim/`; no render/camera/viewport dependency leak.

## Marker

Write and commit exactly one file:

`.team/signoffs/claude-006-integrate-2b7d94e7c6c0.md`

```markdown
---
reviewed_branch: claude/006-integrate
reviewed_sha: 2b7d94e7c6c064a787627310892ebfeb0993fa22
reviewed_by: codex-worker
authored_by: claude-worker
timestamp: <UTC ISO-8601 Z>
tests_run: tools/run_tests.sh
result: signed-off        # or changes-requested
---

<what you checked; suite + both-candidate proof results; that the cell-size
defect is closed; mutation probe; default path unchanged; balance stayed 2970>
```

`signed-off` only if the fix holds and everything above passes. Commit ONLY the
marker with your `Co-authored-by: Codex` trailer, and end your turn with it
committed.
