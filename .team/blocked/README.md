# BLOCKED markers

A resident that genuinely cannot proceed writes a marker here, then ends its
turn. This is the one sanctioned way to end a turn without shipping the
artifact you were dispatched to ship.

It exists because of a specific failure mode: a session ending on "next I will
build X" rather than on X. That is not a blocked session, it is an unfinished
one, and from the outside the two are indistinguishable until someone goes
looking. A marker makes the difference legible, and puts the thing you need in
writing where the next run can act on it.

The bar is high. Before writing one, confirm all three:

1. You cannot answer the question yourself. A question you could answer by
   reading the repo is not a blocker, it is a task.
2. You cannot make a reversible decision and proceed. If a wrong guess costs a
   commit that is cheap to revert, guess, proceed, and say what you guessed.
3. The input you need genuinely comes from outside you: a Scott escalation, a
   peer's sign-off, an unresolved deadlock, a credential you do not have.

Not a blocker: work that is hard, work that is large, work you would rather
scope down. Scope it down, ship the smaller thing, and say what you cut.

## Filename pattern

    .team/blocked/<resident>-<UTC-timestamp>.md

- `<resident>`: `orchestrator`, `claude-worker`, `codex-worker`, `agy-worker`,
  or `critic`.
- `<UTC-timestamp>`: ISO 8601 basic form, `YYYYMMDDTHHMMSSZ`. Basic form
  because colons in filenames are not cross-platform-clean, and Windows is this
  project's primary export target (see CLAUDE.md).

Example: `.team/blocked/claude-worker-20260716T142205Z.md`

Timestamped rather than overwritten: a resident can block twice on the same
assignment for different reasons, and the sequence of what blocked when is
worth more than the latest entry alone.

## Required contents

```markdown
---
resident: claude-worker
assignment: bring motion to the starter town
phase: phase 1 blind proposal
branch: claude/walk-cycle-sprites
timestamp: 2026-07-16T14:22:05Z
blocked_on: scott | orchestrator | peer-resident | external
---

## What I need

One sentence, specific enough to act on. "The sprite sheet dimensions" is not
actionable. "Whether the walk cycle is 4-directional or 8-directional, since
ARCHITECTURE.md does not say and the answer changes the whole sprite pipeline"
is.

## What I tried first

What you read, what you ruled out, and why the answer is not derivable from the
repo. This is what stops a marker from being a question someone else has to
research from scratch.

## What is done and pushed

The commits that exist despite the block. A block is not permission to leave
partial work uncommitted: commit what you have, push it, and cite the SHA here.

## What unblocks me

The specific decision or input, and who can give it.
```

Note `timestamp` appears in both the filename and the front matter. The
filename form is basic (no colons, cross-platform-clean), the front matter form
is the readable one. They record the same instant.

## Where to put it, given worktree isolation

A worker works in its own worktree on its own branch. Committing a marker there
and stopping puts the marker on that branch and nowhere else, so the
orchestrator, reading its own checkout of `main`, sees nothing. The recovery
signal would be invisible in exactly the situation it exists for.

So a blocked worker does both of these, in order:

1. **Commit and push the marker on your own branch**, alongside whatever work
   exists. This is the durable artifact and it satisfies the anti-stall clause
   in your brief. Do not leave it uncommitted in a worktree nobody else will
   ever check out.
2. **Report the block to the orchestrator in your dispatch output**: branch,
   marker path, and the one-sentence version of what you need. The marker is
   the detail; this is the ping. A marker nobody is told about is a message in
   a bottle.

The orchestrator, on its next run, does not rely on step 2 having landed. It
enumerates the resident branches for markers under `.team/blocked/` that are
not on `main`:

    git fetch --all --quiet
    git ls-tree -r --name-only origin/<branch> -- .team/blocked/

A worker can die between committing the marker and reporting it, and that is
one of the likelier ways for a run to end. The scan is what makes the marker
findable anyway.

When the orchestrator acts on a marker, it cherry-picks or re-commits it onto
`main` so the block is visible in one place, and records the pointer in
`TEAM-STATE.md`. The orchestrator's own markers go straight onto `main`, since
it has no feature branch of its own.

## Who reads these

The orchestrator, on its next run. It reads `TEAM-STATE.md` first, which should
name the block under "Phase" (the resident blocking the phase) or "Open
escalations to Scott" if it went up to Scott. This directory holds the detail;
`TEAM-STATE.md` holds the pointer.

The critic cannot write here. It runs read-only under `cursor-agent --mode ask`
by design (see `roles/critic.md`), so a blocked critic says BLOCKED in its
output with the same contents, and the orchestrator writes the marker on its
behalf.

Resolved markers stay. Like decision records, the history of what blocked the
team is worth keeping: three markers naming the same missing input is a fact
about the framework, not about the three residents that hit it.
