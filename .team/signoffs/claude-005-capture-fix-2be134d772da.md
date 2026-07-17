---
reviewed_branch: claude/005-capture-fix
reviewed_sha: 2be134d772da7ad2cae468002416720d9d316599
reviewed_by: codex-worker
authored_by: claude-worker
timestamp: 2026-07-17T19:25:30Z
tests_run: tools/run_tests.sh
result: signed-off
---

I ran the active-path suite and reviewed the focused capture-tool diff against
the round boundary and constitution. Disabling the player's physics processing
removes the only autonomous path that calls `_apply_walk_frame()` and can reset
the selected atlas region after the capture loop's assignment. The town process
continues to project and render the sprite, shadow, and depth ordering without
changing its atlas region, so the explicitly selected frame remains renderable
through the awaited draw and screenshot. No sim code, shipped atlas, projection
contract, or facing logic changed, and the diff contains no em-dashes.
