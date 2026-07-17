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

**ROUND 004 was SPLIT this run by two mid-round Scott rulings.** The original
round ("make it look like a game", assigned 2026-07-17T12:30Z, seven playtest
findings) proceeded through decision 006 to a fully-assembled PR #20. Then two
Scott rulings landed in the orchestrator inbox and were not read for two runs
(see the retro note at the bottom). This run read and acted on both. They
overturn the ground the art slice was built on:

- `2026-07-17-1625-dalinar-ruling-art-is-ours.md`: **third-party asset packs
  RESCINDED.** Kenney (clean CC0) and any outside pack do NOT ship. Outside art
  is reference-only; shipped art is the team's own generated work.
- `2026-07-17-1645-dalinar-ruling-isometric-override.md`: **isometric override.**
  Decision 006 ground 1 (stay orthogonal) is overridden. Sim stays square-grid
  and projection-ignorant; ALL projection math lives render-side.

Both are recorded, with the supersession map of decision 006, in the new binding
record **`docs/decisions/007-isometric-and-own-art-override.md`** (on the round
branch, rides PR #20 to main). Read 007 in full; it is the authority for the
split.

**The round is now two things:**

1. **Round 004 (PR #20, reconstituted):** the projection-agnostic survivors
   only, reqs 4 (road routing) and 5 (camera rig). Ready to merge on normal
   gates; NO Scott visual gate. See Phase.
2. **Round 005 (to dispatch next):** the art re-plan under isometric +
   own-generated-art, reqs 1, 2, 3, 6, 7. Full protocol, contested. Scoped in
   decision 007. Not yet started.

## Phase

**Status:** `review; PR #20 reconstituted to reqs 4+5, CI re-running on 960ac78,
fresh external review requested. Merge on green + external review. NO Scott
visual gate on this PR.`

Round branch `round/004-look-like-a-game`, head **`960ac78`** (force-pushed this
run; previous Kenney head `b6bf7a0` is dropped). PR #20:
<https://github.com/sentania-labs/longwalk/pull/20>, retitled and re-bodied via
REST API (`gh pr edit` is currently broken by a GitHub GraphQL projectCards
deprecation error that aborts the whole mutation; use
`gh api -X PATCH repos/.../pulls/20 -f title=... -f body=...` instead).

At the reconstitution head, constitution and consensus gates PASS; headless
suite and windows export were re-running (green locally, exit 0). A fresh
`@codex review` was requested on the new head (the prior external review ran on
the Kenney head and is moot).

### What this run did to reconstitute round 004

The round branch was reset to `b9d1d46` (the post-road+camera integration state),
which preserves decisions 006 and 007 and both signed slices, then decision 007
was committed on top (head `960ac78`). This DROPPED the Kenney art slice
(`34db981` / merge `aa109d5`) and the moot walk-capture fix (`aad6125b` / merge
`b6bf7a0`, which only serviced the now-moot orthogonal walk-capture acceptance
workflow). No reviewed SHA was rebased; the dropped slices are simply not
integrated. Kenney assets and the moot acceptance artifacts are gone from the
branch tip (verified: `git ls-tree -r HEAD` shows no `assets/kenney`, no
`docs/art/round-004-*`). Full suite green on the reconstituted tree (exit 0).

### What ships in reconstituted round 004 (both peer-signed, both projection-agnostic)

| Slice | Author | Reviewed SHA | Reviewer | Fate |
| --- | --- | --- | --- | --- |
| Road-weighted routing (`src/sim/`, req 4) | claude-worker | `49eb63a` | agy-worker | ships |
| Camera FOLLOW/FOCUSED rig + right-click focus (req 5) | agy-worker | `77846f8` | claude-worker | ships (orthogonal picking correct for current render; iso-picking amendment deferred to round 005) |

Sign-off markers `claude-004-road-49eb63aeea23.md` and
`agy-004-camera-77846f854b57.md` are present at HEAD and name these exact SHAs.
Both slices are mechanical and testable and carry NO Scott visual gate. They are
authorized by decision 006 grounds 4 and 5, which the rulings leave standing.

**IMPORTANT: do NOT present PR #20's old acceptance artifacts to Scott.** The
walk-comparison GIF and before/after PNGs are moot (built on Kenney art and
orthogonal projection, both overturned) and are dropped from the branch.

## Round 005 scope (the art re-plan) — next run dispatches this

Full-protocol, contested. Fixed by Scott (not up for team debate): isometric
projection with sim staying square-grid and projection-ignorant (all iso math
render-side; any `src/sim/` change means the slice is wrong); own generated art
only, no third-party pack ships; reference folder
(`/home/scott/claude/vault/tmp/longwalk-inputs`, predominantly isometric) is
reference-only and the bar; sprite-forge mandate stands (codex exercises
`$generate2dsprite` / `$generate2dmap`, retro reports if it helped).

Genuinely contested for phase-1 blind proposals (per decision 007):
- Generation method for coherent isometric sheets (full-sheet coherent vs.
  per-asset with a shared palette/lighting harness). The vibe gap may be a
  METHOD problem, not a capability problem.
- Isometric facing count (4 diagonal min vs. 8 preferred) + frame-selection
  policy fixed in code before generation. This supersedes decision 005's
  cardinal facing set; the round-005 record must record that supersession.
- How the existing ingest pipeline (`tools/art/ingest_kenney_roguelike.py` and
  generic `process_assets.py` / `build_player_walk.py` /
  `build_walk_comparison.py` / `capture_art_acceptance.gd`) is repurposed to
  ingest OUR generated sheets. The 1625 ruling explicitly allows this code to
  survive retargeted.
- Isometric shadow-mask + grounding/contact-shadow approach (006 grounds 6, 7,
  regenerated for iso) and the render-side camera iso-picking amendment.

Carries reqs 1 (walk cycle), 2 (art vibe), 3 (flora, hard), 6 (building
silhouette shadows), 7 (grounding + contact shadow), plus the nearest-neighbour
render-flip now targeting iso sheets. Its own decision record (008), its own PR,
its own external review, and Scott's visual acceptance gate (walk-cycle GIF +
before/after vibe screenshots, now with isometric eyes) belong to this round.

## What this run did

Respawned to process two unread mid-round rulings. This run:
1. Read both rulings in full (1625 art-is-ours, 1645 isometric override) and
   decision 006 and the round-004 assignment.
2. Authored decision 007 recording both rulings verbatim, the supersession map
   of 006 (grounds 1, 2 overturned; 3-8 survive or amend), the round-004 split,
   and the round-005 scope. It is a directive-authority record (Workers
   dispatched: None, Authority: Scott) so it needs no four-ballot vote.
3. Reconstituted the round branch to `b9d1d46` + 007 (`960ac78`), dropping the
   Kenney art slice and moot fix. Ran the suite green.
4. Force-pushed the round branch, retitled/re-bodied PR #20 via REST API,
   requested a fresh external review.
5. Recorded everything durably here and posted the dashboard.

Did NOT dispatch round 005 (out of scope for this run; fully specified above for
the next run). Did NOT merge PR #20 (waiting on CI + fresh external review).

## Active decision records

**`docs/decisions/007-isometric-and-own-art-override.md`** (on round branch,
rides PR #20 to main), accepted by Scott's authority. THE binding record for the
split. Supersedes 006 grounds 1 (projection) and 2 (asset pack); maps survival
of 3-8; scopes round 005.

**`docs/decisions/006-asset-pack-and-rendering-model.md`** (on round branch),
accepted, signed 4-0. Grounds 1 and 2 are now superseded by 007; grounds 3
(render flip, now iso-targeted), 4 (road costs, shipping), 5 (camera, shipping),
6 (shadow masks, regenerate for iso), 7 (005 topology, facing set superseded), 8
(pixelization not gait evidence) survive per the 007 map. Not rewritten
(append-only); 007 carries the supersession.

**`004-round-branch-integration-and-voting-model.md`** directive authority:
round-branch integration, doers never open PRs, one PR + one external review per
round, four-ballot voting with critic as tiebreaker on a 2-2 split. Read before
round 005.

**`005-walk-cycle-generation-topology.md`**: method stands (per-facing gen,
colored boots, deterministic assembly); its cardinal facing SET is superseded by
the isometric override and round 005's facing-count call will record that.
**`003-village-feel.md`**, **`001-town-motion.md`**, **`002-team-roster-and-critic-seat.md`**
stay accepted (002's standing critic vote rescinded by 004; 001's four cited SHAs
pinned under `refs/archive/001/*`, never sweep). **Next free decision number is
`008`** (round 005 uses it).

## Outstanding sign-offs

**None owed for round 004.** Road (`49eb63a`, signed by agy) and camera
(`77846f8`, signed by claude) are the only slices; both markers present at HEAD
and name the exact reviewed SHAs. 007 is directive-authority and needs no
sign-off. Round 005's protected-path work will need four ballots + both agents'
sign-offs before it merges.

## Branch and PR sweep (end-of-round state)

**Not clean, correctly: round 004 not yet merged.** One open PR (#20),
reconstituted, ready to merge on CI-green + fresh external review (no Scott gate).
Retained on purpose until PR #20 merges:

- `round/004-look-like-a-game` (origin + local): the round branch, `960ac78`.
- Local doer branches carrying the signed commits still shipping:
  `claude/004-road`, `agy/004-camera`, plus the `*-proposal` branches. The
  dropped-slice branches `codex/004-art` and `agy/004-fix-capture` are now
  orphaned from the round (their work is not shipping); they can be deleted on
  the round merge. **All doer branches are LOCAL-ONLY** (Dalinar steer
  2026-07-17T13:10Z): only the round branch and PR #20 reach GitHub.
- Three worktrees on disk: `/home/scott/claude/lw-004-{claude,codex,agy}` (reused
  for round 005 or torn down on merge).

**On the round merge, a continuing run sweeps** the round branch + every doer
branch + worktrees, records `.review-passed` straight to `main` (never its own
PR), and checks whether any decision record cites a SHA reachable only from a
branch about to be deleted (pin under `refs/archive/` if so).

## Open escalations to Scott

**None live.** The two prior escalations (isometric projection, Tiny Swords /
asset-pack authorization) are BOTH now RESOLVED by Scott's 1625 and 1645 rulings
and recorded in decision 007. Tiny Swords is declined; asset packs rescinded;
isometric adopted. Nothing is pending Scott's decision. Round 005's art will
carry a Scott visual acceptance gate when it is built, but that is a future gate,
not an open escalation now.

## Notes for the next run

**RETRO GAP (record for the retro, do not fix mid-round): the inbox-check
convention only fires at spawn.** Two mid-round Scott rulings (1625, 1645) sat
unread in `.pka/inbound/orchestrator/` through TWO implementation-heavy runs
because the orchestrator brief's check-inbox step runs at spawn, and those runs
were already deep in dispatch-and-integrate when the rulings arrived. Dispatches
kept racing ahead of authoritative steers. This is a real structural gap: a
steer that lands mid-run has no trigger to interrupt the run. The brief says a
steer in the inbox is authoritative mid-run, but nothing makes a busy run go
look. Fix candidates for the retro (the brief is not the team's to edit, so this
is a note, not an action): a per-phase-transition inbox re-scan, or a
vault-side signal that pings the active orchestrator run. NOT redesigning the
brief this run.

**Both 1625 and 1645 rulings are PROCESSED** (by decision 007 this run). The
inbox files remain on disk as historical record; a future run should NOT
re-process them as unread. They are cited in 007.

**`gh pr edit` is broken by a GitHub GraphQL projectCards deprecation** that
aborts the whole mutation (title/body/anything). Use the REST API:
`gh api -X PATCH repos/sentania-labs/longwalk/pulls/20 -f title="..." -f body="..."`.
Comments (`gh pr comment`) still work.

**Round 005 is the next run's opening move.** Provision/refresh the three
worktrees, dispatch phase-1 blind proposals per decision 007's contested
questions, detached + polled by end marker (never block a >600s dispatch inside
one tool call). The sprite-forge mandate means codex's slice is central again.

**Dashboard POST works** (token in `/home/scott/.claude/pka-secrets/dashboard-config.md`,
header `X-Bridge-Token`, `--cacert /etc/ssl/certs/sentania.root.pem`). Schema
gaps unchanged: no `critic`/`agy` in `DOCUMENT_AUTHORS`, no `agy` in
`SIGNOFF_AUTHORS`, no `implementation`/`done` phase. Post agy/critic docs as
`author: orchestrator` with the real author named in `body_markdown`.

**A style-rule tension still on `main`, unresolved and Scott's to rule on:** three
tracked files carry em-dashes CLAUDE.md forbids (`.pka/CLAUDE.md`, an inbound
steering message, and a verbatim-quoted critic vote in
`docs/decisions/003-village-feel.md`). None in any open diff. Likely fix is a
constitution carve-out for quoted/inbound text, which is not the team's to edit.

**Deferred non-blocking follow-ups** (carried forward): pin the zoom index remap
and add an epsilon to bounds assertions (round-003 sign-off observations); the
`check_consensus.py` `covered_entries()` prose-scan bug (a record's prose
mentioning a protected path counts as coverage; real, never fixed; 007 lists its
paths as bare entries at the top of its section to stay clean of it); an
anchor-drift gate in `process_assets.py`.

---

**Last updated:** 2026-07-17T~16:50Z (orchestrator run
`orchestrator-run-20260717-163924`). This run processed two unread mid-round
Scott rulings (art-is-ours, isometric override), authored decision 007 recording
them and the supersession of decision 006 grounds 1 and 2, split round 004:
reconstituted PR #20 to the projection-agnostic survivors (reqs 4 road + 5
camera, head `960ac78`) with the Kenney art slice and moot acceptance artifacts
dropped, and scoped the art re-plan as round 005 (isometric + own-generated art)
for the next run to dispatch. PR #20 is ready to merge on CI-green + a fresh
external review, with no Scott visual gate. Nothing left running in the
background.
