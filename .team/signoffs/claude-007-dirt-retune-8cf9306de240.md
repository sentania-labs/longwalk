---
reviewed_branch: claude/007-dirt-retune
reviewed_sha: 8cf9306de2402e4820959a0df5125433aa9186a0
reviewed_by: codex-worker
authored_by: claude-worker
timestamp: 2026-07-18T10:45:57Z
tests_run: tools/run_tests.sh
result: signed-off
---

Ran `tools/run_tests.sh` and `tools/art/village_export_gate.sh`. The active
suite was green, the village export gate passed, and the asset non-mutation
guard reported identical before and after checksums.

Confirmed the bake retains seeds and offsets 7007, 12109, and 14503. Its R
substrate now reads `ground_dirt_plate.png`, not the grass plate, and the
radius-2 shoulder soften is deterministic. Two repeat bakes were byte-identical
at file SHA-256 `d72b4ab4809b7f0c4fc3fcac011f2251c6758a737a50500c07570442b5d48989`;
both decoded to the expected image SHA-256
`1585d0bcb357696fc6cdbd19886397f5ffe531fb0af7c9b4a0d1338795da9435`.

Independently decoded the committed dirt plate. Channel means are
98.58/85.48/43.54 with strict R > G > B, mean per-channel standard deviation is
19.78, and luminance mean/std are 85.23/20.42. The affine grade therefore lands
near the spike target without collapsing the accepted source variation.

Ran the rendered dirt-gate decoder. Protected-core luminance std is 18.44,
materially above the approximately 6 baseline. Core-inclusive gradient is
5.33 and shoulder gradient is 5.72, both below the 10.28 grass shimmer ceiling.
The lower gradient is consistent with a low-gradient, high-variance plate and
the deliberate shoulder soften, while the direct tonal richness measure rises
substantially. Gate 3 remains grass-dominant at 0.2948 coverage. Gate 2 remains
soft at 5.9 to 18.6 pixels and non-monotone with three isoline reversals.

Reviewed the diff for determinism, the real dirt-substrate switch, protected
core direct dirt sampling, additive asset/tool scope, protected-path overlap,
and the no-em-dash rule. No protected path is touched, no stateful RNG or
simulation/render coupling is introduced, and the reviewed commit carries the
Claude co-author trailer. No defect found.
