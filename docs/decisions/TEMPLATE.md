# NNN: <short decision title>

- **Status:** accepted | superseded by NNN | escalated to Scott
- **Date:** YYYY-MM-DD
- **Assignment:** <the assignment statement this decision came out of>
- **Orchestrator run:** <what identifies this run, see TEAM-STATE.md>
- **Lane:** full protocol | fast lane

## Context

What was assigned, and what made this decision necessary. Enough that a reader
who was not here understands the problem before reading the answer.

## Proposals (phase 1, blind)

Both workers proposed independently, neither having seen the other's proposal.

| Worker | Branch | Proposal commit SHA |
| --- | --- | --- |
| claude-worker | `claude/<branch>` | `<full 40-char SHA>` |
| codex-worker | `codex/<branch>` | `<full 40-char SHA>` |

Summarize each proposal in a paragraph. The SHAs are authoritative; these
summaries are for the reader in a hurry.

## Critique (phase 2, adversarial)

What each worker found wrong with the other's proposal. Keep the substance,
drop the courtesies.

## Decision (phase 3, synthesis)

The converged approach. Where the proposals conflicted, say which one won and
why, and say what was grafted in from the one that lost.

## Division of labor

Who does what, and the capability reasoning behind the split (which harness is
better suited to which piece, not an even division for its own sake).

| Piece | Assigned to | Why this harness |
| --- | --- | --- |
| <piece> | claude-worker / codex-worker | <capability reasoning> |

## Dissent

Any losing objection, quoted **verbatim** in the objector's own words. Not
paraphrased. If there was no dissent, say "None" and mean it: a critique round
where both workers agreed on everything is a failed round, so genuine "None"
here should be rare.

> <verbatim objection>

If the losing objection claimed a constitution violation, this record is
escalated to Scott rather than decided by the orchestrator. Note that here.

## Protected paths touched

List the paths from `.github/protected-paths.txt` this decision covers, or
"None" if this record exists for reasons other than the CI gate.

## Sign-offs

Both residents sign. The consensus CI gate greps for exactly these lines and
fails unless both appear. Signing means "I read the synthesis and accept it as
the team's decision," not necessarily "I agree with all of it"; a worker whose
objection lost still signs, and its dissent is recorded above.

    Signed-off-by: claude-worker <claude@sentania.net> YYYY-MM-DDTHH:MM:SSZ
    Signed-off-by: codex-worker <codex@sentania.net> YYYY-MM-DDTHH:MM:SSZ
