# Fix: make candidate atlas cell size manifest-driven (round 006, step 4)

You authored `ae74a8a` ("Wire pilot candidate art into the iso spine"). The
non-author peer reviewer (codex) signed **changes-requested** at
`.team/signoffs/claude-006-integrate-ae74a8a5fd0f.md`. The current head of
`claude/006-integrate` in this worktree (`lw-006-integrate`) is `156eea4` (the
review marker commit). Fix the defect on top of it.

## The defect (real, and your commit message overstates the contract)

Your commit claims "Facing count, frame count, cell size, and contact anchor
come from the manifest rather than hardcoding." That is true for facing count,
frame count, and contact anchor, but **not for cell size**:

- `set_candidate()` reads the manifest `cell_size` only to *assert* it equals the
  hardcoded `WALK_CELL_SIZE.x` (160).
- `_apply_walk_frame()` still computes atlas regions from the hardcoded
  `WALK_CELL_SIZE`.
- `tools/art/verify_candidate_integration.gd` independently hardcodes `CELL := 160`.

So cell size is not actually manifest-driven; it is asserted-against-a-hardcode.
Both pilot candidates happen to use cell 160, so it works today, but the slice
requirement (and decision 009's atlas contract) is that the region geometry comes
from the manifest.

## Fix scope

1. In `player_controller_2d.gd`: store the active candidate's cell size (and
   frame/facing counts + contact anchor, if not already stored from the manifest)
   and have `_apply_walk_frame()` compute atlas regions from the stored
   manifest-derived cell size, not from the hardcoded `WALK_CELL_SIZE`. Keep the
   round-005 default path (no candidate selected -> 4-facing proxy fold) exactly
   as it is; the hardcoded constant may remain as the DEFAULT-path value, but the
   candidate path must use the manifest value.
2. In `tools/art/verify_candidate_integration.gd`: derive the cell dimensions from
   each candidate's manifest rather than hardcoding `CELL := 160`.
3. Keep it minimal. Do not touch anything unrelated. Default behavior (env unset)
   stays byte-for-byte round-005.

## Hard constraints

- **NO Meshy. Zero paid calls.** Balance must stay **2970**.
- **Do NOT background work and end your turn on an intention.** Run the suite and
  BOTH headless proofs in the FOREGROUND this turn, then commit. Nothing
  re-invokes a `claude -p` after your turn ends. A turn that ends on "I will
  commit after the render/monitor" produces NO artifact and fails.
- Produce exactly ONE commit on top of `156eea4`, with your
  `Co-authored-by: Claude` trailer. Do NOT write a sign-off marker (author never
  signs its own work). Do NOT open a PR.

## Prove before you commit (foreground, this turn)

1. `tools/run_tests.sh` exits 0 (the `get_node() absolute paths` ERROR is the
   known benign warning).
2. `LONGWALK_ART_CANDIDATE=a tools/godot/godot --headless --path . --script tools/art/verify_candidate_integration.gd`
   PASSES, and the same with `=b`.
3. Re-run codex's mutation sanity in your head: because the verifier now derives
   the cell dimension from the manifest, confirm a manifest cell-size that does
   not match the atlas would now be caught by geometry, not by a hardcoded assert.

Commit message: describe that cell size is now genuinely manifest-driven for the
candidate path and cite that this addresses codex's changes-requested review. End
your turn with the commit made and the tree clean.
