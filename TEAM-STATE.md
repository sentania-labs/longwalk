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

**Dispatched:** phase 1 `20260718-171534`, phase 2 `20260718-172217`. Phases
1-3 DONE. Implementation IN FLIGHT (codex bake).

=== WHERE WE ARE: PHASES 1-3 DONE; IMPL SLICE 1 (codex bake) IN FLIGHT ===
**Round head `4022fb8`** on origin (== decision 016 record, pushed
3c4c905..4022fb8). Full protocol ran cleanly this run, all verified from
end markers + tree:
- **Phase 1 blind proposals** (all committed, real, verified branch_changed):
  claude `dcbd23ec1065ad89cdf1e9ef3773bfcedb40b266`, codex
  `4e0ee74ba63ead63a0ce28ee5acf278706ac71e2`, agy
  `b906ac6afe719a8fba4c8d0608efd833d8b89aaf`.
- **Phase 2 critiques** (all committed, genuine adversarial + mutual concessions,
  NOT a "looks good" round): claude `c615220a4a7554544b48260d4166baf5d60e00f8`,
  codex `d6b4bc7392dbc6778a6fce87f1f1caef4ff2ac16`, agy
  `c707ff1fa135155627d4d43da929e640f1fe7b60`.
- **Phase 3 synthesis:** `docs/decisions/016-composition-integration.md` @
  `4022fb8`. Converged: OFFLINE-baked footprint field in ground.gdshader (D2),
  offline basal contact + short cast extending the ALREADY-EXISTING
  `process_assets.py::derive_shadows` (D1), offline flora rematte + RGB
  decontamination + feather (D3), one measured light vector + per-kit tonal
  transforms with the ground CanvasModulate held FIXED (D4). Runtime-vs-offline
  field ruled **3-1 for OFFLINE** (codex+agy+orch vs claude), decided WITHOUT
  critic (3-1, not 2-2). claude's runtime dissent recorded VERBATIM in the
  record. Two tree-verified findings drove it: claude's cast-height ordering is
  broken on the manifest (inn native_y-anchor=1 vs tree=10), and the offline
  shadow pipeline already exists in `tools/art/process_assets.py:157`.
- **Division of labor:** codex = offline bake (footprint field + shadow masks +
  flora rematte + manifest schema + byte-stability test); claude = render
  integration + capture-tuning; agy = composed-scene QA seat (new rubric).

**IMPL SLICE 1 (codex bake) DONE + VERIFIED; D3 FLORA BLOCKED ON A SCOPED PAID
REGEN (orchestrator-authorized, deferred off this run tail).**
Codex bake on `codex/016-bake` @ **`d0c861c9550baf2478eb4fc2c9920ed5c492e19a`**
(off 4022fb8), verified from END marker (branch_changed yes, exit 0, not
cap-expired, tree clean) + tree. Two commits: `a667c77` (D2 footprint field) +
`d0c861c` (D1 per-kit contact/cast seam masks + manifest seam_policy + tests).
Delivered: `assets/village/footprint_interaction_field.png` (256x224 RGBA8, 16
texels/cell; R=apron coverage, G=SDF to footprint, B=door-wear, independent of
lane_density), per-kit `assets/village/seams/*_{contact,cast}.png` for all
objects (extends `process_assets.py::derive_shadows`), `manifest.json seam_policy`
render contract (documented in `docs/art/village-seam-bake.md`), baker
`tools/art/bake_footprint_field.gd`, byte-stability + layout-drift test
`test/active_path/test_footprint_field_bake.gd` wired into `tools/run_tests.sh`.
**ORCHESTRATOR SELF-RAN `tools/run_tests.sh` on the bake tree: ALL GREEN**
(incl. the new footprint-field byte-stability/drift test).

**UPDATE (this run): BAKE SLICE SIGNED + INTEGRATED + PUSHED.** claude
NON-AUTHOR sign-off `bd169cf` (`.team/signoffs/codex-016-bake-d0c861c9550b.md`,
reviewed_by=claude-worker, authored_by=codex-worker, reviewed_sha=d0c861c;
claude RE-BAKED byte-identically to verify determinism, not narration). Round
branch FF'd to signed d0c861c + marker cherry-picked on top. **Round head now
`3000e93` on origin** (pushed 4022fb8..3000e93). Orchestrator self-ran
`tools/run_tests.sh` on the integrated tree: ALL GREEN. Review worktree
lw-016-review removed (ephemeral). D3 flora rematte still pending the paid regen
below.

**D3 FLORA REGEN DONE (this run, PAID, supervised) + CODEX FINISH IN FLIGHT.**
Supervised scoped Meshy regen of the 5 flora COMPLETE and orchestrator-verified
visually. Balance 2937 -> **2892** (45 credits, 5 x nano-banana-pro
image-to-image @ 9; API consumed_credits matched exactly; no double-spend, guard
clean: no PENDING tasks pre-spend). Recipe: per-object STYLE CROP from the spike
-> image-to-image on NEUTRAL MID-GREY bg (clean-mattable, the sanctioned D3
HARD-STOP fallback, NOT the rejected same-seam regen). All 5 verified clean
isolated objects on uniform grey, spike style, crisp edges. Raw sprites +
`PROVENANCE.md` (task ids) at `.pka/round007/composition/flora-regen/`. Task ids:
tree 019f7663-59d6; bush_a 019f7664-558a; bush_b 019f7664-7716; flower_a
019f7664-9844; flower_b 019f7664-b820.
**CODEX FINISH dispatched** (`codex/016-flora` off integrated round head 3000e93,
run flora-finish-016-20260718-180745, detached, cap 2400s): rematte via existing
`remove_border_background` recipe + re-bake flora seam masks + manifest + tonal
targets-as-data. VERIFY from its end marker + tree on respawn; then non-author
sign-off (agy or claude, != codex) + FF integrate + gates. The D3 block is
resolved by this regen.

**D3 FLORA HARD-STOP (original block, now RESOLVED by the regen above):** the 5 polygon-sliced flora
(`bush_a`, `bush_b`, `flower_cluster_a`, `flower_cluster_b`, `tree_large`) carry
chromatic painted-grass boundaries (edge chroma 25-81), no recoverable matte, so
they were intentionally NOT rematted (eroding deletes petals). `crown_foliage`
IS recoverable and was handled. Marker on `codex/016-bake` +
copied to main `.team/blocked/016-flora-regen-codex-20260718T173735Z.md` with my
ruling: RECLASSIFIED codex's `blocked_on: scott` -> orchestrator-decidable. A
scoped Meshy flora regen is NOT a Scott-escalation category, Meshy was
pre-authorized for exactly this in the reframe, precedent exists (dirt regen
019f74b2). **AUTHORIZED under deliberate-spend; deferred to the TOP of a fresh
turn (never a paid spend at a run tail).**

**=== PROGRESS THIS RUN (2026-07-18, all durable + pushed) ===**
Round head advanced `4022fb8 -> 3000e93 -> 4e506dd` on origin. Sequence:
- Bake slice (d0c861c) claude-signed (bd169cf), FF+marker integrated -> `3000e93`,
  suite green, pushed.
- PAID FLORA REGEN done + verified (45 credits, balance **2892**; 5 clean
  neutral-grey sprites; provenance `.pka/round007/composition/flora-regen/`).
- Codex flora finish (`codex/016-flora` f196cf8) claude-signed (8083068),
  FF+marker integrated -> `4e506dd`, suite + village export gate GREEN, pushed.
  Flora now clean in-scene (verified the 1x capture: no cutout edges, spike style).
- CLAUDE RENDER SLICE authored (`claude/016-render` @ `81e695f` off 4e506dd): D1
  below-sprite contact/cast (retire shadow_decal) + D2 footprint-field sampling +
  D4 object.gdshader per-kit tonal. Orchestrator DECODED its 1x capture: clear
  improvement (objects grounded, worn aprons, unified key). Before-render ref
  `.pka/round007/composition/before-render-1x.png`.
- **CODEX peer review BLOCKED the render slice (valid, real defect):**
  `ground.gdshader` derives the worn apron from field G+B only and NEVER reads R,
  but the bake contract says R = building-apron coverage. Gates passed only
  because none assert R consumption. Block record
  `.pka/round007/composition/codex-block-render-R-channel.md`. NOT integrated
  (correctly held; no sign-off).
- **CLAUDE RENDER FIX IN FLIGHT** (`claude/016-render`, run
  render-fix-016-20260718-184547, detached cap 1800s): consume baked R apron
  coverage per contract + add a render-side R-consumption regression test +
  re-tune. On respawn VERIFY from end marker + tree, then codex RE-REVIEW the new
  head (ephemeral worktree), FF integrate + push, then agy QA.

**ON RESPAWN / NEXT ACTION (in order):**
1. Check inbox `.pka/inbound/orchestrator/` (Scott steers mid-run).
2. **VERIFY RENDER SLICE from its end marker + tree**
   (`/home/scott/claude/lw-016-render/.team/markers/render-016-*-end.md`):
   branch_changed, exit, cap, uncommitted. If in flight still, `pgrep -af 'claude -p'`
   + poll. DECODE its best 1x capture vs spike + before-render-1x.png yourself.
3. Dispatch CODEX NON-AUTHOR sign-off on `claude/016-render` (codex != author).
   Ephemeral detached review worktree at the render head. FF integrate + marker
   cherry-pick onto round branch, re-run suite + export gate, push round branch.
4. Dispatch AGY QA vs the BINDING rubric
   `.pka/round007/composition/qa-rubric-composed-scene.md` (composed scene at 1x
   vs spike, D1-D4). agy worktree: rebranch off integrated round head.
   If CONFUSABLE -> SURFACE A BUILD to Scott (cross-workspace `to: dalinar`) for
   his OWN playtest verdict (automated seat alone was insufficient last time); do
   NOT auto-expand the village. If NOT-CONFUSABLE -> diagnose the named tell
   rigorously (inspect artifacts, not narration) and iterate off round head.

**Live worktrees + branches (all LOCAL except `round/007-village`):**
- `lw-007-round` on `round/007-village` @ **`4e506dd`** (== origin; integration
  tree; bake + flora integrated).
- `lw-016-render` on `claude/016-render` off 4e506dd (RENDER SLICE IN FLIGHT).
- `lw-007-codex` on `codex/016-flora` @ `f196cf8` (flora finish, signed +
  integrated). Prior `codex/016-bake` @ d0c861c also in history. Proposal
  `codex/016-composition` @ `4e0ee74`, critique `d6b4bc7`.
- `lw-007-claude` on `claude/016-composition` @ `dcbd23e`/`c615220` (proposal +
  critique; holds the ONLY copy of `.pka/round007/ground-source/*` [paid dirt
  sources, URLs expired, do NOT overwrite]). UNTOUCHED (render slice uses a fresh
  worktree lw-016-render, not this one).
- `lw-007-agy` on `agy/016-composition` @ `b906ac6`/`c707ff1` (proposal +
  critique). Rebranch to `agy/016-qa` off the integrated round head for QA.
- Review worktrees lw-016-review / lw-016-review2 were ephemeral, REMOVED.
- Prior 007 slices (010-015) in round history. Old doer branches
  (`claude/015-*`, `codex/015-fill`, `agy/015-qa8`, the `016-composition`
  proposal/critique branches, etc.) still exist LOCAL; archive to
  `refs/archive/007/*` at round close.

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
`.mcp.json`. Balance **2937** (verified this run, no PENDING/IN_PROGRESS tasks).
The DIRT paid path is CLOSED (9 credits, task `019f74b2`, do NOT regen dirt).
Meshy IS available for decision-016 IF in-context flora regeneration wins and
genuinely needs it (no mandate). Any paid spend needs its own guard
(`meshy_list_tasks` no PENDING, `meshy_check_balance` before/after, cost-confirm,
NEVER `save_to`). Paid dirt sources at `.pka/round007/ground-source/*.png` (only
copies, URLs expired) live ONLY in `lw-007-claude`; do NOT overwrite.

## Active decision records

001-008 on main. Round-007 decisions **009-015** on the round branch @ `3c4c905`.
**016 (composition/integration)** is IN PROGRESS this round (phase 1); its record
`docs/decisions/016-composition-integration.md` is written at synthesis.

## Notes for the next run

- **Dashboard `/team` tab is KILLED by Scott** (inbox `2026-07-18-0445`): do NOT
  POST to `dashboard.int.sentania.net/api/team`. Compliance = not posting; a
  missing POST is not a failure.
- `gh pr edit` is broken (GraphQL projectCards). Use REST `gh api -X PATCH
  repos/sentania-labs/longwalk/pulls/N ...`.
- No round PR is open (correct; opens only for the full-village milestone once
  Scott confirms the art bar and the district is expanded).
- **Sweep (last close) clean:** origin carries only `main`, `round/007-village`
  @ `3c4c905`, unrelated `issue-4-world-eras`; leak guard PASS (no doer/rev
  branches on origin). Verified again this run at launch: no doer leaks on
  origin.
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

**Last updated:** 2026-07-18 (BAKE + FLORA both signed + integrated + pushed;
round head 3000e93 then 4e506dd. PAID FLORA REGEN done [45 credits, balance 2892,
5 clean neutral-grey sprites, verified clean in-scene]. Codex flora finish f196cf8
signed 8083068. RENDER SLICE claude/016-render IN FLIGHT off 4e506dd
[run render-016-20260718-182928, detached cap 2400s]: D1 below-sprite contact/cast
+ D2 footprint-field sampling + D4 per-kit tonal, tuned vs spike. NEXT: verify
render from end marker + tree, decode its 1x vs spike/before, codex non-author
sign-off, integrate + gates + push, then AGY QA vs binding rubric; if CONFUSABLE
surface a build to Scott [to: dalinar] for his own playtest verdict.)
