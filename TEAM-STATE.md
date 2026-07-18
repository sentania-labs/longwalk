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
lane treatment toward the confusable-with-spike bar.**

The bar is Scott's, verbatim: *screenshots confusable with the spike*
(`docs/art/iso-five-asset-spike.png`). Deliverable: a playable Windows build of a
full Two Rivers village at spike fidelity, NO PC/NPC, free ("disincorporated")
drag-pan/zoom camera. Walk-cycle/animation OUT of scope. Method unmandated.
Full scope: `.pka/round007/assignment.md`. Standing posture (directive 1500 +
Scott Q2 GO): autonomous back-to-back iteration; surface a build to Scott ONLY
when the team believes a screenshot genuinely passes the confusable bar.

**WHERE WE ARE:** one inn-green district is built at spike fidelity for the
BUILDINGS + the GROUND-TEXTURE (decision 010: continuous painterly shader-quad,
checkerboard tell fixed) + the LANE MACRO-GEOMETRY (decision 011: organic
meandering worn-earth lanes, the straight-X tell fixed). Round head `2c10abe`
(pushed). The remaining gap to the bar is DIRT-SURFACE FIDELITY: the dirt reads
as a flat uniform brown wash with a hard grass edge, and it over-covers the frame
vs the spike's grass-dominant scene. NOT surfaced to Scott (bar not met). The
next iteration (a DIRT-FIDELITY sub-round) is teed up below.

=== GROUND-TEXTURE SUB-ROUND (decision 010) -- DONE ============================
`docs/decisions/010-ground-and-lane-treatment.md` (signed 4-0). Continuous
cell-space SHADER-QUAD ground plane, district painterly plates
(`ground_grass_plate`/`ground_dirt_plate`, 1024x1024, provenance generated+paid),
baked deterministic domain warp, protected lane core, contact-shadow layer.
Integrated, gated, QA'd. Killed the checkerboard (prior dominant tell). Durable
record = the decision file + git; the verbose in-flight tracking is retired.

=== LANE-GEOMETRY SUB-ROUND (decision 011) -- DONE + INTEGRATED + QA'd THIS RUN =
`docs/decisions/011-lane-geometry.md` (signed 4-0, check_consensus PASS, covers
`src/sim/`). Full protocol ran clean and fast:
- **Phase 1 blind:** ALL THREE doers independently chose FORK B (sim centerline
  polylines + width, offline CPU-baked SDF mask, derived PATH, feathered
  transition, deterministic density). Unanimous convergence -- strongest signal
  the protocol produces. Proposals: claude `260eb22e`, codex `23042c5c`, agy
  `f7d1905`.
- **Phase 2 critique:** genuinely adversarial + CONVERGED. Every within-B
  difference resolved by CONCESSION (agy withdrew shader-UV meander + JFA; codex
  conceded its RGB channel-pack). Critiques: claude `f5f0b46e`, codex `ac2982a2`,
  agy `29966187`. NO contested question -> critic seat NOT invoked.
- **Synthesis (decision 011):** hand-authored meander waypoints (no seed);
  derived PATH by cell-square intersection; OFFLINE deterministic SDF+density bake
  with UNWARPED protected-core channel + bounded shoulder-only smin (agy graft);
  shader feathered dual-threshold + density modulation; A* route-preference test
  replaces the full-row/col junction assertion. Ratified 4-0 (ballots claude
  `51804808`, codex `3f42559d`, agy `90e87a44`).
- **Implementation (2 slices, each orchestrator-verified GREEN, not narration):**
  codex sim+bake `560b657` (LanePath + waypoints + derived-PATH + bake_lane_mask.gd
  + lane_mask.png/lane_density.png 256x224 RG8/R8 + fingerprint contract
  + nav/determinism tests; suite green, A* "grass steps=0" cost 10.414<=15.0, zero
  RNG, core provably protected). claude render `fcafbf3` STACKED on codex (consume
  masks via ResourceLoader, shader unwarped-core + two-stop feather + density, no
  double-warp; suite green + honest export gate PASS).
- **Cross sign-off (both genuine non-author, signed-off):** claude reviews codex
  `560b657` (`.team/signoffs/codex-007-lane-impl-560b657591bd.md`); codex reviews
  claude `fcafbf3` (`.team/signoffs/claude-007-lane-impl-fcafbf317809.md`).
- **Integration:** slices STACKED, so FF'd round to fcafbf3 (both authored SHAs +
  trailers preserved) -> cherry-picked both markers -> full suite GREEN + export
  gate PASS on integrated tree -> agy QA report cherry-picked. **Round head
  `2c10abe`, PUSHED.**

**agy MULTIMODAL QA (pass 3) VERDICT: NOT-CONFUSABLE** (`docs/art/village/
qa-agy-lane-003.md`, on round branch; agy `15577f6`, verified from marker+tree,
56s). BUT the DOMINANT tell is now CLOSED and the orchestrator independently
CONFIRMED it by decoding all 3 captures vs the spike:
  - **Lane MACRO-GEOMETRY (prior dominant tell) is GONE** -- lanes now meander,
    vary width, and pool into an organic worn clearing (0.5x reads convincingly
    spike-like). Decision 011 succeeded at its stated goal.
  - **NEW dominant tells (render/source-art, at 1x/2x):**
    1. **Dirt is a flat uniform brown wash** -- no pebbles, no tonal variation, no
       grass tufts. ROOT CAUSE, orchestrator-decoded: `assets/village/
       ground_dirt_plate.png` is INTRINSICALLY FLAT (near-uniform mid-brown, faint
       brushwork only). No shader density-modulation over a flat source can make
       spike-like pebbly dirt. This is a SOURCE-ART gap, not primarily shader.
    2. **Transition is a hard cut** -- the two-stop feather renders closer to a
       binary threshold than the spike's soft patchy dirt-into-grass fade.
    3. **(orchestrator-observed, agy didn't rank):** dirt OVER-COVERS the frame;
       spike is grass-dominant with narrower trails. = authored half-widths too
       generous (geometry knob, zero cost).
Out-of-scope (do NOT fail on these): no PC/NPC (intended); halo cutouts on sliced
props (agy defect #2, known separate fast-lane, visible on bushes/signpost at 2x).

## Phase

**LANE-GEOMETRY SUB-ROUND (decision 011): COMPLETE, INTEGRATED, GATED, QA'd this
run. Round head `2c10abe` (pushed). agy QA pass-3 = NOT-CONFUSABLE (macro-geometry
tell CLOSED; new dominant tell = flat dirt source-art + hard transition).**

=== NEXT RUN: DIRT-FIDELITY SUB-ROUND (decision 012) ==========================
The remaining gap is dirt-surface fidelity, and the ROOT CAUSE is diagnosed and
recorded above: the paid `ground_dirt_plate.png` is intrinsically flat. The three
sub-tells and their likely remedies:
  1. **Flat dirt (dominant) -> SOURCE ART.** Needs a richer painterly dirt plate
     (visible pebbles, tonal/value variation, worn patches, occasional grass
     tufts). Options for the phase-1 fork: (A) REGENERATE `ground_dirt_plate` via
     meshy with a texture-emphasis prompt (SUPERVISED PAID spend, ~6-18 credits,
     balance 2946) -- same supervised path as the 010 ground-source pass; (B)
     shader-composite detail INTO the dirt from the existing grass plate / a baked
     detail-noise field at higher contrast (zero cost, but limited by the flat
     source); (C) a hybrid. This is a genuine design fork -> lean FULL PROTOCOL.
  2. **Hard transition -> SHADER** (widen/soften the two-stop feather, add
     dither/patchiness at the boundary). Zero cost. Any option folds this in.
  3. **Dirt over-coverage -> GEOMETRY** (reduce codex's authored half-widths in
     `town_layout.gd` + re-bake). Zero cost, protected-path edit (decision 011
     already authorizes `src/sim/`; a half-width tweak may ride under it or a new
     record -- check).
**TRIAGE = likely FULL PROTOCOL** (source-art strategy is a real fork; touches the
paid asset pipeline and possibly `src/sim/`). Decision record = **012**. Branch
off the CURRENT round head `2c10abe`. Reuse worktrees `lw-007-{claude,codex,agy}`
(switch to `<prefix>/007-dirt-*` branches). Same shape: blind proposal ->
adversarial critique -> four-ballot synthesis -> decision 012 -> impl -> cross
sign-off -> integrate -> gate -> agy QA pass 4.
**CAUTION:** if the fork lands on a PAID meshy regen, that is a SUPERVISED spend
-- do the double-spend guard (`meshy_list_tasks` for no PENDING, `meshy_check_
balance` before/after, cost-confirm, NEVER `save_to`). Do NOT start the paid spend
at a run tail; sequence it into a fresh turn. Decision 010's plate ARCHITECTURE
must NOT regress; this only improves the dirt ASSET + blending + coverage.

After dirt clears the bar: fast-lane the halo re-cut (agy defect #2) to codex
(border-flood-fill that already worked on buildings), then expand to the full
~12-16-structure village, then open the ONE round PR + external Codex review,
address findings, merge, sweep. Surface to Scott ONLY when a screenshot passes.

**Live worktrees + branches (all LOCAL except `round/007-village` on origin):**
- `lw-007-round` on `round/007-village` @ `2c10abe` (integration tree, pushed).
- `lw-007-claude` on `claude/007-lane-impl` @ `fcafbf3` (integrated; reuse next by
  switching to a `claude/007-dirt-*` branch off 2c10abe).
- `lw-007-codex` on `codex/007-lane-impl` @ `560b657` (integrated; reuse next).
- `lw-007-agy` on `agy/007-lane-qa` @ `15577f6` (reuse for QA pass 4).
- Deliberation/impl branches `<d>/007-{proposal,critique,ballot,lane-geometry,
  lane-impl,lane-qa,ground-*}` are LOCAL-ONLY (never push); they hold the
  decision-009/010/011-cited artifact SHAs; archive under `refs/archive/007/*` at
  round close. Ephemeral review worktrees (rev/clc, rev/cxc) removed this run after
  markers were collected.
===============================================================================

## Round 006 -- CLOSED (superseded by Scott's redefinition)

Scott picked NEITHER candidate (the spike IS the style), dissolving round-006's
whole deliverable. Closed: worktrees pruned, local 006 branches deleted, origin
doer-branch leak + `origin/round/006-two-rivers` deleted, sweep guard PASSES, zero
open PRs. Everything recoverable under **`refs/archive/006/*` (pushed to origin)**:
`round-two-rivers` @ 5eee7bf, `acceptance-harness` @ adaf9a0 (reusable capture
harness), `scale-contract` @ ce5cbe5, `nullfix` @ f880a6d, `camera-calibration` @
7b419ab, `blender-cleanup` @ ee3a99d, candidate-a/b, integrate, pilot-gen, and the
proposal/critique/ballot artifacts. Inspect with
`git show refs/archive/006/<name>:<path>`.

## Durable lessons (paid for repeatedly; honor them)

- **A dispatch is synchronous; nothing external re-invokes you when a detached
  proc finishes.** Only supervisor respawn re-invokes you. Own tool calls cap at
  600s (set the Bash `timeout` param up to ~560000ms when polling; the DEFAULT is
  120s and will kill a poll loop early). So EITHER block on a dispatch in one call
  OR detach (setsid) and poll the end marker across calls, capturing in-flight
  state in THIS file FIRST.
- **Working detach recipe:** `setsid bash -c "'$DISPATCH' <harness> <wt> <brief>
  <prompt> --cap-seconds N --label L >> LOG 2>&1 < /dev/null" & disown`, then poll
  `<wt>/.team/markers/<label>-<stamp>-end.md`. Proposals/critiques/ballots run
  ~60-250s; impl slices ~250-400s. `uncommitted_work: yes` is usually just the
  untracked `.pka/` prompt copies you staged -- check `git status --porcelain`
  excluding `.team/` + your prompt files before worrying.
- **Verify from the end marker + tree, NEVER the exit code or narration.**
  `branch_sha_before` vs `branch_sha_after` + `branch_changed` is load-bearing;
  also `uncommitted_work` + `cap_expired`. Then check `git log`/`git diff --stat`,
  RUN THE SUITE + EXPORT GATE yourself, and DECODE the actual image artifacts
  (captures AND the source plates), not the worker's account. Decoding the dirt
  plate is what turned "the density modulation is weak" into "the source plate is
  flat" this run.
- **Stacked slices integrate by fast-forward.** When slice B branches off slice A
  (dependent work), the round FF's to B preserving both authored SHAs + trailers
  with no rewrite -- cleaner than decision-010's parallel-slice merge+conflict
  path. Cross sign-off still names each slice's exact SHA, reviewed by its
  non-author.
- **Cross sign-off = ephemeral detached review worktrees.** `git worktree add -b
  rev/<slug> <wt> <reviewed-sha>`, dispatch the NON-AUTHOR there to review+run
  suite+write `.team/signoffs/<branch-slug>-<short-sha>.md`, then cherry-pick the
  marker commit onto the round branch and `git worktree remove` it. reviewed_by
  must != authored_by.
- **agy adapter passes `--add-dir` internally** but still can no-op into a scratch
  project; markers catch it. agy QA runs are fast (~60s) but genuinely multimodal.
- **Detached `claude -p` buffers ALL output until completion; "no output + no end
  marker" != dead.** Verify liveness with `ps -o pid=,etimes=` before ANY relaunch;
  a second launch into the same worktree is the corruption + double-spend hazard.
- **Doer seats NEVER push to origin.** Only the orchestrator pushes, only the round
  branch. Prevention + the end-of-round sweep guard are the control.
- **Long render/gate proofs run to completion in the FOREGROUND in the same turn.**
- **Cross-workspace asks to Scott:** address `to: dalinar`, NOT `to: scott`.
- **Do NOT start a fresh full-protocol sub-round (or a paid spend) at the tail of a
  long run.** Tee it up precisely here and let the next run execute it with a full
  turn. (This run ran the ENTIRE decision-011 sub-round -- proposal through QA +
  integration -- in one turn because each phase was fast and uncontested, then
  teed up decision 012.)

## Meshy

Key live at `~/.claude/pka-secrets/longwalk/meshy.env`; MCP `meshy` in `.mcp.json`.
Balance **2946** last confirmed (2970 -> 2952 first paid pass; 2952 -> 2946 ground
source pass; NO paid spend since -- the lane-geometry sub-round used zero paid art).
Verify with `meshy_check_balance` before/after ANY paid work; cost-confirm every
call; NEVER pass `save_to` to `meshy_download_model`; `meshy_list_tasks` for no
PENDING/IN_PROGRESS before any spend (double-spend guard). **The NEXT (dirt-fidelity)
sub-round MAY need one supervised paid spend** if the phase-1 fork lands on
regenerating `ground_dirt_plate` (option A) -- sequence it into a fresh turn, not a
tail. Paid source downloads at `.pka/round007/ground-source/*.png` are the ONLY
copies (raw URLs expired); do NOT regenerate those.

## Active decision records (on main / round branch)

001-008 on main (007 iso-override + 008 iso-identity binding for round 007).
Round-007 decisions **009** (village art method, Option H), **010** (ground/lane
treatment: shader-quad plate), and **011** (lane geometry: fork B, sim centerlines
+ offline SDF mask) are on the round branch, all signed. Round-006's own 009/010
are archive-only (`refs/archive/006/*`), never on main -- no collision. Round-007's
NEXT decision is **012** (dirt-surface fidelity).

## Notes for the next run

- **Dashboard `/team` tab is KILLED by Scott** (inbox `2026-07-18-0445-dalinar-
  disable-dashboard-team-sync.md`): do NOT POST to `dashboard.int.sentania.net/
  api/team` (endpoint being removed, will 404). The dashboard-narration duty is
  suspended; a missing POST is not a failure. Inbox processed through the 04:45Z
  steer; no new orchestrator inbox messages this run.
- `gh pr edit` is broken (GraphQL projectCards). Use REST `gh api -X PATCH
  repos/sentania-labs/longwalk/pulls/N ...`.
- No round PR is open (correct -- the round PR opens only once the district passes
  the confusable bar; it has not yet). The three older stuck escalations are moot
  under the village redefinition.
- Sweep verified THIS run: 0 open team PRs; origin carries only `main`,
  `round/007-village`, unrelated `issue-4-world-eras`; leak guard OK (no doer
  branches on origin).

**Last updated:** 2026-07-18 (LANE-GEOMETRY sub-round FULL-PROTOCOL run, end to end
in one turn: 3 blind proposals [UNANIMOUS fork B] -> 3 adversarial critiques
[converged by concession, no contested question, critic not invoked] -> synthesis
decision 011 -> 4-0 ratification + check_consensus PASS -> codex sim+bake slice
560b657 [verified green, core provably protected, zero RNG] -> claude render slice
fcafbf3 stacked [verified green + export gate PASS] -> cross sign-off [both genuine
non-author] -> FF-integrated round to fcafbf3 + both markers -> full suite + export
gate green -> agy QA pass 3 = NOT-CONFUSABLE. Macro-geometry [prior dominant tell]
CLOSED, orchestrator-confirmed by decoding all 3 captures; NEW dominant tell = FLAT
dirt, root-caused by DECODING ground_dirt_plate.png [intrinsically flat = source-art
gap] + hard transition + dirt over-coverage. Round head 2c10abe PUSHED. NOT surfaced
to Scott [bar not met]. Teed up decision-012 DIRT-FIDELITY sub-round [likely full
protocol, fork A paid-regen / B shader-composite / C hybrid; branch off 2c10abe;
possible ONE supervised paid spend, balance 2946]. Every dispatch verified from end
marker + tree + decoded images + self-run gates. Sweep OK, ephemeral rev worktrees
removed.)
