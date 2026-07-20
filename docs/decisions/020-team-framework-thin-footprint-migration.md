# 020: adopting the shared team-framework thin footprint

- **Status:** accepted
- **Date:** 2026-07-20
- **Assignment:** "let's clean up the worktrees, migrate it to foundry and shift the team out of the repo and into the foundry framework."
- **Orchestrator run:** None. Solo infrastructure session dispatched 2026-07-20 as `longwalk-foundry-migration`, running under no role brief.
- **Lane:** not applicable. No protocol round ran. See "Why this record has no proposals" below.
- **Workers dispatched:** None (directive authority)
- **Authority:** Scott directive, 2026-07-20, recorded verbatim in the vault at `scott/reports/2026-07-20-longwalk-migration-authorization.md` (vault commit `bc2477a`).

## Why this record has no proposals

This is a directive-authority record, following the precedent and the reasoning
of [002](002-team-roster-and-critic-seat.md). No worker proposed this change, no
worker critiqued it, and no synthesis chose between competing proposals, because
none of those things happened. Scott directed it and a solo session implemented
it.

That is the constitution's own rule being followed rather than bypassed.
CLAUDE.md puts constitution edits outside what the team settles for itself, and
this change edits the constitution and removes the role briefs that define how
the team behaves. A team that could vote itself out of its own protocol
machinery would be deciding the composition of the body doing the deciding. So
the change arrives as a directive, and this record exists to make it auditable:
what changed, under whose authority, on what date.

Scott's authorization, quoted from the vault artifact named above:

> let's clean up the worktrees, migrate it to foundry and shift the
> team out of the repo and into the foundry framework.

with the scope it enumerates:

> 3. Convert longwalk from its pilot-era in-repo team machinery to the
>    shared team-framework thin footprint per
>    ~/foundry/tools/team-framework/docs/ADOPTING.md.

**No second-agent sign-off was collected, and none was fabricated.** This was a
solo session with no second resident available to genuinely review the diff.
The convention requires a pre-PR peer sign-off marker under `.team/signoffs/`
from a resident that is not the author, and writing one myself would have been a
forgery of the one artifact whose entire value is that somebody other than the
author actually looked. The `Authority` field stands in its place, which is the
substitution `tools/check_consensus.py` already enforces rather than merely
permits: a record naming no workers must state an authority or it fails the
gate. A human reviewer should treat the absence of a peer marker on the
accompanying PR as a real and disclosed gap, not an oversight.

## Context

longwalk is the project the shared team-framework was extracted from. Its
`roles/` directory, phase templates, and dispatch conventions were written here
first, during the pilot rounds recorded in decisions 001 through 004, and were
later generalized into a standalone install at `~/foundry/tools/team-framework`
so other projects could adopt them.

That leaves longwalk in an odd position: it carries in-repo copies of files the
shared install now owns. The copies are not customizations. They are the
originals, frozen at the moment of extraction, and they have been drifting out
of date ever since, because framework-level fixes land in the framework and
never come back here.

Two other things changed on the same day and are recorded here for the reader
who finds this file later wondering why paths moved:

- The repo moved from `~/claude/longwalk` to `~/foundry/projects/longwalk`.
- Its git worktrees were audited for cleanup. Nothing was removed: see
  TEAM-STATE.md's migration note for why, and for what that implies about
  round 007's landed state.

## Decision

Adopt the framework's thin footprint per `ADOPTING.md`.

**Remove the entire in-repo `roles/` tree** (`orchestrator.md`,
`claude-worker.md`, `codex-worker.md`, `agy-worker.md`, `critic.md`, and
`phases/`). Every file was diffed against its counterpart at
`~/foundry/tools/team-framework/roles/` before removal. **None of them is a
genuine fork.** Every divergence is in one direction and of one kind: longwalk's
copy is the pre-generalization original, and the framework's copy is the same
protocol with project specifics lifted out. The substitutions are mechanical,
for example "the Claude resident of longwalk" becoming "the Claude resident of
this project", "escalate to Scott" becoming "escalate to the principal", and
links to `docs/decisions/004-...` becoming "this framework's round-branch
integration model". Two files (`phases/1-proposal.md` and `phases/README.md`)
are byte-identical.

In one respect the framework's version is now strictly better here: its
orchestrator brief resolves dispatch tooling through `$TEAM_FRAMEWORK_DIR`,
where longwalk's copy hardcodes the vault path the tooling used to live at.

**Role briefs are read from `$TEAM_FRAMEWORK_DIR/roles/`.** The framework's
`bin/team-run` exports that variable when it spawns an orchestrator or a solo
worker, so it is a real resolution mechanism rather than a convention this
record is inventing. CLAUDE.md is updated to say so, and to name
`~/foundry/tools/team-framework` as the install path on this box.

**Three project facts the generalized briefs deliberately do not hardcode are
moved into CLAUDE.md**, because they would otherwise be silently lost with the
in-repo copies:

1. Commit trailers use `@sentania.net`, not the framework placeholder
   `@team.local`.
2. The `gh` repo slug is `sentania-labs/longwalk`.
3. Escalations route through `.pka/inbound/`. The framework brief says to use
   "whatever channel the human principal actually reads" and names none;
   ADOPTING.md item 4 makes naming it the project's job. `.pka/inbound/`
   predates the framework adoption and remains the only inbound mailbox.

**Add `.team/team-config.yaml`**, which longwalk never had. It records the
three-doer roster (`claude`, `codex`, `agy`), the `cursor` critic seat as
active and tiebreaker-only, and pointers to `ROADMAP.md`,
`.github/protected-paths.txt`, and `.pka/inbound/`. `bin/team-run` checks this
file's existence before dispatching an orchestrator, so without it longwalk
could not be driven by the framework at all.

**`roles/` stays listed in `.github/protected-paths.txt`** even though the
directory is now empty. This is deliberate and is the same reasoning that file
already applies to `src/sim/`: protect the path so a future forked brief is
covered the day it lands rather than the day someone remembers. Consequently
`tools/check_consensus.py`'s required-entries list is unchanged, since
`.github/protected-paths.txt` is unchanged.

**`tools/check_consensus.py` is not renamed.** ADOPTING.md instructs a new
project to copy the convention in as `tools/consensus-check.py`. longwalk's file
predates that naming convention, `.github/workflows/consensus.yml` invokes it by
its current name at two call sites, and `--self-test` passes as-is. Renaming
would be pure churn against a working gate for naming parity alone.

## Division of labor

Not applicable. Solo session, no workers dispatched.

## Dissent

None recorded, and this is the failure mode of a directive-authority record
rather than a sign of agreement: there was no second voice in the room to
dissent. Decision 002 has the same shape for the same reason.

The nearest thing to a live objection is the one this record makes against
itself, stated plainly rather than buried: removing `roles/` deletes the
reviewable in-repo diff history of how this team's protocol evolved, and
replaces it with a dependency on an install outside the repo that this repo's
CI cannot see or pin. If `~/foundry/tools/team-framework` changes underneath
longwalk, nothing here fails a test. That cost is real, it is the cost
ADOPTING.md's "a forked role brief stops receiving framework-level fixes"
tradeoff is the mirror image of, and it was accepted by directive rather than
argued down. The git history of the removed files remains in this repo, so the
evolution is recoverable by `git log` even though it is no longer browsable in
the worktree.

## Protected paths touched

CLAUDE.md

AGENTS.md

roles/

`roles/` is the substance: the whole tree is deleted. `CLAUDE.md` changes to
describe where briefs now resolve from and to carry the three project facts
listed above. `AGENTS.md` is regenerated from it by
`tools/generate_agents_md.sh`, and moves only because `CLAUDE.md` moved.

`.github/protected-paths.txt` is deliberately **not** touched and is therefore
deliberately not listed here.

## Sign-offs

None, and deliberately. See "Why this record has no proposals" above: no worker
round happened, so there is no synthesis for a worker to have read and accepted.
The `Authority` field above stands in their place.
