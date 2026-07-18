---
reviewed_branch: claude/016-render-tune
reviewed_sha: a2f5f791344da90c7b535d830bd7fa58c0c1623e
reviewed_by: codex-worker
authored_by: claude-worker
timestamp: 2026-07-18T20:44:23Z
tests_run: tools/run_tests.sh, tools/art/village_export_gate.sh
result: signed-off
---

Independent decoding of the committed 1x captures measured the awning region at
mean 96.5, max 199.7, and 625 pixels above luminance 180 before the fix, versus
mean 93.6, max 166.8, and zero pixels above 180 after it. The roof region stayed
at mean 76.7 versus 76.6, with only its brightest specular reduced from 169.3 to
148.3, so the dark roof and timber lift remains intact.

The shader shoulder is continuous, monotonic, and asymptotic rather than a hard
clip. It uniformly scales RGB by the compressed-to-original luminance ratio,
preserving hue, and is exact identity below the shoulder. Its enabled buckets
match the structure-only shadow-lift set, while flora, flowers, and crowns pass
1.0 to disable compression.

Godot 4.3-stable compiled the shaders cleanly with no shader errors and no
MODULATE built-in reintroduced. The village export gate passed, and its before
and after checksums confirmed that assets/village remained unchanged. The full
active test suite passed, including test_smoke_grade and
test_footprint_apron_r.
