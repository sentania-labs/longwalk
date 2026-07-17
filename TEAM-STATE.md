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

**ROUND 004 ACTIVE: "make it look like a game."** Assigned by Scott via Dalinar
at 2026-07-17T12:30Z, inbox
`.pka/inbound/orchestrator/2026-07-17-1230-dalinar-assignment-round-004.md`
(read it in full; it is the authority). Seven playtest findings, all
requirements. Full derived scope and lane reasoning are in
`docs/decisions/006-asset-pack-and-rendering-model.md`, which is now the binding
record for this round.

**The entire round is built, signed, integrated, and green. The one thing left
is Scott.** PR #20 is open, CI green, the sole external review finding addressed,
and it is HELD on Scott's visual acceptance of requirements 1 and 2 (see Phase).

## Phase

**Status:** `review; PR #20 open and CI-green; merge HELD on Scott's visual gate`.

Round branch `round/004-look-like-a-game`, head `b6bf7a0` (pushed to origin).
PR #20: <https://github.com/sentania-labs/longwalk/pull/20>. All four CI checks
pass (consensus gate, constitution, headless suite, windows export). The
external chatgpt-codex-connector review ran, filed one P2, and it is addressed
(below). A re-review may auto-trigger on the fix push `b6bf7a0`.

### The round is fully assembled: four slices, each peer-signed, each integrated

Every slice was integrated `--no-ff` into the round branch, preserving authorship
via `Co-authored-by:` trailers, and the full suite is green on the integrated
tree (`tools/run_tests.sh`, exit 0, zero FAIL). Signed markers verified: each
`reviewed_by != authored_by`, each names the exact reviewed SHA, each is a real
ancestor of the round head.

| Slice | Author | Reviewed SHA | Reviewer | Integrated merge |
| --- | --- | --- | --- | --- |
| Road-weighted routing (`src/sim/`, req 4) | claude-worker | `49eb63a` | agy-worker | `53fa48c` |
| Camera FOLLOW/FOCUSED rig + right-click focus (req 5) | agy-worker | `77846f8` | claude-worker | `b9d1d46` |
| Kenney CC0 pack + render flip + composition proof (reqs 1,2,3-assets) | codex-worker | `34db981` | claude-worker | `aa109d5` |
| Walk-capture fix (external P2) | agy-worker | `aad6125b` | claude-worker | `b6bf7a0` |

Sign-off markers are on the round branch under `.team/signoffs/`:
`claude-004-road-49eb63aeea23.md`, `agy-004-camera-77846f854b57.md`,
`codex-004-art-34db98194170.md`, `agy-004-fix-capture-aad6125be27e.md`. Every one
was a genuine review: the road sign-off mutation-proved the admissibility
invariant, the camera sign-off re-proved the zoom/bounds contract by three
mutations, the art sign-off independently re-verified CC0 licensing (fetched the
OGA source page for the reference GIF), and the fix sign-off ran the capture tool
end-to-end to confirm the zoom hold.

### THE MERGE BLOCKER, which is genuine and is Scott's eyes, not a team decision

Per decision 006, the art slice "completes to artifacts-for-Scott, not to
auto-merge." Two requirements carry a human acceptance gate that cannot close in
an autonomous run:

- **Req 1 (walk cycle):** `docs/art/round-004-walk-comparison.gif`, our governed
  4-frame cycle beside a CC0 reference on a shared baseline, judged on stride
  length, contact frames, vertical bounce. Decision 005's topology is unchanged;
  frames were not regenerated (verified by the reviewer).
- **Req 2 (art vibe):** `docs/art/round-004-before.png` and `round-004-after.png`
  (the after doubles as the composition proof: traveller, contact shadow,
  grass/path transition, y-sorted flora at shipping zoom).
  Verdict note: `docs/art/round-004-acceptance.md`.

These are evidence for Scott's judgement, not a gate the team passes. **PR #20 is
held for Scott's visual acceptance of reqs 1 and 2.** This is a stated blocker in
the PR body, not a stall. When Scott accepts, a continuing run merges the round,
records `.review-passed`, and sweeps every branch below.

### The codex art dispatch died mid-commit and was recovered, which is the recurring lesson again

The codex art dispatch completed the full slice AND validated it (its own
`tools/run_tests.sh` run passed) and then died on `ERROR: Selected model is at
capacity` before it could commit. `branch_changed=no`, `uncommitted_work=yes`,
`exit_code=1`, ~547s (not a cap-kill). Per the phase-1 precedent (a 529 killing
the claude proposal after it wrote but before it committed), the orchestrator
committed the tree verbatim at `34db981`, authored `codex-worker`, wrote none of
it, and let the independent peer sign-off be the real review gate. This is the
same failure the brief warns about: the end marker plus the tree told the truth
(complete work, uncommitted), the exit code alone would have said "failed".

### The external review found one thing and it is fixed

The chatgpt-codex-connector review of `aa109d5` filed one P2: the camera reparent
removed the player's `Camera2D` child, so `tools/art/capture_player_walk.gd:26`
still called `player.get_node("Camera2D")` and the walk-capture acceptance
workflow (which req 1 depends on) failed. Verified real (one stale reference).
Routed to agy-worker (the rig author) rather than patched by the referee. Fix at
`aad6125b`: retrieves `World/CameraRig2D` and sets `_target_zoom = 1.0` before
`camera.zoom = Vector2.ONE` so the rig's `_process` cannot stomp zoom during the
capture. Not a bare one-line swap: the zoom-override risk needed the rig's own
API, which is why it went to the rig's author.

## What this run did

Inherited a mid-round state after the previous run hit its 5400s cap. Decision
006 was signed 4-0 and the two buildable code slices (road, camera) had already
been dispatched and committed with clean end markers, but had no peer sign-offs
and the codex art slice had never been dispatched. This run:

1. Verified both completed slices from their end markers and diffs (road exit 0;
   camera cap-killed at 40min but committed cleanly at 15:21 before the kill).
2. Dispatched three things in parallel into three worktrees: agy reviewing road,
   claude reviewing camera, codex building the art slice. All detached
   (`nohup setsid`) and polled by end marker across tool calls, because the
   dispatch caps exceed the 600s tool-call cap.
3. Integrated road and camera, ran the suite green.
4. Recovered the codex art slice (committed verbatim, above), dispatched its peer
   sign-off (claude), integrated, ran the suite green.
5. Opened PR #20, triggered the external review, addressed its one P2 through the
   owning doer with its own peer sign-off, re-integrated, re-pushed.
6. Posted the dashboard at each phase transition (all HTTP 200).

## Active decision records

**`docs/decisions/006-asset-pack-and-rendering-model.md`**, accepted, signed 4-0,
critic not invoked (tiebreaker-only, no tie). This round's binding record: Kenney
Roguelike/RPG pack (CC0), orthogonal top-down (isometric rejected),
nearest-neighbour render flip gated on a composition proof, road costs
`PATH=1.0 / GRASS=2.25` heuristic untouched, camera FOLLOW/FOCUSED reparented rig
with persistent right-click focus, preprocessed per-asset shadow masks, decision
005 unamended. **Now implemented and integrated on the round branch**, pending
only Scott's visual acceptance and the round merge.

**`docs/decisions/004-round-branch-integration-and-voting-model.md`**, directive
authority. Governs how a round runs: round-branch integration, doers never open
PRs, one PR and one external review per round, four-ballot voting with the critic
as tiebreaker only on a 2-2 split. Read before the next round.

**`005-walk-cycle-generation-topology.md`**, **`003-village-feel.md`**,
**`001-town-motion.md`**, **`002-team-roster-and-critic-seat.md`** stay accepted.
005 governs the walk cycle and is unamended by 006. 002's standing critic vote is
rescinded by 004. 001's four cited SHAs are pinned under `refs/archive/001/*`
(never sweep those refs). Next free decision number is `007`.

## Outstanding sign-offs

**None owed.** All four slices were peer-signed by a non-author before integration
and every signed SHA is a genuine ancestor of the round head `b6bf7a0`.
Integration was always `--no-ff`, never rebase, so no reviewed SHA was renumbered.

**Precedent worth keeping:** a rebase or a review-round fix invalidates a
sign-off, because the marker names a SHA and the gate checks that SHA. Re-review
the delta and write a new marker at the new SHA. Do not repoint the old one.

## Branch and PR sweep (end-of-round state)

**Not yet clean, and correctly so: the round is not merged.** One open PR (#20),
held on Scott's visual gate with the blocker stated in its body. Retained on
purpose until PR #20 merges:

- `round/004-look-like-a-game` (origin + local): the round branch, `b6bf7a0`.
- Local doer branches carrying the signed, integrated commits:
  `claude/004-road`, `agy/004-camera`, `codex/004-art`, `agy/004-fix-capture`,
  and the `*-proposal` branches (`claude/004-proposal`, `codex/004-proposal`,
  `agy/004-proposal`). **All doer branches are LOCAL-ONLY** (Dalinar steer
  2026-07-17T13:10Z): only the round branch and PR #20 ever reach GitHub.
- Three worktrees on disk: `/home/scott/claude/lw-004-{claude,codex,agy}`.

**On the round merge, a continuing run sweeps all of the above** (round branch +
every doer branch + the three worktrees), records `.review-passed` straight to
`main` (never its own PR), and checks whether any decision record cites a SHA
reachable only from a branch about to be deleted (pin it under `refs/archive/` if
so, as was done for decision 001).

## Open escalations to Scott

**Round 004 merge acceptance (the live one).** Reqs 1 and 2 need Scott's eyes on
`docs/art/round-004-walk-comparison.gif` and the before/after PNGs. Accept and the
round merges; reject and the walk-cycle / vibe work gets another slice. Reqs 6
(building silhouette shadows) and 7 (grounding + contact shadow) are partially
addressed by the composition-proof shadow work; the full per-asset silhouette-mask
pass sequences after the pack scale settles, i.e. after Scott accepts the flip.

**Tiny Swords (Pixel Frog), decision 006.** Named the closest match to the WC2
vibe on the internet, but its license forbids redistribution even modified, so it
fell outside Scott's CC0/CC-BY authorization and is escalated rather than adopted.
Kenney CC0 ships this round regardless. Path if Scott wants it: a private repo or
direct permission from Pixel Frog. `<https://pixelfrog-assets.itch.io/tiny-swords>`

**The Codex review bot's reliability** (`request_id=846fef69-6bf4-411c-aa71-5c55bc3ca1f8`,
filed 2026-07-17T04:26Z). Update: on this round it behaved well, posting a
substantive, correct P2 within ~4 minutes of the `@codex review` request on
PR #20. The intermittency remains the standing concern; nothing blocks on it.

## Notes for the next run

**The codex harness hit "Selected model is at capacity" this run** and it killed
the art dispatch after the work was complete but before commit. If codex keeps
erroring next run, its dispatches are the ones to retry (or recover verbatim from
the end marker), not claude/agy. The recovery pattern is proven: end marker plus
tree tell the truth, commit verbatim preserving authorship, let the peer sign-off
be the gate.

**Detached-dispatch discipline held all seven dispatches this run.** Every
dispatch went out `nohup setsid ... &` and was polled by its end marker across
tool calls. No dispatch was launched with a cap longer than 600s and then blocked
on inside a single tool call. This is the rule that killed two prior runs; it did
not bite this time.

**The dashboard POST works** (HTTP 200 every post this run, token in
`/home/scott/.claude/pka-secrets/dashboard-config.md`, header `X-Bridge-Token`,
`--cacert /etc/ssl/certs/sentania.root.pem`). The three schema gaps are unchanged:
no `critic`/`agy` in `DOCUMENT_AUTHORS`, no `agy` in `SIGNOFF_AUTHORS`, no
`implementation`/`done` phase. This run posted the agy road sign-off in
`status_note` rather than mislabeling it in `signoffs[]` (an earlier post this run
mislabeled it `codex` and was corrected on the next post; do not repeat that).

**Follow-up work this round deliberately did not do**, in a sensible next order:

1. **Pin the zoom index remap** and **add an epsilon to the bounds assertions**
   (two non-blocking observations from a round-003 sign-off; reasoning already
   written in git history). Small and well-specified.
2. **The `check_consensus.py` prose bug:** `covered_entries()` scans the whole
   "Protected paths touched" section including prose, so a record saying "None"
   that later discusses `src/sim/` reads as covering it. No current record is
   exposed (006 lists its paths bare). Real, never fixed.
3. **An anchor-drift gate in `process_assets.py`** (Scott's 0430 steer, "team's
   call"): enforce a stable bottom-anchor-line across walk frames with a numeric
   gate. Composes with the colored-boots check. Provenance in decision 004.
4. **Flora placement polish and the full shadow/grounding pass (reqs 6, 7)**,
   which decision 006 sequences after Scott accepts the pixel-art flip.

**A style-rule tension still on `main`, unresolved and Scott's to rule on.** Three
tracked files carry em-dashes that CLAUDE.md forbids repo-wide: `.pka/CLAUDE.md`
and an inbound steering message (preserved as received), and
`docs/decisions/003-village-feel.md` (inside a verbatim-quoted critic vote, which
the orchestrator brief requires be verbatim). The honest fix is probably a
constitution carve-out for quoted and inbound text, and the constitution is not
the team's to edit. None are in any open diff.

**The `agy` adapter's `--add-dir` worked again** every dispatch; the
throwaway-scratch-project failure its comments warn about has still never occurred
here. `dispatch.sh` blocks synchronously and the adapter auto-passes `--add-dir`.

---

**Last updated:** 2026-07-17T16:35Z (orchestrator run
`orchestrator-run-20260717-155824`). This run inherited round 004 with decision
006 signed and two code slices committed-but-unsigned. It got peer sign-offs on
all slices, recovered the codex art slice from a harness capacity death (committed
verbatim, peer-reviewed), dispatched and integrated the codex art slice, opened
PR #20, addressed the single external-review P2 through the owning doer, and drove
the round to a fully-assembled, CI-green, integrated state. The one remaining gate
is Scott's visual acceptance of reqs 1 and 2; PR #20 is held on it with the
blocker stated. Nothing is left running in the background.
