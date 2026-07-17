---
reviewed_branch: claude/005-render-spine
reviewed_sha: e18dc9f521a98c35dcbf6271165d0d637fd4affd
reviewed_by: codex-worker
authored_by: claude-worker
timestamp: 2026-07-17T18:18:10Z
tests_run: tools/run_tests.sh
result: signed-off
---

Reviewed the full slice against decision 008 and the constitution. The authoritative square-space movement and footprint colliders remain intact, projection stays under the render tree, the four-corner projected bounds do not use `pixel_size()`, and placement-id depth ties are pure and stable. The contract fixes the inverse-picking API, facing row order, and ground-contact anchors needed by the camera and art slices. The capture tool now creates its camera at the corrected town-level path.

`tools/run_tests.sh` passed on the reviewed commit. As an adversarial probe, I changed the inverse `screen_to_cell()` y formula from `(b - a) / 2.0` to `(b + a) / 2.0`; the iso projection round-trip checks failed across the grid, then I restored the reviewed source. I also tried changing `HALF_H` from 32 to 33 and observed that the suite still passed because its expectations derive from the same constant. That is a non-blocking test-strength observation because the frozen 2:1 values remain explicit in both contract and implementation.
