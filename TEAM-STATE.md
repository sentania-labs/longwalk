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

**Dispatched:** phase 1 blind proposals, 2026-07-18 ~17:15Z (run stamp
`20260718-171534`).

=== WHERE WE ARE: PHASE 1 (BLIND PROPOSAL) DISPATCHED + IN FLIGHT ===
Three blind proposals dispatched into separate worktrees off round head
`3c4c905`, cap 2400s, self-contained prompt
`.pka/round007/composition/prompt-proposal.md`:
- claude -> `claude/016-composition` in `lw-007-claude`, label
  `016-prop-claude`, marker `.team/markers/016-prop-claude-20260718-171534-*.md`.
- codex -> `codex/016-composition` in `lw-007-codex`, label `016-prop-codex`,
  marker `016-prop-codex-20260718-171534-*.md`.
- agy -> `agy/016-composition` in `lw-007-agy`, label `016-prop-agy`,
  marker `016-prop-agy-20260718-171534-*.md`.
Logs: `.pka/round007/composition/prop-{claude,codex,agy}.log`. All three
confirmed ALIVE at launch (adapters spawned, start markers written, no
premature end marker).

**ON RESPAWN / NEXT ACTION (in order):**
1. Check inbox `.pka/inbound/orchestrator/` (Scott steers mid-run).
2. Verify each phase-1 proposal from its END marker, NOT narration:
   `ls lw-007-<w>/.team/markers/016-prop-<w>-*-end.md`; read `branch_sha_before`
   vs `branch_sha_after` + `branch_changed` + `uncommitted_work` + `cap_expired`.
   For AGY specifically: confirm workdir in marker == real `lw-007-agy` (agy
   adapter can no-op into a scratch project). Then `git -C lw-007-<w> log
   --oneline -1 <branch>` + read the committed proposal file. Record each full
   40-char proposal SHA.
3. If any proposal is missing/uncommitted (cap-kill mid-write, or agy scratch
   no-op), RE-DISPATCH that one worker (do not fabricate a proposal it didn't
   make; a worker with no real angle can be dropped and recorded, but a
   dispatch that died is re-run).
4. When all committed: DECODE nothing yet (proposals are docs). Move to PHASE 2
   (adversarial critique) using `roles/phases/2-critique.md`: dispatch each
   worker to critique the OTHER two proposals (share the two SHAs/paths). A
   round where everyone says "looks good" is a FAILED round, send it back.
5. Then PHASE 3 synthesis (orchestrator, `roles/phases/3-synthesis.md`):
   write `docs/decisions/016-composition-integration.md`, losing objections
   VERBATIM, divide labor by capability. Contested question -> four ballots
   (orch + 3 doers); 2-2 invokes critic (`roles/critic.md`, cursor ask-mode);
   3-1 / 4-0 decides without critic.
6. Implementation off round head, gates (suite + export gate + decode PNGs),
   NON-AUTHOR sign-off, integrate FF (preserve signed SHA), agy QA against the
   NEW composed-scene rubric. If QA clears CONFUSABLE -> SURFACE A BUILD to
   Scott for his OWN playtest verdict (cross-workspace `to: dalinar`), do NOT
   auto-expand.

**Live worktrees + branches (all LOCAL except `round/007-village`):**
- `lw-007-round` on `round/007-village` @ `3c4c905` (== origin; integration tree).
- `lw-007-claude` on `claude/016-composition` @ `3c4c905` (phase-1 in flight;
  also holds the ONLY copy of `.pka/round007/ground-source/*` [paid dirt
  sources, URLs expired, do NOT overwrite]).
- `lw-007-codex` on `codex/016-composition` @ `3c4c905` (phase-1 in flight).
- `lw-007-agy` on `agy/016-composition` @ `3c4c905` (phase-1 in flight).
- Prior 007 slices (010-015) all in round head `3c4c905` history. Old doer
  branches (`claude/015-*`, `codex/015-fill`, `agy/015-qa8`, etc.) still exist
  LOCAL; archive to `refs/archive/007/*` at round close.

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

**Last updated:** 2026-07-18 (REFRAME TO COMPOSITION/INTEGRATION. Scott
playtested the WIP build -> district NOT passed; texture LOCKED/DONE, fix the
SEAMS [grounding/contact-shadow, object-terrain interaction, flora cutout edges,
lighting coherence]. Wrote the binding rewritten composed-scene QA rubric FIRST
[.pka/round007/composition/qa-rubric-composed-scene.md] + assignment scope, per
Scott's sequencing. Triaged FULL PROTOCOL [genuine seam-treatment forks], set up
decision 016. Rebranched all three doer worktrees off round head 3c4c905
[ground-source preserved in lw-007-claude], verified Meshy billing clean [2937,
no pending]. DISPATCHED phase-1 blind proposals into the three worktrees
[run stamp 20260718-171534], all confirmed alive + in flight. NEXT: verify each
proposal from its END marker [agy: check workdir==real not scratch], record the
three 40-char SHAs, then phase 2 critique.)
