# Template: phase 1, blind proposal

Injected into a worker's dispatch, appended after that worker's role brief.
Both workers get this same text with the same fill-ins, dispatched in parallel
into separate worktrees. Nothing below may hint at what the other worker is
doing, because the orchestrator does not know yet either, and must not relay it
if it did.

---

## Phase 1: propose, blind

You are proposing an approach to the assignment below. You are one of two
workers doing this independently, right now, in parallel. You will not see the
other proposal until phase 1 closes, and it will not see yours.

**Assignment:** <goal statement, verbatim from `0-assignment.md`>

**Constraints:** <constraints from `0-assignment.md`, or "None beyond the
constitution">

**Protected paths this is expected to touch:** <list, or "none">

**Branch:** <your prefix>/<assignment-slug>

### Blind means blind

Do not read the other residents' proposals, branches, worktrees, or inboxes, and
do not accept a summary of one from anyone, including the orchestrator. If you
see one by accident, say so rather than pretending you did not: an anchored
proposal that is disclosed is a recoverable problem, and one that is hidden is
not.

This is the mechanism, not the etiquette. The team is worth running only if
genuinely independent reads of the problem exist to compare. One glance
collapses yours into that read plus an anchoring effect, and then phase 2
critiques your agreement instead of testing the idea.

A corollary that is easy to miss: propose what you actually think is best, not
what you think will survive a critique. Defensive proposals converge on the
safe middle before the protocol has had a chance to do its work.

### Scope it yourself

The assignment above is a goal statement, not a scope. Deciding what it means
is part of what you are proposing, so say plainly what you are choosing to
build and what you are choosing to leave out. If you read an ambiguity in it,
resolve it in your proposal and name that you resolved it, rather than
answering a question the goal did not ask.

### Required output format

Four sections, all of them. A proposal missing one is incomplete and comes back
to you.

**1. Approach.** What you would build, and why this way rather than the obvious
alternative. Concrete enough that the other worker can attack it: name the
files, the modules, the data flow, the shape of the thing. "Use a state
machine" is not attackable. "A `sim/`-side state machine keyed off the tick,
with `render/` reading its current state each frame and owning no transitions
of its own" is.

**2. Risks.** Where this breaks. What you are unsure about. What you would find
out first if you had one hour and one question. Include the risks that make
your own approach look worse. Phase 2 exists to find these, and the other
worker will find them; naming them yourself costs you nothing and makes the
critique round land somewhere more useful than the thing you already knew.

**3. Division-of-labor claim.** Which piece of this you specifically are best
suited to own, and why: what about your harness, your strengths, or your
context makes you the better choice for that piece.

Two things this is not. It is not a commitment: phase 3 divides the labor by
capability and may hand you something you did not claim. And it is not a claim
on the whole job. If some piece is genuinely better suited to the other
resident, say so and say why. That sentence is worth more to the synthesis than
a confident claim on everything, because it is the sentence the orchestrator
cannot write for you.

**4. Rough estimate.** Rough. Order of magnitude, in whatever unit is honest
(sessions, hours, "one sitting", "this is a multi-day thing"). Say what would
blow it up. Nobody is holding you to this number, and a padded estimate is less
useful than a wrong one, because a wrong one is at least information about what
you think the shape of the work is.

### Ship it as a commit

Write the proposal as a real file on your branch and commit it. Not a scratch
file, not your dispatch output, not a message to the orchestrator: a commit.

The decision record cites your proposal by full 40-character SHA, which is what
makes it auditable. Someone reading the record in six months can check out
exactly what you proposed, before you had seen the other proposal, and judge
the synthesis against it. That only works if the artifact is a commit.

Then report the SHA back to the orchestrator. Full 40 characters, plus the
branch it is on. Your turn is not over when the proposal is written. It is over
when it is committed and the SHA is reported.
