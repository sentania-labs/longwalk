# Template: phase 3, synthesis (orchestrator's own)

Not dispatched to anyone. Phases 1 and 2 are injected into worker dispatches;
this one is your own working template. You are the orchestrator and this is the
phase you personally do.

Inputs, all four, read before you write anything:

- Claude worker's proposal: `<branch>` at `<full 40-char SHA>`
- Codex worker's proposal: `<branch>` at `<full 40-char SHA>`
- Claude worker's critique of Codex: `<full 40-char SHA>`
- Codex worker's critique of Claude: `<full 40-char SHA>`

Plus the critic's vote, if this synthesis is one that activates the seat. See
"Invoke the critic" below.

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

Do not run another critique round hoping for agreement. You have both
proposals and both critiques. That is the input. Decide.

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

## Invoke the critic when the seat activates

Two conditions, either one is sufficient (see `roles/critic.md`):

1. **Deadlock.** The critique round did not converge and you are deciding. Your
   vote plus the critic's forms the majority. This is what the seat is for: you
   run on Claude's harness, so you refereeing a Claude-versus-Codex deadlock
   alone is a house call.
2. **Protected paths.** The synthesis touches a path in
   `.github/protected-paths.txt`. Deadlock or not, invoke the seat.

Routine synthesis with neither condition stays two-voice: you and the two
workers. Do not invoke the critic because the decision feels weighty.

The critic writes nothing. It cannot: it runs read-only. Its vote comes back as
output and **you** put it into the record, verbatim, including its model
transparency line. If it disqualified itself, record the disqualification and
its stated reason too, and then decide without its vote on the normal deadlock
rules. A disqualification is a fact about the decision and belongs in the
record exactly as much as a vote does.

## Record dissent verbatim

Where you went against a worker, quote the losing objection in the objector's
own words. Not paraphrased, not summarized, not tightened up.

Expect to be here. Synthesis that fully agreed with one proposal and left the
other with nothing to object to is the rare case, not the normal one. If you
find yourself writing "None" in the Dissent section, check whether the critique
round actually did its job, because a round where both workers agreed on
everything is a failed round.

The dissent is in the record precisely because you might be the one who is
wrong. The next reader needs the losing argument in its own words to see that,
and your paraphrase of an argument you just ruled against is not a neutral
instrument.

Escalate to Scott instead of deciding **only** when the losing objection claims
a constitution violation. Every other disagreement, you settle.

## Produce the record

The output of this phase is a real file: `docs/decisions/NNN-topic.md`.

Copy `docs/decisions/TEMPLATE.md` and fill it in. Follow that template and
`docs/decisions/README.md` for the fields, the sign-off line format, the
numbering, and what the "Protected paths touched" section has to contain. Those
are not restated here on purpose. A schema written down in two places is a
schema that drifts, and the template is the one the gate reads.

Two things worth flagging because they are where synthesis records go wrong:

- **Both proposal SHAs, full 40 characters.** The whole auditability claim
  rests on them.
- **The "Protected paths touched" section authorizes only what it lists.** List
  what the synthesis actually calls for, not what `0-assignment.md` forecast
  before anyone had written anything. If the forecast was wrong, this is where
  it gets corrected.

Then: get both workers' sign-off lines on the record. A worker whose objection
lost still signs, and its dissent stays in the record; signing means "I read the
synthesis and accept it as the team's decision," not "I agree with all of it."
A record signed by one resident is not a consensus record.

## Before you exit this phase

You are ephemeral and you are about to die. Nothing in your head survives.

1. The record exists on disk at `docs/decisions/NNN-topic.md`, committed.
2. `TEAM-STATE.md` is updated: phase, active decision record and its status,
   outstanding sign-offs, both proposal SHAs.
3. The phase-transition snapshot is posted to the dashboard, per
   `roles/orchestrator.md`. A failed post does not block you; log it and move
   on.
4. The implementation dispatches are out, per the division of labor you just
   recorded.

An unwritten synthesis is not a synthesis. It is a thing that briefly existed
in the head of a process that no longer exists.
