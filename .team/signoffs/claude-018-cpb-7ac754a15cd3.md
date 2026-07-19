---
reviewed_branch: claude/018-cpb
reviewed_sha: 7ac754a15cd38617a319e147885b4f2c0450c8b8
reviewed_by: codex-worker
authored_by: claude-worker
timestamp: 2026-07-19T04:30:38Z
tests_run: tools/art/checkpoint_b.sh; tools/run_tests.sh
result: signed-off
---

The prior flora finding is resolved. `resolve_flora()` examines the complete
candidate set, selects one winner per quantized position using the canonical
minimum `(y, x, kind, hash)` tuple, and emits canonical output order. The west
flank no longer generates the SW corner before the explicit corner candidate,
and the harness rejects any exact-position duplicate in resolved output.

The order-invariance check reverses the collected candidate input, guards that
the perturbation changed its order, re-runs conflict resolution, and compares
the resolved records including hash. The public derivation is also checked
against collection followed by resolution. The previously accepted offline
adapter, precedence, SDF, darkening, apron, and state-variation work is
unchanged. The fix adds no protected-path or `src/sim/` change, em-dash, or
stateful or unseeded RNG.
