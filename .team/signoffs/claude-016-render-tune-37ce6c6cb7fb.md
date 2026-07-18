---
reviewed_branch: claude/016-render-tune
reviewed_sha: 37ce6c6cb7fb27b94602f121292d3f7d7b7b9ec5
reviewed_by: codex-worker
authored_by: claude-worker
timestamp: 2026-07-18T20:13:22Z
tests_run: tools/run_tests.sh, tools/art/village_export_gate.sh
result: signed-off
---

Reviewed the fix commit and decoded `docs/art/village/village-inn-green-1x.png` at original resolution. The capture shows feathered earth-brown grounding shadows, lifted and readable roof and timber values without blown plaster, and an apron edge blended into the grass rather than fallback rendering.

Ran `tools/art/village_export_gate.sh` under pinned Godot 4.3-stable. It passed, and `grep -iE 'SHADER ERROR|Shader compilation failed'` over the captured gate output was empty. `MODULATE` remains only in explanatory shader comments. `object.gdshader` reads `texture(TEXTURE, UV)` once, grades that sample, and multiplies by `item_modulate` exactly once, without reusing texture-carrying `COLOR`. `shadow.gdshader` applies `layer_fade` once to feathered alpha. `village_render.gd` explicitly sets both uniforms to their identity values, so neither grade nor shadow output is silently disabled.

Proved the gate failure path by temporarily injecting an invalid identifier into `object.gdshader`. The gate exited 1, reported both `SHADER ERROR` and `Shader compilation failed`, printed no `VILLAGE EXPORT GATE PASSED`, and then the shader was restored with no tracked diff. The `tee` pipeline retains the audit exit through `PIPESTATUS[0]`, while the log scan catches Godot's compile-error fallback even when the audit itself exits zero.

Ran `tools/run_tests.sh`; all active-path suites passed, including `test_smoke_grade` and `test_footprint_apron_r`. The fix does not touch the ground shader, lane, plate, detail, footprint-field, manifest, `src/sim`, or protected paths. `git diff 9da0f94..37ce6c6 -- assets/village` is empty, and both clean and injected gate runs retained the non-mutation checksum for `assets/village/`.
