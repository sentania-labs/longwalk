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

**ROUND 007 / DECISION 016: COMPOSITION + INTEGRATION (fix the SEAMS).**
FULL PROTOCOL. Sub-round of round 007, stacks on round head `3c4c905`
(origin/round/007-village).

Scott PLAYTESTED the WIP build and the inn-green district does NOT pass
(inbox `2026-07-18-1730-dalinar-scott-playtest-verdict-composition-not-texture.md`,
authoritative). His verdict verbatim: *"This is an improvement, but a lot of
work was put in without a ton of progress. Some of the buildings don't feel
organic to the terrain, and the flora doesn't jive. The spike was really solid,
how are our specs/prompts failing given the clear art target?"*

**THE REFRAME (authoritative):** texture/dirt fidelity is now LOCKED + DONE
(decisions 010-015). Do NOT reopen any dirt/ground texture sub-round, do NOT
retune the plate/detail/lane bakes for their own sake. The problem is the SEAMS
between separately-generated objects and the ground. The spike is one composed
image (all object-to-ground interactions baked in); our pipeline decomposes it
into standalone sprites and recomposes in-engine, and nothing ever graded the
seams. Fix: (D1) object grounding / contact shadow, (D2) object-terrain
interaction / worn transition zones, (D3) flora integration / kill the cutout
alpha edges + grade flora in-context, (D4) scene-level lighting coherence.

Full scope + the binding rewritten acceptance rubric:
`.pka/round007/composition/assignment.md` and
`.pka/round007/composition/qa-rubric-composed-scene.md` (unit of grading = the
COMPOSED SCENE at 1x vs the spike, NOT crops / NOT enumerable dirt defects).
Village expansion STAYS GATED on this district passing the NEW rubric AND
Scott's own eye (automated seat alone was what proved insufficient last time).

**Lane:** FULL PROTOCOL. Reasoning: two reasonable engineers pick materially
different seam treatments (baked directional shadow vs procedural blob vs
ground-shader interaction band; flora shader-feather vs in-context regen vs
repaint; global grade vs per-object tonal match). Scott directed full protocol
explicitly. Touches NO protected path (`src/render/town/*`, `assets/village/*`,
`tools/art/*`; `src/sim/` is protected and OUT of scope).

=== WHERE WE ARE: DECISION 016 FULLY IMPLEMENTED + INTEGRATED; QA = NOT-CONFUSABLE (verified); SECOND ITERATION SCOPED ===

**Round head `160139a` on origin/round/007-village.** Full protocol (phases 1-3)
+ all three impl slices are done, signed, integrated, pushed. Lineage on the
round branch: `4022fb8` decision-016 record -> `d0c861c` codex bake (signed
bd169cf) -> `f196cf8` codex flora finish (signed 8083068) -> `81e695f` claude
render + `6bc43ce` R-apron fix (signed 6e50d0d) -> `160139a` agy QA report.

**Phase 1-3 (prior run, unchanged):** blind proposals claude `dcbd23e` / codex
`4e0ee74` / agy `b906ac6`; critiques claude `c615220` / codex `d6b4bc7` / agy
`c707ff1`; synthesis `docs/decisions/016-composition-integration.md`. Runtime-vs-
offline field ruled 3-1 OFFLINE (claude dissent verbatim). Division: codex=bake,
claude=render, agy=QA.

**IMPL (this run, all verified from end markers + tree, gates self-run green):**
- **Bake** (codex `d0c861c`, off 4022fb8): footprint_interaction_field.png
  (256x224, R=apron coverage / G=SDF / B=door-wear, lane-independent) + per-kit
  `seams/*_{contact,cast}.png` extending `process_assets.py::derive_shadows` +
  `manifest.json seam_policy` + baker + byte-stability test. claude signed
  (bd169cf, re-baked byte-identically to verify). Integrated -> 3000e93.
- **PAID FLORA REGEN** (orchestrator-run, supervised): 5 flora regenerated on
  NEUTRAL GREY bg via per-object spike style-crop -> nano-banana-pro
  image-to-image. 45 credits, balance 2937 -> **2892** (API consumed_credits
  matched, guard clean). Sanctioned D3 HARD-STOP fallback (grey bg = mattable,
  not the rejected same-seam regen). Provenance + task ids at
  `.pka/round007/composition/flora-regen/PROVENANCE.md`.
- **Flora finish** (codex `f196cf8`): rematted the regens via the clean
  `remove_border_background` recipe (generated_src) + re-baked flora seam masks +
  manifest provenance slice->generated + tonal-targets-as-data. claude signed
  (8083068). Integrated -> 4e506dd. Flora now clean in-scene (no cutout edges).
- **Render** (claude `81e695f` + fix `6bc43ce`): D2 ground.gdshader samples the
  field at a named worn-apron insertion (now consuming fp.r as authored coverage
  after codex blocked the first cut for ignoring R) + D1 below-sprite contact/cast
  layer (retired shadow_decal) + D4 object.gdshader per-kit tonal (CanvasModulate
  kept). New R-consumption regression test test_footprint_apron_r.gd. codex
  blocked 81e695f (apron ignored field R), claude fixed, codex signed the fix
  (6e50d0d). Integrated -> f388bb8. Suite + export gate green, assets/village
  non-mutation held.

**AGY COMPOSED-SCENE QA: verdict NOT-CONFUSABLE** (report
`docs/art/village/qa-agy-composition-001.md`, on round branch at 160139a;
orchestrator INDEPENDENTLY corroborated the D1+D2 tells by decoding the 2x
crops). Real improvement over Scott's playtest state (objects grounded, worn
aprons, clean flora sprites, more-unified key) but does NOT yet clear the
"one painted world" bar. Four verified tells drive the SECOND ITERATION:
- **D1 shadows (render):** contact/cast read as HARD, too-dark painted polygons
  (inn-sign cast = hard grey polygon; tree shadow = pitch-black hard blob;
  sunflower basal shadow = sharp rectangle). Need softer/lighter/feathered casts,
  and the inn-sign should not throw a hard shape.
- **D2 apron (render):** apron outer edge is a HARD STRAIGHT diamond-tile boundary
  against grass, does not grade in. Need the outer isoline feathered/noise-broken
  (reuse the shader's existing lane edge-break dither) so it dissolves into grass.
- **D4 tonal (render):** buildings too dark/contrasty vs a brighter flat
  yellow-green ground; keys still disparate -> pasted-on read. Rebalance the
  object grade / bring ground+objects toward a shared key.
- **D3 flora (codex, smaller):** residual grey rectangular block behind the
  sunflower stems + a bush bottom-right clipped flat by its bbox. Flora rematte
  feather/flood between thin stems + bbox crop fix.

**ON RESPAWN / NEXT ACTION (SECOND ITERATION, do NOT surface to Scott until
CONFUSABLE):**
1. Check inbox `.pka/inbound/orchestrator/`.
2. Dispatch the render tuning slice on `claude/016-render` (worktree
   lw-016-render, currently at 6bc43ce; rebranch/rebase onto round head 160139a
   first): address D1 (soften+lighten+feather shadows, tame the inn-sign cast),
   D2 (feather/dither the apron outer edge into grass), D4 (rebalance tonal to a
   shared key). Capture-inspect loop vs spike at 0.5x/1x/2x.
3. Dispatch the codex flora touch-up on a new branch off round head: D3 sunflower
   inter-stem grey + bush bbox clip. (Can pipeline with the render slice into
   different worktrees.)
4. Cross non-author sign-offs, FF integrate each onto the round branch, gates,
   push.
5. Re-run AGY QA vs the binding rubric. If CONFUSABLE -> SURFACE A BUILD to Scott
   (cross-workspace `to: dalinar`) for his OWN playtest verdict, do NOT
   auto-expand the village. If still NOT-CONFUSABLE -> decode the named tell,
   iterate off round head.

**Live worktrees + branches (all LOCAL except `round/007-village`):**
- `lw-007-round` on `round/007-village` @ **`160139a`** (== origin; integration).
- `lw-016-render` on `claude/016-render` @ `6bc43ce` (render slice; REBASE onto
  160139a before the D1/D2/D4 tuning iteration).
- `lw-016-qa` on `agy/016-qa` @ `1fc1fbf` (QA report committed; report also
  cherry-picked onto round branch). Reuse for re-QA off the new round head.
- `lw-007-codex` on `codex/016-flora` @ `f196cf8` (flora finish, integrated).
  Rebranch off 160139a for the D3 touch-up.
- `lw-007-claude` on `claude/016-composition` @ `c615220` (proposal/critique;
  holds ONLY copy of `.pka/round007/ground-source/*` paid dirt sources, URLs
  expired, do NOT overwrite). UNTOUCHED.
- `lw-007-agy` on `agy/016-composition` @ `c707ff1` (proposal/critique).
- Ephemeral review worktrees (lw-016-review{,2,3,4}) all REMOVED this run.

## Prior round-007 state (decisions 010-015, DONE, kept for lineage)

Decision 015 (dirt fill quality) INTEGRATED + PUSHED, round head `3c4c905` on
origin. All three dirt tells (grey stones / amber rocks / membrane-smooth fill
islands) CLOSED in sequence (014 + 015). agy QA8 = CONFUSABLE on the OLD
dirt-defect rubric, orchestrator decode agreed at 0.5x/1x/2x. A downloadable WIP
Windows build was produced at `/home/scott/claude/longwalk-build-round007/`
(`longwalk-village-wip.exe`, boots straight into `scenes/village.tscn` free-cam,
verified via export gate + xvfb boot). Scott playtested it -> the composition
verdict above. The dirt PAID path is CLOSED (9 credits spent, task `019f74b2`).
Decisions 009-015 all on the round branch @ `3c4c905` (009-012 signed 4-0;
013/014/015 full-protocol converged records, no protected path). Full decision
lineage in `docs/decisions/` and git history.

## Round 006 -- CLOSED (superseded)

Everything recoverable under `refs/archive/006/*` (pushed). `git show
refs/archive/006/<name>:<path>`.

## Durable lessons (paid for repeatedly; honor them)

- **A dispatch is synchronous; nothing external re-invokes you when a detached
  proc finishes.** Only supervisor respawn re-invokes you. Own tool calls cap at
  ~600s. EITHER block in one call OR detach (setsid) + poll the end marker
  across calls, capturing in-flight state first. Costs: render/re-tune/impl
  slices ~900-1600s (`claude -p`/`godot` buffer ALL output, verify liveness via
  `pgrep`/`ps`, not file mtimes); codex sign-off ~150s; agy QA ~110-135s;
  proposals lighter. Proposals/sign-off/QA can run IN PARALLEL into separate
  worktrees.
- **Verify from the end marker + tree, NEVER exit code or narration.** Then RUN
  the suite + export gate yourself and DECODE the actual PNGs (before-vs-after at
  matched framing + the spike). The gate numbers are necessary but NOT
  sufficient; agy's multimodal read is the bar, and Scott's own eye is above
  that (decisions 014/015 passed gates yet failed his eye on composition).
- **agy adapter can no-op into a scratch project; markers catch it.** Verify
  workdir == real worktree in the marker + branch_changed yes.
- **Stacked slices integrate by fast-forward; cross sign-off = ephemeral
  detached review worktree** (reviewed_by != authored_by). Preserve the signed
  SHA: FF to it, then cherry-pick the (orchestrator-authored) decision record on
  TOP. Never rebase/cherry-pick the signed doer commit.
- **Doer seats NEVER push to origin.** Only the orchestrator, only the round
  branch. Long render/gate/decode proofs run to completion in the FOREGROUND.
- **Cross-workspace asks to Scott: address `to: dalinar`, NOT `to: scott`.**

## Meshy

Key live at `~/.claude/pka-secrets/longwalk/meshy.env`; MCP `meshy` in
`.mcp.json`. Balance **2892** (after the D3 flora regen this run: 45 credits, 5 x
nano-banana-pro image-to-image @ 9; guard was clean, no PENDING/IN_PROGRESS).
The DIRT paid path is CLOSED (9 credits, task `019f74b2`, do NOT regen dirt).
Meshy IS available for decision-016 IF in-context flora regeneration wins and
genuinely needs it (no mandate). Any paid spend needs its own guard
(`meshy_list_tasks` no PENDING, `meshy_check_balance` before/after, cost-confirm,
NEVER `save_to`). Paid dirt sources at `.pka/round007/ground-source/*.png` (only
copies, URLs expired) live ONLY in `lw-007-claude`; do NOT overwrite.

## Active decision records

001-008 on main. Round-007 decisions **009-015** on the round branch.
**016 (composition/integration)** record `docs/decisions/016-composition-integration.md`
is on the round branch @ 4022fb8 and fully implemented (bake + flora + render
integrated); the round is in its SECOND QA iteration (QA1 = NOT-CONFUSABLE).

## Notes for the next run

- **Dashboard `/team` tab is KILLED by Scott** (inbox `2026-07-18-0445`): do NOT
  POST to `dashboard.int.sentania.net/api/team`. Compliance = not posting; a
  missing POST is not a failure.
- `gh pr edit` is broken (GraphQL projectCards). Use REST `gh api -X PATCH
  repos/sentania-labs/longwalk/pulls/N ...`.
- No round PR is open (correct; opens only for the full-village milestone once
  Scott confirms the art bar and the district is expanded).
- **Sweep:** round is OPEN (not closing; district must pass QA + Scott's eye
  first). origin/round/007-village is at `160139a`. Doer branches
  (claude/*, codex/*, agy/*) are LOCAL-only; verify none leaked to origin at the
  next close (the round is mid-iteration, so leaked-branch guard is deferred to
  round close, not now). No round PR open (correct).
- Inbox processed through `2026-07-18-1730` (the composition verdict, actioned
  this run). Older partials `6110faed` / `c3ffe894` were descriptive reads, now
  superseded by Scott's direct playtest verdict.
- **Two STALE cross-workspace responses surfaced in the codex worktree's untracked
  `.pka/inbound` this run** (`308f0465`, `a1c32de4`), addressed `to: lw-007-codex`,
  NOT to me, NOT in my main inbox. Both are responses to superseded requests from
  earlier runs: (1) vault escalated the flora authorization to Scott (report
  `scott/reports/2026-07-18-lw-007-flora-authorization-needed.md`) - MOOT, my
  supervisor's respawn directly authorized this turn's regen and it is
  orchestrator-decidable; (2) a PARALLEL non-role-briefed claude sign-off of the
  bake (`cc1848f`) - redundant, my proper role-briefed sign-off bd169cf is already
  integrated, both agree. No action; noted for visibility. If Scott's report reply
  lands later disagreeing, escalate then (spend already made under direct
  supervisor authorization).

**Last updated:** 2026-07-18 (DECISION 016 FULLY IMPLEMENTED + INTEGRATED +
PUSHED, round head `160139a`. This run: bake signed+integrated (bd169cf ->
3000e93); PAID FLORA REGEN [45 credits, balance 2937->2892, 5 clean neutral-grey
sprites, provenance recorded]; codex flora finish signed+integrated (8083068 ->
4e506dd); claude render slice authored [81e695f] -> codex BLOCKED it [apron
ignored field R, valid contract catch] -> claude R-fix [6bc43ce] + regression
test -> codex signed the fix [6e50d0d] -> integrated [f388bb8]; suite + export
gate green throughout, assets/village non-mutation held. AGY composed-scene QA =
**NOT-CONFUSABLE**, orchestrator-corroborated [4 tells: D1 hard/dark shadows, D2
hard straight apron edges, D3 residual grey behind sunflower stems + bush bbox
clip, D4 tonal disparity]. NOT surfaced to Scott [correct: NOT-CONFUSABLE].
SECOND ITERATION scoped above: claude render tuning [D1/D2/D4] + codex flora
touch-up [D3] -> re-QA -> surface to Scott if CONFUSABLE. Every phase durable +
pushed; nothing in flight at turn end.)
