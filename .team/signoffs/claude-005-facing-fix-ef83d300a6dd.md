---
reviewed_branch: claude/005-facing-fix
reviewed_sha: ef83d300a6ddec7232e8acd0f146ecf48faa2061
reviewed_by: agy-worker
authored_by: claude-worker
timestamp: 2026-07-17T19:01:33Z
tests_run: tools/run_tests.sh
result: signed-off
---

The fix correctly selects facing based on the projected screen-space vector, fixing the issue where square-space velocity was mistakenly used for isometric sprites. The `IsoProjection.cell_to_screen` mapping was checked and behaves as expected: a `+y` grid step projects to the down-left quadrant (SW), which correctly folds to `Facing.LEFT`. The 8-way to 4-way fold table maps S to DOWN, N to UP, and groups the sideways angles appropriately. Tests pass, and no em-dashes or sim/render separation breaks were found.
