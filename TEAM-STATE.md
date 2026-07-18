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
(incl. the new footprint-field byte-stability/drift test). NOT yet integrated
(needs claude NON-AUTHOR sign-off first).

**D3 FLORA HARD-STOP (sound, verified):** the 5 polygon-sliced flora
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

**ON RESPAWN / NEXT ACTION (in order):**
1. Check inbox `.pka/inbound/orchestrator/` (Scott steers mid-run).
2. **PAID FLORA REGEN (full supervision, do at turn TOP):** `meshy_check_balance`
   (record before), `meshy_list_tasks status=PENDING` must be empty, cost-confirm.
   Regen the 5 named flora against a NEUTRAL/grey background (clean-mattable),
   matching the spike style (`docs/art/iso-five-asset-spike.png`); prefer
   nano-banana-pro image-to-image off the existing sliced sprites or the spike.
   NEVER `save_to`; download to `.pka/round007/composition/flora-regen/`; record
   task ids + balance after. Balance 2937, ample.
3. Dispatch CODEX to FINISH the bake (`codex/016-bake`): rematte the regenerated
   neutral-bg flora (decontamination now trivial) + feather + tonal + basal
   contact nest + manifest, extending its slice. This completes impl slice 1.
4. Dispatch CLAUDE NON-AUTHOR sign-off on the COMPLETE codex bake (claude != codex
   author, engaged in critique). Integrate bake into round branch FF (preserve
   signed SHA), re-run suite + export gate on the integrated tree.
5. Dispatch CLAUDE render slice (`claude/016-render` off integrated round head)
   consuming codex's seam_policy: sample the field in `ground.gdshader` at a named
   insertion point (lane core semantics unchanged), wire the below-sprite short
   contact/cast shadow layer (retire `shadow_decal.png`), apply per-kit tonal
   transforms, KEEP the CanvasModulate; TUNE vs spike at 0.5x/1x/2x. codex
   NON-AUTHOR sign-off, integrate FF, re-run gates.
6. Dispatch AGY QA vs the BINDING rubric
   `.pka/round007/composition/qa-rubric-composed-scene.md` (composed scene at 1x
   vs spike, D1-D4). If CONFUSABLE -> SURFACE A BUILD to Scott (cross-workspace
   `to: dalinar`) for his OWN playtest verdict; do NOT auto-expand the village.
   If NOT-CONFUSABLE -> iterate the named tell off round head.

**Live worktrees + branches (all LOCAL except `round/007-village`):**
- `lw-007-round` on `round/007-village` @ `4022fb8` (== origin; integration tree;
  decision 016 record).
- `lw-007-codex` on `codex/016-bake` @ `d0c861c` (IMPL slice 1 bake DONE, suite
  green, D3 flora blocked; NOT yet signed/integrated). Proposal
  `codex/016-composition` @ `4e0ee74`, critique `d6b4bc7`.
- `lw-007-claude` on `claude/016-composition` @ `dcbd23e`/`c615220` (proposal +
  critique; holds the ONLY copy of `.pka/round007/ground-source/*` [paid dirt
  sources, URLs expired, do NOT overwrite]). Rebranch to `claude/016-render` off
  the integrated bake for slice 2.
- `lw-007-agy` on `agy/016-composition` @ `b906ac6`/`c707ff1` (proposal +
  critique). Rebranch to `agy/016-qa` off the integrated round head for QA.
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

**Last updated:** 2026-07-18 (DECISION 016 PHASES 1-3 COMPLETE + RECORD PUSHED;
IMPL SLICE 1 [codex bake] DONE+VERIFIED [d0c861c, suite GREEN, D1 shadows + D2
footprint field + seam_policy contract + byte-stability test]; D3 FLORA BLOCKED
on a scoped Meshy regen [chromatic painted-grass boundaries, no recoverable
matte] which I AUTHORIZED under deliberate-spend + DEFERRED off this run tail
[marker on main + codex branch]. NEXT TURN TOP: supervised flora regen -> codex
finish rematte -> claude sign-off + integrate -> claude render slice -> agy QA vs
new rubric -> surface to Scott if CONFUSABLE. Detail below. Reframe to composition/integration [Scott
playtest verdict], wrote binding composed-scene QA rubric + scope. Ran phase 1
blind proposals [claude dcbd23e / codex 4e0ee74 / agy b906ac6] and phase 2
adversarial critiques [claude c615220 / codex d6b4bc7 / agy c707ff1], all
verified from END markers + tree, genuine convergence via mutual concessions.
Synthesized decision 016 @ 4022fb8 [pushed]: offline-baked footprint field in
ground.gdshader [D2], offline basal contact + short cast extending existing
derive_shadows [D1], offline flora rematte + RGB decontamination [D3], one light
vector + per-kit tonal transforms, ground grade fixed [D4]. Runtime-vs-offline
ruled 3-1 OFFLINE [decided w/o critic], claude dissent verbatim. Division:
codex=bake, claude=render, agy=QA. Dispatched codex bake slice [016-bake-codex,
off 4022fb8]. NEXT: verify bake from marker+tree, self-run gates, then claude
render slice, cross sign-offs, agy QA vs new rubric, surface to Scott if
CONFUSABLE. Two tree-verified findings anchored synthesis: claude cast-height
bug [inn=1 vs tree=10], derive_shadows already exists at process_assets.py:157.)
