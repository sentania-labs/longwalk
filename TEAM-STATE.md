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
paid-regen re-tune) + **DIRT RE-TUNE method converged (decision 013, this run)**.
Round head **`ff2a801`** (decision 013 committed on round branch; NOT yet pushed
-- push happens after integration). Origin still at `2ca6f62`. The PAID PATH IS
DONE (plate accepted + rich); zero paid spend from here.

**THIS RUN so far:** ran decision-013 FULL PROTOCOL on the three pass-5 tells
(muddy tone, tiling, seams). Triage flipped to full protocol after the
orchestrator decoded the spike-dirt crop (std 40.59 > graded plate 19.78),
overturning "reduce contrast" and revealing a frequency-distribution problem with
genuine method alternatives. Blind 3-way proposal (claude 531e701, codex 8a5ef44,
agy 824c456) + adversarial critique (claude 035e9a6, codex a04e79e, agy ab3bb78),
every dispatch verified from end marker + tree. **Unanimous convergence, every
author conceded its contested point, NO 2-2 split so NO four-ballot / NO critic**
(tiebreaker-only). Synthesis = `docs/decisions/013-dirt-retune-fidelity.md`
(round head ff2a801). **IMPL SLICE DISPATCHED** (claude, run
`013-impl-claude-20260718-111122`, branch `claude/013-dirt-impl` off ff2a801, cap
3600s) -- IN FLIGHT as of this writing; verify from its end marker + tree, NOT
narration.

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

=== RESUME HERE (decision 013 IMPLEMENTATION in flight) =========================
The impl slice is dispatched and detached. On respawn:
1. **Verify the impl end marker** at
   `/home/scott/claude/lw-007-claude/.team/markers/013-impl-claude-20260718-111122-end.md`
   (branch_sha_before ff2a801 -> after; branch_changed; cap_expired;
   uncommitted_work). Then INSPECT the tree: `git -C /home/scott/claude/lw-007-claude
   log --oneline`, decode the committed plate + detail sha + captures, and RE-RUN
   `tools/run_tests.sh` + `tools/art/village_export_gate.sh` yourself. Confirm BOTH
   hard gates (core lum_std >= 17.97; 0.5x dirt fine-grad <= ~10.75) from the actual
   numbers, not the commit body's claim. If a gate fails or work is uncommitted,
   bounce back to claude with the specific gap; do not integrate a failing slice.
2. **codex NON-AUTHOR cross sign-off** on the claude impl commit (reviewed_by !=
   authored_by): dispatch codex into an ephemeral detached review worktree
   (`git worktree add -b rev/cxc-013 <wt> <claude-sha>`), it writes a
   `.team/signoffs/` marker naming the EXACT claude commit; cherry-pick the marker;
   `git worktree remove`. No push by the doer.
3. **FF-integrate** the signed claude commit into `round/007-village` (round head is
   ff2a801), cherry-pick the sign-off marker + (later) the QA report. Re-run suite +
   export gate on the integrated tree. Then **push the round branch**.
4. **agy QA PASS 6** (reuse `lw-007-agy`, fresh `agy/013-dirt-qa6` off the integrated
   round head): multimodal confusability read; MUST explicitly re-check the two named
   mid-district seams + whether the flatten dissolved muddy-tone + tiling.
5. If agy verdict CONFUSABLE **and the orchestrator's own decoded read agrees** ->
   **SURFACE A BUILD TO SCOTT** (his stated bar; cross-workspace `to: dalinar`, NOT
   `to: scott`). If still NOT-CONFUSABLE, decode the actual artifacts (never
   narration), diagnose the specific remaining gap, tee up the next fix (paid dirt
   path stays CLOSED).
6. After dirt clears: expand the one inn-green district to the full ~12-16-structure
   village; open the ONE round PR + external Codex review; address findings; merge;
   sweep (delete round + doer branches; leak guard).

**Live worktrees + branches (all LOCAL except `round/007-village`):**
- `lw-007-round` on `round/007-village` @ `ff2a801` (integration tree; decision 013
  committed; NOT yet pushed -- push after integration; origin at 2ca6f62).
- `lw-007-claude` on `claude/013-dirt-impl` @ ff2a801+ (impl slice IN FLIGHT; the
  013 proposal 531e701 + critique 035e9a6 are on the retired `claude/013-dirt-retune`).
- `lw-007-codex` on `codex/013-dirt-retune` @ 8a5ef44+a04e79e (proposal+critique;
  reuse for the non-author sign-off).
- `lw-007-agy` on `agy/013-dirt-retune` @ 824c456+ab3bb78 (proposal+critique; reuse
  for QA pass 6).
- Prior integrated slices: claude 8cf9306 (dirt-retune), codex 7672b3a (bake), agy
  79aaaa1 (qa5) -- all in round head history. Local-only deliberation/doer branches
  archive to `refs/archive/007/*` at round close.

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
