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

**GENERALIZED COMPOSITION: build toward Checkpoint B (one grounded-building demo
tile).** Scott APPROVED Checkpoint A (the spike spec) pragmatically on
2026-07-19T02:45Z (`.pka/inbound/orchestrator/2026-07-19-0245-dalinar-scott-
checkpoint-a-approved-build.md`, "I don't fully understand but let's build
something to iterate on"). Checkpoint A gated the architecture decision; that
decision (**018**) is now DONE, signed, and pushed. The milestone's remaining
Scott gate is **Checkpoint B**: ONE grounded-building demo tile for his eye
BEFORE any full-district generation. Working scope doc:
`.pka/round007/composition/rules/assignment.md` (+ 2255 ADDENDUM). Sub-round of
round 007; round head now **`5ea3aef`** on origin/round/007-village.

**Lane:** the architecture round was FULL PROTOCOL (done). Checkpoint B
implementation is a scoped IMPLEMENTATION of the decided design (not a fresh
design round): dispatch the assigned owner, peer-sign, integrate.

=== WHERE WE ARE: **DECISION 018 DONE + SIGNED + PUSHED. NOTHING IN FLIGHT.
NEXT ACTION = dispatch Checkpoint B implementation (see ON RESPAWN).** Checkpoint
B is buildable NOW: it is offline, render + tools/art only, NO protected path, NO
persistence store (passes `age` as a literal argument). The two Scott escalations
filed this run gate the FULL-milestone sim-side work only, NOT Checkpoint B. ===

## Decision 018 (generalized composition architecture) - DONE this run

Full protocol ran end to end: 3 blind proposals -> (codex re-dispatch after a
provisioning-gap block) -> 3 adversarial critiques -> synthesis -> 3 sign-offs.
Record: `docs/decisions/018-generalized-composition-architecture.md` on round
head **`5ea3aef`** (== origin). All verified from end markers + tree.

- **Proposals (blind, local doer branches):** claude `ba233c6479f14866d131d5b6dba3589a74e34fd5`
  (claude/018-arch), codex `7368784e30a05b9c2bce98664dfcf2ffe0a77580`
  (codex/018-arch; first dispatch correctly BLOCKED on a missing assignment file,
  an orchestrator provisioning gap, resolved + re-dispatched same run), agy
  `474c9012dbda234084537b8aaef074d110353dcd` (agy/018-arch).
- **Critiques (adversarial, genuine):** claude `792520adb6c08a62425c1edb7f8ec039194c09eb`,
  codex `25ae1fe74ed2804488300798702f4a1587fc172e`, agy
  `c269ef5458fd0df35e2fbe716b799df70ff4f613`.
- **Sign-offs (all accepted, no withholds):** claude 16bf494, codex f086c83,
  agy 4df3d86 (files on local branches; lines transcribed into the record).

**Converged architecture (codex spine + grafts):** sim owns coarse zone
(yard/field/wild) + evolving history (age/traffic/disturbance ticks) as
texture-free `src/sim/composition/*` data; render DERIVES the 3-band terrain
response per chunk as a pure function of (seed, position, sim-state snapshot,
rule version); foundation response is a wall-local per-texel modifier (NOT a
stored tag); chunks are a disposable, re-derivable, view-window-bounded cache
(32x32 cells, halo = max response reach, byte-level border test mandatory);
texel density is a MEASURED knob (8 vs 16 tpc benchmarked, not frozen);
per-sample precedence over independent fields (not a single edge enum);
adjacency classified at t=0 from sim-side semantic door/service edges, traffic
MODULATES over time. Passes all three addendum constraints + the disqualification
gate; Checkpoint B is the falsifiable proof (young vs old, byte-diff).

**Contested ruling (recorded verbatim in the record):** agy's traffic-PRIMARY
adjacency ruled **3-1** (claude+codex+orchestrator vs agy) - refuted by the
cold-start case (a young building has no traffic to derive a door from, but the
gate needs young-vs-old). agy's idea grafted as the time-evolution modulator.
NOT a 2-2 split, so NO critic seat. agy's determinism gap (random generator /
order-dependent traffic accumulator) was a critique finding against a LOSING
proposal, NOT a live objection against the winning (deterministic) synthesis, so
NOT a Scott escalation; recorded verbatim for audit. agy SIGNED anyway (protocol).

**Division of labor (capability-based, in the record):**
- **codex** = derivation kernel + chunk/scale harness + the deterministic
  generalization-district generator (byte-stability / determinism rigor; owns
  016/017 bakers). NOT agy for the generator (its own proposal defaulted to
  "random").
- **claude** = Checkpoint B demo tile + authored field-zone grammar + render-side
  consumption + capture-inspect perceptual tuning (the "does it read to Scott's
  eye" loop from 016/017).
- **agy** = QA / acceptance on the never-hand-touched generated district +
  adversarial byte-stability audit (independent third eye for the gate).

## ON RESPAWN: check `.pka/inbound/` FIRST, then dispatch Checkpoint B

- **Inbox:** watch for the Scott escalation reply (**request_id `decbf284`**,
  filed this run -> lands `.pka/inbound/decbf284*.md`): ARCHITECTURE.md
  clarification + early persistence-(b) slice. His ruling gates the FULL-milestone
  `src/sim/` persistence work. It does NOT gate Checkpoint B - do not wait on it
  to build CP B.
- **NEXT ACTION = dispatch Checkpoint B implementation to claude-worker** (the
  assigned owner per decision 018). Scope from decision 018 section "Checkpoint B":
  ONE 32x32-cell tile, one cottage + short lane + door approach + yard + one
  AUTHORED sunflower field (spike palette + grammar, team-authored: warm dark
  cultivated bed, coherent clumps/short rows, soft coverage-broken edges, clean
  access gap to lane, NO crops in yard/travel core) + a wild edge. Rendered from
  TWO sim snapshots of identical geometry+seed: age-1 low-use vs age-40 high-use,
  with a byte-difference assertion (unchanged inputs byte-stable, changed inputs
  observably different). OFFLINE bake, `age` as an explicit literal argument, in
  `src/render/town/*` + `tools/art/*` ONLY (neither protected; NO `src/sim/`
  change, NO persistence store, NO runtime cache). This proves the ground
  responds to the building as a RULE, not a painted patch.
  - claude may need a small piece of codex's kernel contract first (the
    response-field channel shape). Decision 018 says freeze the channel contract
    before the render slice starts. Judgment call: either dispatch a tiny codex
    "freeze the CP B channel contract + minimal one-chunk baker" slice first, then
    claude consumes+tunes+authors the field; OR let claude build the whole CP B
    tile end-to-end (kernel-for-one-tile + render + field) since CP B is
    deliberately the smallest slice and does not need the full chunk harness. Lean
    toward the latter for speed to Scott's eye, but codex owns the kernel design,
    so if claude's one-tile kernel diverges from the decided contract, reconcile.
  - CP B is CODE -> needs a pre-PR peer sign-off marker under `.team/signoffs/`
    from a NON-author resident before it integrates to the round branch (even
    though no protected path). Then integrate locally, run the suite, and
    **STOP at Checkpoint B: surface the demo tile (mature + young side by side)
    to Scott (to: dalinar) for his eye. Do NOT proceed to full-district
    generation until he approves.**
- **If Scott corrects decision 018 or the spec at Checkpoint B:** amend, do not
  re-run the protocol.
- **Meshy:** the authored sunflower field uses EXISTING crops the team holds
  (spike palette). No paid spend needed for CP B. If in-context flora regen is
  genuinely needed, guard it (balance 2892; meshy_list_tasks no PENDING;
  check_balance before/after; cost-confirm; NEVER save_to).

## Live worktrees + branches (all LOCAL except round/007-village)

- `lw-007-round` on `round/007-village` @ **`5ea3aef`** (== origin; integration +
  where decision 018 was authored/signed).
- `lw-016-render` on `claude/018-arch` @ `16bf494` (claude proposal ba233c6 +
  critique 792520a + signoff).
- `lw-007-codex` on `codex/018-arch` @ `f086c83` (codex proposal 7368784 +
  critique 25ae1fe + signoff; note it also carries the resolved block marker
  1a25b61 in history - harmless).
- `lw-007-agy` on `agy/018-arch` @ `4df3d86` (agy proposal 474c901 + critique
  c269ef5 + signoff).
- Older 018-spikespec branches (claude/018-spikespec @ 7a737ff, codex @ 82358ce,
  agy @ f1f29f9) still exist locally, cited by the spike spec; keep by ref.
- Doer 018-arch branches are LOCAL-ONLY (sweep guard passed: none leaked to
  origin this run).

## Prior round-007 state (decisions 009-017, DONE, kept for lineage)

Decisions 016 (composition/seams) + 017 (foundation base-vegetation) INTEGRATED +
SIGNED + QA'd. Decisions 009-015 (dirt fidelity) DONE + locked (do NOT reopen).
The spike spec (`docs/art/village/spike-spec.md`, Checkpoint A, now APPROVED) and
the 016/017 substrate are what decision 018 builds ON, not throws away. Full
lineage in `docs/decisions/` + git history.

## Round 006 -- CLOSED (superseded)

Recoverable under `refs/archive/006/*` (pushed).

## Durable lessons (paid for repeatedly; honor them)

- **A dispatch is synchronous; nothing external re-invokes you when a detached
  proc finishes.** Only supervisor respawn re-invokes you. Own tool calls cap
  ~600s. EITHER block in one call OR detach (`setsid bash -c "..." &`) + poll the
  end marker across calls (pass a long `timeout` on the poll loop). This run:
  proposals ~80-330s, critiques ~90-270s, sign-offs ~40-50s; ran 3-in-parallel
  into separate worktrees each phase. `setsid` prints "[Done]" immediately (setsid
  exits after forking) while dispatch.sh keeps running detached - verify via start
  markers + `ps`, NOT the "[Done]" line.
- **Verify from the end marker + tree, NEVER exit code or narration.** branch_sha
  before/after + branch_changed + uncommitted_work; then confirm the committed
  artifact past the base SHA. uncommitted_work=yes is usually harmless scratch.
- **Provision required-reading files INTO each doer worktree.** This run's codex
  block was because `.pka/round007/.../assignment.md` is untracked in main and so
  absent from the 7aec340-based worktrees. Copy any referenced doc into each
  worktree before dispatch, or inline it in the prompt. (Inlining the addendum
  constraints let claude/agy proceed; codex correctly refused to fabricate.)
- **agy adapter needs `--add-dir WORKDIR`** (hardcoded now); still verify
  branch_changed=yes so it did not no-op into a scratch project.
- **Doer seats NEVER push to origin.** Only the orchestrator, only the round
  branch. Proposals/critiques/sign-offs stay on LOCAL doer branches, cited by SHA.
- **Cross-workspace asks to Scott: address `to: dalinar`.** Use the
  request-crossworkspace skill / `/home/scott/tools/agent-bus/bin/request-crossworkspace`.

## Meshy

Key live at `~/.claude/pka-secrets/longwalk/meshy.env`; MCP `meshy` in `.mcp.json`.
Balance **2892**. NOT needed for Checkpoint B (authored field uses existing
crops). Any paid spend needs its own guard (meshy_list_tasks no PENDING,
check_balance before/after, cost-confirm, NEVER save_to).

## Active decision records

001-008 on main. Round-007 decisions **009-018** on the round branch. **018
(generalized composition architecture) DONE + SIGNED this run** (all three doers).
Two items in 018 escalated to Scott (request_id decbf284): ARCHITECTURE.md
clarification + early persistence-(b) slice - gate the full milestone, not CP B.

## Notes for the next run

- **Dashboard `/team` tab is KILLED by Scott** (inbox `2026-07-18-0445`): do NOT
  POST to `dashboard.int.sentania.net/api/team`. A missing POST is compliance.
- `gh pr edit` is broken (GraphQL projectCards). Use REST `gh api -X PATCH
  repos/sentania-labs/longwalk/pulls/N ...` if ever needed.
- No round PR is open (correct; the round PR to main opens only for the
  full-village milestone once Scott confirms the art bar on a GENERATED district,
  i.e. after Checkpoint B + the generalization test). Round is mid-milestone.
- Inbox processed through `2026-07-19-0245` (Scott's Checkpoint A approval).
  Escalation decbf284 filed this run; reply pending. Older UUID partials
  (6110faed/c3ffe894/d03ff384/fac1635d) superseded/resolved.
- Sweep this run: no leaked doer branches on origin (guard passed); no open team
  PRs; codex's phase-1 block (1a25b61) was a same-run provisioning gap, resolved
  and re-dispatched - not a live block, no cherry-pick needed.

**Last updated:** 2026-07-19 (Checkpoint A APPROVED by Scott -> ran the full
decision-018 architecture round end to end: 3 blind proposals [codex re-dispatched
after a provisioning-gap block], 3 adversarial critiques, synthesis, 3 sign-offs.
Decision 018 committed + fully signed + pushed [round head 5ea3aef]. Strong 3-way
convergence: sim owns evolving zone+history, render derives per-chunk response as
a pure function, chunks are a disposable re-derivable cache. Adjacency ruled 3-1
vs agy [no critic, not 2-2]. Two Scott escalations filed [decbf284: ARCHITECTURE.md
clarification + early persistence slice; gate full milestone, NOT CP B]. NEXT:
dispatch Checkpoint B implementation to claude [offline, render+tools only, no
protected path, young-vs-old byte-diff proof + authored sunflower field], peer-sign,
integrate, STOP at Checkpoint B for Scott's eye. Sweep clean. Nothing in flight.)
