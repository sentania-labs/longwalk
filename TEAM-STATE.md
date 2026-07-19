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

**GENERALIZED COMPOSITION: Checkpoint B is BUILT + INTEGRATED + SURFACED TO
SCOTT. HOLDING for his verdict.** Scott approved Checkpoint A (spike spec)
pragmatically on 2026-07-19T02:45Z; decision **018** (architecture) is DONE +
signed + pushed. This run BUILT Checkpoint B: ONE grounded-building demo tile
(young age-1 vs mature age-40, byte-diff proof), got it peer-reviewed
(codex changes-requested -> claude fix -> codex signed-off), integrated it into
the round branch, ran the suite green, pushed, and surfaced it to Scott for his
eye. Round head now **`de46462`** on origin/round/007-village. Sub-round of round
007. Working scope: decision 018 section 5 + `.pka/round007/cpb-prompt.md`.

**Lane:** the architecture round was FULL PROTOCOL (done). Checkpoint B was a
scoped IMPLEMENTATION of the decided design (dispatch owner, peer-sign,
integrate) - done this run. No new design round was run.

=== WHERE WE ARE: **CHECKPOINT B DONE + PUSHED + SURFACED TO SCOTT (req
`68bca91a`, to: dalinar, filed 2026-07-19T04:32Z). NOTHING IN FLIGHT. HOLDING
for Scott's verdict on the grounding bar.**
- If Scott APPROVES the grounding: dispatch codex to build the deterministic
  generalization district + run the same response on ground never hand-touched
  (decision 018 section 4), then agy QA on the untouched output. THAT is the last
  gate before the round PR to main.
- If Scott says it does NOT read: re-dispatch claude to retune the SAME tile
  (`claude/018-cpb` worktree `lw-cpb-claude` still live); do NOT re-run the
  protocol, amend.
- Do NOT proceed to full-district generation until Scott approves this tile. ===

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

## Checkpoint B - BUILT + PEER-REVIEWED + INTEGRATED + SURFACED (this run)

Implementation-lane (not a design round). Dispatched claude-worker as owner per
decision 018; codex-worker as the non-author peer reviewer. All verified from end
markers + tree + re-running the suites myself.

- **claude build:** commit `58aabce` (claude/018-cpb), dispatch `018-cpb`
  (elapsed 2158s, branch_changed=yes, exit 0). New files ONLY in
  `src/render/town/*` (composition_kernel.gd, composition_tile_renderer.gd),
  `tools/art/*` (bake_checkpoint_b.gd, checkpoint_b.sh, out/checkpoint_b/*.png),
  `docs/art/village/checkpoint-b.md`. NO src/sim, NO protected path.
- **codex review #1 -> changes-requested:** marker
  `.team/signoffs/claude-018-cpb-58aabcef983f.md` (commit `d7b465d` on
  codex/018-cpb-signoff). Real determinism defect: `derive_flora()` claimed
  canonical-tuple conflict resolution but only concatenated+sorted; SW-corner
  candidate duplicated (exact-position dup in output); harness asserted
  repeatability not input-order invariance. The review gate working as designed.
- **claude fix:** commit `7ac754a` (dispatch `018-cpb-fix`, 384s). Split
  derive_flora into collect + resolve; real per-cell canonical-tuple winner
  selection over the complete candidate set; removed the duplicate SW-corner at
  source; added a genuine order-invariance assertion (reverse candidates,
  re-resolve, assert byte-identical, vacuity guard). Only the 2 source files +
  regenerated (byte-stable) captures. flora count 701 -> 700 (the removed dup).
- **codex re-review -> signed-off:** marker
  `.team/signoffs/claude-018-cpb-7ac754a15cd3.md` (commit `99c7c2f` on
  codex/018-cpb-rereview). reviewed_by=codex-worker, authored_by=claude-worker
  (distinct), reviewed_sha=7ac754a.
- **Integration:** merged codex/018-cpb-rereview (--no-ff, brings claude 58aabce
  +7ac754a and the signed marker) then cherry-picked the changes-requested audit
  marker (d7b465d) into `round/007-village`. Round head **`de46462`**, pushed to
  origin. Full active suite (`tools/run_tests.sh`) + CP B harness
  (`tools/art/checkpoint_b.sh`) BOTH exit 0 on the integrated round; worktree
  byte-stable after runs (determinism confirmed end-to-end). young_vs_mature diff
  = 51310/262144 px, RESULT=PASS.
- **Documented contract divergence (accepted by codex for the offline slice):**
  claude's one-tile kernel derives FINAL ground RGBA in ground space instead of
  emitting codex's two response textures for `ground.gdshader` (no shader/viewport
  offline; the screen-space 1-2px seam floor does not apply). Does NOT waive the
  two-texture + screen-space seam contract for codex's full-milestone kernel.
- **Surfaced to Scott:** req `68bca91a` (to: dalinar, 2026-07-19T04:32Z).
  Artifacts: `tools/art/out/checkpoint_b/{compare_young_vs_mature,tile_young_age1,
  tile_mature_age40,field_zone_legend}.png` on origin/round/007-village. STOPPED
  per instruction; did NOT proceed to full-district generation.

## ON NEXT RESPAWN

- **Check `.pka/inbound/` FIRST** for Scott's Checkpoint B verdict (req
  `68bca91a`) AND the still-pending architecture escalation reply (req `decbf284`
  routed, no ruling yet: ARCHITECTURE.md clarification + early persistence-(b)
  slice; gates the FULL-milestone src/sim work, NOT anything immediate).
- **If Scott APPROVES the grounding bar:** dispatch codex-worker to build the
  deterministic generalization-district generator + run the production chunk
  baker over ground never hand-touched (decision 018 section 4), then agy-worker
  QA on that untouched output. Only after that passes does the round PR to main
  open. (codex owns the kernel; the CP B divergence above must be reconciled into
  the two-texture contract there.)
- **If Scott says it does NOT read:** re-dispatch claude-worker to retune the
  SAME tile on `claude/018-cpb` (worktree `lw-cpb-claude` still live). Amend, do
  NOT re-run the protocol. Likely levers if he asks: real building/flora art
  (currently stylized-procedural, the honest caveat surfaced to him), or band
  shape / apron strength tuning.
- **Meshy:** not needed unless Scott wants real flora art. Guard any paid spend
  (balance 2892; meshy_list_tasks no PENDING; check_balance before/after;
  cost-confirm; NEVER save_to).

## Live worktrees + branches (all LOCAL except round/007-village)

- `lw-007-round` on `round/007-village` @ **`de46462`** (== origin; integration).
- **`lw-cpb-claude` on `claude/018-cpb` @ `7ac754a`** (CP B build + fix; RETAINED
  ON PURPOSE for a possible Scott-driven retune of the same tile; integrated into
  round already).
- **`lw-cpb-codex` on `codex/018-cpb-signoff` @ `d7b465d`** (changes-requested
  marker; retained until round close for audit).
- **`lw-cpb-codex2` on `codex/018-cpb-rereview` @ `99c7c2f`** (signed-off marker;
  integrated into round; retained until round close).
- `lw-016-render` on `claude/018-arch` @ `16bf494`, `lw-007-codex` on
  `codex/018-arch` @ `f086c83`, `lw-007-agy` on `agy/018-arch` @ `4df3d86`
  (decision-018 proposal/critique/signoff branches; keep by ref).
- Older 018-spikespec branches (claude @ 7a737ff, codex @ 82358ce, agy @ f1f29f9)
  local, cited by the spike spec; keep by ref.
- ALL doer branches (018-cpb*, 018-arch, spikespec) are LOCAL-ONLY. Sweep guard
  passed this run: none leaked to origin; no open team PRs.

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

001-008 on main. Round-007 decisions **009-018** on the round branch. 018
(generalized composition architecture) DONE + SIGNED; its Checkpoint B slice
BUILT + integrated this run (round head de46462). Two items in 018 escalated to
Scott (request_id decbf284, routing-confirmed this run, no ruling yet):
ARCHITECTURE.md clarification + early persistence-(b) slice - gate the full
milestone, not CP B.

## Notes for the next run

- **Dashboard `/team` tab is KILLED by Scott** (inbox `2026-07-18-0445`): do NOT
  POST to `dashboard.int.sentania.net/api/team`. A missing POST is compliance.
- `gh pr edit` is broken (GraphQL projectCards). Use REST `gh api -X PATCH
  repos/sentania-labs/longwalk/pulls/N ...` if ever needed.
- No round PR is open (correct; the round PR to main opens only for the
  full-village milestone once Scott confirms the art bar on a GENERATED district,
  i.e. after the generalization test). Round is mid-milestone.
- Inbox: `decbf284` reply LANDED this run (routing confirmation only, no Scott
  ruling yet; confirms CP B unblocked, which it was). CP B verdict req `68bca91a`
  filed to Scott this run; reply pending. Older UUID partials
  (6110faed/c3ffe894/d03ff384/fac1635d) superseded/resolved.
- **CP B captures regenerate `.import` sidecars** in the round worktree when the
  bake runs; they are gitignored (worktree stayed clean). The committed PNGs are
  byte-stable across re-bakes.
- Sweep this run: no leaked doer branches on origin (guard passed); no open team
  PRs. Two blocked markers on codex/018-arch history (173735Z resolved-flagged;
  030642Z is the same prior-run provisioning gap that was resolved + re-dispatched
  -> proposal 7368784 landed) - both stale, NOT live, no action.

**Last updated:** 2026-07-19 (Checkpoint B BUILT + peer-reviewed + integrated +
surfaced to Scott. Dispatched claude-worker [owner] -> commit 58aabce; codex peer
review returned changes-requested on a real determinism defect [flora conflict
resolution claimed but not implemented + exact-position dup + order-invariance
untested] -> claude fixed at 7ac754a [genuine canonical-tuple resolution + order-
invariance assertion] -> codex signed-off at 7ac754a. Integrated both markers +
claude work into round/007-village [head de46462, pushed]; full suite + CP B
harness green, byte-stable [determinism confirmed]. Surfaced the young-vs-mature
demo tile + field-zone artifacts to Scott [req 68bca91a, to: dalinar]; STOPPED at
Checkpoint B per instruction, did NOT proceed to full-district generation.
HOLDING for Scott's grounding-bar verdict. Sweep clean, nothing in flight. All
verified from end markers + tree + re-running the suites myself.)
