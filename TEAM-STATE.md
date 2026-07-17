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

**Status:** ACTIVE, phases 1-3 COMPLETE, implementation partly done on the round
branch. Decision 003 signed by all three doers and on `main` at `f4c7dc5`.
**Scott issued three steers mid-run that changed the protocol; see "Three steers
landed mid-run" below and `docs/decisions/004-*.md`. Read them before doing
anything.**

**Assignment (goal statement, verbatim as Scott gave it, relayed through
`.pka/inbound/orchestrator/2026-07-17-0110-dalinar-escalation-reply-50ceed18.md`):**

> Goal: one round of updates delivering (in priority order):
>
> 1. **Quality character animations** - a real multi-facing walk cycle for the
>    PC at minimum (beat the one named defect from spike round 1: foot
>    alternation, judged at shipping size). More spike budget is authorized;
>    different generator framing, more revisions, or hand-authored frames are
>    all in bounds per decision 001's own option analysis.
> 2. **Zoom control** - scroll-wheel plus keybindable zoom in/out on the
>    overhead view.
> 2b. **Click-to-move** (Scott, 2026-07-17 follow-up): NO more keyboard
>    driving. Give the player a cursor; they click where they want to go
>    and the PC walks there. This replaces WASD/arrow movement as the
>    primary control scheme.
> 3. **Visual-feel pass** - move the village view toward a Warcraft 2 /
>    Ultima Online vibe, "but for 2026": that era's readable, warm, isometric
>    character with modern rendering polish.
>
> Stretch goal (only after 1-3 are solid): **flora** - trees, bushes, ground
> cover; make it feel like a real village.
>
> Explicit exclusions: NO NPCs this round. Focus is the graphics engine and
> the base PC animation set.

**Constraints beyond the constitution:**

- Inspiration art at `/home/scott/claude/vault/tmp/longwalk-inputs/` (8 images,
  Age of Empires 1/2, Warcraft-era, isometric references). Style reference for
  the visual-feel pass and the art spike. READ-ONLY.
- The procedural bob fallback from decision 001 step 4 is SUPERSEDED and out of
  bounds. Scott ruled option 2 (more spike budget) on escalation `50ceed18`.
- No NPCs.
- Do not regress the chimney smoke shipped in PR #16. Scott called it out
  specifically as "pretty cool and a good step."

**Lane:** `full protocol`. Directed by Scott in the escalation reply, and it is
also what triage would have chosen independently: the animation approach
continues decision 001's contested lineage, and camera/control/feel scoping is
new design ground where three reasonable engineers would pick three different
shapes.

**Protected paths expected:** `src/sim/` and `project.godot`. A forecast, not a
finding: click-to-move plausibly puts movement intent in the sim layer, and zoom
keybinds plus click need input actions. Phase 3 corrects this against what the
synthesis actually calls for. **Consequence: the critic vote this round is
tiebreaker-grade, not advisory** (protected-path decision), so the mechanics in
`roles/orchestrator.md` under "When the critic votes against you" bind.

**Roster:** three doers (claude, codex, agy) plus the critic at synthesis. This
is the first live three-way blind proposal and the first real critic vote. Both
were seated in PR #17 and neither has been exercised.

## Three steers landed mid-run and changed the protocol

Scott steered three times through the `.pka` channel while this run was working,
at 04:05, 04:30 and 04:35Z. `roles/orchestrator.md` says to treat a steer as
authoritative mid-run, so all three are in force NOW, not next round. They are
recorded in full in **`docs/decisions/004-round-branch-integration-and-voting-model.md`**
(directive authority, no sign-offs owed) and the source files are preserved in
`.pka/inbound/orchestrator/`.

**1. Round-branch integration replaces per-doer PRs (0405). Effective this
round's implementation phase, which means it applied to work already in flight.**
Scott: "seems weird that each doer needs to do a PR for its piece versus a
worktree-like approach that the orchestrator pulls back in the local dir." One
round branch per round, doers branch off it and **never open PRs**, the
orchestrator merges signed-off slices in **locally** and runs the suite on the
integrated result, and the round ships **one** PR with **one** external Codex
review round. A slice that fails integration bounces to its owning doer, not to
GitHub.

**Acted on already, not just recorded:** `round/003-village-feel` exists, the nav
slice is integrated at `39fa6f7` (a `--no-ff` merge of the exact peer-signed
commit `49a7b39`, so the sign-off marker still names a SHA that is still valid;
integration was a merge, not a rebase, so it renumbered nothing), the integrated
result passes the full suite (**106 checks**), and **PR #18 is CLOSED as
superseded rather than abandoned**, with that reasoning in its closing comment.

**2. The codex seat is gaining sprite skills (0430).** `$generate2dsprite` and
`$generate2dmap` from `agent-sprite-forge`. **Verify the install before relying
on it:** skills present under `~/.codex/skills/`. Teft was installing at 04:30Z
and this run did not confirm. This strengthens the argument decision 003 already
used to give codex the art slice; the slice's owner does not change.

Also from that steer, and worth more than it looks: an **anchor-drift gate** (max
anchor-y standard deviation 0.05, clamped/edge-touching frames are regeneration
triggers rather than accepted variance). It composes with decision 003's
colored-boot check along an orthogonal axis, and the pairing is the point:
**boots verify foot ALTERNATION, anchor drift verifies GROUND CONTACT.** 003's
gate can pass a sheet whose feet alternate correctly while the figure bobs off
the baseline, which is exactly the "reads as a shuffle at 160px" failure
claude-worker said its own check could not catch. Recommended for
`process_assets.py` as part of this round's art validation. Team's call on
implementation.

**3. Four-ballot voting; the critic's standing vote is RESCINDED (0435).** Four
ballots on contested synthesis questions: orchestrator, claude-worker,
codex-worker, agy-worker. Every doer votes **including parties to the dispute**,
and a party's vote and its interest are both recorded. 3-1 or 4-0 decides with no
critic. **2-2 invokes the critic as tiebreaker**, with its existing rules intact.
The standing synthesis-time vote from decision 002 / PR #17 is gone.

**This is forward-looking and Scott said so explicitly: decision 003's process
was valid under the rules in force at the time.** Do not reopen 003. Note for the
record that 003's critic vote was not ceremony (it refused to over-read codex's
constitution claim, and found what all three workers missed at
`town_layout.gd:30`), and that under the new model that round would have been
decided by four ballots without it. That tradeoff is Scott's to make and he made
it after reading 003.

### Codification status: written, REFUSED on review, fix dispatched

**codex-worker wrote it** (`codex/roles-codify`, branched off the round branch,
worktree `/home/scott/claude/longwalk-worktrees/codex-roles-codify`), at
`a0fa153`: 7 files, **168 insertions against 347 deletions**, which is the right
shape, because the job was mostly deleting arguments for rules that no longer
exist rather than adding new ones.

**claude-worker reviewed it and REFUSED.** That is the third refusal tonight and
the third that was correct. Its two blocking findings, both one-line:

1. `roles/orchestrator.md:385`, the dashboard example payload, still reads
   `"critic seat invoked (protected path: src/sim/)"`. Under 004 a protected path
   no longer invokes the critic; only a recorded 2-2 split does. Codex fixed this
   exact trigger in `roles/phases/0-assignment.md` and missed it here. Claude's
   reasoning is worth keeping: **"A worked example showing the rescinded
   behavior is worse than prose stating it, because the next orchestrator copies
   examples."**
2. `roles/orchestrator.md:48` is a dangling cross-reference to a "deadlock
   section" the same commit renamed and gutted.

It confirmed the things most at risk survived: dispatch mechanics, the end-marker
verification rule, the blocked-worker scan, and "never end your turn on an
intention". It also confirmed the critic brief genuinely explains its own double
reversal rather than silently reverting.

**Fixed at `8528603`, re-reviewed, SIGNED, and INTEGRATED.** claude-worker signed
at the new head (marker `codex-roles-codify-85286034c11c.md`, `reviewed_by:
claude-worker`, `authored_by: codex-worker`, 04:42:49Z) after verifying both
findings and, notably, checking that the renamed cross-reference **target
actually exists** rather than trusting the rename. Integrated into the round
branch at `0c22983`; the integrated result is green.

**Two things claude raised without blocking, recorded so they are decisions
rather than accidents:**

- **codex invented a rule the steers do not contain:** a self-disqualified critic
  on a 2-2 split escalates to Scott, where the old text had the orchestrator
  decide on deadlock rules. Claude judged it a correct gap-fill and I agree and
  have directed it kept: **the orchestrator is one of the four tied ballots and
  cannot break a tie it is a party to**, so escalation is the only coherent
  outcome. The fix dispatch requires the text to say this is a gap-fill and why,
  because a rule whose origin is invisible gets "corrected" later by someone who
  assumes it was a typo.
- **"You never sign off on your own change, and you never merge your own PR" was
  deleted from all three worker briefs** as collateral to removing the adjacent
  rebase paragraph. The steers did not ask for that. Claude checked and the
  substance survives (the briefs still say a resident that is not you must review
  your diff, and the constitution has its own no-self-merge rule), so I directed
  it left alone rather than churn the slice. **Recorded because nobody decided
  it; it fell out.** If a later reader wants the explicit sentence back, that is
  a legitimate small fix, not a revert of anything.

**Original note, still true of the vehicle:** both steers direct that the
codification ride **this round's single PR** citing record `004`, rather than
spawning another framework PR. Both steers direct that it ride **this round's
single PR** citing record `004`, rather than spawning another framework PR. It is
not written yet because `roles/` is a protected path and the orchestrator does
not write protocol text into one; it is a slice for a doer.

## Phase

**Status:** `execution`. Phases 1, 2 and 3 are COMPLETE and their artifacts are
on `main`. Decision `003-village-feel.md` is signed by all three doers and pushed
at `f4c7dc5`; the consensus gate passes against a PR touching `src/sim/` and
`project.godot`. The nav slice implementation is dispatched (see "Implementation"
below). Phase 1 was re-dispatched at 03:35Z after the stall recorded below.

### The first phase 1 dispatch never ran. Read this before trusting a "dispatched" status.

The dispatch this file previously claimed was in flight (03:28) produced
nothing. Verified, not inferred: all three branches sat at the base `03b06db`
with clean worktrees, no worker end markers existed anywhere, and no worker
process was alive. The three start markers had no matching end markers, which is
the signature the orchestrator brief names.

Cause, from `.team/markers/orchestrator-run-20260717-032624-end.md`: that
orchestrator run lived **170 seconds**. It launched all three workers at
03:28:22 and exited at 03:29:14. The workers died with their parent, roughly one
minute in, each in a way that looks like an independent harness failure but is
not:

- `claude`: `Execution error` (15 bytes of log)
- `agy`: `Error: timeout waiting for response`
- `codex`: cut off mid-reasoning at 50KB of log, having reached a real read on
  the click-to-move sim/render boundary. It was working. It was killed.

Three different error strings, one cause. **This is the exact failure
`roles/orchestrator.md` names under "A dispatch is synchronous. Block on it."**
The run narrated a dispatch, did not block on it, ended its turn, and left this
file asserting in-flight work that did not exist. That assertion is what cost
the next run its first ten minutes. Failed logs are archived at
`/tmp/village-feel/logs-failed-032822/` as evidence.

The lesson is already a rule in the brief, so the brief does not need editing.
What is worth carrying forward is that a dead dispatch does **not** announce
itself as dead: it announces itself as three plausible, unrelated harness
errors. Verify from end markers and branch SHAs, per the brief, every time.

| Worker | Branch | Worktree | Proposal file |
| --- | --- | --- | --- |
| claude | `claude/village-feel` | `/home/scott/claude/longwalk-worktrees/claude-village-feel` | `docs/proposals/claude-village-feel.md` |
| codex | `codex/village-feel` | `/home/scott/claude/longwalk-worktrees/codex-village-feel` | `docs/proposals/codex-village-feel.md` |
| agy | `agy/village-feel` | `/home/scott/claude/longwalk-worktrees/agy-village-feel` | `docs/proposals/agy-village-feel.md` |

All three branched from `main` at `03b06db`. Prompt files are at
`/tmp/village-feel/phase1-<worker>.md` (ephemeral; regenerate from this file's
goal statement plus `roles/phases/1-proposal.md` if a later run needs them).

### Phase 1 CLOSED, all three proposals committed and verified

Verified from each worktree's `.team/markers/p1-<worker>-20260717-033104-end.md`
(`branch_changed: yes`, `uncommitted_work: no`, `exit_code: 0`,
`cap_expired: no`) and then against the tree itself, not from any worker's
narration. All three carry a `Co-authored-by:` trailer and contain no em-dashes.

| Worker | Branch | Proposal SHA (full 40) | Elapsed | Lines |
| --- | --- | --- | --- | --- |
| claude-worker | `claude/village-feel` | `b7faf4046a00871fdd0eb1a39f5bed623fdc4bc1` | 256s | 417 |
| codex-worker | `codex/village-feel` | `5effb7dbf12ebc1ddbff624c8a6a6deeba96c324` | 168s | 240 |
| agy-worker | `agy/village-feel` | `05e62658a1a6b0a650328e5e29c921392378dfd8` | 81s | 47 |

**The three-way blind proposal produced three genuinely different reads, which
is the thing this roster change was seated to test.** They diverge on the one
question that matters most this round, how to beat the foot-alternation defect,
and they diverge on the mechanism rather than the wording:

- **claude** argues the round-1 diagnosis stops one level short: a 3x4 sheet
  asks a diffusion model to satisfy constraints that are *relational between
  cells*, and diffusion has no cross-cell state, so candidate 2 is proof of a
  structural limit rather than prompt luck. Proposes six calls of two figures
  each (one relational constraint per call), plus a mechanical rejection gate
  (`check_walk_sheet.py`) measuring signed leading-leg reversal, calibrated
  against the two known-bad sheets.
- **codex** also abandons the single sheet, but goes per-pose with the preceding
  accepted pose supplied as a visual reference, one facing at a time, eight
  facings via mirroring. Pairs it with a stricter in-game acceptance gate at
  160px.
- **agy** keeps the single 3x4 sheet and attacks the defect with a prompt hack:
  a magenta left boot and cyan right boot to force the model's attention to
  track the leading leg, recolored back to leather brown in `process_assets.py`.

Note the spread's shape: claude and codex converge independently on "stop asking
for a finished sheet in one composition" while agy dissents and keeps the sheet.
Two independent reads landing on the same structural diagnosis is a stronger
signal than either alone, and per `roles/orchestrator.md` a 2-1 split is not a
deadlock. It is not a verdict either: agy's hack is cheap, is the only proposal
that preserves single-composition identity coherence, and is testable in one
generation. That is a real argument and phase 2 is where it gets tested.

They also split on scope: codex proposes eight facings, claude and agy do not.
And all three independently put click-to-move pathfinding in `src/sim/` with
render owning the waypoint following, which is a convergence worth noting
because it confirms the protected-path forecast.

**Phase 1 dispatch verified complete at 2026-07-17T03:35Z.**

### Phase 2 CLOSED, all three critiques committed and verified

Dispatched 03:36Z, all three landed by 03:40Z. Verified from
`.team/markers/p2-<worker>-20260717-033628-end.md` in each worktree. Each worker
critiqued BOTH peers, per `roles/phases/2-critique.md`.

| Worker | Critique SHA (full 40) | Elapsed | Lines |
| --- | --- | --- | --- |
| claude-worker | `0b70f7b282117f046d84dd4c4dd2ac1541244710` | 216s | 435 |
| codex-worker | `4bd86c6514f0b68cc38af2fe789d37b9eb71adaa` | 117s | 204 |
| agy-worker | `67ae2dfdbb21671c1f7b9fe75cc423305aa21301` | 46s | 24 |

**This was a real critique round, not a "looks good" round.** Every worker
conceded something material and every worker landed a hit that changed the
synthesis. The single best exchange in the round, worth reading in full before
touching the art pipeline:

- **agy** proposed color-coded boots (magenta left, cyan right) to force the
  generator to track the leading leg.
- **claude** conceded this beats its own pair-per-call ladder and reframed *why*
  it works better than agy argued it: the defect exists because "left leg" and
  "right leg" are semantically distinct but *visually identical*, so the model
  has no image-space signal to bind the constraint to. Colored boots change the
  constraint's modality from semantic (dropped twice) to chromatic (held
  reliably: both round-1 candidates kept one costume across twelve cells
  unasked).
- **claude** then found the flaw agy missed, which is the load-bearing one: the
  recolor pass maps the boots to brown **unconditionally**, so a sheet with the
  exact round-1 defect passes through and comes out with the defect, its only
  diagnostic signal deliberately destroyed. Agy's proposal contains no
  acceptance criterion at all.
- Resolution, now binding on the art slice: **generate colored, validate per
  source row pre-mirror and pre-recolor, then mirror, then recolor.** The
  pre-recolor image is the artifact of record and is kept under `tools/art/`.
  Claude also noted mirroring inverts the color/leg binding, so the colored
  intermediate cannot validate a mirrored row; only source rows are checked.

**Two constitution-violation claims were filed, in the required terms.** Both
are recorded in `docs/decisions/003-village-feel.md`:

1. **claude and codex, independently, against agy's proposal:** sim moving a
   `CharacterBody2D` during `_physics_process` violates sim/render separation.
   Agy **conceded** its direct-steering design in its own critique, so this
   objection won and no escalation is owed.
2. **codex against claude's proposal:** runtime `(x, y)` hash for ground variants
   plus `sprite_key` on `TownLayout` conflicts with the authored-baseline layer
   and sim/render separation. Claude never rebutted it. This one is live, it is
   what the critic seat was invoked on, and the ruling is in record `003`.

Other findings that survived into the synthesis: claude caught that the camera is
parented to the player (`scenes/player.tscn:18`), which makes codex's
cursor-anchored zoom unimplementable without an unpriced camera-rig change; and
that codex's labor split has two residents editing protected `src/sim/town_layout.gd`
concurrently, with nav tests written against a fixture the feel slice rewrites.

**Phase 2 dispatch verified complete at 2026-07-17T03:40Z.**

### ROUND BRANCH: `round/003-village-feel`, head `f9c7022`. This is where the round lives now.

Created this run per Scott's 0405 steer. **Two slices are integrated, both
peer-signed by a non-author, and the integrated result passes the full suite
(106 checks) after each merge.** Nothing is open on GitHub, which is correct
under the new model: the round ships ONE PR when the round is done, and it is
not done.

| Commit | What |
| --- | --- |
| `39fa6f7` | Integrate nav slice (`--no-ff` of peer-signed `49a7b39`) |
| `ec1453c` | Decision 004, the three steers, directive authority |
| `0c22983` | Integrate roles/ codification (`--no-ff` of peer-signed `8528603`) |
| `f9c7022` | Collect both sign-off markers onto the round branch |

**Why the markers were collected onto the round branch (`f9c7022`), which is a
new practice worth keeping:** under the round-branch model the doer branches are
disposable and get deleted at the sweep. A sign-off marker that exists only on a
doer branch is review evidence that vanishes when that branch does. The round PR
is the thing that gets reviewed and merged, so the round's evidence has to travel
with it.

**Do NOT rebase this branch.** Both markers name SHAs that are reachable from it
through `--no-ff` merges. Integration was deliberately a merge and not a rebase,
which is what keeps both sign-offs valid.

### Implementation dispatched (nav slice first, deliberately)

**Dispatched 2026-07-17T03:48Z:** `impl-nav`, claude-worker, into
`/home/scott/claude/longwalk-worktrees/claude-village-feel` on
`claude/village-feel`, cap 2400s.

Only one of the three slices is dispatched this run, and that is a judgement
worth stating rather than leaving as an apparent omission. The nav slice is the
only one with no dependency on the art spike, and its contract is the one thing
in the round both peers independently endorsed (codex: "Claude's navigation core
is the right basis"; agy conceded to it). The other two slices are NOT dispatched
because decision 003 records a real prerequisite from codex that has not been
produced yet: **all three slices need one agreed player origin, feet anchor,
world scale, and test fixture before implementation begins.** Dispatching the art
and feel slices before that contract exists would be dispatching them into a
conflict.

The worker was told explicitly **not to open a PR**. Its branch carries this
round's proposal and critique artifacts alongside the implementation, and the PR
needs sequencing behind a peer sign-off marker. Next run opens it. This is not a
parked PR; it is a branch with no PR yet.

**Result, verified from the marker and the tree, not narration:** landed at
`bb30105`, 864 insertions, clean tree, `tools/run_tests.sh` green (95 checks; the
orchestrator ran it independently rather than trusting the report).
`src/sim/nav_grid.gd` is a pure `(layout, from, to)` A*, WASD is out of
`project.godot`, and the suite includes real determinism tests (byte-identical
across rebuilds) plus "every walkable cell is reachable from the spawn (0
stranded)".

The worker also found a genuine bug while writing the contract codex demanded:
**the ring metric and the distance metric are not the same**, so stopping at the
first Chebyshev ring with a hit is wrong for Euclidean distance (at r=3 a hit at
(3,3) is 4.24 away while (0,4) on the next ring is 4.00). There is a test pinning
that case. This is codex's phase-2 objection paying off directly.

### The peer review REFUSED, and it was right. Read this one.

**codex-worker reviewed `bb30105` and did not sign off.** No marker was written.
This is the second time the team's gates have said no rather than rubber-stamped
(the first was the round-1 art spike), and it is the no-self-review rule earning
its keep, because the defect is one the author could not see.

claude-worker reported that it had "made `test_nav_grid.gd` assert all three as
invariants, so a future change that breaks one fails the suite instead of
shipping a player that wedges." Codex checked that claim against the code. The
tests only inspect **sim** data: `test_nav_grid.gd:290` checks that footprints
have positive integer dimensions and never instantiates the generated colliders,
so the suite would still pass if `starter_town.gd:117` stopped using
`footprint * TILE_SIZE` or mispositioned the collider, and it never inspects
boundary wall geometry at all.

Why this is worse than an ordinary test gap: **agy's objection ("the collision
and nav must agree by construction, not by runtime exception") is sustained as a
binding design constraint in decision 003.** The author's answer was that the
geometry already agrees and the tests pin it. The first half appears true. The
second half was not, and the second half is the entire reason the first half is
safe to rely on. An invariant nobody checks is a comment, and the wedging player
agy predicted would ship green.

**Fix dispatched** (`fix-nav`, 03:58Z) to claude-worker: assert the three claims
against actual instantiated render geometry, and prove each new assertion can
fail (break the constant, watch it go red, put it back) before trusting it
passing. **codex must then re-review at the NEW head SHA.** The refusal stands
against `bb30105` and does not transfer.

### Re-review PASSED and PR #18 is open

codex-worker re-reviewed at the new head `49a7b39` and **signed off**. Marker:
`.team/signoffs/claude-village-feel-49a7b39.md` on `codex/village-feel` at
`ee51e2e`, `authored_by: claude-worker`, `reviewed_by: codex-worker`. Checked
that `reviewed_by` differs from `authored_by` rather than assuming the reviewer
by elimination, per the brief.

Codex also ruled on claude's partial pushback and **found against its own earlier
finding on one of three points**: the player-clearance assertion had been valid
all along (it did instantiate the real player scene and read the real
`RectangleShape2D` including the offset), so two invariants were broken, not
three. Worth noting because the reviewer corrected itself on the record rather
than letting an overstated finding stand once it had won the argument.

The fix's author also caught its **own** verification being invalid: its first
mutation run reported green because the `sed` patterns had one tab where the
source has two, so it mutated nothing and read unmodified code passing as proof.
Its words: "Same class of error as the one under review, one level up." All five
mutations go red now. This is worth carrying forward as a rule of thumb: **a
mutation that changes nothing showing green is not a plausible result**, and
`git diff --stat` before each run is the cheap check.

**PR #18: https://github.com/sentania-labs/longwalk/pull/18** (open as of 04:04Z).
**CI is fully green: all four checks pass, including the consensus gate.**

**BLOCKED ON THE CODEX REVIEW BOT, which has not posted.** This is the one merge
gate not satisfied and it is why #18 did not merge this run. It is not a parked
PR in the "waiting on unrelated work" sense; it is a PR waiting on an external
service that appears to be down or degraded.

Evidence, so the next run does not repeat the diagnosis: the bot
(`chatgpt-codex-connector`) posted on PR #17 at 03:02:29Z against a 02:58:53Z
open, a latency of 3m36s, and on PR #16 at 00:40:04Z. On #18 it had not posted
**11+ minutes** after open, and `gh api .../issues/18/timeline` shows no review
event at all. Nothing about #18 is unusual: same repo, same author identity, same
branch-prefix convention.

**Do not merge #18 without it.** `roles/orchestrator.md` makes the Codex review
round a merge precondition, and the whole point of the last two rounds is that
gates which can only pass are not gates. If the bot is genuinely dead rather than
slow, that is a question for Scott (it is an external service the team does not
own), not something to route around by quietly dropping a required gate.

Everything else #18 needs is done: peer sign-off marker at the head SHA from a
non-author resident, green CI, signed decision record covering both protected
paths, branch effectively current with `main` (see the rebase ruling below).

### A rebase ruling worth knowing about, because it is a judgement not a mechanic

`roles/orchestrator.md` requires the branch be rebased onto the current tip of
`main` before a PR opens. At PR time `claude/village-feel` was **five commits
behind** `main` and I opened the PR anyway rather than rebasing. The reasoning:

- All five main-only commits touch **`TEAM-STATE.md` and nothing else**, which
  this branch does not touch. The merge is clean by inspection
  (`git diff --name-only HEAD...origin/main` returns exactly `TEAM-STATE.md`).
- The branch **already carries signed decision 003**, verified. The rebase rule
  exists for one stated, concrete reason: the Codex bot reads the branch tree and
  filed a false P1 on PR #16 saying the decision record was missing, because the
  branch was based on a pre-record commit. That reason is fully satisfied here.
- Rebasing would have **invalidated codex's sign-off**, which was 60 seconds old,
  and bought a third review round for zero risk reduction.

**And note what created the drift: my own TEAM-STATE narration commits.** The
orchestrator committing bookkeeping to `main` mid-round is what put a worker
branch five commits behind between its sign-off and its PR. That is a small,
self-inflicted friction worth watching. If it recurs, the fix is to batch
TEAM-STATE writes rather than to loosen the rebase rule.

**Next run: verify all of this from the end markers in that worktree before
believing any of it.**

### Round-1 assignment (town motion), closed out

Ambient motion shipped: PR #16, squash-merged `6c8e74a`, `.review-passed` at
`225f03a`. The walk-cycle half was blocked on escalation `50ceed18`; **that
escalation is now answered and the walk cycle is folded into round 2 above**, so
round 1 is closed rather than open. `docs/decisions/001-town-motion.md` stays
accepted and its mechanics (steps 5-10) still bind any walk-cycle work; only its
step-4 fallback is superseded.

Branches `claude/town-motion` (`17cf61e`) and `codex/town-motion` (`f6c7d77`)
are retained until round 2's animation slice lands, because decision 001 cites
proposal and critique SHAs reachable only from them. Sweep them once round 2
merges.

## Active decision record

**`docs/decisions/003-village-feel.md`, status accepted, signed by all three
doers.** This is the round's durable output and the thing to read before touching
any slice. Committed `c0e26d0`, sign-offs consolidated and pushed at `f4c7dc5`.

    Signed-off-by: claude-worker <claude@sentania.net> 2026-07-17T03:46:30Z
    Signed-off-by: codex-worker <codex@sentania.net> 2026-07-17T03:46:22Z
    Signed-off-by: agy-worker <agy@sentania.net> 2026-07-17T03:46:00Z

Each worker signed on its own branch editing only its own line; the orchestrator
consolidated. Sign-off commits: claude `424460e`, codex `e040426`, agy `ce8acd5`.
The consensus gate was run locally against a PR touching `src/sim/` and
`project.godot` and passes.

Artifact SHAs the record cites (full 40 characters). **All six are now pinned on
the remote under `refs/archive/003/*`**, so a rebase cannot orphan them and the
record's auditability no longer depends on a worker branch surviving:

    git fetch origin 'refs/archive/003/*:refs/archive/003/*'
    git show refs/archive/003/agy-proposal:docs/proposals/agy-village-feel.md

This was done because round 1 already hit the near-miss: `codex/town-motion` was
rebased mid-round and decision 001's cited SHAs survived only by luck of nothing
having been garbage-collected. Two live holes were found during this run's sweep
and both are now closed: `agy/village-feel` **had never been pushed at all** (the
agy adapter does not push, unlike the codex one), so two SHAs decision 003 cites
existed only in a local worktree; and `claude/village-feel` on the remote was
still at its proposal, with its critique and sign-off local only, while an
implementation dispatch was actively about to rebase that branch onto `main` and
renumber them. A record whose citations cannot be checked is not an auditable
record, which is the whole claim the SHAs exist to support.

**The pin was load-bearing within twenty minutes of being created, which settles
whether it was worth doing.** The `impl-nav` dispatch rebased
`claude/village-feel` onto `main` at 03:55Z, exactly as instructed, and that
rebase renumbered the very commits decision 003 cites: claude's proposal moved
`b7faf40` to `d28445a` and its critique `0b70f7b` to `5005f95`. Both original
SHAs are now unreachable from any branch and resolve **only** through
`refs/archive/003/*`. Without the pin, the record would already be citing two
commits nobody could check, and the round's whole auditability claim would have
quietly become false between one dispatch and the next. Pin the SHAs at synthesis
time, before any implementation dispatch rebases anything.

The branches are still retained as well:

- Claude proposal: `b7faf4046a00871fdd0eb1a39f5bed623fdc4bc1`
- Codex proposal: `5effb7dbf12ebc1ddbff624c8a6a6deeba96c324`
- Agy proposal: `05e62658a1a6b0a650328e5e29c921392378dfd8`
- Claude critique: `0b70f7b282117f046d84dd4c4dd2ac1541244710`
- Codex critique: `4bd86c6514f0b68cc38af2fe789d37b9eb71adaa`
- Agy critique: `67ae2dfdbb21671c1f7b9fe75cc423305aa21301`

**Every worker signed something it lost, which is the sign the round worked.**
Codex accepted the split ruling on its own constitution claim. Claude accepted
losing both the art argument and the art slice, and independently verified its
own dissent quote had not been softened. Agy accepted that winning the round's
central argument did not win it the slice.

**Rulings that bind any implementation of this round.** Do not re-litigate these;
they are decided and signed:

- Art: agy's colored boots on the 3x4 sheet. Pipeline order is binding, because
  the natural implementation does exactly the wrong thing: **generate colored,
  validate per source row pre-mirror and pre-recolor, then mirror, then
  recolor.** The pre-recolor image is the artifact of record.
- Gate: claude's hue-centroid sign-flip check may only **reject**, never pass.
  Codex's in-game capture at 160px is the accept authority.
- Three source rows (down, up, side). Diagonals are the first stretch.
  Four-cardinal snapping is **not authorized at all**.
- Nav: deterministic grid A* in `src/sim/`, physics and steering render-side.
- Zoom: player-centered discrete steps. Cursor-anchored is cut.
- No building moves this round. Flora cut.

**`docs/decisions/001-town-motion.md`** stays accepted; its mechanics (steps
5-10) still bind walk-cycle work, and only its step-4 bob fallback is superseded.
**`docs/decisions/002-team-roster-and-critic-seat.md`** stays accepted, directive
authority, no sign-offs owed.

Next free decision number is `004`.

**The gate bug from the last run is still there and is still worth a dispatch.**
`covered_entries()` in `tools/check_consensus.py` scans the whole "Protected paths
touched" section for protected-path strings including prose, so a record that
says "None" and then discusses `src/sim/` in a nearby paragraph reads as covering
`src/sim/`. Record 003 is not exposed to this (it lists its paths bare, exactly as
they appear in `.github/protected-paths.txt`, with no prose in that section, which
was deliberate). Not fixed here: out of scope for this round and not a regression.

## Outstanding sign-offs

**None owed on decision 003.** All three doers signed.

**One owed before the nav slice can open a PR:** a pre-PR peer sign-off marker
under `.team/signoffs/` from a resident that did **not** author it. Claude
authored the nav slice, so the reviewer is codex-worker or agy-worker; check the
marker's `reviewed_by` against `authored_by` rather than assuming by elimination,
per `roles/orchestrator.md`. One marker from one non-author resident clears the
gate.

**Precedent worth keeping:** a rebase or a review-round fix invalidates a
sign-off, because the marker names a SHA and the gate checks that SHA. Re-review
the delta and write a new marker. Do not repoint the old one.

## Open escalations to Scott

**ONE OPEN, filed this run. It blocks PR #18's merge and nothing else.**

**The Codex review bot has stopped posting.**

- Filed 2026-07-17T04:26Z via the `.pka` channel,
  `request_id=846fef69-6bf4-411c-aa71-5c55bc3ca1f8`, urgency normal, to `scott`.
  Response lands in `.pka/inbound/orchestrator/`.
- Trigger: `chatgpt-codex-connector` did not post on PR #18 after 21+ minutes,
  against a 3m36s latency on PR #17 and a prior post on #16. The issue timeline
  shows no review event at all. Nothing about #18 is unusual.
- Why it is not the team's call: the connector is an external service the team
  does not own, so the team cannot fix it, and waiving a required merge gate
  because the service looks unavailable is not the team's decision to make. If
  the connector is gone for good, the Codex review gate in `CLAUDE.md` and
  `roles/orchestrator.md` needs amending, and that is a constitution edit, which
  `roles/orchestrator.md` puts squarely outside what the team decides.
- Questions put to Scott: (1) is the connector expected to be down or removed?
  (2) if so, may #18 merge on the peer sign-off plus green CI alone? (3) if it is
  gone for good, the constitution needs amending.
- **Nothing is spinning while Scott decides.** No worker is dispatched on it.
- **The 0405 steer changed this escalation's urgency, though not its merits.**
  Under the round-branch model there was never going to be a per-slice external
  review, so the bot no longer blocks anything today: the Codex review round now
  happens once, at round end, on the round PR. The round cannot ship until
  priority 1 lands anyway. So this is no longer urgent, and it is still real: if
  the connector is dead, the round PR will hit the same wall, and the gate text
  in `CLAUDE.md` needs amending, which is Scott's. Do not close it on the grounds
  that it stopped hurting.

**PREVIOUSLY OPEN, NOW CLOSED:** the round-1 escalation `50ceed18` (whether the
procedural bob may ship as "the walk cycle") was **answered by Scott: option 2,
spend more spike budget**. That answer is folded into this round's assignment and
the bob fallback is out of bounds. The round-1 escalation `50ceed18` (whether the procedural bob may
ship as "the walk cycle") was **answered by Scott: option 2, spend more spike
budget**. That answer is folded into this round's assignment and the bob fallback
is out of bounds. Nothing is waiting on Scott and nothing is blocked.

**Two things Scott should know, neither of which is a blocker and neither of
which stopped the round:**

1. **"Keybindable" does not mean what it looks like it means, and the team
   interpreted rather than escalated.** Codex found that the repo has no
   control-remapping UI to extend: the settings screen exposes window mode and
   resolution, and input actions are static entries in `project.godot`. Decision
   003 interprets "keybindable zoom" as **InputMap actions ready for a later
   remapping UI**, not a remapping UI this round. Codex was explicit that this
   "should be escalated as a requirement interpretation, not silently presented
   as complete", and the second half of that sentence is the part being honored
   here: it is written down loudly rather than smuggled. If Scott meant a real
   rebinding UI, that is its own dispatch and this interpretation is wrong.
2. **Cursor-anchored zoom was cut**, because the camera is a child of the player
   node (`scenes/player.tscn:18`) and anchoring a zoom to the cursor needs either
   a camera reparent or a drag-pan system, neither of which anyone priced. If
   Scott wants it, it is a camera-rig dispatch with its own scene-contract
   change.

## Notes for the next run

**THE DASHBOARD POST WORKS NOW. Stop assuming it 401s.** Three consecutive runs
recorded it as broken with `{"detail":"Invalid or missing X-Bridge-Token"}` and
this run posted successfully, HTTP 200, twice, using the token already in
`/home/scott/.claude/pka-secrets/dashboard-config.md` unmodified. Nothing was
rotated or fixed; the value in that file is simply valid again, presumably
because `deploy.sh` has not rotated it since it was last written. The full
snapshot went up (7 documents: three proposals, three critiques, decision 003).
**The Team tab is live and true for the first time this assignment.** Treat the
token as working until a POST actually fails, and re-read this note before
inheriting the old assumption: a stale "known broken" note cost three runs a
narration they could have had for free.

**The three contract gaps are unchanged and two of them bit this run for real.**
`DOCUMENT_AUTHORS` still has no `critic` and no `agy`, and `SIGNOFF_AUTHORS` has
no `agy`. This round posted agy's proposal and critique as `author: orchestrator`
with a first line naming the real author, per the brief's workaround. The agy
sign-off was **left out of `signoffs[]` entirely** and named in `status_note`
instead, because `signoffs[]` has no body field to carry the truth in and a
sign-off attributed to the wrong resident is worse than an absent one. The phase
enum still has no `implementation`/`done`. Closing these dashboard-side is worth
more than it was: the critic is now a standing seat, so the missing `critic`
author bites every full-protocol round.

**The critic seat's first live vote happened and it earned its cost.** Model:
Composer (Cursor Auto). It established independence from all three doers, did not
disqualify, voted WITH the orchestrator on both questions, and **found something
all three workers missed**: `BuildingPlacement.sprite_key` already exists at
`src/sim/town_layout.gd:30`, so the sim/render leak codex named is pre-existing
debt rather than hypothetical. Verified against the tree. It also refused to
over-read codex's constitution claim while explicitly preserving codex's
bake-over-hash preference as a losing design preference. Note for future
invocations: it was given the orchestrator's reasoning and told to vote the
argument, and the vote is visibly not a rubber stamp. That framing is worth
reusing.

**The agy seat's first live round: the third read is genuinely different.** This
was the open question from the last run and the answer is yes. Agy's proposal was
the shortest by far (47 lines against claude's 417) and it **won the round's
central argument** on the merits, against two better-resourced proposals, because
it was the only one that questioned whether the constraint had to be semantic at
all. Do not read agy's brevity as low effort; read it as a different search. Its
critiques were also genuinely adversarial and it conceded both of its own
contested positions unprompted. Its runs are fast (81s, 46s, ~60s) which is worth
watching but has not yet correlated with worse output.

**Verifying agy's `--add-dir` behaviour, since the adapter warns about it:** it
worked. Every agy dispatch this round produced real commits in the real worktree,
confirmed by branch SHA movement. The throwaway-scratch-project failure the
adapter comments describe did not occur.

**What is left of this round, in priority order. Read this first if you are the
next run.**

Everything below happens on `round/003-village-feel`, not on `main` and not on
per-doer PRs. Doers branch off the round branch; you integrate locally; the round
ships ONE PR at the end.

1. **PRIORITY 1: the walk cycle. It is still not started and it is the thing
   Scott cares most about.** It has now failed twice and been escalated once. The
   approach is decided and signed (decision 003): agy's color-coded boots, three
   source rows, validate pre-recolor per source row, then mirror, then recolor.
   The owner is codex-worker. **Blocked on step 2 below.**
2. **Produce the shared contract decision 003 requires**: one agreed player
   origin, feet anchor, world scale, and test fixture. The art and feel slices
   are blocked behind it, and it is why they were not dispatched this run.
   Dispatching them without it means dispatching into a conflict. This is small
   and it unblocks two thirds of the round.
3. **Verify the codex sprite skills installed** (`~/.codex/skills/`, per the 0430
   steer) before relying on them for the art slice. Teft was installing at 04:30Z
   and this run did not confirm.
4. **Consider the anchor-drift gate** in `process_assets.py` (0430 steer, max
   anchor-y stdev 0.05). It is orthogonal to the boot check and covers the exact
   hole claude-worker admitted its own check could not: **boots verify
   ALTERNATION, anchor drift verifies GROUND CONTACT.**
5. **Zoom plus visual feel** to agy-worker, per 003's division of labor.
6. **Then, and only then, the round PR:** `round/003-village-feel` to `main`, ONE
   external Codex review round, address findings routing substantive ones to the
   owning doer, merge, `.review-passed` straight to `main`, delete every branch
   including the round branch. **Check `refs/archive/003/*` still resolves before
   deleting anything**; the pins exist so the doer branches are disposable.
7. **The Codex bot escalation (`846fef69`) will bite at step 6** if the connector
   is still dead, because the round PR needs the same gate PR #18 never got. It
   is not urgent until then, and it is not fixed by ignoring it.

**The Codex review gate is the `chatgpt-codex-connector` bot, not codex-worker.**
It posts automatically on PR open, roughly 2-3 minutes in. `gh pr view <n> --json
reviews` shows only wrapper text; the findings are at
`gh api repos/sentania-labs/longwalk/pulls/<n>/comments`.

**Branch and PR sweep, run this round. The previous run's sweep claim was
false and this is worth knowing about the sweep generally.** TEAM-STATE said
"Every merged PR's branch from #3 through #15 was still on the remote and is now
deleted." They were not deleted. This run found and removed six of them: PRs
`#15` (team-framework-phase-prompts), `#14` (team-framework-conventions), `#13`
(record-review-passed-display-settings), `#12` (display-settings), `#5`
(feat/m2-walkable-world), `#3` (feat/continent-mask-layer). Only `#17`
(team-framework-hygiene) had actually gone, and a stale local ref made it look
present. A sweep that is recorded but not performed is worse than one that is
skipped, because the next run reads the note and does not look.

**One open team PR at end of run: #18**, and it is not a parked PR in the
disallowed sense. Its blocker (the Codex review bot never posting) is stated in
its own body as a comment and diagnosed above. It is green, peer-signed at its
head, and merges the moment the gate runs.

Remote branches at end of run: `main`, the three `*/village-feel` (live round;
`agy/village-feel` was pushed for the first time this run), `claude/town-motion`
and `codex/town-motion` (retained: decision 001 cites SHAs reachable only from
them, sweep once round 2's animation slice lands), `issue-4-world-eras` (not a
team branch, no PR). Plus `refs/archive/003/*`, which are pins and not branches
and must not be swept.

Remember `git branch -r --merged` reports nothing useful here because the repo
squash merges; check merged PRs' head branches instead. And `git branch -r`
alone will lie to you about deleted remotes unless you `git fetch --prune` first,
which is probably how the previous run's claim came to be wrong.

---

**Last updated:** 2026-07-17T03:50Z (orchestrator run
`orchestrator-run-20260717-032957`). This run found phase 1 stalled and never
actually dispatched, re-dispatched it, and carried the round through phases 1, 2
and 3 to a signed decision record on `main` (`f4c7dc5`). First live three-doer
blind proposal, first live adversarial three-way critique, and first live critic
vote, all of which worked. The nav slice implementation is dispatched; the art
slice, which is Scott's priority 1, is not, and is blocked on the shared contract
named above.
