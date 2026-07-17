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

**ROUND 005 IS FULLY IMPLEMENTED, INTEGRATED, PUSHED, AND IN EXTERNAL REVIEW.
PR #21 IS OPEN, all four CI gates GREEN, mergeStateStatus CLEAN, MERGEABLE, head
`3513687`. DO NOT MERGE until (a) the external Codex review is fully addressed
(one P1 fixed, TWO P2 findings STILL OUTSTANDING as of this run) AND (b) Scott
accepts the art vibe (subjective gate, not the orchestrator's to decide).**

Round branch `round/005-isometric-art` at **`3513687`** (origin AND local agree).
Five slices landed, each peer-signed by a non-author resident, decision 008
signed 4-0 riding the branch:
- **claude render spine** `e18dc9f` (signed codex `05c1dc0`): iso projection
  module `src/render/iso/projection.gd`, footprint depth sort, KEEP-AUTHORITATIVE
  movement, frozen contract `docs/contracts/iso-projection-contract.md`.
- **agy camera** `1aa290e` (signed claude `a618aa4`): drag-pan, DRAG state +
  threshold, `/zoom` pan, cursor-preserving zoom, clamp to `projected_bounds()`,
  `project.godot` pan_drag binding (008 authorizes the protected path).
- **codex art+pipeline** `49d1796` (signed claude `52999d8`): BOARD-LED gen,
  `ingest_generated_sheet.py`, manifest-driven process/build, OFFLINE-DERIVED
  shadows, five-asset spike + walk GIF. Then `3ac84db` (manifest policy),
  integrated at `63ecca8`.
- **claude facing-fix** `ef83d30` (signed agy `3513687`): addresses Codex review
  ROUND 1 P1 (facing was read from square-space velocity, not projected motion;
  now routes through `IsoProjection` + `facing_octant`, folds 8 octants onto the
  4 shipped walk rows). This is the fix the killed run integrated last.

Round 004 (split) merged to `main` at `7d6100e` (PR #20). `.review-passed` on
main at `7b0fb3d`.

## Codex external review disposition (PR #21)

TWO Codex review rounds have posted:

**Round 1** (reviewed commit `63ecca8`, @2026-07-17T18:54Z): one inline P1 on
`src/render/town/starter_town.gd:326` / `player_controller_2d.gd:188-199` -
facing selected from square-space velocity, not projected motion. **ADDRESSED**
by claude facing-fix `ef83d30`, signed by agy, integrated to `3513687`.

**Round 2** (reviewed commit `3513687`, @2026-07-17T19:10Z): two inline P2s,
**BOTH STILL OUTSTANDING** (this is the immediate work for the next run):
- **P2 `tools/art/capture_player_walk.gd:58`** - idle animation resets
  `_walk_frame` to 0 during capture (spawned player has no route, so
  `_update_walk_animation(delta, false)` fires each physics tick), so the
  acceptance montage repeats frame zero or nondeterministically omits frames.
  Fix: disable the player's physics processing during capture, OR apply the
  requested atlas region AFTER the await. **This corrupts the very walk-cycle
  GIF Scott needs to judge, so it must be fixed AND the GIF regenerated before
  the visual-acceptance artifact goes to Scott.** OWNER: claude (authored the
  render spine + capture retarget).
- **P2 `tools/art/process_assets.py:85`** - making `manifest` positional breaks
  the documented `python3 tools/art/process_assets.py` regeneration command in
  `tools/art/README.md` (now exits in argparse without processing), and the
  README still describes outputs/variants this replacement no longer generates,
  so the documented asset-regen workflow cannot reproduce the live assets. Fix:
  restore a compatible default manifest OR update the invocation + legacy-output
  guidance in the README. OWNER: codex (owns the manifest-driven art pipeline).

Neither P2 is a shipped-game correctness bug, but both are real (P2 #1 blocks a
correct acceptance artifact; P2 #2 breaks determinism-relevant reproducibility),
so both route to their owning doer per decision 004's "address external review
findings, route substantive fixes to the owning doer, integrate signed commits
locally." These are fast-lane targeted fixes (one obvious repair each, no design
choice), dispatched single-worker, then peer-signed by a non-author, merged into
the round branch locally, suite re-run, pushed, and a fresh `@codex review`
requested on the new head.

## Phase

**Status:** `REVIEW. Round fully implemented + integrated + pushed; PR #21 open
and green. Codex review round 1 P1 fixed. Codex review round 2 P2x2 OUTSTANDING
-> dispatch two owner fixes (claude=capture_player_walk.gd, codex=process_assets
.py+README), integrate, re-verify, regenerate walk GIF, re-request review. THEN
hold for Scott's visual acceptance gate (art vibe). Merge is blocked on BOTH the
P2 clearance and Scott's acceptance; the orchestrator does NOT decide the art
taste question.`

## Visual acceptance gate (Scott's, subjective, cannot be self-decided)

Artifacts on the round branch for Scott's eyes:
- `docs/art/player-walk-iso-spike.gif` (walk-cycle GIF - **REGENERATE after the
  P2 #1 capture fix; the current one may repeat frame zero / drop frames**).
- `docs/art/isometric-before-after.png` (before/after vibe).
- `docs/art/iso-five-asset-spike.png` (five-asset spike).
- `docs/art/player-walk-option-c-capture.png`.

Once the two P2s clear and the GIF is regenerated clean, put these in front of
Scott (inbox/dashboard) and HOLD. Do not merge on the orchestrator's own read of
the art. Scott's ruling arrives via the `.pka` inbox.

## Round 005 artifact SHAs (proposal/critique/ballot, local-only branches)

| Worker | Proposal | Critique | Ballot |
| --- | --- | --- | --- |
| claude | `adb79abe62ee1e294bfc22dbe5365b7ac8e4f4dc` | `e54a3358348f09053f1df79355d73f1c807517d6` | `12c328a9fd902285b0784cdc1dd0c416c2d4f041` |
| codex | `b42081c8a328b8caeb3d38b7d4d13fa8cc4f945c` | `dec9f002976d61ea3ff0745e6ef55025db015e1c` | `bdc5c005eaaf2149847787c41956579bb1286128` |
| agy | `35d7d342399c634ad4f132f1600708d6694e6d6c` | `966c4381a0d0b367dc5ba75f1da62b66da68ac66` | `8bcb7c11963a62f3b298ce1e9bccee1886f6d57e` |

Phases 1-3 detail (proposal spread, critique convergences, phantom-file catch,
four-ballot arithmetic 4-0 on all three contested questions, verbatim dissents)
lives in **decision 008** on the round branch. Not duplicated here.

## Round 005 scope

Full-protocol, contested. Authority: decision 007 (isometric + own-art override)
plus Scott's 2026-07-17T17:20Z playtest feedback. What 008 settled: 8 facings
(supersedes 005's cardinal set, though only 4 walk rows ship today - the full
8-facing atlas stays Scott-gated); BOARD-LED generation; KEEP-AUTHORITATIVE
movement; OFFLINE-DERIVED shadows (ground-contact silhouette, not roof pixels);
camera split (agy owns the rig, consumes claude's frozen `projected_bounds()` /
`screen_to_cell()`); corrected pipeline file names. Sim stays square-grid and
projection-ignorant (any `src/sim/` change = wrong slice). No constitution
violation, nothing escalated.

## Active decision records

**`008-isometric-visual-identity.md`** (on `round/005-isometric-art`, signed 4-0,
reaches main via the round PR). Round-005 synthesis. Authorizes the
`project.godot` protected path. Supersedes decision 005's cardinal facing SET.

**`007-isometric-and-own-art-override.md`** (on main via PR #20). Binding record
for the round-004 split and round-005 scope. Supersedes 006 grounds 1
(projection) and 2 (asset pack).

**`006-asset-pack-and-rendering-model.md`** (on main). Grounds 1/2 superseded by
007; 3/4/5 shipped or survive; 6 (shadow masks, regenerate for iso); 7 (facing
set) superseded by 008.

**`004-round-branch-integration-and-voting-model.md`**: round-branch integration,
doers never open PRs, one PR + one external review per round, four-ballot voting
with critic as tiebreaker on a 2-2 split. Governs round 005.

**`005`/`003`/`001`/`002`** stay accepted (002's standing critic vote rescinded by
004; 001's SHAs pinned under `refs/archive/001/*`, never sweep).
**Next free decision number is `009`.**

## Outstanding sign-offs

The two P2 fixes, when built, each need a pre-PR peer sign-off marker under
`.team/signoffs/` from a NON-author resident naming the exact commit, before they
merge into the round branch. Everything already integrated is signed:
render-spine (codex), camera (claude), art-pipeline (claude), facing-fix (agy),
decision 008 (4-0).

## Branch and PR sweep

**Round 005 in flight - branches retained on purpose:**
- `round/005-isometric-art` at `3513687` (local + origin, PR #21 head).
- `claude/005-facing-fix` (`3513687` head incl. signoff), `agy/005-camera`
  (`a618aa4`), `codex/005-art-pipeline` (`52999d8`), `claude/005-render-spine`,
  `claude/005-proposal`, `codex/005-proposal`, `agy/005-proposal` - all local
  doer branches (LOCAL-ONLY per the 2026-07-17T13:10Z Dalinar steer).
- Worktrees: `/home/scott/claude/lw-005-round` (round), `lw-004-claude`,
  `lw-004-codex`, `lw-004-agy` (doer worktrees, reused from 004 naming).
- Two `/tmp/lw-before.*` detached-HEAD worktrees (before-shot captures), harmless.

On the round-005 merge (AFTER P2 clearance + Scott acceptance): delete all round
+ doer branches, tear down the worktrees, pin any 008-cited SHA reachable only
from a deleting branch under `refs/archive/005/*` and push, write `.review-passed`
to main. **One open team PR right now: #21 (intended - the round PR).**

## Open escalations to Scott

**None as an escalation.** The art-vibe visual acceptance gate is a pending
Scott gate, not an open dispute. If a P2 fix surfaces a contested design choice,
re-triage to full protocol; a 2-2 split invokes the critic; a constitution
violation or critic-vs-orchestrator standoff escalates to Scott.

## Notes for the next run

**IMMEDIATE NEXT STEP (if this run did not finish it): dispatch the two Codex
review-round-2 P2 fixes**, each off the round head `3513687` into its own
worktree, blocked-on or detached-and-polled, verified from end markers:
- claude -> `tools/art/capture_player_walk.gd` idle-animation-during-capture fix
  (disable physics processing during capture OR apply region after the await).
  New branch `claude/005-capture-fix`.
- codex -> `tools/art/process_assets.py` positional-manifest + `README.md` drift
  fix (restore a default manifest OR fix the documented invocation + outputs).
  New branch `codex/005-manifest-doc-fix`.
Then cross-sign (non-author each), merge both signed commits into the round
branch locally, re-run the suite, push, request a fresh `@codex review`, and
REGENERATE `docs/art/player-walk-iso-spike.gif` with the fixed capture tool.
THEN produce the Scott visual-acceptance package and HOLD. Do not merge on the
orchestrator's own art read.

**Watch the agy adapter's `--add-dir`** (silent scratch no-op otherwise; markers
catch it). Verify every dispatch from `.team/markers/<run_id>-end.md`
(`branch_changed`, `uncommitted_work`, `cap_expired`), not the transcript.

**RETRO GAP still open:** inbox-check convention only fires at spawn, so mid-run
Scott steers can sit unread. Fix candidates for the retro: per-phase-transition
inbox re-scan, or a vault-side ping to the active run. Brief is not the team's to
edit; this is a note.

**`gh pr edit` is broken** by a GitHub GraphQL projectCards deprecation. Use REST
(`gh api -X PATCH repos/sentania-labs/longwalk/pulls/N ...`). `gh pr comment`,
`gh pr merge`, `gh pr view --json` all work. Transient TLS-handshake timeouts on
`gh` seen this run; retry.

**Dashboard POST works** (token in
`/home/scott/.claude/pka-secrets/dashboard-config.md`, header `X-Bridge-Token`,
`--cacert /etc/ssl/certs/sentania.root.pem`). Schema gaps: no `critic`/`agy` in
`DOCUMENT_AUTHORS`, no `agy` in `SIGNOFF_AUTHORS`, no `implementation`/`done`/
`review-in-progress` phase. Post agy/critic docs as `author: orchestrator` with
the real author named in `body_markdown`; name agy sign-offs in `status_note`.

**Style-rule tension still on `main`, Scott's to rule on:** tracked files with
em-dashes CLAUDE.md forbids (`.pka/CLAUDE.md`, an inbound steering message, a
verbatim critic vote in `docs/decisions/003-village-feel.md`). None in an open
diff. Likely fix is a constitution carve-out for quoted/inbound text.

**Inbox note:** the three files in `.pka/inbound/orchestrator/` dated 1625/1645/
1720 are the OLD rulings that created round 005 (already folded into decision 007
+ the phase-1 prompt). Not new. No new Scott message this run.

**Zombie process cleanup:** this run killed a 4-hour hung `godot --headless`
test (`test_player_zoom.gd`, pid 2952326) left in `lw-004-agy` by a long-dead agy
dispatch. Watch for these after cap-killed dispatches.

**Deferred non-blocking follow-ups:** pin the zoom index remap + epsilon on bounds
assertions; the `check_consensus.py` `covered_entries()` prose-scan bug; an
anchor-drift gate in `process_assets.py` (may fold into the P2 #2 fix).

---

**Last updated:** 2026-07-17T~19:12Z (orchestrator run
`orchestrator-run-20260717-191022`, respawn after the prior run hit the 5400s
cap mid-write on this file). This run: reconciled the half-written TEAM-STATE
against verified reality (round fully integrated + pushed at `3513687`, PR #21
CLEAN/MERGEABLE, all CI green); confirmed Codex review round 1 P1 was fixed +
signed + integrated (facing-fix `ef83d30`); found Codex review round 2's two P2s
still outstanding; killed a 4-hour zombie godot test. NEXT: dispatch the two P2
owner fixes, integrate, regenerate the walk GIF, then hold for Scott's art
acceptance. Merge blocked on both.
</content>
</invoke>
