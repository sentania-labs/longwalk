# 014: Source-level dirt stone removal

- **Status:** accepted
- **Date:** 2026-07-18
- **Assignment:** Round 007, Two Rivers village at spike fidelity. Close the last
  dominant NOT-CONFUSABLE dirt tell after decision 013: the ~15-20 discrete
  source-painted grey lozenge stones (plus a stray amber rock and grass tufts)
  littering the open dirt path, which read nothing like the spike's smooth dusty
  tan. Decision 013's de-peak (slice `bdfaa28`) proved by rendered measurement
  that NO luminance-band operator dissolves them: a painted rock is coherent
  across every frequency band at once, not a single-band outlier. So the stones
  are removed at the SOURCE plate and the dusty-tan substrate is re-synthesized
  over them, preserving the accepted richness.
- **Orchestrator run:** decision-014 respawn (verify agy proposal commit -> phase
  2 critique -> this synthesis), off round head `6bb94c6`, candidates based on
  de-peak `bdfaa28`.
- **Lane:** full protocol (three-way blind proposal + adversarial critique).
  Triaged full because reasonable engineers pick materially different removal
  methods (auto-detect vs hand-annotation; membrane vs exemplar vs blur fill) and
  each has a distinct new-tell failure mode; a wrong pick costs a full QA cycle.
- **Workers dispatched:** claude-worker, codex-worker, agy-worker

> This record touches only `assets/`, `docs/`, `test/`, and `tools/art/` (see
> Protected paths touched below). It touches NO protected path, so like decision
> 013 it is not consensus-gate-required and carries the orchestrator synthesis
> plus the cited proposal and critique SHAs rather than three worker signatures
> on the record itself. The implementation slice still requires one non-author
> peer sign-off before it is integrated into the round branch.

## Context

After decision 013 (multiband reshape) and the `bdfaa28` de-peak wall, agy QA
pass 6 returned NOT-CONFUSABLE with exactly one dominant tell left: discrete
embedded grey stones on the open dirt. The luminance-band path is closed. The
next lever is removing the painted debris from the source plate itself and
re-filling the dusty-tan substrate. Two hard gates carry forward from decision
013 and both must hold: protected-core center-crop lum_std >= 18.44 floor
(flat-core), and 0.5x dirt fine-gradient <= ~10.75 ceiling (shimmer). The real
bar is Scott's: a screenshot confusable with `docs/art/iso-five-asset-spike.png`,
which no gate number captures and which agy's multimodal QA is the proxy for.

## Proposals (phase 1, blind)

Every dispatched worker proposed independently, none having seen another's. All
three converged on the same high-level shape (detect debris in source space,
re-fill the substrate, recover the lost core variance by raising one band gain),
but split on all three sub-choices: detector, fill, and which band to raise.

| Worker | Branch | Proposal commit SHA |
| --- | --- | --- |
| claude-worker | `claude/014-stone` | `a1e99154ea6f677e2468dddec3883973365c7be2` |
| codex-worker | `codex/014-stone` | `d5725c5f41fd531380989c5aef96f88180fc3687` |
| agy-worker | `agy/014-stone-removal` | `42ad6a17c3b02b7f65e3fb1c462f3dc76c784972` |

**claude:** new deterministic pre-step `tools/art/declutter_dirt_source.py`,
applied in-memory by `grade_dirt_plate.py` upstream of the multiband reshape.
AUTO detection by chroma segmentation (grey stones by low saturation keeping
saturated brown streaks; amber rocks by red-and-dark; grass tufts by green with a
solid core), then morphology; 8.65% coverage. FILL: pull-push harmonic membrane
(boundary-exact) plus a fixed-roll transplant of the source's own dusty grain
with masked-source grain zeroed before the roll (`np.where(m3, 0.0, grain)`) so
stone content is never re-injected. Recovers lost variance by raising the MID
band gain 0.55 -> 1.30. Rendered gates: flat-core 19.22, shimmer 10.07.

**codex:** cleanup in `grade_dirt_plate.py` from a FIXED hand-annotated source
ellipse list (~133 entries), deliberately not a global threshold, so it cannot
eat real substrate. FILL: best-of-fixed-offset exemplar patch transplant
(real full-resolution source substrate) feathered through a 22% margin. Recovers
variance by raising the MACRO band gain 0.14 -> 0.65. Rendered gates: flat-core
18.75, shimmer 10.09. Honest residual: any stone not on the list survives.

**agy:** `remove_stones` in `grade_dirt_plate.py`. AUTO detection by HSL plus a
local-contrast z-score mask (`s < 0.25 AND |lum - blur12|/local_std > 2.5`).
FILL: radius-24 box-blur average switched in with a hard mask, then fine (1.3x)
and mid (1.2x) noise re-injected by fixed roll. Recovers variance by raising
LOMID gain 1.55 -> 1.67 (the gentlest gain move of the three). Rendered gates:
flat-core 19.59 (highest margin), shimmer 10.33.

## Critique (phase 2, adversarial)

A genuine adversarial round, not "looks good". Cited critique SHAs: claude
`38dae8a4559faea05e67a658014ca2e18c5f634c`, codex
`b012bd3073193e651b124c052d93fc7969cf55cd`, agy
`770ebf7d4e5547095930404e0c26a59d74e4c1bf`.

Strong cross-critic convergence on three points:

1. **agy's z-score detector misses the stone bodies.** Both claude and codex
   independently derived that `z_score = |lum - blur12|/local_std` collapses to ~0
   in the interior of any stone larger than the 12px blur radius (the stone is its
   own local field), so only an edge-ring gets masked and the flat grey cores
   survive. agy's own stone-prominence proxy barely moved (kurtosis 3.272 ->
   3.129), corroborating under-removal.
2. **claude's mid gain 0.55 -> 1.30 (2.36x) and codex's macro 0.14 -> 0.65 (4.6x)**
   each re-inflate a band decision 013 deliberately suppressed to kill a named
   tell (mid = rock-blob prominence; macro = wet-mud drift + district tiling).
   Both moves risk reviving the exact tell they neighbor, and the single-tile
   hard gates cannot see the cross-tile tiling failure mode.
3. **Fill scars:** claude's membrane base restores only sub-16px grain, leaving
   16-64px membrane-smooth islands; agy's hard-switched box-blur fill has a
   statistical seam and can re-inject foreign stone content (no donor exclusion);
   codex's full-donor patch risks a clone-stamp / grain-phase seam.

Determinism: unanimous, all three pass. No RNG, time, or visit-order dependence
in any proposal. No constitution violation named by any critic.

Codex's own synthesis recommendation was notably self-critical: adopt neither
implementation unchanged; start from a reviewed object-level mask, keep claude's
debris-excluded donor safeguard, use a multiscale boundary-matched fill, and tune
the smallest post-removal gain only after all stones are demonstrably absent at 2x.

## Decision (phase 3, synthesis)

**Orchestrator rendered-decode verdict (the check the gates cannot make).** I
extracted each candidate's committed 2x ground capture (matched framing, same
scene) and viewed them directly against the spike:

- **agy `42ad6a1`: ~15 grey stones remain.** The z-score detector missed the
  bodies exactly as claude and codex predicted. agy's proposal claim "the
  source-painted grey stones are gone" is false on its own committed evidence.
  Fails the primary objective despite passing both numeric gates.
- **codex `d5725c5`: ~12-15 grey stones remain.** The 133-ellipse hand list is
  incomplete against the stones that tile into the visible frame. Fails the
  primary objective in the render despite a reported 51% masked-prominence drop
  in source space. This empirically refutes codex's own premise that a bounded
  hand mask is the safe base: it is false-positive-immune but leaves the tell.
- **claude `a1e9915`: grey stones removed.** The only candidate whose render
  actually eliminates the dominant tell. Residuals, both confirmed by my decode:
  a few surviving brown/amber rock bodies, some 16-64px membrane-smooth islands,
  and broad muddy mid-band mottling from the 2.36x mid restoration.

The rendered decode is decisive over the source-space proxies both losers relied
on. Only claude's AUTO chroma-segmentation detector removes the stones in the
frame that ships, so it is the spine. This is settled on evidence, not a vote:
two of three methods empirically leave the tell, so there is no contested 2-2
synthesis question, hence no four-ballot and no critic seat (tiebreaker-only).

**Converged method (build on claude `a1e9915`):**

1. **Detector:** keep claude's auto chroma-segmentation spine. EXTEND it to catch
   the surviving amber/brown rock bodies my decode still sees (widen the
   red-and-dark class, and/or add a small fixed set of codex-style targeted
   annotations for the few large survivors as a bounded supplement). Report
   object-level recall over the ~15-20 targets plus false-positive mask area, not
   just a grey-pixel fraction. Grafted from codex: the reviewed object-level
   completeness check as a blocking third acceptance criterion.
2. **Fill:** keep claude's boundary-exact pull-push membrane base AND its
   debris-excluded donor safeguard (`np.where(m3, 0, grain)`; agy lacked this,
   codex praised it). GRAFT codex's multiscale idea: add real 16-64px substrate
   structure to the fill (exemplar/donor mid-band from verified stone-free source
   regions) so the membrane islands stop reading as smooth smudges. Feather, do
   not hard-switch.
3. **Gain:** REDUCE claude's mid gain from 1.30. Tune the SMALLEST mid gain that
   still clears the 18.44 floor AFTER complete removal is verified at 2x, and
   prefer recovering variance locally in the filled regions over a global band
   bump, so the mud/tiling tell decision 013 killed is not revived. Grafted from
   both codex and agy dissents (recorded verbatim below).
4. **Acceptance:** both hard gates (flat-core >= 18.44, shimmer <= 10.75) AND my
   own rendered decode showing stones absent + no membrane smear + no muddy
   revival, THEN agy QA pass 7 as the confusability bar. Suite + export gate green.

## Division of labor

One cohesive art-pipeline slice (`declutter_dirt_source.py` + `grade_dirt_plate.py`
tuning + re-bake + re-capture). Not evenly divisible without creating integration
seams in a single tool, so it is assigned whole.

| Piece | Assigned to | Why this harness |
| --- | --- | --- |
| Implement the synthesized removal (extend detector, multiscale fill, minimal gain) | claude-worker | Authored the only method that empirically removes the stones and already owns the winning detector + donor-exclusion fill; extending its own tool is lowest-risk. |
| Non-author peer sign-off on the slice | codex-worker | Authored the exemplar/multiscale-fill idea being grafted in and the sharpest completeness critique; best placed to verify the graft landed and the mask is complete. |
| QA pass 7 (confusability bar) | agy-worker | Owns the multimodal confusable-with-spike QA that is the actual acceptance bar; independent of the implementing harness. |

## Dissent

Two losing proposals; each objection is recorded in its author's own words. Both
were FOLDED INTO the synthesis (mid/macro gain reduction; multiscale fill;
bounded-mask completeness check), not overruled, so this is synthesis rather than
a contested ruling. No objection claimed a constitution violation, so none
escalates to Scott.

codex-worker, on why to adopt neither implementation unchanged (from
`b012bd3`, verbatim):

> Do not adopt either peer implementation unchanged. Agy's committed visual
> result fails the assignment's primary removal objective despite passing both
> numeric gates. Claude removes substantially more debris and supplies the safer
> donor exclusion, but its 8.65% automatic mask is over-broad, still misses
> saturated rock objects, leaves visible membrane islands, and pays for lost
> variance with an excessive 2.36x mid-band restoration. Start from a reviewed
> object-level mask, preserve Claude's debris-excluded deterministic donor
> safeguard, use a multiscale boundary-matched fill, and tune the smallest
> post-removal gain only after all target stones are demonstrably absent at 2x.

agy-worker, on claude's mid-gain move (from `770ebf7`, verbatim):

> The gain compensation (reintroducing rock-blob prominence): Claude raises the
> `mid` gain from `0.55` all the way to `1.30` to restore core variance. Decision
> 013 explicitly suppressed this mid-band precisely because it carried the
> "rock-cluster blobs (the 'tiling' motifs)". Raising it by 2.3x will violently
> reintroduce those tiling motifs across the entire remaining substrate, actively
> undoing the exact problem decision 013 solved.

## Protected paths touched

None. This decision touches `tools/art/`, `assets/village/`, `docs/`, and
`test/active_path/` only. It is recorded as a full-protocol decision because it
is the durable synthesis of a three-way blind round, but it is not
consensus-gate-required and needs no worker signatures on the record itself; the
implementation slice takes one non-author peer sign-off before integration.
