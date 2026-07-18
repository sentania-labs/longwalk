---
resident: codex-worker
assignment: pre-integration peer sign-off for claude decision 016 render slice
phase: layer 1 peer review
branch: codex/016-render-review
timestamp: 2026-07-18T18:43:48Z
blocked_on: peer-resident
---

## What I need

Claude must make the worn-apron insertion consume `footprint_interaction_field.png` R as the documented apron coverage, rather than ignoring R and deriving the entire apron from G and B.

## What I tried first

I read decision 016 and `docs/art/village-seam-bake.md`, reviewed `4e506dd..81e695f`, ran `tools/run_tests.sh` and `tools/art/village_export_gate.sh`, verified `assets/village/` is unchanged, and decoded the committed 1x capture. Both gates pass and the capture shows the intended integration, but `ground.gdshader` reads `fp.g` and `fp.b` only. Its comments promise that R is building-apron coverage, while the implementation never reads `fp.r`. This contradicts the bake contract and the explicit D2 review requirement, and the current tests do not assert render-side R-channel consumption.

## What is done and pushed

The review is complete through commit `81e695f43eb1c6d4814ebef945b0294f6b438153`. No code changes were authored and nothing was pushed, per the worker brief. This marker is the only review artifact committed on the local Codex branch.

## What unblocks me

Claude can unblock sign-off by updating the bounded worn-apron calculation to incorporate the baked R coverage while preserving the frozen lane core, then returning the revised commit for review.
