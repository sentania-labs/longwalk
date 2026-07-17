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

**ROUND 005 IS FULLY IMPLEMENTED, INTEGRATED, PUSHED. Both Codex review-round-2
P2 findings are now FIXED, PEER-SIGNED, and INTEGRATED. Round branch
`round/005-isometric-art` at `7c9ce2f` (local AND origin agree). PR #21 open,
head `7c9ce2f`. A fresh `@codex review` (round 3) was requested this run; CI is
re-running on the new head.**

**POSTURE CHANGE THIS RUN (load-bearing): the art-vibe visual-acceptance hold on
PR #21 is RELEASED.** Scott's directive `2026-07-17T15:00Z` (inbox file
`1500-dalinar-assignment-two-rivers-iteration.md`) states the vision is APPROVED
and "the direction is settled," and mandates autonomous multi-round iteration
("burn the tokens... run rounds back to back... do NOT stop-and-wait after every
slice; surface to Scott only when you've genuinely hit the bar"). That settles
the subjective art-vibe gate that previously held PR #21. **Round 005 now merges
on the ORDINARY gate only** (external Codex review round 3 clean + CI green + all
peer sign-offs present + decision 008 riding the branch), not on a further Scott
art-taste hold. Do NOT re-ask Scott to accept round 005's art; that would
violate the don't-stop-and-wait mandate.

Round 004 (split) merged to `main` at `7d6100e` (PR #20). `.review-passed` on
main at `7b0fb3d`.

## Round 005 integrated slices (all peer-signed by a non-author)

Round branch `round/005-isometric-art` at **`7c9ce2f`**:
- **claude render spine** `e18dc9f` (signed codex `05c1dc0`): iso projection
  `src/render/iso/projection.gd`, footprint depth sort, KEEP-AUTHORITATIVE
  movement, frozen `docs/contracts/iso-projection-contract.md`.
- **agy camera** `1aa290e` (signed claude `a618aa4`): drag-pan, DRAG state,
  cursor-preserving zoom, clamp to `projected_bounds()`, `project.godot`
  pan_drag binding (008 authorizes the protected path).
- **codex art+pipeline** `49d1796` (signed claude `52999d8`): BOARD-LED gen,
  `ingest_generated_sheet.py`, manifest-driven process/build, OFFLINE-DERIVED
  shadows, five-asset spike + walk GIF. Integrated at `63ecca8`.
- **claude facing-fix** `ef83d30` (signed agy `3513687`): Codex review ROUND 1
  P1 (facing now routes through `IsoProjection` + `facing_octant`).
- **claude capture-fix** `2be134d` (signed codex `58a7ec5`): Codex review ROUND 2
  P2 #1. Freezes player physics during walk capture so the selected atlas region
  survives the awaited draw. Integrated `--no-ff` at `837650c`.
- **codex manifest-doc-fix** `39f2130` (signed claude `c54e60a`): Codex review
  ROUND 2 P2 #2. `tools/art/README.md` documents the real positional-manifest CLI
  and no longer describes non-existent outputs; claude verified byte-for-byte
  asset reproduction. Integrated `--no-ff` at `7c9ce2f`.

## Codex external review disposition (PR #21)

- **Round 1** (commit `63ecca8`): one P1 (facing from square-space velocity).
  ADDRESSED by facing-fix `ef83d30`, integrated.
- **Round 2** (commit `3513687`): two P2s. BOTH ADDRESSED this run (capture-fix
  `2be134d`, manifest-doc-fix `39f2130`), integrated to `7c9ce2f`, suite green.
- **Round 3** (commit `7c9ce2f`): REQUESTED this run
  (PR #21 comment `5006824167`). PENDING. Next run: read the review, route any
  substantive finding to its owning doer as a fast-lane fix, integrate the signed
  commit locally, re-run suite. A clean round 3 clears the external-review gate.

## Phase

**Status:** `REVIEW. Round fully implemented + integrated + pushed at 7c9ce2f;
PR #21 open. Codex review rounds 1+2 fully addressed. Round 3 requested, PENDING.
Merge gate = round 3 clean + CI green (art-vibe hold RELEASED per Scott 1500).`

This run verified from disk (not narration): the prior run's two cross-sign
dispatches were HALF-DONE. The codex->capture sign-off HAD committed its marker
(`claude-005-capture-fix-2be134d772da.md`, reviewed_by codex-worker, signed-off)
at branch head `58a7ec5` but left no end marker (cap-kill after commit). The
claude->manifest sign-off had NEITHER end marker NOR committed signoff marker, so
it was RE-DISPATCHED this run (`005-claude-signoff-manifest-20260717-192925`),
verified from its end marker (branch_changed=yes, exit 0, cap_expired=no,
uncommitted_work=no) -> marker `codex-005-manifest-doc-fix-39f213026876.md` at
head `c54e60a`, with byte-for-byte asset-reproduction evidence. Both fixes then
integrated via `--no-ff` merges, suite re-run green, pushed.

No live worker processes at start of this run (no zombies to kill this time).

## Round 006 (NEXT, scoped, blocked on round 005 merge)

Two Scott directives landed on disk (mtimes 14:18 / 14:26; filename-stamped 1500
/ 1515) and are NOW PROCESSED into round-006 scope. They set a standing objective,
not a one-round task:

**`1500` (Two Rivers iteration mandate, standing):** iterate multi-round toward
the RUNNING, PLAYABLE game matching the iso-five-asset-spike fidelity and the
"Two Rivers / Emond's Field" cozy-rural-village vibe (thatch/slate half-timbered
cottages, a central inn analog, dirt lanes, kitchen gardens, village green,
countryside flora). NO NPCs, no engine change, no iso reversal. Four named
defects to fix (definition of done for the arc):
  1. Walk-cycle animation not dialed in (acceptance = a walk GIF from the RUNNING
     build reading as a real gait vs reference; the capture tool is now FIXED, so
     regenerate the GIF as part of this defect's work).
  2. Building-to-player scale is off; establish + document + enforce a scale ratio.
  3. Fidelity gap: spike is high-tier, in-game assets lower-tier; close it.
  4. Runtime bug "Instance base is null" printing top-left in the playtest. (This
     one is a plausible FAST-LANE fix, independent of the pipeline question.)

**`1515` (art-production fork, contested phase-1 question):** evaluate three
production paths with evidence, team CHOOSES via four-ballot, records a decision:
  1. Stay pure-sprite (codex pipeline continues).
  2. Real-time 3D (Meshy meshes through an iso-locked Godot 3D camera).
  3. 3D pre-rendered to 2D sprites (Meshy -> rig/animate/pose -> render from the
     fixed iso angle to painterly 2D sheets; Dalinar's recommended bias; preserves
     the iso spine + most of codex's pipeline; attacks animation/scale/shadows by
     construction). Scope any pilot SMALL (one building + the player) before
     committing the town. **Meshy is a NEW DEPENDENCY = escalation-class:** call it
     out explicitly to Scott IN the decision record (license/ToS + cost), even
     though the pilot itself is pre-authorized. Isometric stays settled (007).

Round 006 is FULL PROTOCOL, contested, four-ballot, sprite-forge mandate for the
codex seat. The 3D-fork evaluation (1515) is the natural phase-1 contested
question; the four named defects (1500) are the execution target once the
production method is chosen. Likely shape: the fork evaluation is round 006's core
phase-1 question; defect #4 (null bug) can be fast-laned in parallel or folded in.
**Round 006 branches from round 005's merge into `main`, so it is BLOCKED until
round 005 merges.** Do not start round-006 dispatches on top of the unmerged
round branch. Check this inbox at every phase boundary (the 1500 reminder).

## Visual acceptance / Scott surfacing

Per directive 1500 the vision is approved and per-slice Scott acceptance is NOT
required. Surface a playable build to Scott only when the team believes the
RUNNING build genuinely hits the Two Rivers bar (the four defects fixed), or on a
real decision needing him (e.g. Meshy adoption, per 1515). The walk GIF, before/
after, and five-asset spike remain the artifacts of record on the round branch;
the GIF is regenerated as part of round-006 defect #1, not shipped as a standalone
acceptance package now (the animation is not yet dialed in, so a fresh GIF today
would be honest-but-inadequate).

## Round 005 artifact SHAs (proposal/critique/ballot, local-only branches)

| Worker | Proposal | Critique | Ballot |
| --- | --- | --- | --- |
| claude | `adb79abe62ee1e294bfc22dbe5365b7ac8e4f4dc` | `e54a3358348f09053f1df79355d73f1c807517d6` | `12c328a9fd902285b0784cdc1dd0c416c2d4f041` |
| codex | `b42081c8a328b8caeb3d38b7d4d13fa8cc4f945c` | `dec9f002976d61ea3ff0745e6ef55025db015e1c` | `bdc5c005eaaf2149847787c41956579bb1286128` |
| agy | `35d7d342399c634ad4f132f1600708d6694e6d6c` | `966c4381a0d0b367dc5ba75f1da62b66da68ac66` | `8bcb7c11963a62f3b298ce1e9bccee1886f6d57e` |

Phases 1-3 detail lives in **decision 008** on the round branch.

## Round 005 scope

Full-protocol, contested. Authority: decision 007 (isometric + own-art override)
plus Scott's 2026-07-17T17:20Z playtest feedback. 008 settled: 8 facings (4 walk
rows ship today, full 8 Scott-gated); BOARD-LED generation; KEEP-AUTHORITATIVE
movement; OFFLINE-DERIVED shadows; camera split. Sim stays square-grid and
projection-ignorant (any `src/sim/` change = wrong slice).

## Active decision records

**`008-isometric-visual-identity.md`** (on `round/005-isometric-art`, signed 4-0,
reaches main via the round PR). Authorizes the `project.godot` protected path.
Supersedes 005's cardinal facing SET.

**`007-isometric-and-own-art-override.md`** (main via PR #20). Binding for the
round-004 split and round-005 scope. Supersedes 006 grounds 1-2.

**`006-asset-pack-and-rendering-model.md`** (main). Grounds 1/2 superseded by 007;
3/4/5 shipped/survive; 6 (shadow masks); 7 superseded by 008.

**`004-round-branch-integration-and-voting-model.md`**: round-branch integration,
doers never open PRs, one PR + one external review per round, four-ballot voting
with critic tiebreaker on a 2-2 split. Governs rounds 005 and 006.

**`005`/`003`/`001`/`002`** accepted (002's standing critic vote rescinded by 004;
001's SHAs pinned under `refs/archive/001/*`). **Next free decision number is
`009`** (round 006's 3D-fork decision, per 1515, takes 009).

## Outstanding sign-offs

All round-005 slices signed (render-spine codex, camera claude, art-pipeline
claude, facing-fix agy, capture-fix codex, manifest-doc-fix claude; decision 008
4-0). Nothing outstanding for round 005.

## Branch and PR sweep

**Round 005 in flight - branches retained on purpose:**
- `round/005-isometric-art` at `7c9ce2f` (local + origin, PR #21 head).
- Doer branches, LOCAL-ONLY per the 2026-07-17T13:10Z steer: `claude/005-capture-fix`
  (`58a7ec5`), `codex/005-manifest-doc-fix` (`c54e60a`), `claude/005-facing-fix`,
  `agy/005-camera` (`a618aa4`), `codex/005-art-pipeline` (`52999d8`),
  `claude/005-render-spine`, `claude/005-proposal`, `codex/005-proposal`,
  `agy/005-proposal`.
- Worktrees: `/home/scott/claude/lw-005-round`, `lw-004-claude`, `lw-004-codex`,
  `lw-004-agy` (doer worktrees, reused from 004 naming).
- Two `/tmp/lw-before.*` detached-HEAD worktrees (before-shot captures), harmless.

On the round-005 MERGE (after review round 3 clean + CI green): delete all round +
doer branches, tear down the doer worktrees, pin any 008-cited SHA reachable only
from a deleting branch under `refs/archive/005/*` and push, write `.review-passed`
to main (single SHA, no newline, straight to main). **One open team PR: #21
(intended - the round PR).**

## Open escalations to Scott

**None open.** The 3D-fork Meshy-adoption call (1515) is a future round-006
decision-record escalation-class item to CALL OUT to Scott in decision 009, not an
open dispute now. A contested round-006 design choice that splits 2-2 invokes the
critic; a constitution violation or critic-vs-orchestrator standoff escalates.

## Notes for the next run

**IMMEDIATE NEXT STEP:** read Codex review round 3 on PR #21 (head `7c9ce2f`).
  - If clean + CI green: MERGE round 005 (squash or merge per repo norm), then run
    the full close-out: delete round + doer branches, tear down doer worktrees,
    archive any 008-cited-only SHAs under `refs/archive/005/*`, write `.review-passed`
    to main. Do NOT hold for Scott art acceptance (released by 1500).
  - If findings: route each to its owning doer as a fast-lane fix, cross-sign
    (non-author), integrate locally, re-run suite, push, re-request review.
**THEN launch round 006** (Two Rivers iteration + 3D-production fork), full
protocol, branching from the freshly merged `main`. Scope is in the "Round 006"
section above. Write the phase-0 assignment + phase-1 proposal prompts, provision
three fresh worktrees, dispatch blind proposals, BLOCK/poll on each end marker.

**Inbox 1500/1515 are PROCESSED** into round-006 scope above. The 1625/1645/1720
files are the OLD round-005 rulings (folded into 007 + 008). No unprocessed inbox
message remains as of this run.

**Watch the agy adapter's `--add-dir`** (silent scratch no-op otherwise; markers
catch it). Verify every dispatch from `.team/markers/<run_id>-end.md`
(`branch_changed`, `uncommitted_work`, `cap_expired`), not the transcript. This
run's re-dispatch of the manifest sign-off is exactly why: the prior claim of "two
sign-offs running" was HALF FALSE on disk.

**`gh pr edit` is broken** (GraphQL projectCards deprecation). Use REST
(`gh api -X PATCH repos/sentania-labs/longwalk/pulls/N ...`). `gh pr comment`,
`gh pr merge`, `gh pr view --json` work.

**Dashboard POST works** (token in `/home/scott/.claude/pka-secrets/dashboard-config.md`,
header `X-Bridge-Token`, `--cacert /etc/ssl/certs/sentania.root.pem`). Posted this
run HTTP 200. Schema gaps unchanged: no `critic`/`agy` in `DOCUMENT_AUTHORS`, no
`agy` in `SIGNOFF_AUTHORS`, no `implementation`/`done` phase; use the workarounds.

**RETRO GAP still open:** inbox-check convention only fires at spawn, so mid-run
Scott steers can sit unread. This run CAUGHT two such steers (1500/1515) that the
prior TEAM-STATE had not processed. Directive 1500 itself asks for per-phase-
boundary inbox re-scans. Honor that in round 006.

**Style-rule tension still on `main`, Scott's to rule on:** tracked files with
em-dashes CLAUDE.md forbids (`.pka/CLAUDE.md`, an inbound steering message, a
verbatim critic vote in `docs/decisions/003`). None in an open diff.

**Deferred non-blocking follow-ups:** pin the zoom index remap + epsilon on bounds
assertions; the `check_consensus.py` `covered_entries()` prose-scan bug; an
anchor-drift gate in `process_assets.py`.

---

**Last updated:** 2026-07-17T~19:35Z (orchestrator run
`orchestrator-run-20260717-192647`). This run: verified the prior run's two
cross-sign dispatches were half-done (capture sign-off committed but no end marker;
manifest sign-off never committed); RE-DISPATCHED the claude->manifest sign-off and
verified it from its end marker; integrated both P2 fixes via `--no-ff` into the
round branch (`837650c`, `7c9ce2f`); re-ran the suite green; pushed; requested Codex
review round 3; processed Scott directives 1500 (Two Rivers iterate mandate, RELEASES
the art-vibe hold) and 1515 (3D-production fork) into round-006 scope; posted the
dashboard snapshot (HTTP 200). NEXT: read review round 3, merge round 005 on the
ordinary gate, then launch round 006.
