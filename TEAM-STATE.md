# TEAM-STATE

<!--
MACHINERY, NOT A CHANGELOG.

This file is the orchestrator's memory. The orchestrator is ephemeral: it is
spawned with an assignment, runs the protocol, and dies. Nothing it holds in
memory survives. So it reads this file first thing on every run and rewrites
it before it exits, and that read/write cycle is the only reason the team has
continuity between runs at all.

Consequences worth knowing before you edit this file:

  - It is overwritten. Do not park notes here expecting them to persist. The
    durable record of a decision is docs/decisions/NNN-topic.md, which is
    append-only and never rewritten.
  - It describes the present, not the past. When an assignment finishes, its
    state is replaced, not appended to. History lives in git and in the
    decision records.
  - Humans read it, but it is not written for humans the way a changelog is.
    It is a state dump the next orchestrator run can act on.

Keep the section structure below stable: the orchestrator (and eventually the
Dashboard "Team" tab, a follow-up dispatch) parse it by heading.
-->

## Current assignment

**ROUND 006: Two Rivers iteration + art-production fork. FULL PROTOCOL,
contested, four-ballot. PHASE 1 (blind proposal) IS IN FLIGHT.** Round branch
`round/006-two-rivers` created from `main` at `2805f00`. Three blind proposals
dispatched DETACHED at run stamp `20260717-202010`:
- claude on `claude/006-proposal` (worktree `lw-006-claude`)
- codex on `codex/006-proposal` (worktree `lw-006-codex`)
- agy on `agy/006-proposal` (worktree `lw-006-agy`)
Each writes `docs/proposals/<prefix>-006-two-rivers-production.md` and commits it.
Cap 2400s. Poll end markers in each worktree's `.team/markers/`; verify
`branch_changed`/`uncommitted_work`/`cap_expired`, then read each proposal doc.

**The contested phase-1 question (directive 1515):** which art-PRODUCTION path,
of three: (1) stay pure-sprite, (2) real-time Meshy 3D through an iso-locked
Godot 3D camera, (3) 3D pre-rendered to painterly 2D sprites (Dalinar's
recommended bias; preserves the iso spine + most of codex's pipeline). Meshy is a
NEW DEPENDENCY = escalation-class: any Meshy-adoption recommendation must be
called out to Scott in decision 009, though a SMALL pilot (one building + player)
is pre-authorized. The GOAL is fixed (spike fidelity + Two Rivers vibe in the
running game); only the production METHOD is contested.

**The four named defects (directive 1500), the execution target once the method
is chosen:** (1) walk-cycle animation not dialed in; (2) building-to-player scale
off (document + enforce a ratio); (3) fidelity gap (whole-scene generation
collapses when bridged to game tiles/sprites); (4) runtime bug "Instance base is
null" prints top-left in playtest (independently fast-lane-able).

**Posture (directive 1500, standing):** autonomous multi-round iteration toward
the approved iso-five-asset-spike + Two Rivers vibe. "Burn the tokens, run rounds
back to back, do NOT stop-and-wait after every slice." Surface a playable build
to Scott only when the team believes it genuinely hits the bar, or on a real
decision (constitution question, deadlock the critic can't settle, or the
Meshy-adoption call specifically). Check the `.pka/inbound/orchestrator/` inbox
at EVERY phase boundary, not just spawn.

## Phase

**Status:** `ROUND 006, PHASES 1-3 COMPLETE. Decision 009 (3D-authored,
2D-delivered pipeline, pilot-gated) SIGNED 4-0/4-0, committed to
round/006-two-rivers at 85dc620 (branch pushed to origin), validated against the
consensus gate (signed by all three doers, covers project.godot, PASS). NEXT
PHASE = EXECUTION of the pilot slices.`

**Round 006 artifact SHAs (archived under refs/archive/006/*, pushed to origin):**
| Worker | Proposal | Critique | Ballot |
| --- | --- | --- | --- |
| claude | `8da1420640a1461b936111e42db7419749490f7f` | `0b496efe1f15ade69a8232a61cc176be203bc3a9` | `b182a2819ab8b4388e51f6db9ae30faf4905139b` |
| codex | `b707cf7f7e7102ff57e34df0b47377b751f11eea` | `e4237a22d75a9f47d601b10223948f9fb81d9735` | `d9bef93d2a809e17df671c2f05f5c785545d581b` |
| agy | `d6a0f8288ba266ceeda3f0d66afce1b2bdc783cb` | `b7327bec27e149e42d6ad62795db5f7ea7415da6` | `e5989621ac7299ff60f62999e450b040a7d4a904` |

**Decision 009 outcome (full detail in the record on the round branch):**
unanimous Path 3; per-frame generative repaint BANNED (both converged, no
ballot). Four-ballot on two contested questions, both 4-0:
- Q1 (fidelity recovery): dual-candidate pilot. (A) deterministic NPR/composite
  baseline AND (B) generative stylization in TEXTURE SPACE (mesh albedo, once) OR
  a single fixed-seed WHOLE-SHEET pass, never per-frame; the pilot MEASURES both
  under rejection rules (no landmark mutation, no boiling; freeze accepted outputs
  + provenance; gate fails if A misses the spike and B cannot close it cleanly).
- Q2 (render tool): Blender headless single offline authoring+render source; Godot
  only for acceptance capture. agy conceded its Godot-sub-viewport position.
Plus: camera-calibration-first vs `src/render/iso/projection.gd` (verify the iso
angle); codex's meter scale contract + build-failing validation; the 008-QC
offline-derived shadow MASK stays SHIPPED (Blender cast-shadow = cross-check);
small pilot = one 2x2 cottage + one player (6-pose walk, 8 facings) + minimal
dressing; cleanup-labor ledger extrapolated to ~200 assets before any production
tranche; anonymized in-engine gate vs the SPIKE; `src/sim/` untouched.
**Meshy adoption beyond the pilot is ESCALATED to Scott in decision 009** (pilot
pre-authorized; production adoption needs his explicit approval, brought with the
pilot result + ledger).

## Round 006 EXECUTION plan (phases 1-3 done; this is what's next)

Decision 009 division of labor (all three ACCEPTED their slices in their ballots):
- **claude:** in-engine integration into `starter_town.gd`/`player_controller_2d.gd`,
  camera + `building_contact_cell` anchor-contract conformance, candidate B
  (texture-space/whole-sheet generative) design, AND the "Instance base is null"
  fast-lane fix (independent lane; clean-import repro + engine stack, NOT a guessed
  `load()` site; boot-flow regression assertion on that exact text).
- **codex** (sprite-forge mandate): 2D delivery boundary, deterministic NPR/
  composite baseline (candidate A), render-pass specs + pre-render manifests,
  anchor+scale validation scripts, 8-facing atlas assembly, acceptance-capture +
  walk-GIF harness.
- **agy:** Meshy API integration + provenance manifest, Blender-headless offline
  render tool + primitive camera-calibration scene, cleanup-labor ledger tooling.
- **shared, sequenced:** Blender topology cleanup, armature weighting, gait tuning.

Ordered execution steps:
1. **Defect #4 (null bug), independent FAST-LANE, no Meshy needed:** dispatch claude
   to reproduce "Instance base is null" from a clean import, fix from the engine
   stack, add the regression assertion. Cross-sign (non-author), `--no-ff` into
   `round/006-two-rivers`, suite green. This can go FIRST and in parallel with
   scaffolding, since it does not depend on the art pipeline.
2. **Non-Meshy scaffolding (can proceed WITHOUT Meshy access):** agy's Blender
   camera-calibration scene proving agreement vs `projection.gd` using PRIMITIVES;
   codex's scale-contract validation script; the render-pass/manifest spec. Prove
   camera + scale on primitives before any Meshy asset is judged (009 constraint 2).
3. **Meshy-dependent pilot steps (BLOCKED on Meshy credentials, see below):** one
   cottage + one player generated in Meshy, cleaned/rigged/posed in Blender,
   rendered to candidate A and B, integrated, run the anonymized acceptance gate
   vs the spike + the cleanup ledger.
4. Round PR to main, one external Codex review round, address findings, merge on
   the ordinary gate, close-out sweep (delete branches + worktrees, archive already
   done under `refs/archive/006/*`, write `.review-passed`).

**PROVISIONING FLAG (surface early):** the Meshy-dependent steps need a Meshy
account/API key that likely does not exist in this environment yet. Directive 1515
pre-authorized the PILOT, so provisioning credentials is within that authorization,
but it is an external/manual step. Steps 1-2 do NOT need Meshy and should run first;
if step 3 is reached with no Meshy access, that is a genuine BLOCKER to raise with
Scott (a `.pka` cross-workspace request or inbox item), not a reason to fake the
pilot. Do NOT introduce a second external dependency (e.g. Mixamo) by convenience.

## Round 005 (COMPLETED + MERGED + SWEPT this run)

Round 005 (isometric visual identity, decision 008) is DONE. PR #21 merged to
`main` at merge commit **`5d83f477`** (2026-07-17T20:16Z), via a merge commit
(round-branch norm, matches PR #20). `.review-passed` on main records `5d83f47`
(commit `2805f00`, straight to main per the sanctioned exception).

External Codex review reached FIVE rounds, all findings addressed by the owning
doer + peer-signed + integrated before merge:
- r1: facing-from-square-velocity P1 (claude facing-fix).
- r2: two P2s (capture-freeze, manifest-doc).
- r3: two P2s THIS RUN: camera zoom-clamp ordering (agy `618b578`) + README
  build_player_walk stale invocation (codex; first attempt `ec176dc` documented a
  non-running command, CAUGHT by claude peer review as `changes-requested`;
  re-fixed `cd35047` adding `tools/art/rebuild_player_walk_option_c.py`, verified
  byte-for-byte artifact reproduction sha256 `0e4c952b...`).
- r4: two more P2s THIS RUN: camera pan drag-threshold only applied to the first
  gesture (agy `db71051`, adds a `FREE` state + regression test) + README:84
  stale `out/processed/` attribution (codex `b43daf9`).
- r5 (head `84aa8cf`): CLEAN ("Didn't find any major issues. Delightful!").
All CI green at merge. Close-out sweep done: round + all doer branches deleted
(remote round branch, both stale remote codex/005 fix branches, all local 005
branches); doer worktrees torn down; nine 008-cited proposal/critique/ballot SHAs
archived under `refs/archive/005/*` (pushed to origin).

## Active decision records

- **`008-isometric-visual-identity.md`** (on main via PR #21). 4-0. Authorizes
  the `project.godot` protected path. Supersedes 005's cardinal facing SET.
- **`007-isometric-and-own-art-override.md`** (main). Binding for iso + own-art.
  Supersedes 006 grounds 1-2.
- **`006-asset-pack-and-rendering-model.md`** (main). Grounds 1/2 superseded by
  007; 3/4/5 survive; 7 superseded by 008.
- **`004-round-branch-integration-and-voting-model.md`**: round-branch
  integration, doers never open PRs, one PR + one external review per round,
  four-ballot voting with critic tiebreaker on a 2-2 split. Governs round 006.
- `005`/`003`/`001`/`002` accepted (002's standing critic vote rescinded by 004;
  001's SHAs pinned under `refs/archive/001/*`; 005's under `refs/archive/005/*`).
  **Next free decision number is `009`** (round 006's production-fork decision).

## Branch and PR sweep (round 006 in flight)

- **Zero open team PRs** (round 006 has no PR yet; execution not started).
- **Remote branches:** `origin/main`; `origin/round/006-two-rivers` (pushed to
  protect decision 009, PR opens after execution); `origin/issue-4-world-eras` (a
  HUMAN branch, author sentania, 2026-07-13, no resident prefix, predates the team
  framework; NOT the team's to delete, retained). The three `<w>/006-proposal`
  branches are LOCAL-ONLY (their artifact SHAs are archived under
  `refs/archive/006/*` on origin, so the branches are disposable).
- **Worktrees (retained on purpose, round 006 in flight):** primary `longwalk`
  (main); `lw-006-round` (round/006-two-rivers, the integration tree);
  `lw-006-claude`, `lw-006-codex`, `lw-006-agy` (`<w>/006-proposal`, reuse for
  execution doer branches off the round branch). All round-005 worktrees torn down.

## Open escalations to Scott

**None open.** The Meshy-adoption call (1515) becomes an escalation-class
call-out IN decision 009 IF the team chooses a Meshy path; it is not an open
dispute now. A 2-2 four-ballot split in round 006 invokes the critic; a
constitution violation or critic-vs-orchestrator standoff escalates.

## Notes for the next run

**IMMEDIATE NEXT STEP:** begin round-006 EXECUTION (see the "Round 006 EXECUTION
plan" above). Check the `.pka/inbound/orchestrator/` inbox FIRST (per-phase-boundary
rule). Start with defect #4 (null bug, claude, no Meshy needed) and the non-Meshy
scaffolding (agy camera-calibration on primitives + codex scale-contract
validation), which can all proceed without Meshy access. Provision execution doer
branches off `round/006-two-rivers` (the round branch, at `85dc620` + whatever
`main` has advanced to; note main moved past the round-branch base with the
round-005 `.review-passed` and the TEAM-STATE commits, but the round branch was cut
from that same main so it is current). Dispatch, BLOCK/poll each end marker, verify
from disk. If the Meshy-dependent pilot step is reached with no Meshy credentials,
that is a real BLOCKER for Scott (`.pka` request), not a reason to fake the pilot.

**Watch the agy adapter's `--add-dir`** (the adapter now passes it internally at
`adapters/agy.sh:88`; markers still catch a scratch no-op). Verify every dispatch
from `.team/markers/<run_id>-end.md`, not the transcript.

**`gh pr edit` is broken** (GraphQL projectCards deprecation). Use REST
(`gh api -X PATCH repos/sentania-labs/longwalk/pulls/N ...`). `gh pr comment`,
`gh pr merge`, `gh pr view --json` work.

**Dashboard POST** works (token in `/home/scott/.claude/pka-secrets/dashboard-config.md`,
header `X-Bridge-Token`, `--cacert /etc/ssl/certs/sentania.root.pem`). Schema
gaps: no `critic`/`agy` in `DOCUMENT_AUTHORS`, no `agy` in `SIGNOFF_AUTHORS`, no
`implementation`/`done` phase; use the role-brief workarounds (post agy/critic
docs as `author: orchestrator` with a naming line in `body_markdown`; carry an
agy sign-off in `status_note`, not `signoffs[]`). A failed POST never blocks the
protocol.

**RETRO GAP:** inbox-check convention only fires at spawn; directive 1500 asks
for per-phase-boundary re-scans. Honor that every round-006 phase boundary.
Inbox as of this run: 1500 + 1515 PROCESSED into round-006 scope; no unprocessed
message remains.

**Style-rule tension still on `main`, Scott's to rule on:** tracked files with
em-dashes CLAUDE.md forbids (`.pka/CLAUDE.md`, an inbound steering message, a
verbatim critic vote in `docs/decisions/003`). None in an open diff.

**Deferred non-blocking follow-ups:** pin the zoom index remap + epsilon on
bounds assertions; the `check_consensus.py` `covered_entries()` prose-scan bug;
an anchor-drift gate in `process_assets.py`.

---

**Last updated:** 2026-07-17T~20:40Z (orchestrator run
`orchestrator-run-20260717-193928`). This run, end to end: (1) addressed Codex
review rounds 3+4 on PR #21 (four P2s total: agy camera clampfix + drag-threshold,
codex README walk-build + attribution; the walk-build fix bounced once on a
`changes-requested` peer review and was re-fixed with a byte-reproducible
`rebuild_player_walk_option_c.py`); round 5 CLEAN; MERGED PR #21 to main
(`5d83f47`); full close-out sweep (all round+doer branches, worktrees, 9 archive
refs under `refs/archive/005/*`, `.review-passed` at `2805f00`). (2) Ran round 006
phases 1-3 in full: three blind proposals (unanimous Path 3), three adversarial
critiques (genuinely attacking, converged the per-frame-repaint ban), phase-3
synthesis + decision 009 (dual-candidate fidelity pilot + Blender headless, 4-0/4-0,
no dissent, gate-validated), artifact SHAs archived under `refs/archive/006/*`,
round branch pushed. Every dispatch verified from its end marker + the tree. NEXT:
round 006 EXECUTION, starting with the no-Meshy slices (null bug + camera/scale
scaffolding).
