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

**Status:** `ROUND 006, PHASE 2 (adversarial critique) IN FLIGHT. Phase 1 done:
all three blind proposals CONVERGED on Path 3 (3D authored -> pre-rendered
painterly 2D sprites). Three critiques dispatched detached (stamp
20260717-202714). NEXT: poll the three critique end markers, verify from disk,
read them, then run phase 3 (synthesis + four-ballot on the contested
fidelity-recovery sub-question) and write decision 009.`

**Round 006 phase-1 proposal SHAs (local-only proposal branches; ARCHIVE these
under refs/archive/006/* at close):**
| Worker | Proposal | Critique |
| --- | --- | --- |
| claude | `8da1420640a1461b936111e42db7419749490f7f` | (phase 2 in flight) |
| codex | `b707cf7f7e7102ff57e34df0b47377b751f11eea` | (phase 2 in flight) |
| agy | `d6a0f8288ba266ceeda3f0d66afce1b2bdc783cb` | (phase 2 in flight) |

**Phase-1 outcome:** unanimous Path 3. The remaining CONTESTED sub-question for
phase 3 is HOW to recover painterly fidelity from a clean 3D render:
- claude (`8da1420`): a generative REPAINT pass is required (painterly quality is
  a property of the 2D generator, not the 3D render); "3D-as-scaffold,
  2D-as-skin" variant. Deepest proposal (270 lines).
- codex (`b707cf7`): DETERMINISTIC NPR/compositing only; explicitly warns
  per-frame generative repaint causes temporal "boiling." Detailed scale contract
  (1 unit = 1m, player 1.75m, door 2.0m, ridge 4.8-5.6m), Blender offline render,
  strong pilot acceptance gate. Poses key question to Scott: may fidelity depend
  on a deterministic local NPR/compositing pass, or must the raw 3D render meet
  the spike?
- agy (`d6a0f82`): OPTIONAL low-strength img2img stylization (middle position);
  Meshy API + Blender-headless or Godot sub-viewport; claims the 3D->2D pipeline
  tooling slice + the null-bug fast-lane.
Determinism (CLAUDE.md) bears directly on this: a per-frame generative repaint is
a determinism/temporal-coherence risk; a deterministic NPR pass is not. Weigh
that in synthesis. Meshy adoption = escalation-class call-out in decision 009.

## Round 006 next steps (ordered)

1. Poll the three phase-1 end markers; verify each from disk (branch_changed=yes,
   uncommitted=no, cap_expired=no) and read each committed proposal doc. Record
   the three proposal SHAs here.
2. Phase 2 (adversarial critique): dispatch each doer to read the other two
   proposals and genuinely attack them (a "looks good" round is a failed round;
   send it back). Record critique SHAs.
3. Phase 3 (synthesis): rule the production-path question. It is contested, so
   collect FOUR ballots (orchestrator + claude + codex + agy); a 3-1/4-0 decides,
   a 2-2 invokes the critic (`roles/critic.md`, cursor `--mode ask`,
   `--allow-primary`). Record every losing objection VERBATIM in decision 009.
   Meshy adoption (if chosen) is called out to Scott in 009. Divide labor by
   capability (codex seat = sprite-forge mandate).
4. Execution: implement chosen slices on doer branches off `round/006-two-rivers`,
   peer-sign (non-author), `--no-ff` integrate, suite green. Defect #4 (null bug)
   is a plausible parallel FAST-LANE fix; the other three defects follow the
   chosen method.
5. One round PR to main, one external Codex review round, address findings (route
   to owning doer, cross-sign, integrate locally), merge on the ordinary gate,
   then close-out sweep (delete branches + worktrees, archive artifact SHAs under
   `refs/archive/006/*`, write `.review-passed`).

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

## Branch and PR sweep (verified this run, post round-005 merge)

- **Zero open team PRs.**
- **Remote branches:** `origin/main`, `origin/issue-4-world-eras` (a HUMAN branch,
  author sentania, 2026-07-13, no resident prefix, predates the team framework;
  NOT the team's to delete, retained), plus the three `round/006` proposal
  branches are LOCAL-ONLY (not pushed). No stale team branches.
- **Worktrees:** primary `longwalk` (main) + three round-006 proposal worktrees
  (`lw-006-claude`, `lw-006-codex`, `lw-006-agy`). All round-005 worktrees torn
  down.

## Open escalations to Scott

**None open.** The Meshy-adoption call (1515) becomes an escalation-class
call-out IN decision 009 IF the team chooses a Meshy path; it is not an open
dispute now. A 2-2 four-ballot split in round 006 invokes the critic; a
constitution violation or critic-vs-orchestrator standoff escalates.

## Notes for the next run

**IMMEDIATE NEXT STEP:** poll the three round-006 phase-1 end markers
(`lw-006-{claude,codex,agy}/.team/markers/006-*-proposal-*-end.md`), verify each
from disk, read the three proposal docs, record their SHAs, POST the dashboard
snapshot (phase=proposal), then dispatch phase 2 (adversarial critique). If a
proposal marker shows no branch change or uncommitted work, RE-DISPATCH it (the
half-done-dispatch lesson: verify from markers + tree, never narration).

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

**Last updated:** 2026-07-17T~20:22Z (orchestrator run
`orchestrator-run-20260717-193928`). This run: read Codex review round 3 on PR
#21, found TWO P2s, fixed both (agy clampfix + codex readme fix, the latter
bounced once on a `changes-requested` peer review and re-fixed with a
reproducibility script); requested review round 4, found TWO more P2s, fixed both
(agy drag-threshold + codex attribution); review round 5 CLEAN; MERGED PR #21 to
main (`5d83f47`); ran the full close-out sweep (branches, worktrees, archive
refs, `.review-passed` at `2805f00`); processed directives 1500 + 1515;
LAUNCHED round 006 phase 1 (three blind proposals dispatched detached). NEXT:
poll + verify the three proposals, then phase 2 critique.
