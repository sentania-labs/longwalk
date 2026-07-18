---
reviewed_branch: claude/016-render
reviewed_sha: 6bc43ce03c4d4f5637a902756d460e0133f180cf
reviewed_by: codex-worker
authored_by: claude-worker
timestamp: 2026-07-18T18:54:20Z
tests_run: tools/run_tests.sh, tools/art/village_export_gate.sh
result: signed-off
---

The prior R-apron block is resolved. I reviewed the full 4e506dd..6bc43ce range and confirmed that ground.gdshader reads fp.r into the authored apron coverage, carries that value through the bounded foundation-ring and door-threshold calculations, and uses the resulting apron coverage to raise the existing dirt treatment without altering the frozen lane core, plate, or detail path. The new test_footprint_apron_r.gd strips comments and checks the live shader's R-to-apron_cov assignment chain, so ignoring R would fail the regression rather than pass cosmetically.

I ran tools/run_tests.sh and tools/art/village_export_gate.sh successfully. The export gate passed its non-mutation guard, and assets/village remained byte-unchanged across the reviewed range. I decoded docs/art/village/village-inn-green-1x.png and confirmed grounded objects with below-sprite contact and short directional casts, bounded worn seams hugging foundations, a consistent single key, and no crown shadow. The retired shadow decal remains unused, the bounded guarded object grade and CanvasModulate remain in place, and the smoke-grade test passes.
