# Template: phase 3, synthesis (orchestrator's own)

Not dispatched to anyone. Phases 1 and 2 are injected into worker dispatches;
this one is your own working template. You are the orchestrator and this is the
phase you personally do.

Inputs, every one of them, read before you write anything. There are two per
dispatched worker: its proposal, and its critique of the peers it was given.
The round may have dispatched two workers or three, so fill in as many rows as
you actually dispatched.

- `<worker>`'s proposal: `<branch>` at `<full 40-char SHA>`
- `<worker>`'s critique of its peers: `<full 40-char SHA>`
- `<worker>`'s proposal: `<branch>` at `<full 40-char SHA>`
- `<worker>`'s critique of its peers: `<full 40-char SHA>`

Each critique artifact covers every peer that worker was given, per
`roles/phases/2-critique.md`, so a three-doer round produces three proposals and
three critiques rather than one critique per pair. If a worker's critique
engaged only some of its peers, that is a failed critique round for the peers it
skipped: send it back rather than synthesizing over an untested proposal.

For each contested question, include the four ballots described below. Include
the critic's vote only if those ballots split 2-2.

## Synthesis is not averaging

Where the proposals conflict, pick the better one and graft in the good parts of
the loser. Do not split the difference into a third thing neither worker
proposed and neither critique tested. That third thing has the unique property
of never having been reviewed by anybody, which is worse than either input, no
matter how reasonable it looks to you right now.

You are choosing, and the record says you chose. Say which approach won, why,
and what came across from the one that lost. "Both had merit" is not a
synthesis. If both genuinely had merit on the same point, one of them had more,
and naming which is your job.

Do not run another critique round hoping for agreement. You have every proposal
and every critique. That is the input. Decide.

## Divide labor by capability, argued from the record

Assign each piece to whichever harness is better suited to it, and argue it from
what is actually in front of you: each worker's division-of-labor claim from
phase 1, and what the critiques revealed about each worker's grip on the
problem.

The claims are input, not commitments, and they are not binding. A worker that
claimed a piece can lose it, and the reason it lost it belongs in the record. A
worker whose critique showed a sharper read of some corner is a candidate to own
that corner even if it never claimed it, and that is one of the more useful
signals phase 2 produces.

Do not divide evenly for its own sake. The workers are not interchangeable and
an even split is a claim that they are. If one piece is three quarters of the
work and one harness is clearly better at it, that is the split. Record the
capability reasoning per piece, not a single sentence covering the whole
division: the per-piece reasoning is what a later run reads to judge whether
the split was right.

## Record four ballots and invoke the critic on 2-2

For every contested synthesis question, record ballots from the orchestrator,
claude-worker, codex-worker, and agy-worker. Every doer votes, including parties
to the dispute. Record a party's interest alongside its vote. A 3-1 or 4-0
result decides the question without a critic. A 2-2 result invokes the critic
as tiebreaker. This model is required by
[decision 004](../../docs/decisions/004-round-branch-integration-and-voting-model.md).

The critic writes nothing. It cannot: it runs read-only. Its vote comes back as
output and **you** put it into the record, verbatim, including its model
transparency line. If it disqualified itself, record the disqualification and
its stated reason too, then escalate the unresolved 2-2 question to Scott. A
disqualification is a fact about the decision and belongs in the record exactly
as much as a vote does.

## Record dissent verbatim

Where you went against a worker, quote the losing objection in the objector's
own words. Not paraphrased, not summarized, not tightened up. With three doers
there may be more than one losing objection; each gets recorded in its own
words rather than merged into a single summarized dissent.

Expect to be here. Synthesis that fully agreed with one proposal and left the
others with nothing to object to is the rare case, not the normal one. If you
find yourself writing "None" in the Dissent section, check whether the critique
round actually did its job, because a round where every worker agreed on
everything is a failed round.

The dissent is in the record precisely because you might be the one who is
wrong. The next reader needs the losing argument in its own words to see that,
and your paraphrase of an argument you just ruled against is not a neutral
instrument.

Escalate to Scott instead of deciding when the losing objection claims a
constitution violation. If the critic cannot break a 2-2 tie because it
self-disqualifies, escalate the unresolved question too.

## Produce the record

The output of this phase is a real file: `docs/decisions/NNN-topic.md`.

Copy `docs/decisions/TEMPLATE.md` and fill it in. Follow that template and
`docs/decisions/README.md` for the fields, the sign-off line format, the
numbering, and what the "Protected paths touched" section has to contain. Those
are not restated here on purpose. A schema written down in two places is a
schema that drifts, and the template is the one the gate reads.

Two things worth flagging because they are where synthesis records go wrong:

- **The `Workers dispatched` field.** Name every worker you dispatched, and only
  those. The gate reads this line to work out who has to sign, so a name you
  leave off is a sign-off nobody will ever be asked for, and a name you add that
  did not run is a record that can never pass.
- **Every proposal SHA, full 40 characters.** One per dispatched worker. The
  whole auditability claim rests on them.
- **The "Protected paths touched" section authorizes only what it lists.** List
  what the synthesis actually calls for, not what `0-assignment.md` forecast
  before anyone had written anything. If the forecast was wrong, this is where
  it gets corrected.

Then: get a sign-off line on the record from every worker you dispatched. A
worker whose objection lost still signs, and its dissent stays in the record;
signing means "I read the synthesis and accept it as the team's decision," not
"I agree with all of it." A record missing a sign-off from a worker it names as
dispatched is not a consensus record.

## Before you exit this phase

You are ephemeral and you are about to die. Nothing in your head survives.

1. The record exists on disk at `docs/decisions/NNN-topic.md`, committed.
2. `TEAM-STATE.md` is updated: phase, active decision record and its status,
   outstanding sign-offs, every proposal SHA.
3. The phase-transition snapshot is posted to the dashboard, per
   `roles/orchestrator.md`. A failed post does not block you; log it and move
   on.
4. The implementation dispatches are out, per the division of labor you just
   recorded.

An unwritten synthesis is not a synthesis. It is a thing that briefly existed
in the head of a process that no longer exists.
