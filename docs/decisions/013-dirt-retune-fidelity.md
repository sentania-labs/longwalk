# 013: Dirt re-tune fidelity (muddy tone, tiling, seams)

- **Status:** accepted
- **Date:** 2026-07-18
- **Assignment:** round-007 nested full-protocol sub-round closing the THREE new
  tells agy QA pass 5 (`docs/art/village/qa-agy-dirt-005.md`, NOT-CONFUSABLE)
  found after the decision-012 paid dirt regen + re-tune: (1) high-contrast muddy
  tone (dominant, all zooms), (2) visible tiling / rock-cluster repetition (1x,
  2x), (3) grid seams mid-district (1x, 2x). ZERO paid spend: the accepted paid
  source plate is closed; the fix is processing/compositing only. Scope +
  proposal prompt: `.pka/round007/013-proposal-prompt.md`.
- **Orchestrator run:** round 007, dirt-retune sub-round, resolved 2026-07-18 on
  `round/007-village` (branched from round head `2ca6f62`).
- **Lane:** full protocol. Triage: the muddy-tone tell looked mechanical (a grade
  re-tune) until the orchestrator decoded the spike-dirt crop and found its std
  (40.59) is HIGHER than the graded plate (19.78), overturning "reduce contrast"
  as the fix and revealing a frequency-distribution problem with genuine method
  alternatives (frequency-selective flatten vs local-contrast normalize vs
  shadow-lift+gamma vs in-shader anti-tiling vs seam-heal). Contested method =
  full protocol. NOTE: no protected path is touched (`src/render/town/`,
  `tools/art/`, `assets/` are all unprotected; `src/sim/` is untouched), so this
  record is not gate-required, but a full-protocol round earns one by convention.
- **Workers dispatched:** claude-worker, codex-worker, agy-worker

## Context

The decision-012 paid regen gave the dirt plate real earthy structure (std ~19.8
vs the old flat 4.5) and closed pass 4's flat-core / retinted-grass / shimmer
tells, but the affine tone-grade that installed it (matched the spike mean,
preserved source std) introduced three new tells. Orchestrator-decoded facts the
round was handed (raw-plate decodes, validated methodology):

| plate | std_rgb | mean_grad | meanRGB / lum |
| --- | --- | --- | --- |
| current graded `ground_dirt_plate.png` | 19.78 | ~5.6 | (98.6,85.5,43.5) lum 85.2 |
| spike-dirt crop (target) | **40.59** | **10.43** | (98.6,85.0,43.5) lum 84.9 |
| grass plate (shipping, clean at 0.5x) | 14.00 | 10.75 | -- |

The graded plate's mean/lum is already ON the spike target, yet it reads muddy
while the higher-variance spike reads as dry dusty tan. The pipeline:
`.pka/round007/ground-source/dirt-regen-nbpro-019f74b2.png` ->
`tools/art/grade_dirt_plate.py` -> `assets/village/ground_dirt_plate.png` (core
samples this directly) -> `tools/art/bake_dirt_detail.gd` (RG8: R shoulder
high-pass, G core drift) -> `src/render/town/ground.gdshader` (single-quad
district composite, plate sampled once, `plate_repeat = 1.0`, `repeat_disable`).

## Proposals

| worker | branch | proposal SHA | critique SHA |
| --- | --- | --- | --- |
| claude-worker | `claude/013-dirt-retune` | `531e7010a2c3ebf1df3b3f70a51b689477ce4e64` | `035e9a6fc55a8400d7f5b9ffcb0cbf4097ead584` |
| codex-worker | `codex/013-dirt-retune` | `8a5ef44b42d2c658919b9e11571fa1c54114663e` | `a04e79ed88d0a72e086eb80b0f118cb9479dbbd2` |
| agy-worker | `agy/013-dirt-retune` | `824c456a71a454a3b95940549626ba0eeb708046` | `ab3bb78ee088b2995fa08d1a4468fbe0a626bb8b` |

(claude critique recorded on `claude/013-dirt-retune`.)

## Converged decision

The blind round produced strong independent 3-way convergence on the diagnosis
and the primary fix, and the critique round resolved the sub-questions with every
author conceding its contested point. There was NO 2-2 split and no dissent
overruled on argument, so no four-ballot vote and no critic seat (tiebreaker-only
per decision 004) was invoked.

### Root cause (unanimous)

The three tells share ONE cause: the regen plate carries its variance in the
LOW/MID spatial-frequency band (broad dark drifts + prominent rock clusters),
while the spike carries its (larger) variance in the HIGH-frequency band (crisp
dry speckle on a near-uniform tan). `std` was the wrong invariant for the affine
grade to preserve. Broad low-frequency dark drift reads as "wet smeary mud" (tell
1); the same prominent mid-band rock blobs recurring across the once-sampled
district read as "tiling" (tell 2); a broad luminance step landing on a mask
isoline reads as a "seam" (tell 3, partially). Fix the frequency balance and
tells 1 and 2 move together.

### The method (synthesized from all three + both critique rounds)

1. **Primary: replace the affine grade in `grade_dirt_plate.py` with a
   deterministic multiband luminance reshape.** Split source luminance into bands
   with wrapped separable box blurs (the `_box_blur_wrapped` primitive ported
   from `bake_dirt_detail.gd`): macro (~64 texel), mid (~12-24), fine (~3).
   Attenuate macro + mid (kill the mud and the rock-blob prominence), handle the
   fine band to move the plate toward the spike's high-frequency signature, apply
   the luminance delta equally to R,G,B (no hue shift), then re-match the spike
   luminance mean exactly. Pure function of the committed source bytes, no RNG, no
   order dependence; the determinism contract and SHA/std/grad print block extend
   naturally. Add codex's diagnostics (per-octave band RMS, dark-tail percentiles,
   rock-patch cross-correlation) to the decode report.

2. **The detail bake MUST change (plate-only was retracted).** `bake_dirt_detail.gd`
   `_standardize`s the R high-pass to unit variance, so flattening the plate does
   NOT quiet the shoulder: R renormalizes and re-emphasizes whatever mid-band rock
   structure survives. Move the R high-pass radius from 12 toward ~3 (catch fine
   speckle, not the 12-64 mid-band rock motifs), bound/winsorize rock-edge
   outliers before standardize, and reduce the 0.78 painted share if correlation
   remains. Update the expected-SHA header. Gate: plate-rock <-> rendered-shoulder
   cross-correlation must drop.

3. **Shader amplitudes are a measured joint sweep, not a-priori values.**
   `ground.gdshader`'s `detail_shoulder_amp` (0.40), `tone_contrast` (0.16), and
   `detail_core_amp` (0.11) are independent low-frequency darkening/modulation
   mechanisms that do NOT inherit the plate regrade. Reduce them ONLY as far as
   captures require, with two HARD regression gates below.

4. **Seams: LOCALIZE before fixing (unanimous).** The mid-district seams QA5
   reported ("above the blacksmith," "across paths") are NOT agy's border-clamp
   artifact. Map each seam's capture endpoints back through `cell/grid_size` to
   district UV and classify as source brush boundary / `lane_mask` contour / mask
   texel boundary / cell boundary / district border BEFORE choosing a fix. The
   multiband flatten may dissolve them (if plate drift) or not (if `lane_mask` /
   `lane_density` bilinear facets). Do NOT claim tell 3 closed until localized.

### The one empirical (not contested) tuning question

Core richness has exactly one source: high-frequency content in the plate itself
(the honesty ruling denies the protected core the shader's high-freq R channel).
claude+agy predict BOOSTING the fine band (>1.0) keeps the core rich; codex warns
fine-boost has almost no headroom (spike gradient 10.43 vs grass ceiling 10.75)
and would breach the 0.5x shimmer ceiling, so retain enough non-muddy MID-band
energy instead. This is NOT a design fork: both sides accept the same two hard
gates and disagree only on the predicted band-gain solution. The impl resolves it
by MEASUREMENT against both gates, not by ruling.

**Two hard regression gates (both camps agree):**
- **Flat-core gate:** core luminance std must NOT fall below its current value
  (reopening pass-4 flat core is a reject).
- **Shimmer-ceiling gate:** the shipped dirt fine-gradient must NOT exceed the
  grass shimmer ceiling (~10.75) measured on the 0.5x `capture_ground_only.gd`
  render (not just the native decode, which reads high).

### Ruled out (unanimous, including agy self-concession)

- **Switching `dirt_detail` to `repeat_enable` + `fract()`** (agy phase-1): would
  introduce a REAL wrap seam. Neither the AI plate nor the `FastNoiseLite` fields
  are periodic; `_box_blur_wrapped` wraps only the kernel, not the signal. This is
  exactly the tell `repeat_disable` (shader lines 40-60) was chosen to prevent.
- **In-shader stochastic anti-tiling** (hex/rotated resampling): would ghost the
  same finite rock set into double images; the plate flatten dissolves the
  perceived repeat at its source instead.
- **Global contrast reduction / shadow-lift + gamma:** scales all frequencies
  together, killing the crisp speckle the spike HAS and we LACK, driving straight
  back to the flat-core tell.

### Kept as optional polish

agy's rotated-derivative one-liner (`vec2(ddx.y,-ddx.x)` for the edge-break
sample) is mathematically correct (the current code passes unrotated derivatives
to a 90-degree-rotated sample) but immaterial to the seams (no mips committed;
affects only the coverage-dither on the edge-break band). Apply only if the
edge-break sample survives seam localization.

## Verbatim concessions (the substance of the convergence)

**agy (self-correction, `ab3bb78`):** "I must concede that my own proposal (agy)
is incorrect regarding the grid seams (Tension 1). My diagnosis of the `eb_uv`
clamp at `1.0` in `ground.gdshader` only explains artifacts at the absolute top
and right boundaries of the district ... It completely fails to explain the
mid-district seams QA5 reported 'above the small blacksmith building.' ...
Additionally, my proposed fix of using `repeat_enable` and `fract(eb_uv)` for
`dirt_detail` is dangerous: `bake_dirt_detail.gd` uses `FastNoiseLite` without
seamless boundary mapping, so `dirt_detail` does not tile seamlessly. Wrapping it
would introduce hard seams at the district edges."

**claude (`035e9a6`):** "Two corrections stand against me and I take them: (1)
the detail R is standardized, so plate-only does NOT quiet the shoulder and the
shoulder amplitude may need to drop (codex, Concession 1); (2) my `k_mid ~= 1`
leaves the mid-band rock blobs alive in both core and R, so mid must be attenuated
and the R high-pass radius moved finer."

**codex (`a04e79e`):** "Claude is right that a corrected plate is the proper
first intervention, and I was wrong if my proposal implied the detail bake was an
independent source that could be tuned before seeing that corrected plate. ... My
phase-1 suggested ranges are hypotheses, not values that should ship without
captures."

## Division of labor (by capability)

- **claude-worker owns the whole coupled measurement slice** (multiband plate
  reshape in `grade_dirt_plate.py` + detail-bake R-radius/winsorize change in
  `bake_dirt_detail.gd` + shader amplitude joint sweep + decode/capture loop +
  seam localization). Rationale: the three pieces share ONE decode/capture tuning
  loop and would thrash if split across residents; claude wrote `bake_dirt_detail.gd`
  and the box-blur pattern being ported, and its flat-core handling (boost the
  plate's own fine band, correctly locating that the honesty ruling governs R and
  not the plate the core samples) survived critique best. Grafts in codex's
  diagnostics.
- **codex-worker: non-author cross sign-off** on claude's slice (reviewed_by !=
  authored_by), bringing its UV-classification rigor to the seam-localization
  claim at review. codex's coupling insight (detail bake + shader amplitudes must
  move) is grafted into the slice; its plate numbers lost to claude's on the
  flat-core gate.
- **agy-worker: QA pass 6** (its standing multimodal role) on the integrated
  result, explicitly re-checking the two named mid-district seams and whether the
  flatten dissolved the muddy-tone and tiling tells. agy's seam fix was retracted;
  its diagnostic sharpness serves QA.

This is a normal division: not every worker gets an impl slice.
