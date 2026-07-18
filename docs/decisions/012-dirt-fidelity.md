# 012: Dirt-surface fidelity (worn-earth dirt, spike-fidelity)

- **Status:** accepted
- **Date:** 2026-07-18
- **Assignment:** round-007 nested full-protocol sub-round on DIRT-SURFACE
  FIDELITY. Decisions 010 (continuous shader-quad + district painterly plates +
  baked domain warp + protected core + contact shadows) and 011 (sim-side
  meandering lane centerlines + offline SDF/density bake + feathered
  dual-threshold + density modulation) closed the checkerboard and straight-X
  tells. agy's multimodal QA pass 3 (`docs/art/village/qa-agy-lane-003.md`,
  verdict NOT-CONFUSABLE) plus an orchestrator decode of the source plates found
  the new dominant tell: the DIRT is a flat uniform brown wash, root-caused to an
  intrinsically FLAT source plate. Per decision 009 item 9 ("method failure at the
  gate changes the METHOD"), the dirt-detail method is the open question. Scope:
  `.pka/round007/dirt-fidelity/assignment.md`.
- **Orchestrator run:** round 007, dirt-fidelity sub-round, resolved 2026-07-18 on
  `round/007-village` (branched from round head `2c10abe`).
- **Lane:** full protocol (design fork on the dominant tell touching the paid
  asset pipeline; edits protected `src/sim/town_layout.gd` `half_widths`).
- **Workers dispatched:** claude-worker, codex-worker, agy-worker

## Context

Root cause, orchestrator-decoded and independently reconfirmed by all three
doers: `assets/village/ground_dirt_plate.png` is INTRINSICALLY FLAT. Decoded:
mean RGB (150,119,82), std RGB **~4.5/channel**, luminance span 64, mean spatial
gradient **2.5**. The grass plate has std **~16**, span 173, gradient **~10.6**
(roughly 4x the high-frequency structure). The shader already mottles dirt by the
baked density field, but there is no source structure to modulate: mottling a
near-uniform brown yields a near-uniform brown. The dirt plate is ITSELF a paid
meshy generation (decision 010's plate fallback) that came out flat, so "just
regenerate it" is a re-roll of the exact path that produced the flat result.

Three tells: #1 flat dirt (dominant, source/compositing), #2 hard transition
(shader), #3 dirt over-coverage (authored `half_widths` geometry). Decisions 010
and 011 must NOT regress; the grass plate is reused; no unsupervised paid art.

## Proposals (phase 1, blind)

Every dispatched worker proposed independently, none having seen another's.

| Worker | Branch | Proposal commit SHA |
| --- | --- | --- |
| claude-worker | `claude/007-dirt-fidelity` | `960b30ea2a850fb4a6abc337be46025880adf8b9` |
| codex-worker | `codex/007-dirt-fidelity` | `e2242ea1584a67193012cf5d996d36b745be4d4a` |
| agy-worker | `agy/007-dirt-fidelity` | `d49929c230def5f35e4b565cd8b3075d2dff50b6` |

**All three independently chose Fork B (zero-cost shader-composite); none chose a
pure paid regen (A).** Unanimous convergence on the method family, the strongest
signal this protocol produces. The differences were WITHIN B and are what the
critique round tested:
- **claude:** borrow the grass plate's painted luminance, high-passed and baked
  WHOLE into a single R8 `dirt_detail` field; dual-use (dirt structure + edge
  break); zero-mean value modulation across the whole dirt surface incl. core
  (flagged as needing an explicit 012 nod); half_widths narrow 25-35% with a
  decoded coverage gate; explicit hybrid-C paid-regen fallback rule.
- **codex:** four-channel RGBA control plate (value drift / pebbles / worn patch /
  edge tuft), borrowing grass luminance as substrate; strong determinism +
  fingerprint + byte-identity discipline; coverage measured from final shader
  output; core kept true-tone (detail shoulder-only except a bounded broad drift);
  paid reroll only if retinted morphology still reads as grass.
- **agy:** leanest: pure `FastNoiseLite` (cellular + simplex) detail, no painted
  borrow; single detail texture; widen shoulder stops; narrow half_widths 30-40%;
  hand the bake to codex.

## Critique (phase 2, adversarial)

| Worker | Branch | Critique commit SHA |
| --- | --- | --- |
| claude-worker | `claude/007-dirt-fidelity` | `318d238f9354e594f34b764aae13bd7d1dce4219` |
| codex-worker | `codex/007-dirt-fidelity` | `3d5c5f3f4ef8f094da575512fce3f6f8388a3681` |
| agy-worker | `agy/007-dirt-fidelity` | `36d884ac4459044d470327fb6bc4b5c8269520a8` |

Genuinely adversarial and strongly CONVERGENT. Resolutions by question:

- **Detail source: RESOLVED by concession -> painted-luminance substrate.** Both
  codex and agy conceded that pure procedural noise reads synthetic and claude's
  borrowed-painted-luminance is the correct substrate. agy withdrew its own
  pure-noise fork ("my own proposal's reliance on pure FastNoiseLite would fail
  the synthetic-reads-synthetic test"). claude's mechanistic attack stands:
  single-octave cellular noise makes uniform-size Voronoi cells and thresholded
  simplex makes anti-clustered (blue-noise) freckles, the opposite of real
  clustered multi-scale gravel.
- **Bake the high-pass WHOLE, not split live/baked.** claude's decisive catch on
  codex: codex's §1 defined R/B as independent noise fields but §2 subtracted them
  as if they were a low-frequency grass copy (internal contradiction); and any
  design that computes `lum(grass live) - baked_lowfreq` is scale-dependent and
  shimmers because the two terms mip on different schedules. Resolution: compute
  the high-passed residual (grass luminance minus its own box-blur) OFFLINE in the
  bake and sample it as one unit.
- **Channel layout: RESOLVED by concession -> minimal channels.** codex conceded
  its four-channel RGBA plate is over-engineered (its own first-hour plan builds
  the single-field version first). Both peers attacked the second-order B channel
  and the green-chroma A channel. Start minimal; add a channel only when a
  demonstrated need appears (see the finalization refinement below, which found
  exactly one such need).
- **Edge/tone decorrelation (codex graft on claude).** Using one field sample for
  both dirt tone and shoulder edge-break correlates them (bright flecks recur
  exactly where the edge bulges = an embossed/camouflage look). Sample the same
  committed plate at a fixed offset/rotated UV for the edge-break so the two uses
  decorrelate.
- **Coverage: RESOLVED -> measure from final shader output; MANDATORY lane
  re-bake.** claude caught that agy narrows `half_widths` but never re-bakes
  `lane_mask.png`/`lane_density.png` (consumed offline by `bake_lane_mask.gd`), so
  agy's Tell-3 is a literal no-op that never renders. All coverage tuning measures
  the composited `dirt_amount` on an unobstructed ground-only render (free of
  building/shadow occlusion), not a frame fraction and not inferred from literals.
  A wider feather can cancel a narrower lane, so net coverage is measured after
  both changes.
- **Shimmer/mip: RESOLVED -> blocking gate.** Imports ship no committed mipmaps;
  strong high-frequency detail aliases at 0.5x and crawls under a pan. All three
  require still captures at 0.5x/1x/2x AND a slow fractional-pixel pan at 0.5x as a
  blocking gate; the high-frequency band is prefiltered/reduced if it crawls, never
  "fixed" by more contrast. std alone is an inadequate gate (a checkerboard passes
  std>=12); mean spatial gradient + a post-0.5x-downsample measure + clipping
  limits + a blinded crop verdict are required.

### The one contested synthesis question: tonal texture on the protected core

Not converged in critique. Three positions: claude (full zero-mean detail on the
core, but offered to concede to shoulder-only if rejected); codex (bounded
low-amplitude broad value drift on the core, strong detail shoulder-only, raised
as a **constitution-conformance concern** that decision 012 must explicitly
supersede 010's true-tone-core prose before any core texture is allowed); agy
(strictly shoulder-only, also framed as conformance). Resolved by the four-ballot
below.

## Decision (phase 3, synthesis)

**Fork B, as converged, with codex's rigor grafts and the contested core question
resolved to codex's bounded middle path (ratified 4-0).** Concretely:

1. **New offline bake (`tools/art/bake_dirt_detail.gd`, new; committed
   `assets/village/dirt_detail.png`).** Modeled exactly on
   `bake_ground_warp.gd`/`bake_lane_mask.gd`: fixed seed (`LAYOUT_SEED 7007` + a
   new named layer offset), pure function of (seed, integer texel) plus the
   committed grass plate as input, prints an `image_sha256`, gets a repeat-bake
   byte-identity test, pinned lossless/non-sRGB import. **RG8, two channels with a
   demonstrated separation need** (see the finalization refinement folding codex's
   ballot mechanism correction):
   - **R = full high-frequency detail** for the SHOULDER: the grass plate's
     luminance high-passed (grass luminance minus its own box-blur, computed WHOLE
     in the bake at matched resolution) as the majority painted substrate, blended
     with a minority fixed-seed FBM/sparse-speckle field, normalized to ZERO MEAN,
     centered at 0.5. The box-blur radius is named in source texels and its
     retained band inspected at 0.5x/1x/2x for ringing.
   - **G = broad low-frequency zero-mean drift** for the CORE: a heavily
     prefiltered / low-octave deterministic field (broad-only, no high-frequency
     content), centered at 0.5. This is the channel that lets the core receive
     broad drift WITHOUT the strong high-frequency band, which a single high-passed
     field cannot express (codex's ballot correction).

   No RNG, no time, no order dependence, no live hash.
2. **Shader composite (`src/render/town/ground.gdshader`).** Add
   `uniform sampler2D dirt_detail`, sampled once at `paint_uv` with `textureGrad`
   (mip-correct, matched to the plate mapping). Uses:
   - **#1 dirt structure (zero-mean value modulation, `dirt.rgb *= mix(1-c, 1+c,
     detail)`).** On the SHOULDER (`1.0 - core_solid`): the R channel at full
     amplitude (strong high-frequency structure, pebbles, tufts). On the protected
     CORE: the G channel (broad drift) at a BOUNDED LOW amplitude only, never the R
     high-frequency band. Core coverage/opacity (`dirt_amount`, `core_solid`) is
     untouched: the drift is tone-only, zero-mean, and never reduces the core.
   - **#2 transition break.** Perturb the shoulder coverage threshold before the
     two-stop smoothstep by the R field sampled at a FIXED OFFSET/ROTATED UV
     (decorrelated from the tone use), plus a widened two-stop feather. This
     dithers the clean isoline into a patchy grass-invades-dirt edge. Measured by a
     decoded perpendicular profile (>= a stated screen-pixel span of 10-90% dirt,
     with a non-monotone isoline), never by the constants alone.
3. **Coverage (`src/sim/town_layout.gd`, PROTECTED; the `half_widths` literals
   ONLY).** Narrow the three `LanePath` half_widths ~25-35% keeping the
   swell/narrow rhythm, re-bake `lane_mask.png`/`lane_density.png`, and TUNE
   against a decoded coverage target: measure the spike's dirt-area fraction first,
   then the composited `dirt_amount` on an unobstructed ground-only render, and
   choose the smallest width change that reaches grass-dominance while every
   existing nav invariant (connectivity, blocker clearance, A* route preference)
   still passes. The file stays headless/texture-ignorant/viewport-free.
4. **Wiring/export/tests.** `village_render.gd` binds the new `dirt_detail`
   uniform; the honest export gate gets a `ResourceLoader.exists` + load assertion
   for `dirt_detail.png`; tests cover the bake byte-identity, PCK sampler
   resolution, materially-non-flat detail, the coverage/gradient decode gates, and
   the nav invariants under narrower lanes.
5. **Hybrid-C paid-regen fallback (explicit, bounded, orchestrator-only).** Fire a
   SINGLE supervised paid regen ONLY if, after the composite is implemented and
   detail contrast is at its non-busy ceiling, the rendered dirt-crop mean gradient
   is still < 8.0 (from ~4.5 today; spike ~11.7) OR agy QA pass 4 still calls the
   dirt flat OR a blinded crop reads as retinted grass rather than worn earth. The
   spend is surfaced to the orchestrator (never run from a doer, never `save_to`),
   under the double-spend guard, with the acceptance decode (regen plate std >= 12,
   gradient >= 8) deciding it; if the regen also comes back flat, keep the composite
   and do not chase a third spend. Prompt drops decision 010's seamless-tile framing
   (which suppressed the macro value variation that flattened the current plate) and
   asks explicitly for tonal/value variation, pebbles, worn patches, grass tufts.

Do NOT regress decisions 010/011: the continuous quad, once-per-district plates,
baked lane mask/density, protected core coverage, contact shadows, authored
meandering centerlines, and offline SDF all remain; this adds source structure to
the dirt COLOR path plus a coverage narrow only.

### Finalization refinement (codex ballot mechanism correction, folded)

codex's ballot raised a mechanism correction (explicitly not an objection): a
single high-passed R8 field cannot by itself supply a BROAD-only signal for the
core while the shoulder gets the full high-frequency band, because sampling one
high-passed field yields the same frequency content everywhere. The record
therefore names a deterministic derivation: the bake emits **RG8**, R carrying the
full high-frequency shoulder detail and G carrying a broad low-frequency core
drift (item 1). This is the one demonstrated need that justifies a second channel
under the "add a channel only when a demonstrated need appears" rule; it is not a
return to codex's conceded speculative four-channel design.

## Ballot (four-ballot on the contested core-texture question)

Contested question: **may the protected lane core carry tonal texture, and how
much?** Orchestrator ruling: **bounded low-amplitude zero-mean BROAD value drift
on the core (to remove the dead-flat read that is a large part of tell #1 in the
pooled clearing), explicitly authorized here and superseding decision 010's
absolute true-tone-core prose ONLY for this bounded case; STRONG high-frequency
detail (pebble/tuft/edge-break) confined to the cosmetic shoulder. Core
coverage/opacity is unchanged.** This adopts codex's middle position.

Ballot artifacts: claude `11c4a75b86d4e7993ac22ff24ee7a941c31eaa50`, codex
`e19291239320b143c46973719150a660888c0a6a`, agy
`17c9b6f172697e75f17684c0eceb2128779d7c6b`.

- **orchestrator:** FOR. The pooled clearing is a large, mostly-core region; strict
  shoulder-only leaves it dead flat and only half-closes the dominant tell, while
  full high-frequency core texture raises the readability/shimmer/honesty concerns
  codex and agy correctly named. Low-amplitude zero-mean broad drift is the minimum
  that closes the core's flatness without breaking the silhouette.
- **claude-worker:** FOR (both the core question and the synthesis). PARTY (argued
  full-core detail, offered to concede). "The ruling gives me the substantive thing
  I argued for and drops only the part I could not defend... Broad drift is
  zero-mean, low-amplitude, and leaves `dirt_amount`/`core_solid` untouched, so the
  honest-core intent is preserved."
- **codex-worker:** FOR (both). PARTY (its middle position is adopted). "The bounded
  ruling addresses the dominant flat read in the pooled clearing... without changing
  the core's coverage, opacity, or traversability silhouette... Decision 012
  explicitly and narrowly supersedes decision 010's absolute true-tone-core prose,
  satisfying the decision-record requirement I raised in phase 2."
- **agy-worker:** FOR (both). PARTY (argued strict shoulder-only, relaxed here).
  "Permitting bounded low-amplitude zero-mean broad value drift on the core
  effectively mitigates the uniform flatness while keeping the strong high-frequency
  details on the shoulder... the correct balance of closing the visual tell without
  breaking gameplay invariants."

**Tally: 4-0 FOR, unanimous.** A 4-0 result decides the question without the
critic. The critic seat (tiebreaker-only, decision 004) is therefore NOT invoked.

## Division of labor (by capability, stacked slices)

Mirrors decisions 010/011: codex = deterministic bake + committed assets +
contract; claude = render/shader + decode + captures + authored-literal tuning.
The slices STACK (claude's render consumes codex's committed assets), integrated
by fast-forward.

| Piece | Assigned to | Why |
| --- | --- | --- |
| `bake_dirt_detail.gd` (RG8: R grass-luminance-high-pass-baked-whole + minority FBM/speckle zero-mean for the shoulder; G broad low-frequency zero-mean drift for the core) + committed `dirt_detail.png` + `image_sha256` fingerprint contract + repeat-bake byte-identity test; determinism review of the whole slice | codex-worker | Authored `bake_ground_warp.gd` and `bake_lane_mask.gd`; this rewards exact seed/offset/format contracts and byte fingerprints. |
| `ground.gdshader` dirt_detail composite (decorrelated dual-use, core G-channel bounded-broad-drift vs shoulder R-channel full-detail, widened two-stop feather) + `village_render.gd` uniform binding + export-gate assertion + the numeric decode harness (gradient/coverage/profile/post-0.5x-shimmer gates) + capture regen at 0.5x/1x/2x + `half_widths` literal tuning against decoded coverage (authored-constant block only, cross-signed by codex) + lane-mask re-bake | claude-worker | Authored the entire decision-010/011 render and holds that context; decodes PNGs in-session to close the bake->decode->tune loop without eyeballing; the shape must be tuned against captures. |
| Multimodal QA pass 4: re-judge the dirt at 0.5x/1x/2x + a 0.5x pan against the spike (flat read closed? transition soft/patchy? coverage grass-dominant? no shimmer/synthetic tell?), and the blinded worn-earth-vs-retinted-grass verdict | agy-worker | The QA seat; diagnosed this tell in pass 3; judges genuinely multimodally; the round explicitly routes the author-blind visual verdict away from the composite's author. |

## Protected paths touched

- `src/sim/town_layout.gd` -- the `half_widths` literal constants ONLY (semantic
  geometry). This record authorizes that edit. The file stays texture-ignorant and
  viewport-free.

## Dissent

None. The four-ballot was unanimous 4-0 FOR on both the contested core-texture
question and the synthesis as a whole; no worker recorded a dissenting objection
and no constitution-violation claim survived. codex's constitution-conformance
concern from phase 2 is HONORED, not overruled: this record explicitly and
narrowly supersedes decision 010's absolute true-tone-core prose for the bounded
broad-drift case via the signed decision-record mechanism the constitution
provides, and all three doers confirmed that resolution at signing. codex's ballot
mechanism correction is folded into the decision (RG8 two-channel bake) rather than
recorded as a dissent, because it corrected the mechanism without opposing the
ruling. The critic seat was not invoked (tiebreaker-only; the ballot did not split
2-2).

## Sign-offs

Every worker named in `Workers dispatched` signs. This record authorizes the
`src/sim/town_layout.gd` `half_widths` literal edit.

    Signed-off-by: claude-worker <claude@sentania.net> 2026-07-18T09:13:53Z
    Signed-off-by: codex-worker <codex@sentania.net> 2026-07-18T09:13:42Z
    Signed-off-by: agy-worker <agy@sentania.net> 2026-07-18T09:13:16Z
