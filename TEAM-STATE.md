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

## TWO THREADS THIS RUN

1. **ADVISORY ROUND (engine/stack) - DONE this run.** Full protocol ran end to
   end; decision **019** committed + surfaced to Scott; HOLDING for his ruling.
   Adopted nothing (deliberation-only). See the section just below.
2. **Checkpoint B - FAILED (Scott verdict landed 0555). Needs a retry with REAL
   spike-fidelity art.** Not worked this run (advisory round was the assigned
   scope). This is the TOP next action. See "Checkpoint B - FAILED".

## ADVISORY ROUND: engine/stack - DONE + SURFACED, HOLDING for Scott's ruling

**Status: COMPLETE. Recommendation delivered; Scott decides.** Full protocol:
3 blind proposals (claude, codex, agy) + cursor as Scott's summoned full 4th
voice -> 4 adversarial critiques -> synthesis + 4 ballots. Deliberation-only:
no code, no `src/`, nothing adopted. Assignment: `.pka/advisory/0-assignment.md`.

- **Deliverable:** `docs/decisions/019-engine-and-stack-advisory.md` @ **`9bf81e9`**
  on LOCAL branch `advisory/engine-stack` (NOT pushed; advisory branch is
  local-only). Surfaced to Scott: **req `ae56c8b2`** (to: dalinar, 2026-07-19).
- **The recommendation (Scott rules on all of it):**
  - **Q1 engine: GODOT 4.x** - unanimous 4-0, agent operability + Unity license
    activation disqualifier. Do NOT reopen Unity unless Scott prioritizes Netcode
    zone sharding over unattended runners.
  - **Q2 characters: layered 2D DEFAULT + MANDATORY time-boxed Godot runtime-3D
    pilot + 3D-assisted base-body-sheet hybrid candidate; Scott's eye gates.**
    Ballot **3-1** (claude dissent = prove-3D-first, recorded VERBATIM in 019).
    All in Godot, not a Unity reason. Round-006 static-bake failure does NOT veto
    runtime-3D.
  - **Q3 server: REJECT Unity Netcode; Godot-headless-first around pure src/sim,
    freeze a language-neutral contract, MEASURED extract trigger.** Ballot 4-0.
  - **Q4: minimal-infra ladder** (Postgres only when persistence authorized;
    every other dep - Redis/NATS/PostGIS/Nakama/K8s/Agones/Go/Rust/Python - a
    new-dependency Scott escalation), shared-proficiency skills, scope honesty.
  - **Recommended next step IF Scott greenlights:** a Godot-only agent-run
    character bake-off at shipping zoom (layered-2D vs 3D-assisted-base-body-sheet
    vs live runtime-3D), same traveller in motion, 2 lighting states, judged on
    Scott's eye. No src/, no new dep, no Unity.
- **Constitution-violation flags:** codex/agy/claude raised CONDITIONAL
  new-dependency + persistence-now violation claims in critique (recorded verbatim
  in 019). Disposition: NO live violation (advisory adopts nothing) + synthesis
  UPHOLDS the objected-to position -> objection did not lose -> NO forced Scott
  escalation. Flags carried forward as a standing constraint.
- **Phase artifacts (all verified from end markers + tree):**
  - Proposals: claude `bb3d24842e954a0133f1d6ba43d411bc9fb84c75` (claude/adv-engine),
    codex `a492fd2fbe8f35dd9bb4fa7ff88f05740087dff8` (codex/adv-engine),
    agy `88d70a53f90ba7c268f9fbe4d201a9366ee1d874` (agy/adv-engine),
    cursor `.pka/advisory/cursor-p1-output.md` (advisory, read-only).
  - Critiques: claude `8bc2b62060407b5d7e1e09b875d4b1bbc3e74e97`,
    codex `04c99971253cdcbe9f3815505ff413d38ad8fa89`,
    agy `cf3654a29dd6c528132f944cf8a528c8b675e55c`,
    cursor `.pka/advisory/cursor-p2-output.md` (advisory).
  - Full phase-1 map + convergence notes: `.pka/advisory/phase1-shas.md`.
- **NOTE (dead-dispatch pattern, paid again):** the prior run's phase-1 dispatches
  for claude/codex/cursor DIED (claude harness "Execution error", codex
  narrated-but-uncommitted, cursor empty capture) - only agy's first dispatch was
  real. Caught by verifying branch heads at base ef2cfac + no live procs, NOT the
  markers/narration. Re-dispatched (labels adv-p1b-*), all four landed. Every
  phase this run was detached + polled for the end marker within the same turn.
- **ON RESPAWN:** if Scott RULES on the engine/stack, record his verdict as a
  follow-up (update 019's status or a new record) and act on it. If he greenlights
  the bake-off, dispatch it as its own scoped round. Until he rules, the advisory
  round is CLOSED and nothing is pending on it.

## Checkpoint B - FAILED (Scott verdict). TOP NEXT ACTION: retry with REAL assets

**Scott's Checkpoint B verdict landed: FAIL** (inbox
`2026-07-19-0555-dalinar-scott-checkpoint-b-verdict-fail.md`). Verbatim: "none of
those pass ... they resemble nothing like our inspiration/concept art." NOT worked
this run (advisory round was the assigned scope); recorded here so the next run
acts on it.

- **Why it failed (dalinar's working interpretation, relayed as the team's unless
  Scott corrects):** the checkpoint used stylized-procedural STAND-IN art, burying
  the grounding/aging signal Scott grades by under art noise. A grounding cue
  cannot be validated on pixels that themselves read as wrong.
- **NEW STANDING RULE (not a one-round correction):** NOTHING is surfaced to
  Scott's eye again, at any checkpoint, unless rendered in the REAL approved
  spike-fidelity art. The stand-in-art shortcut is retired permanently.
- **What CP B retry must be:** (1) re-render the demo tile using the REAL
  spike-fidelity assets the team already owns (the inn-green district: actual
  cottages/inn/smithy/well/flora on the approved ground plate) with the decision-018
  age/state derivation on top; same young-vs-old comparison, same sim-state-only
  discipline. (2) If the terrain-response bands/aging rules were tuned against
  procedural art, RE-VERIFY them against the spike spec's measured values on the
  real assets before re-surfacing. (3) Gate question unchanged: does the building
  read BUILT-ON, and does age-40 vs age-1 read as organic history? Scott's eye.
  Full-district generation stays gated behind a passing retry.
- **HOW to dispatch (implementation lane, not a new design round):** re-dispatch
  claude-worker (owner per decision 018; worktree `lw-cpb-claude` on `claude/018-cpb`
  @ `7ac754a` still live) to re-render the SAME tile with real assets. Amend, do
  NOT re-run the protocol. codex-worker peer-reviews (non-author). Integrate the
  signed commit into `round/007-village` locally, run suite + CP B harness, then
  re-surface to Scott. This is the last gate before the round PR to main.
- Prior CP B build (58aabce + fix 7ac754a, codex-signed at 7ac754a, integrated at
  round head `de46462`) is what Scott rejected as stand-in art. The determinism
  work in it is sound and carries; the ART is what must change.

## Decision 018 (generalized composition architecture) - DONE (lineage)

Full protocol done end to end (3 blind proposals -> 3 adversarial critiques ->
synthesis -> 3 sign-offs). Record on round head **`5ea3aef`** (== origin
round/007-village base). Converged: sim owns coarse zone + evolving history as
texture-free `src/sim/composition/*`; render DERIVES the 3-band terrain response
per chunk as a pure function of (seed, position, sim snapshot, rule version);
chunks are a disposable re-derivable cache; adjacency classified at t=0 from
sim-side semantic edges, traffic MODULATES over time. agy's traffic-PRIMARY
adjacency ruled 3-1 (refuted by cold-start), grafted as the modulator. Division
of labor: codex = derivation kernel + generalization-district generator; claude =
CP B demo tile + field grammar + perceptual tuning; agy = QA on the untouched
generated district. Two 018 items escalated to Scott (req `decbf284`,
routing-confirmed, no ruling yet): ARCHITECTURE.md clarification + early
persistence-(b) slice - gate the FULL milestone, not CP B.

## Live worktrees + branches

**Advisory round (all LOCAL, retained on purpose until Scott rules on 019):**
- `lw-adv-round` on `advisory/engine-stack` @ **`9bf81e9`** (holds decision 019).
- `lw-adv-claude` on `claude/adv-engine` @ `8bc2b62` (proposal bb3d248 + critique).
- `lw-adv-codex` on `codex/adv-engine` @ `04c9997` (proposal a492fd2 + critique).
- `lw-adv-agy` on `agy/adv-engine` @ `cf3654a` (proposal 88d70a5 + critique).
- `lw-adv-cursor` detached @ `ef2cfac` (read-only; cursor artifacts captured to
  `.pka/advisory/cursor-p{1,2}-output.md`).

**Checkpoint B / round 007 (round branch pushed; doer branches LOCAL):**
- `lw-007-round` on `round/007-village` @ `de46462` (== origin; integration).
- `lw-cpb-claude` on `claude/018-cpb` @ `7ac754a` (RETAINED for the CP B retune).
- `lw-cpb-codex` on `codex/018-cpb-signoff` @ `d7b465d`, `lw-cpb-codex2` on
  `codex/018-cpb-rereview` @ `99c7c2f` (CP B review markers; keep until round close).
- 018-arch + spikespec branches local, kept by ref for lineage.
- ALL doer branches LOCAL-ONLY. Sweep this run: guard PASSED (no claude/*|codex/*|
  agy/* on origin), no advisory branch on origin, no open team PRs.

## Durable lessons (paid for repeatedly; honor them)

- **A dispatch is synchronous; nothing external re-invokes you when a detached
  proc finishes.** EITHER block in one call OR detach (`setsid bash -c "..." &`) +
  poll the end marker across calls (long `timeout` on the poll loop). This run:
  proposals ~210-320s, critiques ~80-235s, ran 3-4 in parallel into separate
  worktrees each phase.
- **Verify from the end marker + tree, NEVER exit code or narration.** This run
  caught 3 dead phase-1 dispatches (branches at base + no live procs) that a
  clean exit / plausible transcript would have hidden.
- **Provision required-reading files INTO each worktree.** Advisory specs went to
  `advisory-inputs/`, peer proposals to `advisory-peers/` (both gitignored via
  `.git/info/exclude`; doers told not to commit them).
- **cursor adapter** = read-only critic seat (`cursor-agent -p --mode ask --model
  auto`); its STDOUT is the artifact (branch_changed=NO is correct). Free plan
  forces `--model auto` (Composer routing); record the model line it self-reports.
- **agy adapter needs `--add-dir WORKDIR`** (hardcoded); still verify
  branch_changed=yes so it did not no-op into a scratch project.
- **Doer seats NEVER push to origin.** Only the orchestrator, only a round branch.
- **Cross-workspace asks to Scott: `request-crossworkspace --from longwalk --to
  dalinar --summary "..." --body "..."`** (`--from`/`--body` are required).

## Meshy

Key at `~/.claude/pka-secrets/longwalk/meshy.env`; MCP `meshy` in `.mcp.json`.
Balance 2892. Guard any paid spend (meshy_list_tasks no PENDING, check_balance
before/after, cost-confirm, NEVER save_to). May be needed for the CP B retry ONLY
if real character/flora art must be generated - but CP B retry should first use
the REAL assets the team ALREADY owns (the inn-green district), per Scott's rule.

## Active decision records

001-008 on main. Round-007 decisions **009-018** on the round branch (unmerged).
**019 (engine/stack advisory) on `advisory/engine-stack` @ 9bf81e9 (local),
awaiting Scott's ruling.** Numbering: advisory branch's docs/decisions only shows
001-008 (009-018 live on the round branch); 019 allocated globally to avoid
collision, per assignment.

## Notes for the next run

- **Dashboard `/team` tab is KILLED by Scott** (inbox `2026-07-18-0445`): do NOT
  POST to `dashboard.int.sentania.net/api/team`. Missing POST is compliance.
- `gh pr edit` is broken (GraphQL projectCards). Use REST `gh api -X PATCH
  repos/sentania-labs/longwalk/pulls/N ...` if needed.
- No round PR is open (correct). The round PR to main opens only for the
  full-village milestone once Scott confirms the art bar on a GENERATED district.
- **Inbox status:** CP B FAIL verdict (0555) = ACTED-ON-BY-RECORDING (retry is the
  top next action). Advisory assignment (0510/0530) = DONE (019). CP B tint
  follow-up (req 72b4e7a8) + 018 escalation (req decbf284) = pending Scott, no new
  reply. CP B verdict req 68bca91a = ANSWERED by the 0555 FAIL. Older UUID
  partials superseded.
- Sweep this run: clean. No leaked doer branches on origin, no advisory branch on
  origin, no open team PRs, nothing in flight.

### MIGRATION NOTE (2026-07-20, solo infra session, not an orchestrator run)

Authority: `scott/reports/2026-07-20-longwalk-migration-authorization.md` in the
vault (vault commit `bc2477a`). Nothing above this note was altered; no decision
record was touched, renumbered, or reinterpreted.

- **The repo moved** from `~/claude/longwalk` to `~/foundry/projects/longwalk`.
  All 15 worktrees were relinked with `git worktree repair` and verified working
  from their own directories. The worktrees themselves did NOT move and are
  still at `~/claude/lw-*`.
- **Worktree cleanup removed NOTHING.** All 15 were audited and all 15 kept. 14
  hold uncommitted work, and every branch is genuinely unlanded: the last merged
  PR is #21 (round 005), `refs/archive/` stops at `006`, and there is no
  `refs/archive/007*` namespace at all. `round/007-village` alone is 91 commits
  and about 12,600 insertions ahead of `main` with no PR. **Read this before
  assuming round 007 or the CP B / advisory work is safely landed. It is not.
  It exists only in these worktrees and in local branches.**
- The 2026-07-19 05:19 hard-killed run corresponds to `lw-cpb-claude`
  (`claude/018-cpb`), which carries an unmatched `cpb-retry-20260719-052522-start`
  marker with no end marker. That worktree is intact and was not touched.
- `~/claude/longwalk-build-round007/` (135MB, the round-007 WIP .exe plus
  screenshots) and the empty `~/claude/longwalk-worktrees/` are outside the
  authorized scope and were left alone. Both await a separate Scott call.
- **The team machinery moved out of this repo** into the shared framework at
  `~/foundry/tools/team-framework` (decision 020). `roles/` is gone; briefs now
  resolve from `$TEAM_FRAMEWORK_DIR/roles/`. New file: `.team/team-config.yaml`.
  The next orchestrator run should be launched via the framework's
  `bin/team-run`, not by hand-injecting a brief from this repo.

**Last updated:** 2026-07-19 (ADVISORY ROUND engine/stack DONE. Re-dispatched the
3 dead phase-1 dispatches [claude/codex/cursor - verified dead from branch heads
at base + no live procs, not narration], all 4 proposals landed + verified;
dispatched + verified 4 adversarial critiques [genuine round, real attacks +
concessions + conditional constitution-violation claims recorded verbatim];
synthesized + wrote decision 019 with 4-ballot arithmetic [Q1 4-0 Godot, Q2 3-1
2D-default+mandatory-Godot-3D-pilot w/ claude dissent verbatim, Q3 4-0
reject-Unity-Netcode + Godot-headless-first, Q4 4-0 minimal-infra]; no 2-2 tie so
critic seat NOT invoked [cursor stayed advisory]; committed 019 @ 9bf81e9 on LOCAL
advisory/engine-stack; surfaced to Scott req ae56c8b2. HOLDING for his ruling,
nothing pending on the advisory thread. SEPARATELY recorded Scott's Checkpoint B
FAIL verdict [0555] + the new STANDING RULE (never surface stand-in art; retry CP
B with real spike-fidelity assets) as the TOP next action for the next run. Sweep
clean, nothing in flight.)
