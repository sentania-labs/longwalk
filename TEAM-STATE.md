# TEAM-STATE

<!--
MACHINERY, NOT A CHANGELOG.

The orchestrator is ephemeral: spawned with an assignment, runs the protocol,
dies. Nothing it holds in memory survives. It reads this file first on every
run and rewrites it before exiting. That read/write cycle is the team's only
continuity between runs.

  - It is OVERWRITTEN. The durable record of a decision is
    docs/decisions/NNN-topic.md (append-only), not this file.
  - It describes the PRESENT, not the past. When an assignment finishes its
    state is REPLACED, not appended. History lives in git + decision records +
    refs/archive/NNN/*.
  - Humans read it, but it is a state dump the next run can act on, not a
    changelog.

Keep the heading structure stable (orchestrator + Dashboard parse by heading).
-->

## Current assignment

**ROUND 007: Two Rivers village at spike fidelity, free-cam, no PC/no NPC.
FULL PROTOCOL (decision 009, Option H, 4-0). EXECUTION iterating on the ground/
lane/dirt treatment toward the confusable-with-spike bar.**

The bar is Scott's, verbatim: *screenshots confusable with the spike*
(`docs/art/iso-five-asset-spike.png`). Deliverable: a playable Windows build of a
full Two Rivers village at spike fidelity, NO PC/NPC, free ("disincorporated")
drag-pan/zoom camera. Walk-cycle/animation OUT of scope. Method unmandated.
Full scope: `.pka/round007/assignment.md`. Standing posture (directive 1500 +
Scott Q2 GO): autonomous back-to-back iteration; surface a build to Scott ONLY
when the team believes a screenshot genuinely passes the confusable bar.

**WHERE WE ARE:** one inn-green district at spike fidelity for BUILDINGS +
GROUND-TEXTURE (010) + LANE MACRO-GEOMETRY (011) + DIRT FIDELITY (012 fork B +
paid-regen re-tune) + **DIRT RE-TUNE (decision 013) integrated + pushed**. Round
head **`6bb94c6`** on origin (decision 013 + impl f81db85 + codex signoff + agy
QA6). The PAID PATH IS DONE (plate accepted + rich); zero paid spend from here.
The live status + resume steps are in the "STATUS: decision 013 IMPL landed +
QA6 = NOT-CONFUSABLE; DE-PEAK slice in flight" section below -- read THAT, it
supersedes the historical detail in this block.

**THIS RUN:** ran decision-013 FULL PROTOCOL on the three pass-5 tells (muddy
tone, tiling, seams). Triage flipped to full protocol after the orchestrator
decoded the spike-dirt crop (std 40.59 > graded plate 19.78), overturning "reduce
contrast" and revealing a frequency-distribution problem with genuine method
alternatives. Blind 3-way proposal (claude 531e701, codex 8a5ef44, agy 824c456) +
adversarial critique (claude 035e9a6, codex a04e79e, agy ab3bb78), every dispatch
verified from end marker + tree. **Unanimous convergence, every author conceded
its contested point, NO 2-2 split so NO four-ballot / NO critic** (tiebreaker-only).
Synthesis = `docs/decisions/013-dirt-retune-fidelity.md`. Impl f81db85 (multiband
reshape) integrated (round FF), codex non-author signed, suite/gate GREEN, PUSHED
(round `6bb94c6`). agy QA6 = NOT-CONFUSABLE, closed muddy-tone + seams, stones
remain -> DE-PEAK follow-on slice IN FLIGHT (see STATUS section below).

Converged method (decision 013 is authoritative): (1) replace the affine grade in
`grade_dirt_plate.py` with a deterministic MULTIBAND luminance reshape (attenuate
macro+mid = kill mud + rock-blob tiling; handle fine toward spike speckle;
re-match spike mean). (2) Change `bake_dirt_detail.gd`: R high-pass radius 12->~3
+ winsorize (its `_standardize` renormalizes surviving mid-band rocks, so
plate-only was retracted). (3) Shader amplitude MEASURED sweep
(`detail_shoulder_amp`/`tone_contrast`/`detail_core_amp`). (4) LOCALIZE the
mid-district seams (UV-classify) before fixing. TWO HARD GATES: core center-crop
lum_std >= 17.97 (flat-core), 0.5x dirt fine-grad <= grass ceiling ~10.75
(shimmer). RULED OUT (unanimous incl. agy self-concession): `repeat_enable`/`fract`
on dirt_detail (real wrap seam, not periodic), in-shader stochastic anti-tiling
(ghosting). `src/render/town/` is NOT protected; `src/sim/` untouched.

=== 010 (ground) + 011 (lane) + 012 (dirt fidelity fork B) -- DONE ==============
`docs/decisions/010/011/012-*.md` (all 4-0). Killed checkerboard, straight-X,
hard-cut, over-coverage. On round branch.

=== PAID DIRT REGEN + RE-TUNE (this run, decision 012 item 5) -- DONE, INTEGRATED =
The pre-authorized single supervised paid regen of the dirt source plate. Full
sequence, every step orchestrator-verified from marker + tree + decoded PNGs:
- **Double-spend guard:** `meshy_list_tasks` (no PENDING/IN_PROGRESS),
  `meshy_check_balance` (2946 confirmed) BEFORE the call.
- **Regen:** `meshy_text_to_image` nano-banana-pro, task
  `019f74b2-36fc-777a-880b-dbd814e2a725`, **9 credits** (2946 -> **2937**, verified
  after). Prompt dropped the seamless-tile framing that flattened the original.
  Downloaded (URLs expire) to the ONLY copy
  `.pka/round007/ground-source/dirt-regen-nbpro-019f74b2.png`. Did NOT overwrite
  `source-dirt.png`.
- **Acceptance decode (orchestrator, not eyeballed; ruling in
  `.pka/round007/dirt-regen-acceptance.md`):** raw std_rgb **19.83** (>= 12 bar PASS,
  4.4x the old flat 4.48) with visible pebbles/gravel + strong tonal variation +
  earthy morphology (viewed directly). mean_grad 5.60 < 8 but ruled non-blocking (the
  8 bar conflated composite Gate-1 with a raw-plate gradient; 5.60 is BELOW the grass
  plate's 10.75 = FAVORABLE for shimmer). ACCEPTED. One tunable flagged: tone (regen
  lum 145 vs spike 85).
- **Re-tune slice (claude render, fast-lane under 012 item 5), commit `8cf9306`:**
  affine tone-grade (`grade_dirt_plate.py`) onto spike mean (98.6,85.0,43.5) that
  HELD std (~19.8) instead of a multiply that would collapse it; installed as
  `ground_dirt_plate.png` (core samples it -> core lum std 6.15 -> 18.44, flat-core
  fix); switched `bake_dirt_detail.gd` R-substrate grass->dirt-plate (retinted-grass
  fix); softened shoulder radius 2 (shimmer). Suite GREEN + export gate PASS +
  non-mutation guard clean, all orchestrator-re-run. Orchestrator independently
  decoded the committed plate: std 19.78, mean (98.6,85.5,43.5) lum 85.2 (on spike
  target), R>G>B no green cast, center-crop lum_std 17.97.
- **Cross sign-off (non-author):** codex reviews claude `8cf9306`
  (`.team/signoffs/claude-007-dirt-retune-8cf9306de240.md`, `result: signed-off`,
  independent decodes match). NO protected path touched (tools/assets/tests/docs
  only), so no decision record required for the merge beyond the sign-off.
- **Integration:** round FF 7548872 -> 8cf9306 + cherry-picked sign-off marker +
  agy QA5 report. Suite + export gate GREEN on integrated tree. **Round head
  `2ca6f62`, PUSHED.**

**agy QA PASS 5 VERDICT: NOT-CONFUSABLE** (`docs/art/village/qa-agy-dirt-005.md`,
on round branch; agy `79aaaa1`). CLOSED all three pass-4 tells (flat core,
retinted-grass, shimmer -- orchestrator confirmed at 1x/2x). THREE NEW tells,
dominant first (all ZERO-COST composite fixes, no paid spend):
  1. **Muddy high-contrast tone (dominant, all zooms).** The graded plate's dark
     values are too dark / contrast too high -> reads as wet chunky river mud, not the
     spike's dry dusty low-contrast tan. Orchestrator confirmed dark smeary drifts at
     2x. Fix: lower plate contrast + lift dark values toward dry tan (a
     `grade_dirt_plate.py` param re-tune; the affine grade darkened the mean but kept
     std 19.8, so darks went too deep).
  2. **Visible tiling repetition (1x/2x).** The now-rich plate has distinct
     high-contrast rock clusters that repeat identically across path tiles. Fix:
     per-tile rotation / macro-variation / secondary mask to break the repeat.
  3. **Grid seams (1x/2x).** Faint straight-edge luminosity seams between tiles
     (the plate is no longer seamless -- the richness-for-seamlessness trade the regen
     prompt deliberately made). Fix: tile-blend / offset-heal across seams.

=== STATUS: DECISION 014 (source stone removal) PHASE 1 DONE -> PHASE 2 CRITIQUE ===
**Phase 1 blind proposals ALL committed + orchestrator-verified from marker+tree
(2026-07-18):**
- claude `a1e99154ea6f677e2468dddec3883973365c7be2` (branch `claude/014-stone`):
  NEW tool `declutter_dirt_source.py`, auto chroma-segmentation detect + pull-push
  harmonic membrane fill + fixed-roll grain transplant; mid gain 0.55->1.30.
  Rendered gates flat-core 19.22 >= 18.44, shimmer 10.07 <= 10.75. grey frac 2.68%->0.34%.
- codex `d5725c5f41fd531380989c5aef96f88180fc3687` (branch `codex/014-stone`):
  FIXED hand-annotated source ellipse list (NOT auto-threshold) + best-of-fixed-offset
  exemplar patch transplant + feather; macro gain 0.14->0.65. Gates flat-core 18.75,
  shimmer 10.09. Honest residual: a missed small stone stays source content.
- agy `42ad6a17c3b02b7f65e3fb1c462f3dc76c784972` (branch `agy/014-stone-removal`):
  `remove_stones` in grade_dirt_plate.py, HSL+local-contrast z-score auto mask +
  box-blur fill + fine/mid band energy re-injection; lomid gain 1.55->1.67. Gates
  flat-core 19.59, shimmer 10.33. (agy's prior dispatch finished the work but did NOT
  commit; re-dispatched narrow commit-only, landed 42ad6a1, verified branch_changed:yes.)
All three base off bdfaa28 (de-peak wall). Three genuinely distinct fill methods.

**PHASE 2 CRITIQUE DONE + verified** (claude 38dae8a / codex b012bd3 / agy 770ebf7,
each branch_changed:yes). Genuine adversarial round. Cross-critic convergence:
agy's z-score mask misses stone bodies; claude's mid 1.30 + codex's macro 0.65
revive killed tells; determinism unanimous-pass.

**PHASE 3 SYNTHESIS DONE -> decision 014 committed `a857db9` on round branch.**
ORCHESTRATOR RENDERED DECODE (viewed all three committed 2x captures + spike
myself, matched framing): agy `42ad6a1` ~15 stones REMAIN (fails objective);
codex `d5725c5` ~12-15 stones REMAIN (hand-list incomplete, fails in render);
claude `a1e9915` stones GONE (only method that works) but residuals = surviving
amber/brown rocks + membrane-smooth islands + muddy mid mottling. Decode decisive
over source-space proxies -> NO 2-2, NO four-ballot, NO critic. Synthesis = build
on claude detector+donor-exclusion spine, GRAFT codex multiscale fill +
object-level completeness check, REDUCE mid gain (both dissents recorded verbatim
in 014). Not gate-required (no protected path). Division: claude implements,
codex non-author signs off, agy QA7.

**IMPLEMENTATION IN FLIGHT:** claude dispatched on `claude/014-stone-impl` (off
a1e9915, de-peak in ancestry). run `014-impl-claude-20260718`, cap 3000s.
Prompt `.pka/round007/014-impl-claude-prompt.md`. RESUME: verify impl end
marker + tree + BOTH hard gates + DECODE the new ground-2x yourself (stones AND
amber rocks gone, no membrane smear, no muddy revival). Then codex NON-AUTHOR
sign-off -> FF-integrate into round/007-village -> re-run suite+export gate ->
PUSH round branch -> agy QA pass 7. If QA CONFUSABLE and my own decode agrees ->
SURFACE BUILD TO SCOTT (to: dalinar). Else diagnose from artifacts, tee up next.

=== (prior) NEXT: phase 2 adversarial critique ===

=== (prior) DE-PEAK WALL VERIFIED -> DECISION 014 PHASE 1 ===
Round head **`6bb94c6`** on origin (decision 013 impl + codex signoff + agy QA6).
agy QA PASS 6 (`docs/art/village/qa-agy-dirt-006.md`): **NOT-CONFUSABLE**, CLOSED
muddy tone + grid seams, no new tells, no regressions. ONE dominant tell left:
discrete embedded STONES.

**DE-PEAK SLICE bdfaa28 -- WALL TRIGGERED, VERIFIED by orchestrator.** claude
`bdfaa28` (on local `claude/013-dirt-depeak`, off 6bb94c6; end marker
`013-depeak-claude-20260718-115340-end.md`, branch_changed yes, cap not expired;
"uncommitted" is only untracked .pka/.team scratch, not code). The worker did a
rendered measurement and PROVED the HARD FALLBACK: NO luminance-band winsorize/
de-peak removes the stones at ANY strength (incl. breaching both gates), because a
painted rock is coherent across every frequency band at once, not a single-band
outlier. Orchestrator CONFIRMED by viewing the actual artifacts: ground-2x capture
(~15-20 grey lozenge stones + amber rock), the spike (smooth dusty tan, no path
stones), AND the source plate itself
(`.pka/round007/ground-source/dirt-regen-nbpro-019f74b2.png`): the stones are
PAINTED CONTENT, and the dusty-tan substrate BETWEEN them is already spike-correct.
The de-peak is a non-regressing mid-band improvement (kurtosis 3.27->3.09, both
gates hold) that DID NOT move the visible tell. The luminance-band path is CLOSED.

**ORCHESTRATOR DESIGN RULING (decision 014, mine at the wall):** the next
iteration is ZERO-COST SOURCE-LEVEL stone removal -- detect the painted stones +
amber rock + grass tufts and inpaint/synthesize the surrounding dusty-tan
substrate over them, preserving the accepted richness. This is within team art
authority (no engine/arch/dependency/constitution trigger), zero paid credits;
the PAID regen path stays CLOSED as a fallback only if zero-cost removal fails.
NOT escalating to Scott (per his autonomy directive 1500 + Q2 GO: iterate; surface
only when confusable). Running the METHOD as a FULL-PROTOCOL EMPIRICAL round
because reasonable engineers differ on removal method (detection mask + fill:
cv2 inpaint vs patch/exemplar synthesis vs statistical resample) and each has a
distinct new-tell failure mode; wrong pick = another full QA cycle. Not fast-lane.

**DE-PEAK bdfaa28 is NOT integrated separately** (zero visible gain would waste a
sign-off/QA cycle). Decision-014 candidates BASE OFF bdfaa28 so the de-peak
wall-record + mid improvement ride along in ONE integration once a winner clears.

Proposal prompt (same for all 3, blind): `.pka/round007/014-stone-removal-prop-prompt.md`.
Two HARD gates unchanged: flat-core lum_std >= ~18.44 floor; 0.5x dirt fine-grad
<= ~10.75. Source plate is the ONLY copy + untracked; each doer worktree needs a
COPY of `.pka/round007/ground-source/` (do NOT overwrite the original).

--- ON RESPAWN, verify then proceed (decision 014): ---
1. **Verify each phase-1 proposal** from its end marker + tree + DECODED captures
   (view ground-2x yourself; do not trust the proxy/narration). Each must hold BOTH
   hard gates + run suite + export gate. A candidate that reopens flat core or leaves
   a new tell (inpaint smear / patch seam / repetition) is disqualified.
2. **PHASE 2 adversarial critique:** each doer reads the others, actively hunts new
   tells introduced by each fill method. "Looks good" = failed round, re-dispatch.
3. **PHASE 3 synthesis** -> `docs/decisions/014-*.md`: pick the removal method whose
   rendered captures are actually stone-free without a new tell (my own decode is the
   check, agy QA is the bar). Unanimous/majority = no four-ballot; a 2-2 contested
   question invokes the critic (tiebreaker-only). Promote/implement the winner off
   bdfaa28, codex NON-AUTHOR sign-off, FF-integrate into `round/007-village`, re-run
   suite+gate, PUSH the round branch.
4. **agy QA PASS 7** off the integrated head: multimodal confusability read; MUST
   confirm the stones are gone + no new fill tell + no muddy/seam/flat-core
   regression.
5. If agy CONFUSABLE **and orchestrator's own decoded read agrees** -> **SURFACE A
   BUILD TO SCOTT** (his bar; cross-workspace `to: dalinar`). Two of three pass-5
   defects already closed; stones are the last. If still NOT-CONFUSABLE, decode the
   artifacts (never narration), diagnose, tee up next fix (paid dirt stays a fallback,
   escalate only if zero-cost source removal is also proven exhausted).
6. After dirt clears: expand the inn-green district to the full ~12-16-structure
   village; ONE round PR + external Codex review; address; merge; sweep.

**Live worktrees + branches (all LOCAL except `round/007-village`):**
- `lw-007-round` on `round/007-village` @ `6bb94c6` (== origin; integration tree).
- `lw-007-claude` on `claude/013-dirt-depeak` @ `bdfaa28` (de-peak wall commit +
  source plate; the ONLY copy of `.pka/round007/ground-source/*`).
- `lw-007-codex` on `codex/013-dirt-retune`; `lw-007-agy` on `agy/013-dirt-retune`
  (reuse for decision-014 proposals/critique/QA; rebranch off bdfaa28).
- Prior integrated slices (claude 8cf9306, codex 7672b3a, agy 79aaaa1, claude
  f81db85+signoff, agy QA6) all in round head 6bb94c6 history. Local doer/deliberation
  branches archive to `refs/archive/007/*` at round close.

## Round 006 -- CLOSED (superseded)

Everything recoverable under `refs/archive/006/*` (pushed). `git show
refs/archive/006/<name>:<path>`.

## Durable lessons (paid for repeatedly; honor them)

- **A dispatch is synchronous; nothing external re-invokes you when a detached proc
  finishes.** Only supervisor respawn re-invokes you. Own tool calls cap at ~600s --
  SET the Bash `timeout` param up to ~560000ms when polling. EITHER block in one call
  OR detach (setsid) + poll the end marker across calls, capturing in-flight state
  first. This run: paid regen ~24s; render re-tune slice **1569s (26 min)** (matches
  prior render-slice cost -- `claude -p` buffers ALL output, verify liveness via
  `pgrep adapters/claude.sh` not file mtimes); codex sign-off 157s; agy QA 135s. Ran
  the sign-off + QA IN PARALLEL into separate worktrees (both read the same commit).
- **Verify from the end marker + tree, NEVER exit code or narration.** Then RUN the
  suite + export gate yourself and DECODE the actual PNGs. This run: independently
  re-decoded the committed graded plate (std 19.78, mean on spike target, no green
  cast) and confirmed agy's new muddy-tone/tiling tells at 2x before believing them.
- **The gradient metric is necessary but NOT sufficient; agy's multimodal read is the
  bar.** This run twice: (a) acceptance -- the raw plate's mean_grad 5.60 < 8 did NOT
  block, because the dominant flat-core tell is a TONAL (std) property not a gradient;
  (b) QA5 -- the decoded gates all passed but agy caught muddy tone + tiling + seams
  that no gate number shows. Always run agy QA before believing a decode or surfacing.
- **A paid spend CAN be the right call when a zero-cost path is genuinely exhausted.**
  Fork B (zero-cost) could not fix the flat core (root cause = flat source plate the
  core samples directly); the one supervised regen closed it decisively. But it TRADED
  richness for seamlessness (new tiling/seam tells) -- expect a downstream composite
  round after any source regen. Do the guard + accept-decode + single-spend-no-chase
  discipline every time.
- **Stacked slices integrate by fast-forward; cross sign-off = ephemeral detached
  review worktree** (`git worktree add -b rev/<slug> <wt> <sha>`, dispatch NON-AUTHOR,
  cherry-pick the marker, `git worktree remove`). reviewed_by != authored_by.
- **agy adapter can no-op into a scratch project; markers catch it.** This run agy
  committed a real report (branch_changed: yes, 79aaaa1) -- verified.
- **Doer seats NEVER push to origin.** Only the orchestrator, only the round branch.
- **Long render/gate/decode proofs run to completion in the FOREGROUND same turn.**
- **Cross-workspace asks to Scott: address `to: dalinar`, NOT `to: scott`.**
- **Do NOT start a paid spend at a run tail.** This run the regen was the FIRST thing
  done on a fresh turn -- correct. The remaining dirt work is zero-cost.

## Meshy

Key live at `~/.claude/pka-secrets/longwalk/meshy.env`; MCP `meshy` in `.mcp.json`.
Balance **2937** (was 2946; **9 credits spent this run** on the accepted dirt regen,
task `019f74b2`, nano-banana-pro). The DIRT paid path is now CLOSED -- the plate is
accepted and rich; the remaining dirt tells are zero-cost composite fixes. Do NOT
regen dirt again. Paid source downloads at `.pka/round007/ground-source/*.png`
(including `dirt-regen-nbpro-019f74b2.png`, the installed plate's source, and the
legacy `source-dirt.png`/`source-grass.png`) are the ONLY copies (URLs expired); do
NOT regenerate/overwrite those. Any FUTURE paid spend needs its own guard
(`meshy_list_tasks` no PENDING, `meshy_check_balance` before/after, cost-confirm,
NEVER `save_to`).

## Active decision records (on main / round branch)

001-008 on main. Round-007 decisions **009** (art method), **010** (ground/lane
shader-quad plate), **011** (lane geometry fork B), **012** (dirt fidelity fork B +
item-5 paid-regen path) are on the round branch, all signed 4-0. **013** (dirt
re-tune fidelity: multiband reshape) committed this run on the round branch (round
head ff2a801); it is a full-protocol converged record but touches NO protected path,
so it is not gate-required and carries the orchestrator synthesis + cited proposal/
critique SHAs rather than worker signatures. Round-006's own 009/010 are archive-only.

## Notes for the next run

- **Dashboard `/team` tab is KILLED by Scott** (inbox `2026-07-18-0445`): do NOT
  POST to `dashboard.int.sentania.net/api/team`. No in-repo sync tool exists;
  compliance = simply not posting. Duty suspended; a missing POST is not a failure.
  Inbox fully processed through 04:45Z; NO new orchestrator inbox messages this run
  (checked at start).
- `gh pr edit` is broken (GraphQL projectCards). Use REST `gh api -X PATCH
  repos/sentania-labs/longwalk/pulls/N ...`.
- No round PR is open (correct -- opens only once the district passes the bar).
- Sweep verified THIS run: 0 open team PRs; origin carries only `main`,
  `round/007-village` @ 2ca6f62, unrelated `issue-4-world-eras`; leak guard OK (no
  doer/rev branches on origin). Ephemeral codex review worktree removed.

**Last updated:** 2026-07-18 (DECISION 013 DIRT RE-TUNE, full-protocol converged
round: triage flipped to full protocol after decoding spike crop std 40.59 > plate
19.78; blind 3-way proposal [claude 531e701 / codex 8a5ef44 / agy 824c456] +
adversarial critique [claude 035e9a6 / codex a04e79e / agy ab3bb78], every dispatch
verified from marker+tree; unanimous convergence on the multiband-reshape method,
every author conceded its contested point, NO 2-2 so NO four-ballot/critic; decision
013 committed to round branch [round head ff2a801]; claude impl slice DISPATCHED +
IN FLIGHT [run 013-impl-claude-20260718-111122, branch claude/013-dirt-impl off
ff2a801]. RESUME at the "RESUME HERE" section: verify impl marker+tree+both hard
gates, then codex non-author sign-off -> FF-integrate -> push -> agy QA pass 6 ->
surface to Scott iff confusable. Sweep still OK: origin at 2ca6f62 + main +
issue-4-world-eras, no leaked doer branches.)

**PRIOR update:** 2026-07-18 (PAID DIRT REGEN + RE-TUNE, one fresh turn: double-spend
guard -> paid regen [nano-banana-pro, 9cr, 2946->2937] -> orchestrator accept-decode
[raw std 19.83, earthy/pebbly, viewed directly; mean_grad 5.60<8 ruled non-blocking]
-> claude re-tune slice 8cf9306 [affine tone-grade holding std onto spike mean +
plate install fixing flat core + grass->dirt substrate switch fixing retinted-grass +
shoulder soften for shimmer; suite+gate GREEN, orchestrator re-decoded] -> codex
non-author sign-off [signed-off, independent decodes match] -> FF-integrate round
2ca6f62 + suite + export gate GREEN + PUSHED -> agy QA pass 5. Pass 5 CLOSED all three
pass-4 dirt tells but found THREE NEW tells the re-tune introduced [muddy high-contrast
tone dominant, tiling repetition, grid seams -- all zero-cost composite fixes]. Still
NOT-CONFUSABLE; NOT surfaced to Scott. Teed up the ZERO-COST dirt tiling+tone sub-round
[likely full protocol decision 013 on the anti-tiling method; tone folded in mechanical]
off round head 2ca6f62 for a fresh turn. Every dispatch verified from end marker + tree
+ decoded images + self-run gates. Sign-off + QA ran in parallel. Sweep OK.)
