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

**Status:** ACTIVE, phase 1 closed, phase 2 (adversarial critique) dispatched. Round 2 of the team
framework, and the first live three-doer round.

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

## Phase

**Status:** `proposal` (phase 1, blind), RE-dispatched 2026-07-17T03:35Z to
three doers in parallel into three isolated worktrees.

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

**`docs/decisions/001-town-motion.md`, status accepted, signed by both.**

    Signed-off-by: claude-worker <claude@sentania.net> 2026-07-17T00:13:00Z
    Signed-off-by: codex-worker <codex@sentania.net> 2026-07-17T00:13:44Z

Commits: record `236dde3`, claude sign-off `7bd5311`, codex sign-off `282c521`.

Artifact SHAs the record cites (full 40 characters, all still valid on the
worker branches):

- Claude proposal: `00a717edb5f1d12d9f3a322ee0a680ed9868785d`
- Codex proposal: `ad0a0b3c77c930b6a5ac3306dad2c20766319f95`
- Claude critique: `6552e1df50434ab2a036db2181d71ba0a9c50573`
- Codex critique: `4ab315e37da0d44413b75009c01959d87952865d`

Note: `codex/town-motion` was rebased onto `main` during the review round, so
the *spike* commit is now `3d98b8f` (was `5eb92d0`) and the smoke is `a901bcb`
(was `552e153`). The proposal and critique SHAs above are the pre-rebase ones
the record cites; they remain reachable. The rebase was verified by claude-worker
as a clean linear replay that left `docs/decisions/` byte-identical to `main`.

**Spike outcome, recorded:** `docs/proposals/codex-spike-walk-sheet.md`, merged
to `main` via PR #16. Both rejected candidates and both prompts are preserved
under `tools/art/` as evidence.

**`docs/decisions/002-team-roster-and-critic-seat.md`, status accepted, no
sign-offs and none owed.** It is a directive-authority record, not a converged
synthesis: Scott directed the roster change on 2026-07-17, no worker round ran,
so it cites the directive as its authority instead of worker signatures. It
covers the `roles/` and `.github/protected-paths.txt` changes that landed in
PR #17. Read its "Why this record has no proposals" section before writing
another record of this kind; the category is narrow and is not a shortcut around
the protocol.

Next free decision number is `003`.

**The record schema changed in PR #17 and a new field is required.** Every
record now carries a machine-parseable `Workers dispatched` header line naming
the workers the round actually dispatched, and `tools/check_consensus.py` builds
its required-signer set from that line rather than from a hardcoded pair of
names. Fill it in when you author a record, or the gate fails the record as
unauditable. A record with no worker round writes
`Workers dispatched: None (directive authority)` **and** an `Authority` line;
both together or neither, the gate enforces it. `001-town-motion.md` was
backfilled with the field (`claude-worker, codex-worker`) rather than the gate
carrying a legacy fallback, so there is exactly one parsing path. See
`docs/decisions/README.md`.

**Known pre-existing gate bug, not fixed in PR #17, worth a future dispatch.**
`covered_entries()` in `tools/check_consensus.py` scans the whole "Protected
paths touched" section for protected-path strings, including explanatory prose.
`001-town-motion.md` says "None" there and then discusses `src/sim/` in the
paragraph below, so the gate reads it as covering `src/sim/`. That record could
therefore be cited to wave a `src/sim/` change through the gate. It was found
while verifying PR #17 and left alone deliberately: it is out of scope for that
PR's review round, and it is not a regression from it.

## Outstanding sign-offs

**Status:** none owed.

- Decision 001: signed by both.
- PR #16: signed by claude-worker (the non-author), twice. The first marker
  `.team/signoffs/codex-town-motion-552e153d009f.md` covers the pre-rebase head;
  the second `.team/signoffs/codex-town-motion-f6c7d77908d0.md` covers the
  merged head and supersedes it. The first was deliberately NOT rewritten to
  point at the new SHA: it records a real review of a real commit, and editing
  it would have laundered a review that did not happen.

**Precedent worth keeping:** a rebase or a review-round fix invalidates a
sign-off, because the marker names a SHA and the gate checks that SHA. Re-review
the delta and write a new marker. Do not repoint the old one.

## Open escalations to Scott

**ONE OPEN, and it blocks the assignment's stated minimum.**

**The art spike failed. Whether the procedural fallback may ship is Scott's.**

- Filed 2026-07-17T00:24Z via the `.pka` channel,
  `request_id=50ceed18-9978-4a82-857d-ffbd06bc59e3`, urgency high, to `scott`.
  Response lands in `.pka/inbound/orchestrator/`.
- Trigger: decision 001 step 4, which armed exactly this and was conditional
  until now. It is open now.
- Why it is not the team's call: the assignment said "walk cycle at minimum."
  Both workers agree on the record that a bob on a rigid billboard is not a walk
  cycle (Claude conceded the crux in phase 2; Codex asked for explicit
  acceptance in its critique). Granting that acceptance redefines the minimum
  Scott set.
- Options put to Scott: (1) accept the fallback and ship the bob, (2) spend more
  spike budget, (3) re-scope this assignment to ambient motion only and make the
  walk cycle its own assignment with a real art budget. The referee's read,
  stated as a read and not a decision: option 2, because both spike failures
  share one specific defect that looks addressable.
- **Nothing is spinning while Scott decides.** No worker is dispatched on that
  slice and no urgency is manufactured.

## Notes for the next run

**The gate said no, and that is the pilot's most useful result.** Codex was
given an explicit licence to fail the spike and it used it, on its own generated
art, against its own preferred representation, having won that argument in phase
3. Claude then independently viewed both candidates during sign-off rather than
accepting the verdict, and concurred. A gate that can only pass is not a gate;
this one demonstrably says no. Do not treat the FAIL as the pilot going wrong.

**What the two spike failures had in common, for whoever runs a widened spike.**
Both failed the same way: the feet do not reliably alternate. Candidate 1 failed
in the side row (columns 1 and 3 repeated the same contact silhouette).
Candidate 2's revised prompt attacked the side row specifically and did fix its
silhouette variety, but columns 1 and 3 still failed to reverse the leading leg,
*and the down and up rows regressed* because the revision left them unattended.
A third attempt should constrain leading-leg reversal across all three rows at
once rather than fixing one row and losing the others.

**Five items that used to live here are now rules in the briefs, not retro
notes.** The dispatch tooling's vault paths and working invocation shape,
dispatches being synchronous, verifying from end markers rather than exit codes,
rebasing worker branches onto `main` before opening a PR, and PR hygiene. All of
them are in `roles/orchestrator.md` now (see "Dispatch mechanics", "Rebase onto
main before opening a PR", "PR hygiene"), and the worker-facing halves are in
each worker brief. Read the brief; it is the source of truth. They were removed
from this file deliberately rather than kept in both places, because this file
is overwritten every run and a rule that lives only here is a rule that lasts
until someone forgets to copy it forward. Twice now, someone did.

**The Codex review gate is the `chatgpt-codex-connector` bot, not codex-worker.**
It posts automatically on PR open, roughly 2-3 minutes in, as a review with
inline comments. `gh pr view <n> --json reviews` shows only the wrapper text;
the actual findings are at
`gh api repos/sentania-labs/longwalk/pulls/<n>/comments`. It being a separate
identity is what keeps the gate clear of the no-self-review rule when
codex-worker authored the PR.

Both of its P1s on #16 were worth having, and one was a false positive with a
real cause: it reported the decision record missing, because the branch was
based on a pre-`001` commit and it reads the branch tree. This is now the
recorded reason behind the rebase-before-PR rule in `roles/orchestrator.md`.

**Grafting a fix onto a review finding is the orchestrator's call, and I made
one:** the smoke-texture P1 offered two remedies, and the dispatch directed the
Godot-primitive one rather than routing a 24px gradient circle through an
`image_gen` pipeline built for character art. Recorded here because it is a
judgement, not a mechanical fix.

**Still outstanding:** the Dashboard "Team" tab (build order step 5). It is the
last unbuilt piece of the framework, and the three contract gaps below are its
scope now rather than a footnote to it.

**Stale team branches were swept on 2026-07-17** as part of the PR-hygiene
dispatch, and the sweep is now a standing end-of-round duty in
`roles/orchestrator.md`. Every merged PR's branch from #3 through #15 was still
on the remote and is now deleted. Retained on purpose, and not to be swept:
`claude/town-motion` and `codex/town-motion` (the pilot assignment is still
open), and `issue-4-world-eras` (no PR, not a team branch). Note that
`git branch -r --merged origin/main` reports nothing useful here: the repo squash
merges, so a merged branch's commits are not ancestors of `main`. Check merged
PRs' head branches instead.

**Dashboard POST still 401s. Attempted this run, same failure:**
`{"detail":"Invalid or missing X-Bridge-Token"}`. Cause unchanged: `deploy.sh`
rotates the token on every deploy, so the value in
`/home/scott/.claude/pka-secrets/dashboard-config.md` is stale. Not fixed here,
for the same reason as the prior two runs: rotating a shared token other
services depend on is an outward change taken as a side effect of narration, and
narration is not allowed to bend the protocol or reach outside the repo on its
own initiative. Needs Scott, or a run whose actual assignment is the dashboard:
re-run `deploy.sh` and update the secrets file, or read the live value from
`/srv/services/dashboard/dashboard.env` on docker.int.

Logged, not retried in a loop, every phase proceeded. **The Team tab has been
stale for this entire assignment.** The truth is in this file, in
`docs/decisions/001-town-motion.md`, and in PR #16.

**Three known contract gaps against `POST /api/team`,** worked around in
`roles/orchestrator.md`, worth closing dashboard-side: no `critic` author value,
no `agy` author value in either `DOCUMENT_AUTHORS` or `SIGNOFF_AUTHORS`, and the
phase enum has no `implementation` or `done` (folded into `execution` and
`review`, truth carried in `status_note`). This run's payload would have posted
`phase: "review"` with a `status_note` distinguishing merged-but-blocked, which
is exactly the lossy case the workaround warns about.

Two of those three got worse rather than staying flat, and a dashboard dispatch
should know why. The critic is now a standing seat, so the missing `critic`
author value bites every full-protocol round rather than the rare invoked one.
And `agy` is now a seated doer whose sign-offs `signoffs[]` cannot express at
all: there is no body field to carry the truth in the way a `documents[]` entry
can, so the brief directs that an agy sign-off be named in `status_note` and
left out of `signoffs[]` rather than posted under another resident's name. That
is a workaround around a workaround, and it is the strongest argument yet for
just adding the enum values.

**The critic seat was not invoked during the pilot, and under the rule in force
at the time that was correct:** neither trigger fired (no deadlock, no protected
path). **That rule is gone.** The critic is now invoked at synthesis on every
full-protocol assignment, with its vote recorded in the decision record every
time; the old deadlock and protected-path triggers now set the vote's weight
(tiebreaker-grade versus advisory) rather than gating invocation. Fast lane gets
no critic vote, explicitly. See `roles/critic.md` and `roles/orchestrator.md`'s
"The critic seat". The pilot is exactly why it changed: the seat's trigger was a
judgment call by the one resident whose bias the seat exists to check, and it
duly never fired. The `cursor` adapter is built and ready, and has still never
served a real vote.

**The `agy` seat is real now but has never run a live round.** `roles/agy-worker.md`
exists, `.pka/team-config.yaml` lists it, `.pka/inbound/agy/` exists, and the
adapter was smoke-tested in the vault. What has not happened is a
three-way blind proposal with an actual Gemini-family read in it. The first
full-protocol assignment after this one is that test, and the thing most worth
watching is whether the third read is genuinely different or just a third way of
saying what the other two said. Also unexercised: three-way worktree isolation,
and the orchestrator naming a reviewer now that "the other resident" is two
candidates.

---

**Last updated:** 2026-07-17 (framework hygiene dispatch, closed out and merged
as PR #17: agy seated as a third doer, critic made a standing synthesis-time
voter, orchestrator brief given the pilot's retro lessons as rules, PR hygiene
codified, stale branches swept. The review round on that PR added decision record
`002`, generalized the phase 2 and phase 3 templates off a hardcoded two-worker
shape, and moved the consensus gate to a per-record `Workers dispatched` signer
set. The "seat agy, make the critic standing, codify PR hygiene" item is done and
is no longer outstanding. The walk-cycle escalation `50ceed18` is untouched and
still open; ambient motion remains merged as `6c8e74a`, PR #16.)
