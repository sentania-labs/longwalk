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
(read it in full; it is the authority, this is the scope derived from it).

Scott playtested build 29564548380. Machinery verdict good, game verdict mixed.
Seven findings, all **requirements, not suggestions**:

1. Walk animation is "just okay, really rudimentary, sort of skipping". New
   acceptance bar: side-by-side animated GIF against a reference-game walk
   cycle, attached to the decision record, judged on stride length, contact
   frames, vertical bounce. Frame order alone no longer passes.
2. No visible change in art vibe. The round-003 feel pass produced a color
   grade, not a style change. Judged against the reference images, with
   before/after screenshots in the round PR.
3. **Flora is now a hard requirement.** Trees, bushes, at least one flower
   patch. Scott has asked three times. Decision 003 cut it; that cut does not
   carry forward.
4. Pathfinding must know roads exist (weighted nav costs, prefer paths).
5. Add right-click to focus/recenter the view, independent of pathing.
6. Building shadows must conform to building silhouettes, not rounded blobs.
7. The traveller floats. Ground him, plus a contact shadow consistent with the
   building shadow direction.

**Strategy change, authorized by Scott: licensed asset packs (CC0/CC-BY) are
now permitted as a base layer**, AI generation reserved for custom pieces. Every
adopted asset needs a CREDITS.md entry with source URL and license. No
noncommercial or unclear-license assets. Scott flagged "which pack(s)" as the
likely biggest single unlock for the vibe gap and as a phase-1 contested
question. The codex seat **must** exercise its agent-sprite-forge skills
(`$generate2dsprite` / `$generate2dmap`) for remaining generation, and the retro
must report whether they materially helped.

Exclusions: still no NPCs, and no engine change (Scott asked; the assessment is
that asset sourcing and art direction are the constraint, not Godot).

Reference folder (read-only): `/home/scott/claude/vault/tmp/longwalk-inputs`.
Technique reference: CorsixTH, techniques citable, assets never.

### Lane

**FULL PROTOCOL.** Three reasons, any one of which would be sufficient:

- It touches two protected paths (below), which is design-level by definition.
- Scott explicitly flagged the asset-pack question as contested, and it is: the
  pack choice is a one-way door that the whole art direction then inherits, and
  it partially supersedes decision 005's generation topology.
- Seven requirements with real sequencing tension between them (the pack choice
  gates the vibe work, the flora work, and arguably the walk cycle). A
  reasonable engineer could scope this several materially different ways.

### Protected paths touched

**Yes**, forecast as two entries from `.github/protected-paths.txt`:

- `src/sim/` (requirement 4: road-weighted routing extends
  `NavGrid.find_path()`; `GroundTile.PATH` already exists in
  `src/sim/town_layout.gd`, so the data is there and only the cost function is
  missing).
- `project.godot` (requirement 5: a new InputMap action for right-click focus).

A forecast, not a certainty. Phase 3 corrects it against what the synthesis
actually calls for. Consequence: contested synthesis questions take four
ballots, critic invoked only on a 2-2 split, per decision 004.

### Round structure

Round branch `round/004-look-like-a-game`, cut from `main` at `9988feb`. Doer
branches `claude/004-proposal`, `codex/004-proposal`, `agy/004-proposal`, each
cut from the round branch, each in its own worktree at
`/home/scott/claude/lw-004-<name>`. One PR to `main` from the round branch, one
external review round, per decision 004.

## Phase

**Status:** `synthesis complete, consensus signed, implementation dispatch next`.

The entire deliberative half of round 004 is done and durable on the round
branch `round/004-look-like-a-game` (pushed to origin):

- **Phase 1 (blind proposal):** three committed proposals. claude
  `7ab3585fcae70faa50df13adef821925a86cfd89` (its dispatch was killed by a 529
  after writing but before committing; the orchestrator committed the artifact
  verbatim, authored none of it, did not re-dispatch, because a phase-1
  artifact's value is that it is the blind one). codex
  `71d9d31b02aab16e6fcdaff77e51dcf26aaa8f39`. agy
  `25473e73e3808d5dd44b41d7ca577a67247f36cb`.
- **Phase 2 (adversarial critique):** claude
  `874baa43141eb7c85134956ead726a0a65ce02e0`, codex
  `67cbb4d46a92c4e31254114e1806f4d04fa32c54`, agy
  `b6bbb5efeb62bb24d31f518f72326f93e9dd7eff`. The round worked: three blind
  reads converged on a synthesis none proposed in phase 1.
- **Phase 3 (synthesis):** `docs/decisions/006-asset-pack-and-rendering-model.md`,
  accepted, **signed by all three doers**, passing `check_consensus.py` for both
  protected paths (`src/sim/`, `project.godot`). 4-0 ballot, critic not invoked
  (correctly tiebreaker-only, no tie). Verified by running the gate this run.

### The ruling in one paragraph

Stay orthogonal / top-down (isometric rejected: it discards decision 005's walk
sheet and forces projection into `src/sim/`). Adopt **Kenney Roguelike/RPG pack
(CC0)**, the intersection of orthogonal and license-clean that all three doers
landed on once claude's LPC pack failed licensing (OGA-BY not CC-BY, caught
independently by codex and agy) and isometric was rejected. Flip the rendering
model to nearest-neighbour at a fixed art scale (claude's central claim), landed
first and alone gated on a composition proof. Road costs `PATH=1.0 / GRASS=2.25`,
heuristic untouched (codex's numbers, invariant comment + test per claude's C6).
Camera FOLLOW/FOCUSED state machine reparented off the player, right-click focus
persists, Space returns. Preprocessed per-asset shadow masks, one light vector.
Decision 005 stands unamended.

### Division of labor (from decision 006)

- **claude-worker:** road-weighted routing (req 4), `src/sim/`. Headless, no
  pack dependency. Buildable and fully gateable without Scott.
- **agy-worker:** camera rig + right-click focus (req 5). No pack dependency.
  Buildable and fully gateable without Scott. Inherits the synthesis semantics,
  not agy's own defeated camera design.
- **codex-worker:** pack ingestion, rendering-model flip, composition proof
  (reqs 1, 2, 3 assets). Scott mandated the sprite-forge skills here. The long
  pole. **Reqs 1 and 2 have a human acceptance gate that is Scott's eyes** (a
  side-by-side walk GIF, before/after screenshots). That gate cannot close
  inside an autonomous run, so the art slice completes to artifacts-for-Scott,
  not to auto-merge.

Flora placement (req 3) and the walk-cycle work sequence AFTER the composition
proof, because both consume the pack and the art scale it settles.

### What a continuing run does next

Create fresh implementation branches from the current round head (they build on
decision 006 and integrate together, so cut from `round/004-look-like-a-game`,
NOT from the `*-proposal` branches). Dispatch the two buildable code slices
(road routing, camera) to committed + suite-green + cross-peer sign-off + local
integration. Dispatch the codex art slice to its Scott-facing artifacts. Then
one round PR, one external review, address findings, merge.

### Doer worktrees currently on disk

`/home/scott/claude/lw-004-{claude,codex,agy}`, each on its `*-proposal` branch,
holding the committed phase-1 and phase-2 artifacts. Reusable for
implementation after checking out fresh impl branches cut from the round head.

## What this run did

Inherited a mid-round state after the previous run hit its 5400s cap. PR #19 was
open and green with an external Codex review posted. Carried it to merge.

### The Codex review found three things and all three are addressed

| Finding | Verdict | Fix |
| --- | --- | --- |
| P1: art-test Python deps not installed in CI | correct when filed, already fixed | `bb7aaf5`, landed after the reviewed commit |
| P2: minimum zoom escapes the town bounds | correct, verified independently | `bec2cef` (agy-worker, peer-signed at `8ddc330`) |
| P1: em-dashes in generated markers | correct | `4f2945a`, then properly at `4de5de7` |

**The zoom P2 was real and the arithmetic was checked before dispatching rather
than taken on the bot's word.** The authored town is 2304x1792 (18x14 at
`TILE_SIZE` 128) and a 1280x720 viewport at zoom 0.5 spans 2560x1440, so **both
axes overshoot**, not just the horizontal one the bot named. The floor is now
derived as `maxf(viewport_w / town_w, viewport_h / town_h)` at `set_layout()`,
which tracks the authored map instead of today's numbers. Hardcoding 0.75 would
have fixed this town and silently broken on the next one.

### A dead dispatch was found and re-run, which is the recurring failure

`.team/markers/fix-zoom-20260717-064745-start.md` existed with **no end marker**:
the previous run dispatched the zoom fix and died with its parent before it
finished, leaving partial uncommitted work in the worktree. Re-dispatched
detached (`nohup setsid`) and polled for the end marker across tool calls, which
is the shape that works given the 600s tool-call cap against longer dispatch
caps. This is the third time this round the dispatch-lifetime rule has bitten.
The rule is already in the brief; what keeps recurring is the belief that it
does not apply to this particular dispatch.

### The peer review was rigorous and worth reading as a model

claude-worker reviewed agy's zoom fix and signed off at
`.team/signoffs/agy-feel-8ddc3307befe.md`, but only after **re-proving all five
player-world contract invariants by mutation** rather than re-reading the
assertions, because the zoom path had changed underneath those tests. It killed
the `maxf`-to-`minf` inversion and the dropped `_recompute_zoom_levels()` call,
and drove the index-remap logic with a live probe rather than resting on an
argument that it was safe.

Its two **non-blocking** observations are the best follow-up material this round
produced, and neither is fixed (deliberately, to keep the PR scoped to the review
findings):

1. **The zoom index remap is entirely unpinned.** Replacing the whole remap block
   with `_zoom_index = _zoom_levels.size() - 1` (jump to max zoom on every
   `set_layout()`) passes the full suite. The code is correct; nothing would catch
   a regression.
2. **The new bounds assertions sit on an exact float boundary and pass on
   favourable rounding, not margin.** 32-bit `camera.zoom` quantizes the x floor
   *up* (viewport spans 2303.99989 px, inside 2304 by 0.0001), while the y floor
   quantizes *down* and would overshoot 1792 by 0.00006 px if y were the binding
   axis. Shipped behavior is correct because x binds. A change to town or viewport
   dimensions could turn the suite red for a sub-pixel reason unrelated to any
   real bug. An epsilon on the two comparisons would make the test say what it
   means.

### Two mistakes I made, recorded because the next run should not repeat them

**1. My em-dash fix commit introduced seven new em-dashes, and the bot caught
it.** `4f2945a` built its fix list with `git ls-files | xargs grep -l` (tracked
files only) and then staged with `git add .team/markers/` (which sweeps in
untracked files too). Seven markers that had accumulated in the working tree
across the round were staged unfixed **by the commit whose message said they were
fixed**. The re-review filed a P1 against the final tree saying "the claimed
remediation is not present in the final commit", which was exactly right. Fixed
at `4de5de7`, verified against the committed tree across every tracked file
rather than the directory I expected the problem in. **A fix list narrower than
the stage command is how a remediation introduces the thing it removes.**

**2. I told agy to delete its BLOCKED marker, which contradicts the convention.**
`.team/blocked/README.md` ends with "Resolved markers stay", because three
markers naming the same missing input is a fact about the framework rather than
about the three residents that hit it. I restored it at `cdbee2d` and told the
reviewer not to spend a finding on it, since agy did exactly what I instructed.
Both round-003 blocked markers (agy's and codex's) are on `main` and stay there.

### Decision 001's cited SHAs are now pinned, which unblocked the town-motion sweep

`claude/town-motion` and `codex/town-motion` had been retained for two rounds
because decision 001 cites four proposal and critique SHAs reachable **only** from
them. Rather than retain them a third round or delete them and orphan the
citations, all four are pinned:

    git fetch origin 'refs/archive/001/*:refs/archive/001/*'
    git show refs/archive/001/claude-proposal:docs/proposals/codex-town-motion.md

All ten pins (`refs/archive/001/*` and `refs/archive/003/*`) were verified to
resolve to real content **before** any branch was deleted. **Both decision records
are now auditable with every doer branch gone**, which is the property the pins
exist to provide. `refs/archive/*` are pins, not branches: never sweep them.

## Active decision record

**`docs/decisions/005-walk-cycle-generation-topology.md`**, accepted, signed by
all three doers. The walk-cycle topology, shipped from `codex/art` at `18e2a1b`.

**`docs/decisions/003-village-feel.md`**, accepted, signed by all three doers.
Round 003's rulings. Its art, nav, and zoom rulings are now **implemented and
merged**, so the record is history rather than a live constraint, except where a
future round revisits the same ground (flora is cut; cursor-anchored zoom is cut;
four-cardinal snapping is not authorized).

**`docs/decisions/004-round-branch-integration-and-voting-model.md`**, accepted,
directive authority, no sign-offs owed. **This is the one to read before running
the next round**, because it governs how a round is run: round-branch
integration, doers never open PRs, one PR and one external review per round, and
the four-ballot voting model with the critic as tiebreaker only on a 2-2 split.

**`001-town-motion.md`** and **`002-team-roster-and-critic-seat.md`** stay
accepted. 001's step-4 bob fallback remains superseded. 002's standing critic vote
is **rescinded** by 004.

Next free decision number is `006`.

**The consensus gate bug is still there and is still worth a dispatch.**
`covered_entries()` in `tools/check_consensus.py` scans the whole "Protected paths
touched" section for protected-path strings **including prose**, so a record that
says "None" and then discusses `src/sim/` in a nearby paragraph reads as covering
`src/sim/`. No current record is exposed (003 lists its paths bare, deliberately).
Not a regression, never fixed, still real.

## Outstanding sign-offs

**None owed.** Every slice this round was peer-signed by a non-author resident
before integration, and all eight signed SHAs were verified as **genuine
ancestors** of the merged head before merge, so each marker names a commit that is
actually in the tree. Integration was always by `--no-ff` merge and never rebase,
so no reviewed SHA was renumbered.

**Precedent worth keeping:** a rebase or a review-round fix invalidates a
sign-off, because the marker names a SHA and the gate checks that SHA. Re-review
the delta and write a new marker. Do not repoint the old one.

## Open escalations to Scott

**NEW THIS RUN: Tiny Swords (Pixel Frog) for the traveller/vibe, decision 006.**
claude named it "by a distance, the closest thing on the internet to what Scott
is asking for" for the WC2 vibe: 64x64 top-down, Warcraft-inspired, real walk
cycles, eight buildings, terrain autotiles, flora. Its license is clear and
clearly forbids what the team would do: "you may not redistribute, resell, or
repackage the assets, even if the files are modified", so a public repo with the
PNGs committed is out, and it is not CC0/CC-BY so it fell outside Scott's
authorization. Decision 006 adopts Kenney CC0 as the license-clean baseline and
escalates Tiny Swords rather than silently dropping it, because the unlock is
large enough that Scott should decline it knowingly rather than never see it.
The path if Scott wants it: a private repo, or direct permission from Pixel Frog.
Nothing blocks on this; Kenney ships this round regardless. `<https://pixelfrog-assets.itch.io/tiny-swords>`

**STILL OPEN, unchanged and now less urgent.**

**The Codex review bot's reliability (`request_id=846fef69-6bf4-411c-aa71-5c55bc3ca1f8`,
filed 2026-07-17T04:26Z).** Nothing blocks on it.

The picture is now more nuanced than when it was filed, and Scott should have the
update: **the bot is not dead.** It reviewed PR #19 twice unprompted (on
`f040ed1` at 06:40Z and on `cdbee2d` at 07:10Z, both auto-triggered on push) and
its findings were substantive and correct every time, including catching my own
botched remediation. What it did not do is answer an explicit `@codex review`
request against the final head `4de5de7`, silent for 25+ minutes against a 3m36s
latency on PR #17. So the failure mode looks intermittent, not terminal.

**I merged #19 on the two reviews that ran, and that is a judgement Scott should
see stated rather than buried.** The distinction from PR #18 is the whole basis:
#18 was escalated and held because the gate **never ran at all**, so there was no
review to address. Here the gate ran, spoke twice, and every finding was fixed.
The only delta it never saw is `4de5de7`, which is seven single-character
substitutions in bookkeeping markers and is *precisely the remedy the bot itself
prescribed*. Requiring a fresh review of the fix the reviewer demanded, and then
a review of that review, is an infinite regress no round could clear. If Scott
disagrees with that reading, the rule to write down is what "the Codex review
gate must pass" means when the gate has reviewed an earlier commit but not the
head.

**Two interpretations from round 003 that Scott may want to correct.** Neither
blocked the round and both are shipped:

1. **"Keybindable zoom" was interpreted as InputMap actions ready for a later
   remapping UI, not a remapping UI this round.** The repo has no control-remapping
   UI to extend. If Scott meant a real rebinding UI, that is its own dispatch.
2. **Cursor-anchored zoom was cut**, because the camera is a child of the player
   node (`scenes/player.tscn:18`). Anchoring zoom to the cursor needs a camera
   reparent or a drag-pan system, neither priced. It is a camera-rig dispatch with
   its own scene-contract change.

## Notes for the next run

**The claude harness hit 529 Overloaded repeatedly this run** (killed the phase-1
claude proposal after it wrote but before it committed, and killed the first
claude sign-off dispatch outright). Both recovered: the phase-1 artifact was
committed verbatim by the orchestrator, and the sign-off retried clean on a
second dispatch. Lesson reconfirmed: the end marker is the authority. A 529
leaves `exit_code=1`, `branch_changed=no`, `uncommitted_work=yes`, and a
plausible-looking transcript; only the marker plus the tree tell the truth. If
the claude harness keeps 529ing next run, its dispatches are the ones to retry,
not the codex/agy ones.

**Two mechanical sign-off defects caught and fixed this run, both worth
remembering.** (1) agy signed with the name token `Antigravity` instead of
`agy-worker`; the consensus gate keys on the exact `Workers dispatched` name, so
that would have red the gate. Re-dispatched agy to fix only its own line. (2) The
first synthesis draft omitted agy's verbatim concession from the Dissent section
(it quoted claude and codex but not agy), and **agy correctly refused to sign
until it was added**. That refusal is the sign-off gate working as designed: a
doer holding the referee to the verbatim-dissent rule. Adding it reset codex's
sign-off to PENDING (record substance changed after codex signed) and all three
were re-collected against the corrected text, per the invalidates-on-edit
precedent. When a synthesis claims every party conceded, quote every party.

**Doer branches are LOCAL-ONLY (Dalinar steer, 2026-07-17T13:10Z, inbox
`2026-07-17-1310-*`).** Both `claude/004-proposal` and `codex/004-proposal` got
pushed to origin by their worker dispatches this run; Scott spotted it. Deleted
both remotes this run. Only the round branch and its single end-of-round PR ever
reach GitHub. The steer asks that this be codified: the current framework text
says "no PRs" but not "no pushes", and the gap is what let this happen. Not a
gate breach, no work lost, but the codification is owed. **The next dispatch
prompts must remind seats: no pushes to origin from doer branches; the
orchestrator pushes the round branch and nobody else pushes anything.**

**Follow-up work this round deliberately did not do**, in the order a next round
should probably take it:

1. **Pin the zoom index remap** and **add an epsilon to the bounds assertions**
   (the two observations from claude's sign-off, quoted in full above). Small,
   well-specified, and the reasoning is already written.
2. **Flora**, cut by decision 003. The obvious next feature and Scott's original
   stretch goal.
3. **The `check_consensus.py` prose bug** described above.
4. **An anchor-drift gate in `process_assets.py`** (Scott's 0430 steer, explicitly
   "team's call"): the sprite-forge technique of enforcing a stable
   bottom-anchor-line across walk frames with a numeric gate. Composes with the
   colored-boots check: boots verify foot **alternation**, anchor drift verifies
   **ground contact**. Never implemented; the provenance is in decision 004.

**THE DASHBOARD POST WORKS. Do not inherit the old "it 401s" assumption.** Posted
HTTP 200 this run using the token in
`/home/scott/.claude/pka-secrets/dashboard-config.md` unmodified. Treat it as
working until a POST actually fails.

**The three dashboard contract gaps are unchanged.** `DOCUMENT_AUTHORS` has no
`critic` and no `agy`; `SIGNOFF_AUTHORS` has no `agy`; the phase enum has no
`implementation`/`done`. This run posted `phase: review` with
`status_note: "done: merged 6a0b3fb"` per the brief's mapping, and named agy's
sign-off in `status_note` rather than mislabeling it in `signoffs[]`. Closing these
dashboard-side is worth more each round, not less.

**A rule of thumb this round earned twice, once by each side:** a mutation that
changes nothing showing green is not a plausible result, and `git diff --stat`
before each run is the cheap check. Both claude-worker (whose `sed` patterns had
one tab where the source had two) and I (whose fix list did not match the stage
command) shipped a verification that verified nothing. **The tree is the
authority, not the working copy and not the transcript.**

**A tension between two rules that is now visible on `main` and needs a ruling
eventually.** Three tracked files contain em-dashes, which CLAUDE.md forbids
repo-wide with no exception: `.pka/CLAUDE.md` and
`.pka/inbound/orchestrator/2026-07-17-0001-*.md` are inbound steering messages
preserved as received, and `docs/decisions/003-village-feel.md` carries them
inside the **verbatim-quoted critic vote**, which `roles/orchestrator.md` requires
be recorded verbatim. Editing a quote to satisfy a style rule defeats the reason
the quote is verbatim. None are in any open diff, so nothing is blocked. Recorded
for Scott rather than resolved unilaterally, because the honest fix is probably an
explicit carve-out in the constitution for quoted and inbound text, and the
constitution is not the team's to edit.

**The `agy` adapter's `--add-dir` worked again**, every dispatch producing real
commits in the real worktree, confirmed by branch SHA movement. The
throwaway-scratch-project failure its comments warn about has still never occurred
here.

**Branch sweep discipline.** `git branch -r --merged` reports nothing useful
because the repo squash merges (though **PR #19 was merged as a merge commit, not
a squash**, deliberately: decision 004 rests attribution on commit authorship and
`Co-authored-by:` trailers with "the branch prefixes living on in the round
branch's history", and squashing would collapse exactly that). `git branch -r`
alone lies about deleted remotes unless you `git fetch --prune` first. Before
deleting a branch, check whether a decision record cites a SHA reachable only from
it, and pin it if so.

---

**Last updated:** 2026-07-17T07:57Z (orchestrator run
`orchestrator-run-20260717-065018`). This run inherited PR #19 open and green with
an external review posted, addressed all three review findings (one already fixed,
one dispatched to agy and peer-signed by claude, one my own to fix and then to fix
again after the bot caught my botched first attempt), merged the round at
`6a0b3fb`, recorded `.review-passed` at `d9dee4f`, pinned decision 001's four
cited SHAs so the two-round-old town-motion branches could finally be swept, and
closed the round: zero open PRs, zero team branches, one worktree. Round 003 is
done.
