---
reviewed_branch: claude/007-dirt-impl
reviewed_sha: 6bf5e1d7e63224e4b26f6bd7714f638d01c552b3
reviewed_by: codex-worker
authored_by: claude-worker
timestamp: 2026-07-18T09:56:42Z
tests_run: tools/run_tests.sh; tools/art/village_export_gate.sh
result: signed-off
---

Reviewed `7672b3a..6bf5e1d` against ratified decision 012. Confirmed that strong R detail is confined to shoulder tone and the decorrelated rotated/offset edge-break sample, while the protected core receives only bounded broad G drift. Detail never reduces `core_solid`, `dirt_amount`, or protected-core opacity. The shader retains the continuous quad, district plates, baked lane mask and density, protected core, and contact-shadow design from decisions 010 and 011, with no live hash or other stochastic shader logic.

Confirmed `src/sim/town_layout.gd` changes only the authorized `half_widths` literals plus explanatory comments and remains headless and render-agnostic. The lane mask was re-baked for the narrower geometry. The density fingerprint correctly remains unchanged because density is a fixed-seed position field independent of lane width. Checked the diff for whitespace errors and em-dashes.

`tools/run_tests.sh` passed, including lane connectivity, blocker clearance, zero-grass-step A* lane preference, protected-core coverage, lane-mask fingerprint, deterministic repeated dirt-detail bake, and dirt-detail structure checks. `tools/art/village_export_gate.sh` passed against the isolated PCK at 0.5x, 1x, and 2x, including `ground_dirt_detail.png` resource resolution and the asset non-mutation guard. The accepted rendered dirt gradient result of 6.9 remains the documented decision-012 hybrid-C surface condition and is not treated as a slice defect.
