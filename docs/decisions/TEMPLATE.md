# NNN: <short decision title>

- **Status:** accepted | superseded by NNN | escalated to Scott
- **Date:** YYYY-MM-DD
- **Assignment:** <the assignment statement this decision came out of>
- **Orchestrator run:** <what identifies this run, see TEAM-STATE.md>
- **Lane:** full protocol | fast lane
- **Workers dispatched:** claude-worker, codex-worker

> `Workers dispatched` is read by the gate, not just by humans. List every
> worker actually dispatched for this round, comma-separated, by resident name
> exactly as it appears in that worker's sign-off line (`claude-worker`,
> `codex-worker`, `agy-worker`). The gate requires a valid sign-off from each
> name you list and from no one else, so a three-doer round lists three and a
> two-doer round lists the two that ran, whichever two those were.
>
> Write `None (directive authority)` instead, and add an `Authority` line
> naming what authorized the change, only for a record where no worker round
> happened at all: a change Scott directed rather than one the team proposed and
> converged on. That record needs no worker sign-off, because no worker proposed
> it, and it must say plainly in its own text why it is that category. See
> `docs/decisions/README.md` and the escalation rule in
> `$TEAM_FRAMEWORK_DIR/roles/orchestrator.md`. Delete this instruction block
> when filling it in.

## Context

What was assigned, and what made this decision necessary. Enough that a reader
who was not here understands the problem before reading the answer.

## Proposals (phase 1, blind)

Every dispatched worker proposed independently, none having seen another's
proposal. One row per worker named in `Workers dispatched` above.

| Worker | Branch | Proposal commit SHA |
| --- | --- | --- |
| claude-worker | `claude/<branch>` | `<full 40-char SHA>` |
| codex-worker | `codex/<branch>` | `<full 40-char SHA>` |

Summarize each proposal in a paragraph. The SHAs are authoritative; these
summaries are for the reader in a hurry.

## Critique (phase 2, adversarial)

What each worker found wrong with each peer's proposal, one critique artifact
per worker per peer it critiqued. Keep the substance, drop the courtesies.

## Decision (phase 3, synthesis)

The converged approach. Where the proposals conflicted, say which one won and
why, and say what was grafted in from the one that lost.

## Division of labor

Who does what, and the capability reasoning behind the split (which harness is
better suited to which piece, not an even division for its own sake).

| Piece | Assigned to | Why this harness |
| --- | --- | --- |
| <piece> | <one of the dispatched workers> | <capability reasoning> |

## Dissent

Any losing objection, quoted **verbatim** in the objector's own words. Not
paraphrased. With three doers there may be more than one losing objection; each
gets recorded in its own words rather than merged into one summarized dissent.
If there was no dissent, say "None" and mean it: a critique round where every
worker agreed on everything is a failed round, so genuine "None" here should be
rare.

> <verbatim objection>

If the losing objection claimed a constitution violation, this record is
escalated to Scott rather than decided by the orchestrator. Note that here.

## Protected paths touched

> List the entries from `.github/protected-paths.txt` this decision covers, one
> per line, copied exactly as they appear there (for example `src/sim/`, not
> `src/sim/game_state.gd`). Write "None" if this record exists for reasons
> other than the CI gate.
>
> This section is read by the gate, not just by humans: the record authorizes
> only the paths listed here. A PR touching a protected path this record does
> not list needs its own record. Delete this instruction block when filling it
> in.

None

## Sign-offs

Every worker named in `Workers dispatched` signs, one line each, and the gate
checks exactly that set. Signing means "I read the synthesis and accept it as
the team's decision," not necessarily "I agree with all of it"; a worker whose
objection lost still signs, and its dissent is recorded verbatim above.

A directive-authority record (`Workers dispatched: None`) carries no worker
sign-offs. Its `Authority` line stands in their place, because there was no
worker round to sign.

Replace `YYYY-MM-DDTHH:MM:SSZ` with the real UTC time you signed. The gate
validates the whole line and rejects these placeholders, so an unsigned copy of
this template fails the gate rather than passing it. That is deliberate: the
template already carries the names, so the timestamp is what proves a human or
agent actually signed.

    Signed-off-by: claude-worker <claude@sentania.net> YYYY-MM-DDTHH:MM:SSZ
    Signed-off-by: codex-worker <codex@sentania.net> YYYY-MM-DDTHH:MM:SSZ
    Signed-off-by: agy-worker <agy@sentania.net> YYYY-MM-DDTHH:MM:SSZ
