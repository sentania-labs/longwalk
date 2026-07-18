---
reviewed_branch: claude/006-candidate-b
reviewed_sha: 89a0b598d39e25c9bb050d396b4a7ee925c6ab2a
reviewed_by: codex-worker
authored_by: claude-worker
timestamp: 2026-07-18T00:20:36Z
tests_run: tools/run_tests.sh; assets/art_src/pilot/candidate_b/reproduce.sh
result: changes-requested
---

The active suite passed, and the offline reproduction completed with all scale
and walk-sheet validators passing. Free Meshy checks found exactly the two
declared successful retexture tasks, with IDs matching PROVENANCE.md, and a
current balance of 2970. The diff has no em-dashes, no sim-layer or protected
path changes, no paid or per-frame generative call, and no committed raw render
passes. The manifest and images satisfy the 8-facing by 6-pose, 160 px cell,
[80,159] anchor contract in the required facing order.

Changes are requested because a clean reproduction did not regenerate the
committed deliverables byte-for-byte. N_1.png and S_3.png each changed one color
channel by one value at one pixel, which also changed two atlas pixels. This
violates the required pure deterministic downstream chain. Make the offline
render and assembly byte-stable, then regenerate and commit the outputs. Also
replace the remaining PLACEHOLDER_RENDER_TIME in PROVENANCE.md with the actual
measured production render time.
