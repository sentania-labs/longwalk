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

**Status:** BLOCKED ON SCOTT, half delivered. Pilot run of the multi-harness
team framework (build order step 7).

**Assignment (goal statement, verbatim as Scott gave it):**

> Bring motion to the starter town: player walk cycle at minimum, ambient town
> motion if cheap.

**Where it actually stands:**

- **Ambient town motion: DONE and merged.** PR #16, squash-merged as `6c8e74a`.
  `.review-passed` marker recorded on `main` at `225f03a`.
- **Player walk cycle: NOT delivered, and cannot proceed without Scott.** The
  art spike ran and FAILED. Per decision 001 step 4, taking the fallback is a
  change to the assignment and is Scott's call, not the team's. Escalation is
  filed and open (see "Open escalations").

So the town moves, but the thing the assignment named as its *minimum* is the
thing that is blocked. Do not read "PR merged" as "assignment done."

**Lane:** `full protocol`. Directed by Scott, not left to orchestrator triage.

**Protected paths touched:** none. Settled, not forecast. Confirmed again at
merge: PR #16 touches no protected path, so the consensus gate did not apply
and the critic seat was not triggered.

## Phase

**Status:** `review` COMPLETE for the ambient slice (merged). The assignment as
a whole is **blocked**, not done.

Phase history: triage, phase 1 (blind proposal), phase 2 (adversarial critique),
phase 3 (synthesis, decision 001 signed by both), implementation (partial), peer
sign-off, Codex review gate, merge. All complete for what shipped.

- Claude worker: branch `claude/town-motion`, worktree
  `/home/scott/claude/longwalk-worktrees/claude-town-motion`, head `17cf61e`
  (proposal, critique, and two sign-off markers; **no implementation**).
- Codex worker: branch `codex/town-motion`, worktree
  `/home/scott/claude/longwalk-worktrees/codex-town-motion`, head `f6c7d77`
  (merged into `main` via PR #16; branch retained deliberately, not deleted).

### What shipped, verified from end markers rather than narration

| Dispatch | Harness | Result | End marker |
| --- | --- | --- | --- |
| `art-spike` | codex | **FAIL** gate call, `4ab315e` -> `5eb92d0` | `art-spike-20260717-001757-end.md` |
| `chimney-smoke` | codex | smoke landed, `5eb92d0` -> `552e153` | `chimney-smoke-20260717-002454-end.md` |
| `peer-signoff` | claude | signed `552e153`, `6552e1d` -> `8323b54` | `peer-signoff-20260717-003107-end.md` |
| `codex-review-round` | codex | both P1s fixed + rebase, `552e153` -> `f6c7d77` | `codex-review-round-20260717-004118-end.md` |
| `peer-resignoff` | claude | re-signed `f6c7d77`, `8323b54` -> `17cf61e` | `peer-resignoff-20260717-004639-end.md` |

All five: `exit_code=0`, `cap_expired=no`, `uncommitted_work=no`,
`branch_changed=yes`. Every one of them blocked in the orchestrator's own turn.
Elapsed was 304-348s each; the whole implementation-through-merge run was about
35 minutes.

**What the next run does:** nothing on the walk cycle until Scott answers. See
the escalation. If Scott's answer is in `.pka/inbound/orchestrator/`, act on it;
it is authoritative mid-run.

Depending on the answer:

- **Fallback accepted:** dispatch claude-worker on the controller/animator slice
  per decision 001's division of labor, built on the procedural pose function,
  mechanics per record steps 5-10. Then codex-worker peer sign-off, PR, Codex
  review gate, orchestrator merges. The record's mechanics bind regardless of
  representation, so they do not need re-litigating.
- **More spike budget:** dispatch codex-worker on a widened spike. See the note
  under "Notes" about what the two failures had in common; a third attempt
  should not repeat the second's mistake.
- **Re-scoped to ambient only:** the assignment is already delivered under that
  reading. Close it out and supersede decision 001's steps 1-4 with a new record
  rather than editing 001, which is signed and append-only.

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
