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

**Status:** active. Pilot run of the multi-harness team framework (build order
step 7).

**Assignment (goal statement, verbatim as Scott gave it):**

> Bring motion to the starter town: player walk cycle at minimum, ambient town
> motion if cheap.

**Dispatched:** 2026-07-16T23:52:59Z (phase 1 dispatch failed to launch; re-dispatched
2026-07-17T00:00Z, see "Phase" below)

**Lane:** `full protocol`. Directed by Scott, not left to orchestrator triage.
Recorded reasoning as directed: "full protocol: pilot run, design-level (three
viable animation approaches), Scott directed full protocol explicitly for this
assignment."

**Constraints (beyond the constitution):**

- Render-layer work. The sim/render separation applies in full: no
  simulation-side timing or state may leak into animation logic.
- Any new generated art assets follow the existing `tools/art/` pipeline
  conventions already in the repo.
- Nothing else beyond the constitution.

**Protected paths touched:** not expected. This is forecast, made before anyone
has proposed anything, and phase 3 corrects it against what the synthesis
actually calls for. The forecast is "no" because the assignment is scoped to the
render layer and the constraint above explicitly keeps timing and state out of
the sim side.

One live possibility the next run must not miss: `src/sim/` is protected and
holds `town_layout.gd`, the authored starter-town data. If either proposal wants
ambient town motion to be driven by, or to add entries to, the authored layout,
the assignment touches a protected path after all. That flips two things on
automatically: the consensus decision record must be signed by both agents
before merge, and the critic seat (`roles/critic.md`) is invoked at synthesis
whether or not the critique round deadlocks. Check this at phase 3 against the
actual proposals rather than trusting this forecast.

**Scope:** not yet scoped. A goal statement is not a scope, and the scoping
fight (generated sprite-sheet frames vs. procedural animation in Godot vs. a
hybrid) is deliberately part of what phase 1 argues about. Scott named the
scoping fight as part of the pilot's test. Do not resolve it from the referee
seat.

## Phase

**Status:** `phase 1: blind proposal`, re-dispatched 2026-07-17T00:00Z after the
first dispatch was found never to have launched.

- Claude worker: branch `claude/town-motion`, worktree
  `/home/scott/claude/longwalk-worktrees/claude-town-motion`
- Codex worker: branch `codex/town-motion`, worktree
  `/home/scott/claude/longwalk-worktrees/codex-town-motion`

Blocking on: both workers. Phase 1 closes when both proposal commit SHAs are
recorded under "Active decision record" below.

**The 2026-07-16T23:52:59Z dispatch was claimed but never happened.** This run
verified rather than assumed, per the anti-stall clause, and found: both branches
sat at `3e1eb0c` (the dispatch commit itself), `git reflog claude/town-motion`
showed a single entry (`branch: Created from main`) and no work on top, both
worktrees were clean, no `codex`/`claude`/`cursor-agent` worker process was alive,
and no BLOCKED marker existed on either branch. The prior run's own end marker
tells the story: it ran 262 seconds and exited 0. It created the worktrees, wrote
this file saying both workers were dispatched, and exited. Nothing was ever
launched.

The lesson for the next run, because this failure mode is cheap to repeat: a
dispatch is not a durable artifact and `exit_code=0` on the orchestrator run says
nothing about whether the workers ran. Only a commit on the worker's branch does.
An orchestrator that claims a dispatch and exits in four minutes has not
dispatched anything, it has written a note saying it did. Verify worker branches
before believing this file's own phase claim, including when the claim was
written by an orchestrator run that appeared to succeed.

**Re-dispatch form used (hand-rolled, no wrapper exists):** both workers launched
in parallel, in their own pre-existing worktrees, blind to each other:

- Claude: `claude -p "$(cat phase1-assignment)" --model opus --permission-mode
  bypassPermissions --append-system-prompt "$(cat roles/claude-worker.md +
  roles/phases/1-proposal.md)"`
- Codex: `codex exec --dangerously-bypass-approvals-and-sandbox "$(cat
  roles/codex-worker.md + phase1-assignment)"`

The shared assignment text was identical for both (goal statement verbatim,
constraints, protected-path warning about `src/sim/town_layout.gd`, the blind
discipline, the four-section output format, commit-and-report-SHA requirement,
proposal-only). The critical difference from the failed run: this run blocks on
the workers until they finish, rather than launching and exiting.

## Active decision record

**Status:** none yet. Drafting begins at phase 3 (synthesis), per
`roles/phases/3-synthesis.md`. Next free number is `001`; `docs/decisions/`
currently holds only `README.md` and `TEMPLATE.md`.

Proposal SHAs (full 40 characters, cited by the decision record):

- Claude proposal: not yet reported.
- Codex proposal: not yet reported.

## Outstanding sign-offs

**Status:** none. Nothing has been built yet, so no pre-PR peer sign-off is owed
and no decision record is awaiting signature.

## Open escalations to Scott

**Status:** none open.

## Notes for the next run

**The dispatch wrapper does not exist, and this run worked around it.** This
orchestrator run was told to dispatch via `scripts/team/dispatch.sh` per
`scripts/team/README.md`'s adapter contract. Neither file exists, in this repo
or anywhere on this box. That wrapper is build order step 1 in
`vault/scott/reports/2026-07-16-longwalk-team-framework-design.md` ("Teft: codex
exec dispatch wrapper, role injection, worktree isolation, durable markers, N-
harness adapter interface, two adapters"), owned by a different workspace, and
it was never built. The build order says steps 1-2 are prerequisites for the
pilot at step 7, so the pilot was started with a prerequisite missing.

This run dispatched both workers by hand instead: `git worktree add` for
isolation, then the invocation form the constitution already documents
(`claude -p --append-system-prompt "$(cat roles/claude-worker.md)"` and the
equivalent instruction prepend for `codex exec`), with
`roles/phases/1-proposal.md` appended as the phase template. The orchestrator
did not author the missing wrapper: writing it is code, and the referee seat
does not write code (`roles/orchestrator.md`). Scott should decide whether the
wrapper still gets built by its owner or whether the hand-dispatch path is good
enough to keep. Until then, every orchestrator run pays this cost by hand and
the "durable markers" part of the wrapper's remit has no implementation at all.

**The design report lives in the vault, not this repo.** It is at
`/home/scott/claude/vault/scott/reports/2026-07-16-longwalk-team-framework-design.md`.
The dispatch prompt cited it as `scott/reports/...`, a repo-relative path that
does not resolve here. Not a blocker, but it costs a search every run.

**Still outstanding from the previous run:** the Dashboard "Team" tab (build
order step 5).

**Two known contract gaps against the dashboard's `POST /api/team` schema,**
both worked around in `roles/orchestrator.md` and both worth closing dashboard-
side: the schema has no `critic` author value (critic votes post as
`author: "orchestrator"`, `kind: "decision"`, identity folded into the body
text), and its phase enum has no `implementation` or `done` (folded into
`execution` and `review`, with the truth carried in `status_note`).

Dashboard POST failures get logged here, under this heading, with a timestamp
and what was tried. A failed post never blocks the protocol.

**2026-07-16T23:53Z: dashboard POST failed, 401, phase 1 snapshot never landed.**
Tried `POST https://dashboard.int.sentania.net/api/team` with the token from
`/home/scott/.claude/pka-secrets/dashboard-config.md`. Response:
`{"detail":"Invalid or missing X-Bridge-Token"}`. That config file documents the
failure mode exactly: `deploy.sh` rotates the token on every deploy, and a 401
means the recorded token is stale. The fix is to re-run deploy.sh and update the
secrets file with the new `BRIDGE_API_TOKEN` from its output, or read the live
value from `/srv/services/dashboard/dashboard.env` on docker.int.

This run did not do that on purpose. Rotating a shared token is an outward
change to a service other things depend on, taken as a side effect of narration,
and narration is explicitly not allowed to block or bend the protocol. It needs
Scott, or a run whose actual assignment is the dashboard. Per the brief: logged,
not retried in a loop, and the phase proceeded. The Team tab is stale for this
assignment until the token is refreshed; the truth is in this file and in the
decision record either way.

---

**Last updated:** 2026-07-16T23:52:59Z (pilot assignment dispatched, phase 1
open)
