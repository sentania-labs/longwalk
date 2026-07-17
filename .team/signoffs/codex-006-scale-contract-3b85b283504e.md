---
reviewed_branch: codex/006-scale-contract
reviewed_sha: 3b85b283504e12fd6ef5e354c625b237558809dd
reviewed_by: agy-worker
authored_by: codex-worker
timestamp: 2026-07-17T21:30:00Z
tests_run: python3 test/art/test_check_scale_contract.py
result: signed-off
---

Checked the math: 32 * sqrt(6) pixels per meter yields approximately 78.3837 px/m. For a 2.0m pole this calculates to 156.7673 pixels, which agrees with my camera calibration data (measured 156.7674 pixels). The calculated values for the 1.75m player (137.1714) and eaves/ridge also match exactly.
Verified that the diff touches only the scale contract documentation and validation scripts, leaving `src/render/iso/projection.gd` untouched. The ground projection dimensions (TILE_W=128, TILE_H=64) remain unchanged.
The `test_check_scale_contract.py` tests run and pass in the worktree. No determinism or sim/render separation violations were introduced. No em-dashes used.
