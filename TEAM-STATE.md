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

**ROUND 004 IS MERGED AND CLOSED. ROUND 005 PHASE-3 SYNTHESIS IS COMPLETE:
decision 008 authored and SIGNED 4-0 by all three workers on the round branch.
NEXT PHASE IS IMPLEMENTATION (execution), not yet dispatched.**

Round 004 (split) merged to `main` at merge commit **`7d6100e`** (PR #20), the
projection-agnostic survivors only: road-weighted routing (req 4) and the camera
rig (req 5). Decisions 006 and 007 rode the merge to main. The `.review-passed`
marker recording the merge is on main at **`7b0fb3d`** (40 bytes, no newline).
All round-004 branches and the round branch are deleted, worktrees reused for
round 005. See the sweep section.

Round 005 (the art re-plan under Scott's isometric + own-art override, plus his
playtest 1720 camera refinement) is now in **phase 1: blind proposal**, three
dispatches running. See Phase.

## Phase

**Status:** `phase-3 SYNTHESIS COMPLETE 2026-07-17T~17:33Z. Decision 008
committed + signed 4-0 on round/005-isometric-art (e51d4d0 authored, 43459d4
signed). NEXT: phase-3 IMPLEMENTATION, sequenced (see "Implementation plan").`

**DECISION 008 is landed and gate-ready** on `round/005-isometric-art` (local
only, not pushed per the doer-branch-local steer; reaches origin when the round
PR opens). Ballots were 4-0 on all three contested questions, so the critic seat
was correctly NOT invoked. Worker sign-offs on 008 (real timestamps, collected
in a sign-off dispatch): claude `17:32:54Z`, codex `17:32:50Z`, agy `17:33:04Z`.

**Round 005 artifact SHAs (all local-only branches, shared object store):**

| Worker | Proposal | Critique | Ballot |
| --- | --- | --- | --- |
| claude | `adb79abe62ee1e294bfc22dbe5365b7ac8e4f4dc` | `e54a3358348f09053f1df79355d73f1c807517d6` | `12c328a9fd902285b0784cdc1dd0c416c2d4f041` |
| codex | `b42081c8a328b8caeb3d38b7d4d13fa8cc4f945c` | `dec9f002976d61ea3ff0745e6ef55025db015e1c` | `bdc5c005eaaf2149847787c41956579bb1286128` |
| agy | `35d7d342399c634ad4f132f1600708d6694e6d6c` | `966c4381a0d0b367dc5ba75f1da62b66da68ac66` | `8bcb7c11963a62f3b298ce1e9bccee1886f6d57e` |

## Implementation plan (phase-3 execution, next run's job)

Decision 008 is the frozen authority. All slices branch from
`round/005-isometric-art` (currently at `43459d4`). The slices have a real
dependency order, so DO NOT fire all three in parallel blind:

1. **claude first (render spine + frozen contracts).** iso projection module
   under `src/render/...` (`cell_to_screen`, `screen_to_cell`,
   `projected_bounds()` from the four projected diamond corners), footprint-aware
   y-sort + stable placement-id tie key, KEEP-AUTHORITATIVE movement (retain
   `move_and_slide`/collider contract, project a render proxy), `starter_town.gd`
   render rework, `capture_player_walk.gd` acceptance-capture retarget. This
   FREEZES the projection<->camera contract agy consumes and the anchor
   convention codex generates against. Sim untouched (any `src/sim/` change =
   wrong slice).
2. **agy + codex in parallel, AFTER step 1's contract lands.**
   - agy: camera drag-pan rework consuming `projected_bounds()`/`screen_to_cell()`
     - DRAG state, click-vs-drag threshold, `relative/zoom` pan, RETIRE
     `focus_view` primary verb, cursor-preserving zoom, clamp to projected bounds,
     `project.godot` `pan_drag` binding. (project.godot is the ONE protected path;
     008 authorizes it.)
   - codex: BOARD-LED generation + pipeline - style board, category sheets,
     individual buildings, 8 per-facing walk grids, NEW
     `tools/art/ingest_generated_sheet.py`, manifest-drive `process_assets.py`/
     `build_player_walk.py`, OFFLINE-DERIVED shadow masks (cast from
     ground-contact silhouette, NOT the roof pixels), retarget `check_walk_sheet.py`,
     author walk/before-after GIF producers fresh. Sprite-forge mandate; retro
     reports whether `$generate2dsprite`/`$generate2dmap` helped.
3. **Integration + gates.** Each slice needs a pre-PR peer sign-off marker under
   `.team/signoffs/` from a NON-author resident naming the exact commit. Merge
   the signed commits locally into the round branch (no rebase of a signed
   branch), run the suite on the integrated branch, then open the ONE round PR to
   main (008 rides it; consensus gate checks 008 covers project.godot). One
   external Codex review round. THEN Scott's visual acceptance gate (iso
   walk-cycle GIF + before/after vibe screenshots) - the taste gate no automated
   check substitutes for; put one building + player + contact shadow in front of
   Scott EARLY (the five-asset spike), not a full town late.

De-risk before final generation: freeze the manifest/anchor contract between
claude (consumer) and codex (generator). The round-004 P2 capture-tool node-path
fix (`capture_player_walk.gd` calling `player.get_node("Camera2D")` after the
camera moved to `World/CameraRig2D`) folds into claude's capture-retarget work.

Round branch **`round/005-isometric-art`** off main at `7b0fb3d`. Three proposal
branches off it, all started at `7b0fb3d` (verified identical blind start).

Phases 1-3 detail (proposal spread, critique convergences, the phantom-files
catch, the four-ballot arithmetic, verbatim dissents) is fully recorded in
**decision 008** on the round branch; TEAM-STATE does not duplicate it. The
artifact SHAs are in the table above. What 008 settled, in one breath: 8 facings
(supersedes 005's cardinal set); BOARD-LED generation; KEEP-AUTHORITATIVE
movement; OFFLINE-DERIVED shadows (cast from ground-contact silhouette, not roof
pixels); camera split (agy owns the rig, consumes claude's frozen
`projected_bounds()`/`screen_to_cell()`); the corrected pipeline file names (no
`ingest_kenney_roguelike.py`/`build_walk_comparison.py`/`capture_art_acceptance.gd`
exist; create a new generic ingest, retarget the real files). No constitution
violation, so nothing escalated.

## Round 005 scope

Full-protocol, contested. Authority: decision 007 (isometric + own-art override)
plus Scott's 2026-07-17T17:20Z playtest feedback (`1720-...-playtest-feedback`),
which is folded into the phase-1 prompt.

Fixed by Scott, not up for debate: isometric projection (sim stays square-grid
and projection-ignorant, ALL iso math render-side, any `src/sim/` change = wrong
slice); own generated art only (no third-party pack ships; reference folder is
the bar and reference-only); sprite-forge mandate (codex exercises
`$generate2dsprite` / `$generate2dmap`, retro reports if it helped).

Genuinely contested (phase-1 blind questions, per decision 007 + 1720):
1. Generation method for coherent iso sheets (full-sheet coherent vs. per-asset
   with a shared palette/lighting harness).
2. Iso facing count (4 diagonal min vs. 8 preferred) + frame-selection policy
   fixed in code before generation. Supersedes decision 005's cardinal facing
   set; round-005 decision (008) records that supersession.
3. Repurposing the ingest pipeline (`ingest_kenney_roguelike.py` + generic
   `process_assets.py` / `build_player_walk.py` / `build_walk_comparison.py` /
   `capture_art_acceptance.gd`) to ingest OUR generated sheets.
4. Iso shadow-mask + grounding/contact-shadow (006 grounds 6, 7, regenerated for
   iso) + the render-side camera iso-picking amendment.
5. **Camera drag-pan (Scott's 1720 refinement):** replace round-004's
   right-click point-recenter with map PANNING. Preference order: (a)
   right-click-DRAG to scroll = the requirement now; (b) scroll/edge-based
   panning as alternative; (c) minimap-click recenter = design seed for later,
   NOT this round. Round 004's `CameraRig2D` is the base to rework, not discard.
   `project.godot` input-map changes in scope for the drag binding.

Carries reqs 1 (walk cycle, iso), 2 (art vibe), 3 (flora, hard), 6 (building
silhouette shadows), 7 (grounding + contact shadow), the render flip (now iso
sheets), the camera iso-picking + drag-pan rework, and the repurposed ingest
pipeline. **Scott's visual acceptance gate belongs to this round** (iso
walk-cycle GIF + before/after vibe screenshots). Its decision record is **008**
(authored at synthesis, with four ballots + both agents' sign-offs before its
protected-path work merges). Its own PR, its own external review.

## What this run did

Ran round 005 from a stalled phase-1 all the way through a signed phase-3
synthesis.

1. Checked the inbox: nothing newer than 1720 (already folded into the phase-1
   prompt by the prior run). Read TEAM-STATE.
2. **Caught and repaired a phase-1 stall.** The prior run "detached" the claude
   and codex proposal dispatches but they did NOT survive its turn (start markers,
   no end markers, no live process, branches still at `7b0fb3d`); only agy's
   proposal (`35d7d34`) had landed. Re-dispatched claude + codex in parallel,
   blocking in one tool call; both landed (`adb79ab`, `b42081c`). Verified from
   end markers, not transcripts. codex's `exit_code=1` was CLI noise on a clean
   commit (`branch_changed=yes`, no uncommitted work).
3. **Phase 2 (adversarial critique):** dispatched all three, blocking. Genuinely
   adversarial round (`e54a335`/`dec9f00`/`966c438`), with real concessions
   (claude conceded 8 facings + Y-sort + camera-bounds; camera-ownership split
   went unanimous) and a load-bearing catch (all three named phantom pipeline
   files; orchestrator-verified against the base).
4. **Phase 3 (four-ballot vote)** on the three questions still contested after
   critique. Result **4-0 on all three** (BOARD-LED, KEEP-AUTHORITATIVE,
   OFFLINE-DERIVED). No 2-2 split, so the critic seat was correctly not invoked.
5. **Authored decision 008** (synthesis + verbatim abandoned positions + all four
   ballots + capability division of labor), committed to the round branch
   (`e51d4d0`), then collected genuine worker sign-offs in a sign-off dispatch and
   applied them (`43459d4`). 008 is signed 4-0 and gate-ready.
6. Posted the phase-3 snapshot to the dashboard (200, 7 documents). Cleaned agy's
   untracked scratch peer-copies. Did NOT dispatch phase-3 implementation (it is
   sequenced claude-first and is the next run's job; see "Implementation plan").

## Active decision records

**`007-isometric-and-own-art-override.md`** (now on main via PR #20 merge),
accepted by Scott's authority. Binding record for the round-004 split and the
round-005 scope. Supersedes 006 grounds 1 (projection) and 2 (asset pack); maps
survival/amendment of 3-8.

**`006-asset-pack-and-rendering-model.md`** (on main), accepted 4-0. Grounds 1
and 2 superseded by 007; grounds 3 (render flip, iso-targeted), 4 (road costs,
SHIPPED in round 004), 5 (camera, SHIPPED in round 004), 6 (shadow masks,
regenerate for iso), 7 (facing set superseded), 8 survive per 007's map.

**`004-round-branch-integration-and-voting-model.md`**: round-branch integration,
doers never open PRs, one PR + one external review per round, four-ballot voting
with critic as tiebreaker on a 2-2 split. Governs round 005.

**`008-isometric-visual-identity.md`** (on `round/005-isometric-art`, signed 4-0,
NOT yet on main; reaches main via the round PR). Round-005 synthesis: 8 facings,
BOARD-LED generation, KEEP-AUTHORITATIVE movement, OFFLINE-DERIVED shadows, the
camera/projection split, the corrected pipeline file names. Authorizes the
`project.godot` protected path. Supersedes decision 005's cardinal facing SET.

**`005-walk-cycle-generation-topology.md`**: method stands (per-facing gen,
colored boots, deterministic assembly); its cardinal facing SET is now superseded
by decision 008 (8 facings). **`003-village-feel`**, **`001-town-motion`**,
**`002-team-roster-and-critic-seat`** stay accepted (002's standing critic vote
rescinded by 004; 001's SHAs pinned under `refs/archive/001/*`, never sweep).
**Next free decision number is `009`.**

## Outstanding sign-offs

**None owed right now.** Decision 008 is signed 4-0 (claude/codex/agy, real
timestamps on the record). Round 005's IMPLEMENTATION slices, when built, each
need a pre-PR peer sign-off marker under `.team/signoffs/` from a NON-author
resident naming the exact commit, before the round PR merges. Those do not exist
yet because implementation is not dispatched.

## Branch and PR sweep (end-of-round-004 state)

**Round 004 sweep is CLEAN.** Zero open team PRs. Zero stale team branches
(verified: no local `004`/`round` branches, no origin `round/004` or `/004-`
branches). Round-004 artifacts preserved on origin under `refs/archive/004/*`
(claude/codex/agy proposal + critique, and the four dropped-slice SHAs cited by
007). PR #20 merged at `7d6100e`.

**Round 005 branches now live (retained on purpose, round in flight):**
- `round/005-isometric-art` (local, now `43459d4`: 008 authored + signed). NOT
  yet on origin (per the Dalinar 2026-07-17T13:10Z steer, only the round branch
  reaches GitHub, and only when its PR opens; doer branches are LOCAL-ONLY).
  Worktree: `/home/scott/claude/lw-005-round` (created this run for the
  orchestrator to commit 008; retain until the round closes).
- `claude/005-proposal` (`12c328a`), `codex/005-proposal` (`bdc5c00`),
  `agy/005-proposal` (`8bcb7c1`) (local-only): each now carries its proposal +
  critique + ballot commits. Worktrees `/home/scott/claude/lw-004-{claude,codex,agy}`
  (named for 004, reused for 005).
- Two `/tmp/lw-before.*` detached-HEAD worktrees also exist (before-shot
  captures); harmless, left as-is.

Zero open team PRs (the round PR does not open until implementation integrates).
On the round-005 merge, sweep the same way: delete all round + doer branches,
tear down the four worktrees, pin any 008-cited SHA reachable only from a
deleting branch under `refs/archive/005/*` and push, write `.review-passed` to
main.

## Open escalations to Scott

**None live.** Isometric and asset-sourcing are both resolved (decision 007).
Round 005's art carries a Scott visual acceptance gate when built, but that is a
future gate, not an open escalation. If phase-2 critique or synthesis surfaces a
2-2 contested question, the critic seat breaks it (decision 004); a claimed
constitution violation or a critic-vs-orchestrator standoff escalates to Scott.

## Notes for the next run

**IMMEDIATE NEXT STEP: dispatch phase-3 IMPLEMENTATION, sequenced** (see the
"Implementation plan" section). claude first to freeze the projection<->camera
and anchor contracts; THEN agy (camera) + codex (generation+pipeline) in
parallel against them. Each slice into its own worktree, blocked-on or
detached-and-polled, verified from end markers (not transcripts). Decision 008 is
the frozen authority; it is already signed 4-0. Watch the agy adapter's
`--add-dir` (silent scratch no-op otherwise; the markers catch it). Art
generation is the long, Scott-gated pole; put the five-asset spike in front of
Scott early.

**RETRO GAP still open (do not fix mid-round):** the inbox-check convention only
fires at spawn, so mid-run Scott steers can sit unread (this is how 1625/1645 sat
two runs, and 1720 arrived after those). This run caught 1720 only because the
respawn prompt told it to re-check. Fix candidates for the retro: per-phase-
transition inbox re-scan, or a vault-side ping to the active run. Brief is not
the team's to edit; this is a note.

**`gh pr edit` is broken by a GitHub GraphQL projectCards deprecation.** Use REST
(`gh api -X PATCH repos/sentania-labs/longwalk/pulls/N ...`). `gh pr comment`,
`gh pr merge`, `gh pr view --json` all work.

**Dashboard POST works** (token in `/home/scott/.claude/pka-secrets/dashboard-config.md`,
header `X-Bridge-Token`, `--cacert /etc/ssl/certs/sentania.root.pem`). Schema
gaps: no `critic`/`agy` in `DOCUMENT_AUTHORS`, no `agy` in `SIGNOFF_AUTHORS`, no
`implementation`/`done` phase. Post agy/critic docs as `author: orchestrator`
with the real author named in `body_markdown`; name agy sign-offs in
`status_note`, never mislabel them in `signoffs[]`.

**Style-rule tension still on `main`, Scott's to rule on:** tracked files with
em-dashes CLAUDE.md forbids (`.pka/CLAUDE.md`, an inbound steering message, a
verbatim critic vote in `docs/decisions/003-village-feel.md`). None in an open
diff. Likely fix is a constitution carve-out for quoted/inbound text, not the
team's to edit.

**Deferred non-blocking follow-ups** (carried forward): the round-004 P2 capture
tool node-path fix (fold into 008's pipeline slice); pin the zoom index remap +
epsilon on bounds assertions; the `check_consensus.py` `covered_entries()`
prose-scan bug; an anchor-drift gate in `process_assets.py`.

---

**Last updated:** 2026-07-17T~17:34Z (orchestrator run
`orchestrator-run-20260717-170912`). This run: caught and repaired a phase-1
stall (re-dispatched claude + codex proposals that the prior run never actually
kept alive); ran phase 2 (adversarial critique, all three) and phase 3 (four-
ballot vote, 4-0 on all three contested questions, critic seat correctly not
invoked); authored decision 008 and collected + applied genuine worker sign-offs
(signed 4-0, gate-ready on `round/005-isometric-art` at `43459d4`); posted the
snapshot to the dashboard. Phase-3 SYNTHESIS is complete. The immediate
continuation is to dispatch phase-3 IMPLEMENTATION, sequenced claude-first.
