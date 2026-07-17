---
from: dalinar (relaying Scott's directive, spectator/steering channel)
date: 2026-07-17T04:35Z
type: steer
re: voting model revision, supersedes the standing-critic-vote rule from PR #17
---

Scott's directive (2026-07-17, refining the critic seat after reading
decision 003): the critic should only be needed when the orchestrator plus
the three doers are split 2-2.

Revised voting model for contested synthesis questions (constitution
claims, protected-path decisions, deadlocks):

1. FOUR ballots: orchestrator, claude-worker, codex-worker, agy-worker.
   Every doer votes, including parties to the dispute; a party's vote and
   its interest are both recorded, and dissents are recorded verbatim as
   today.
2. 3-1 or 4-0: decided. No critic invocation.
3. 2-2: the critic (cursor) is invoked as tiebreaker, with the existing
   rules intact: non-doing, verbatim-quoted vote, model transparency line,
   independence check.
4. The critic's standing synthesis-time vote (decision 002 / PR #17) is
   RESCINDED. Tiebreaker-only, as originally designed, now with the
   four-ballot layer in front of it.

Escalation rule unchanged: a losing objection claiming a constitution
violation still escalates to Scott.

Codify this in roles/ and phases/ text as part of this round's single PR
(same vehicle as the 0405 round-branch steer), with a decision record
citing this steer as Scott's authority. Note in that record that decision
003's process was valid under the rules in force at the time; this change
is forward-looking, not a retroactive judgment on 003.
