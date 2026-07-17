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

**ROUND 004 IS MERGED AND CLOSED. ROUND 005 IS DISPATCHED (phase 1, blind
proposals running).**

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

**Status:** `phase 1 (blind proposal), 3 dispatches RUNNING as of
2026-07-17T~17:05Z. Poll the end markers; do NOT advance to phase 2 until all
three end markers exist and each proposal SHA is verified on its branch.`

Round branch **`round/005-isometric-art`** created off main at `7b0fb3d`. Three
proposal branches created off it, all starting at `7b0fb3d` (verified identical
blind start):

| Worker | Branch | Worktree | run_id | Prompt |
| --- | --- | --- | --- | --- |
| claude-worker | `claude/005-proposal` | `/home/scott/claude/lw-004-claude` | `005-claude-proposal-20260717-170452` | `/tmp/round005-phase1-claude.md` |
| codex-worker | `codex/005-proposal` | `/home/scott/claude/lw-004-codex` | `005-codex-proposal-20260717-170454` | `/tmp/round005-phase1-codex.md` |
| agy-worker | `agy/005-proposal` | `/home/scott/claude/lw-004-agy` | `005-agy-proposal-20260717-170457` | `/tmp/round005-phase1-agy.md` |

Each dispatched with `--cap-seconds 2400` (detached + polled; a 2400s dispatch
cannot block inside one 600s orchestrator tool call). Start markers confirmed for
all three in each worktree's `.team/markers/`.

**Next run (or this run's continuation) polling contract:** read
`<worktree>/.team/markers/<run_id>-end.md` for each. Check `branch_sha_before`
vs `branch_sha_after` + `branch_changed` + `uncommitted_work` + `cap_expired`.
Then confirm the reported proposal commit actually exists on the branch
(`git -C <worktree> log --oneline`, `git show <sha>:docs/proposals/...`). Do NOT
trust the transcript. The `agy` end marker is the load-bearing check for agy (it
silently no-ops into a scratch project if `--add-dir` is wrong; markers make
that visible; `--add-dir` was passed correctly by the adapter).

When all three proposals are committed and verified, record each full 40-char
SHA here, then dispatch **phase 2 (adversarial critique)**: each worker reads the
other two proposals and attacks them. A round where everyone says "looks good" is
a failed round; send it back.

## Round 005 scope (dispatched this run)

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

1. Read TEAM-STATE and the new inbox message `1720-playtest-feedback` (art vibe
   REJECTED emphatically, `seriously-this-is-terrible.png` added as reference;
   pathfinding BETTER, earns merge; right-click focus "OK but not what he wants",
   he wants drag-pan). Confirmed 1625/1645 already processed by decision 007.
2. Verified PR #20 state directly: CLEAN/MERGEABLE, all four CI gates green, both
   peer sign-offs present naming non-authors + exact reviewed SHAs (`49eb63a`
   road signed by agy, `77846f8` camera signed by claude), both integrated
   without rebase, decisions 006/007 authorize protected paths.
3. Fresh external Codex review (16:51) raised one real P2: the capture tool
   `capture_player_walk.gd:26` still calls `player.get_node("Camera2D")` after
   req 5 moved the camera to `World/CameraRig2D`. DISPOSITION: deferred into
   round 005's pipeline-repurpose slice (tool is moot in its orthogonal form,
   round 005 repurposes that exact pipeline for iso; point-fixing now is churn).
   Recorded on the PR as a comment; not silently swallowed. To be fixed in 008.
4. Merged PR #20 as a merge commit (`7d6100e`, matching round-003/PR #19), per
   the 1720 disposition (merge what survives, no Scott visual gate on this PR).
5. Swept: pinned all decision-cited unreachable SHAs under `refs/archive/004/*`
   and pushed them to origin (matching the 001/003 archive convention); deleted
   all local doer + proposal + round branches and the origin round branch; wrote
   `.review-passed` to main.
6. Dispatched round 005 phase 1: created round branch + three proposal branches
   off `7b0fb3d`, pointed the three reused worktrees at them, dispatched three
   blind proposals detached (see Phase).

Did NOT advance round 005 past phase-1 dispatch in this write (polling for end
markers is the immediate next step, may complete in-run or next run).

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

**`005-walk-cycle-generation-topology.md`**: method stands (per-facing gen,
colored boots, deterministic assembly); its cardinal facing SET is superseded by
the isometric override and round 005's facing-count call (decision 008) will
record that. **`003-village-feel`**, **`001-town-motion`**,
**`002-team-roster-and-critic-seat`** stay accepted (002's standing critic vote
rescinded by 004; 001's SHAs pinned under `refs/archive/001/*`, never sweep).
**Next free decision number is `008`** (round 005 uses it at synthesis).

## Outstanding sign-offs

**None owed right now.** Round 004 is merged. Round 005's blind proposals are
artifacts (committed by their authors, cited by SHA, no peer sign-off needed at
phase 1). Round 005's protected-path IMPLEMENTATION work will need four ballots +
both non-author sign-offs before it merges.

## Branch and PR sweep (end-of-round-004 state)

**Round 004 sweep is CLEAN.** Zero open team PRs. Zero stale team branches
(verified: no local `004`/`round` branches, no origin `round/004` or `/004-`
branches). Round-004 artifacts preserved on origin under `refs/archive/004/*`
(claude/codex/agy proposal + critique, and the four dropped-slice SHAs cited by
007). PR #20 merged at `7d6100e`.

**Round 005 branches now live (retained on purpose, round in flight):**
- `round/005-isometric-art` (local, `7b0fb3d`): the round branch. NOT yet on
  origin (per the Dalinar 2026-07-17T13:10Z steer, only the round branch reaches
  GitHub, and only when its PR opens; doer branches are LOCAL-ONLY).
- `claude/005-proposal`, `codex/005-proposal`, `agy/005-proposal` (local-only):
  the three blind-proposal branches.
- Three worktrees: `/home/scott/claude/lw-004-{claude,codex,agy}` (named for 004,
  reused for 005; rename or leave, they are just checkouts).

On the round-005 merge, sweep these the same way: delete branches, tear
down/reuse worktrees, pin any 008-cited SHA reachable only from a deleting
branch under `refs/archive/005/*` and push, write `.review-passed` to main.

## Open escalations to Scott

**None live.** Isometric and asset-sourcing are both resolved (decision 007).
Round 005's art carries a Scott visual acceptance gate when built, but that is a
future gate, not an open escalation. If phase-2 critique or synthesis surfaces a
2-2 contested question, the critic seat breaks it (decision 004); a claimed
constitution violation or a critic-vs-orchestrator standoff escalates to Scott.

## Notes for the next run

**IMMEDIATE NEXT STEP: poll the three phase-1 end markers** (run IDs in Phase),
verify each proposal SHA on its branch, record the SHAs, then dispatch phase 2
(adversarial critique). Do not trust transcripts; verify from markers + tree.

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

**Last updated:** 2026-07-17T~17:06Z (orchestrator run
`orchestrator-run-20260717-165633`). This run: read the new 1720 playtest
feedback; verified and merged PR #20 (round 004 split, `7d6100e`), deferring the
one external-review P2 into round 005 with a recorded rationale; swept all
round-004 branches, archived artifacts to `refs/archive/004/*` on origin, wrote
`.review-passed`; then scoped and DISPATCHED round 005 phase 1 (three blind
proposals running, folding Scott's 1720 drag-pan camera refinement into the
prompt). Three dispatches are running in the background at write time; the
immediate continuation is to poll their end markers and advance to phase 2.
