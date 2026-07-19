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

**GENERALIZED COMPOSITION: zone grammar + procedural terrain response.** FULL
PROTOCOL. New milestone/redirection from Scott, relayed by dalinar 2026-07-18T22:40Z
(`.pka/inbound/orchestrator/2026-07-18-2240-dalinar-scott-verdict-generalize-composition-rules.md`,
authoritative, read in full). Working scope doc:
`.pka/round007/composition/rules/assignment.md`. Sub-round of round 007, stacks
on round head (now `7aec340` on origin/round/007-village).

**THE REDIRECTION (authoritative):** the decision-016/017 seam+foundation-veg work
is DONE but Scott ruled it "solid progress, not there yet": buildings still read
"stitched on / floating," sunflowers sit in the road not a field. The real tell is
NOT vegetation at the seams: **the GROUND does not respond to the buildings.** STOP
polishing the one hand-tuned inn-green district. The milestone is now to make the
SYSTEM produce grounded buildings + zoned flora ANYWHERE and prove it on ground
never hand-touched (Scott's 1k x 1k / 10k x 10k scale question). Four binding
artifacts: (1) annotated spike spec [Checkpoint A], (2) composition rules = zone
grammar + auto terrain-response bake, (3) generalization test = QA a NEW never-
polished district, (4) scale contract in the architecture decision. Two cheap
Scott checkpoints: A = the spike spec (gates implementation), B = ONE grounded-
building demo tile (gates full-district generation). The decision-017 floater-fork
questions (escalation `fac1635d`) are SUBSUMED by this reframe: no fresh build yet;
floaters are a zoning problem (sunflowers -> field zone, lanes stay clean).

**Lane:** FULL PROTOCOL (Scott-directed; a zone grammar + operational definition of
"built on the ground" is genuinely interpretive). Protected paths: NONE this
sub-round (spec is analysis + a doc). `src/sim/` protected + untouched.

=== WHERE WE ARE: **CHECKPOINT A SURFACED TO SCOTT. AWAITING HIS APPROVAL. NOTHING
IN FLIGHT. DO NOT START IMPLEMENTATION until he approves/corrects the spec.** ===

**The Checkpoint-A deliverable is DONE, committed, pushed:**
`docs/art/village/spike-spec.md` on **origin/round/007-village @ `7aec340`**
(orchestrator-authored synthesis; DRAFT pending Scott). It is the operational
definition of "built on the ground," synthesized via full protocol:
- **Phase 1 blind proposals** (each independently measured the spike, committed on
  its own LOCAL branch): claude `418572c1` (claude/018-spikespec, lw-016-render),
  codex `2ea3f981` (codex/018-spikespec, lw-007-codex), agy `cfc22d46`
  (agy/018-spikespec, lw-007-agy). All verified from end markers + tree; blind
  integrity held (agy's untracked `*_prop.md` were STALE base-veg scratch from a
  prior run, mtime 16:06, not this round's proposals).
- **Phase 2 adversarial critiques** (each critiqued the other two, committed on the
  same branches): claude `7a737ff4`, codex `82358ce1`, agy `f1f29f9f`. Real
  adversarial work (re-measured + ruled contested numbers).
- **Phase 3 synthesis** = the spec at `7aec340`.

**Converged findings in the spec:** "built on the ground" = a 3-band ground-response
stack (contact SEAM ~3-6px + altered-ground APRON + WEAR/recovery ~40px total);
adjacency-driven orientation asymmetry (>3x width sunlit/lane-facing vs shaded/
garden; a symmetric decal is the stitched-on look we kill); darkening = clamped
RATIO to local ground luminance (open grass itself varies ~30L); precedence-based
zone grammar (lane+door approaches exclude rooted flora FIRST; foundation response
is a wall-local modifier; then yard; then authored field/wild); hybrid scale
contract (seam screen-space w/ 1-2px floor; apron/yard RELATIVE to a LOCAL ground
feature not whole-building footprint/height). **The FIELD zone is NOT evidenced by
the spike** (only one small occluded smithy flower bed; no broad crop field) - this
is a real finding surfaced to Scott, because his "sunflowers in a field" needs an
AUTHORED field zone, not a measured one.

**Contested ruling (recorded verbatim in the spec):** scale-tag absolute-vs-relative
ruled 3-1 against agy's blanket-ABSOLUTE model (refuted by measurement: baseline
variance + orientation asymmetry; agy conceded the luma-ratio half in critique). NOT
a 2-2 split, so NO critic seat invoked. agy's dissent recorded verbatim.

**Checkpoint A filed to Scott** `to: dalinar`, request_id **`d03ff384`**
(`/home/scott/.pka/vault/agents/riker/inbox/2026-07-19-0231-longwalk-to-dalinar-d03ff384.md`;
reply lands in `.pka/inbound/d03ff384*.md`). Asked 3 gating questions: (1) the
field-zone-not-in-spike fork (point us at a field reference / approve authoring a
bed / make sunflowers foundation planting); (2) does the operational definition
match his eye (cheap to correct now); (3) adjacency vs a fixed-sun lighting term.

## ON RESPAWN: check `.pka/inbound/` for Scott's steer (req d03ff384) FIRST.

- **If he APPROVES the spec (with or without corrections):** apply any corrections
  to `docs/art/village/spike-spec.md`, then open the **decision-018 architecture
  round** (FULL PROTOCOL): zone-data model (baked per-cell tag vs render-time
  distance-field derivation - touches sim/render separation, may need an
  ARCHITECTURE.md escalation, flag it), terrain-response bake design on the existing
  substrate, the FULL scale contract (bake units / memory / file size / bake time
  per 1k+10k chunk), and the generalization-test district (NEW, never hand-touched).
  Build ONE grounded-building demo tile, then STOP at **Checkpoint B** for his eye
  before any full-district generation. Record decision 018 with four ballots on any
  contested synthesis question (critic only on 2-2). NOTE: 018 will touch protected
  paths (`src/render/town/*`; possibly `src/sim/` for zone tags) -> needs a signed
  decision record.
- **If he answers the field fork specifically:** fold it into the decision-018 scope.
- **If he wants a fresh Windows build:** he said no fresh build yet in the 22:40
  message, so only build if he changes that. Prior pattern: export gate + xvfb boot
  verify, build at `/home/scott/claude/longwalk-build-round007/`.
- **DO NOT** start implementation, write decision 018, design the bake, or touch code
  before his approval. Checkpoint A is a hard gate by the assignment's own structure.
- **DO NOT** re-run the spec protocol; it is done. If he corrects the spec, amend the
  doc, do not re-dispatch a new round.

## Live worktrees + branches (all LOCAL except round/007-village)

- `lw-007-round` on `round/007-village` @ **`7aec340`** (== origin; integration +
  where the orchestrator authored the spec).
- `lw-016-render` on `claude/018-spikespec` @ `7a737ff4` (claude proposal+critique).
- `lw-007-codex` on `codex/018-spikespec` @ `82358ce1` (codex proposal+critique;
  has untracked measurement scratch, harmless).
- `lw-007-agy` on `agy/018-spikespec` @ `f1f29f9f` (agy proposal+critique; untracked
  measurement scripts + STALE `*_prop.md` base-veg scratch, harmless).
- Older branches preserved by ref (iter4 base-veg): claude/017-tune @ was reset;
  codex/017-tune-signoff, agy/017-qa, agy/016-baseveg, claude/016-composition etc.
  still exist locally, not needed for 018.
- Doer 018 branches are LOCAL-ONLY (verified: none leaked to origin this run).

## Prior round-007 state (decisions 010-017, DONE, kept for lineage)

Decision 016 (composition/seams) + 017 (foundation base-vegetation) INTEGRATED +
SIGNED + QA'd, round head advanced 3c4c905 -> ... -> a6f7ddd (spec commit ->
7aec340). Decisions 009-015 (dirt fidelity) all on the round branch, DONE + locked
(do NOT reopen dirt/texture work). Full lineage in `docs/decisions/` + git history.
The seam-grading (016) and foundation-veg (017) work IS the substrate the new
terrain-response bake builds ON ("aim it at rules instead of one district") - do not
throw it away.

## Round 006 -- CLOSED (superseded)

Recoverable under `refs/archive/006/*` (pushed).

## Durable lessons (paid for repeatedly; honor them)

- **A dispatch is synchronous; nothing external re-invokes you when a detached proc
  finishes.** Only supervisor respawn re-invokes you. Own tool calls cap ~600s
  (bash default is 120s - pass a longer `timeout` param on poll loops). EITHER block
  in one call OR detach (setsid) + poll the end marker across calls. This run:
  proposals ran ~240-360s, critiques ~90-235s, dispatched 3-in-parallel into
  separate worktrees, polled end markers. `setsid bash -c "..." &` returns control
  immediately while dispatch.sh keeps running detached - that is correct, verify via
  start markers + pgrep, not the "[Done]" line.
- **Verify from the end marker + tree, NEVER exit code or narration.** branch_sha
  before/after + branch_changed + uncommitted_work; then confirm the committed
  artifact exists past the base SHA. uncommitted_work=yes is usually harmless scratch
  (.pka noise, measurement scripts) - check WHAT it is, the deliverable is the commit.
- **agy adapter hardcodes `--add-dir WORKDIR`** (no longer a manual flag), but still
  verify branch_changed=yes so it did not no-op into a scratch project.
- **Doer seats NEVER push to origin.** Only the orchestrator, only the round branch.
  Proposals/critiques stay on LOCAL doer branches, cited by SHA (not merged to the
  round branch, no sign-off gate - they are analysis artifacts, not code).
- **Cross-workspace asks to Scott: address `to: dalinar`, NOT `to: scott`.** Use the
  request-crossworkspace skill / `/home/scott/tools/agent-bus/bin/request-crossworkspace`.

## Meshy

Key live at `~/.claude/pka-secrets/longwalk/meshy.env`; MCP `meshy` in `.mcp.json`.
Balance **2892**. Available if in-context flora/asset regen genuinely needs it (no
mandate; NOT needed for the spec round). The DIRT paid path is CLOSED. Any paid spend
needs its own guard (meshy_list_tasks no PENDING, check_balance before/after,
cost-confirm, NEVER save_to).

## Active decision records

001-008 on main. Round-007 decisions **009-017** on the round branch (all DONE +
signed). **018 (generalized composition architecture) NOT YET WRITTEN** - it opens
only after Scott approves the spike spec (Checkpoint A). The spec itself
(`docs/art/village/spike-spec.md`) is a Checkpoint-A analysis doc, not a decision
record.

## Notes for the next run

- **Dashboard `/team` tab is KILLED by Scott** (inbox `2026-07-18-0445`): do NOT POST
  to `dashboard.int.sentania.net/api/team`. A missing POST is compliance, not failure.
- `gh pr edit` is broken (GraphQL projectCards). Use REST `gh api -X PATCH
  repos/sentania-labs/longwalk/pulls/N ...` if ever needed.
- No round PR is open (correct; opens only for the full-village milestone once Scott
  confirms the art bar on a generated district). Round is mid-milestone, NOT closing;
  leaked-branch sweep guard deferred to round close (verified no leak this run anyway).
- Inbox processed through `2026-07-18-2240` (this assignment) + the fac1635d/0330
  replies (subsumed). UUID partials 6110faed/c3ffe894 superseded. Stale codex-worktree
  inbound (308f0465/a1c32de4) noted in prior state, no action.

**Last updated:** 2026-07-19 (CHECKPOINT A DELIVERED. Full protocol ran clean: 3
blind spike-spec proposals -> 3 adversarial critiques -> orchestrator synthesis. The
annotated spike spec `docs/art/village/spike-spec.md` is committed + pushed at round
head `7aec340` and surfaced to Scott [req d03ff384] for approval. Key converged
finding: "built on the ground" = a 3-band adjacency-driven ground-response stack with
clamped-ratio darkening + a precedence-based zone grammar + a hybrid scale contract;
the FIELD zone is NOT in the spike [surfaced as a gating question]. Scale-tag question
ruled 3-1, agy dissent verbatim, no critic. HOLDING at Checkpoint A - implementation
is gated on Scott's approval. Nothing in flight at turn end.)
