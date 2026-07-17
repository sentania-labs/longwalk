# Template: phase 2, adversarial critique

Injected into a worker's dispatch, appended after that worker's role brief.
Dispatched only once **both** proposals are committed and their SHAs recorded:
sending this to one worker while the other is still proposing leaks the first
proposal into the second, which retroactively destroys phase 1.

---

## Phase 2: critique, adversarially

Phase 1 is closed. Both proposals are committed and neither of you saw the
other's while writing your own. Read the peer's now, and attack it.

**Your proposal:** `<branch>` at `<full 40-char SHA>`
**Peer's proposal:** `<branch>` at `<full 40-char SHA>`

Read the peer's proposal from its branch, read-only. Do not edit in its
worktree.

### Steelman first, then attack

Before you write a single criticism, state the strongest version of the peer's
proposal in one or two sentences. Not a summary and not a courtesy: the
strongest version. If its argument would be better with a premise it left
implicit, supply that premise. If you can see a version of it that answers your
first objection, that is the version you are supposed to be attacking.

This is here because the failure mode is real and it is invisible from the
inside. It is much easier to demolish a slightly weakened reading of a proposal
than the proposal itself, and the demolition feels identical either way. The
steelman is what makes your critique land on the real thing. It is also the
cheapest way to find out that your objection was already answered, which is
worth knowing before you spend a round on it.

If steelmanning it makes it better than your own proposal, say that. That is a
finding, not a defeat, and it is one of the more valuable outputs this round
can produce.

### Then attack it

Adversarial means actually trying to find what is wrong with it, not politely
noting that alternatives exist. Aim at:

- **Wrong assumptions.** What does it take as given that is not true in this
  repo? A constraint from the constitution it did not account for, a file that
  does not work the way it assumes, a claim about the engine that is stale.
- **Hidden costs.** What does it pay for that its estimate does not include?
  Work it pushes onto a later milestone, complexity it adds somewhere the
  proposal does not look, a thing it makes harder to change later.
- **Where it breaks at scale.** Fine for one sprite, what about two hundred?
  Fine for one player, what about the sim layer running headless on a server?
  Fine today, what about after the ecology layer lands? The roadmap is
  available to you and the proposal has to survive it.

Constitution conformance is fair game and high-value: determinism (no stateful
or unseeded RNG in a placement decision), sim/render separation (nothing under
`src/sim/` reaching for a viewport, camera, or UI node), cross-platform
cleanliness. A proposal that violates one of these has a problem you can name
precisely, which is the most useful kind of critique there is.

Be specific enough to be answerable. "This will not scale" is not a critique.
"This regenerates the whole layout every tick, so it is O(n) per frame in town
size, and the starter town is already <n>" is one, because it can be refuted
with a number.

### "Looks good" is a failed round

A critique round where every worker says the others' proposals look good is a
failed round, not a converged one, and it gets sent back. This is not a
threat, it is a definition: the round produced nothing, so it did not happen.

If you genuinely believe a peer's proposal is better than yours, the response
is not "looks good." It is to say which part is better and why, **and** to keep
attacking the parts that are still weak. The best proposal in the room still
has the most useful critique in the room aimed at it. Agreement is not the goal
of this round. Finding what is wrong is the goal, including in a proposal you
expect to win.

Two workers who cannot find anything wrong with each other's work have almost
certainly not looked hard enough, because the base rate of flawless proposals is
not high enough to explain it twice in a row.

### Required output

For each point: what you are attacking, why it is wrong or costly, and what you
think should happen instead. Concede explicitly where the peer is right,
including where it is right and you were wrong: a concession in phase 2 is what
lets phase 3 synthesize rather than referee.

Commit the critique on your branch and report the SHA to the orchestrator, same
as phase 1. The decision record cites it. Your turn is over when the critique
is committed and its SHA is reported, not when it is written.

If your critique amounts to a claim that the peer's proposal violates the
constitution, say so in exactly those terms and name the rule. That phrasing
matters procedurally: a losing objection claiming a constitution violation is
escalated to Scott rather than settled by the orchestrator.
