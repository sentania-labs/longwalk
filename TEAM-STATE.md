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

**Status:** none. No assignment is active. The team framework is being built;
the first pilot assignment has not been dispatched yet.

When an assignment is active, this section holds:

- **Assignment:** the goal statement as Scott gave it, verbatim.
- **Dispatched:** UTC ISO 8601 timestamp of the orchestrator run that took it.
- **Lane:** `full protocol` or `fast lane`, plus one line on why the triage
  went that way.
- **Scope:** what the team scoped the goal down to, once it has. A goal
  statement is not a scope; the scoping is itself team work.

## Phase

**Status:** not started.

For a full-protocol assignment, one of:

- `phase 1: blind proposal` (workers proposing independently, neither having
  seen the other's work)
- `phase 2: adversarial critique` (each worker critiquing the other's
  proposal)
- `phase 3: synthesis` (orchestrator converging, dividing labor by
  capability)
- `implementation` (workers building the agreed synthesis)
- `review` (pre-PR peer sign-off, external Codex review, merge)
- `done`

For a fast-lane assignment: `fast lane: dispatched` or `fast lane: review`.

Record which worker is blocking the phase, if any. A phase that has been
sitting in the same state across two orchestrator runs is a stall, and the
next run should say so here rather than quietly wait again.

## Active decision record

**Status:** none.

Link to the `docs/decisions/NNN-topic.md` record for the active assignment,
and its status (`drafting`, `awaiting sign-offs`, `signed`, `escalated to
Scott`). If both proposals are committed, record their SHAs here too, so a
resumed run does not have to go hunting for them on branches.

## Outstanding sign-offs

**Status:** none.

Two different things land here; label which is which:

- **Pre-PR peer sign-off** (`.team/signoffs/`): which branch and SHA is
  waiting, and which resident owes the review. Remember a marker covers one
  SHA: if the author pushed after the sign-off, the marker is stale and the
  review is owed again.
- **Decision record sign-off** (`docs/decisions/`): which record is waiting,
  and which resident has not signed it.

## Open escalations to Scott

**Status:** none.

Anything sent to Scott and not yet answered: what was asked, when, and what is
blocked behind the answer. Escalation-worthy topics are engine changes,
architecture changes, new dependencies, and constitution edits, plus any
deadlock where the losing objection claimed a constitution violation.

## Notes for the next run

**Status:** the framework conventions (constitution refactor, role briefs,
decision records, sign-off markers, consensus gate) have landed, and so have
the orchestrator phase prompts plus assignment template (build order step 6):
see `roles/phases/`, plus the new critic seat brief at `roles/critic.md` and
the BLOCKED marker convention at `.team/blocked/`.

Still outstanding before the pilot can run: the Dashboard "Team" tab (build
order step 5). The pilot assignment (step 7) is "bring motion to the starter
town: player walk cycle at minimum, ambient town motion if cheap."

Two known contract gaps against the dashboard's `POST /api/team` schema, both
worked around in `roles/orchestrator.md` and both worth closing dashboard-side:
the schema has no `critic` author value (critic votes post as
`author: "orchestrator"`, `kind: "decision"`, identity folded into the body
text), and its phase enum has no `implementation` or `done` (folded into
`execution` and `review`, with the truth carried in `status_note`).

Dashboard POST failures get logged here, under this heading, with a timestamp
and what was tried. A failed post never blocks the protocol.

Anything the next orchestrator run needs and cannot derive from the repo. Keep
it short. If it is long, it probably belongs in a decision record.

---

**Last updated:** 2026-07-16 (phase prompts / critic seat dispatch, no
assignment active)
