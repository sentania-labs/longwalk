# Template: assignment scoping (orchestrator's own)

Not dispatched to anyone. This is the orchestrator's working template for
turning a goal statement into a scoped assignment, filled in the moment a goal
arrives and before either worker is dispatched.

A goal statement is not a scope. Scott gives a goal; the team scopes it. The
scoping fight is part of the work, not preamble to it, so do not resolve it
here by deciding what the goal means. Record the goal faithfully, decide the
lane, and let phase 1 argue about the rest.

Copy the block below and fill it in. What you fill in feeds `TEAM-STATE.md`'s
"Current assignment" section and, if this goes to full protocol, the Context
section of the decision record.

---

## Goal statement (verbatim, as given)

> <Paste the goal statement exactly as Scott wrote it. Do not tidy it, do not
> expand an abbreviation, do not resolve an ambiguity you noticed. An ambiguity
> in the goal is information: it tells you the workers will have to scope it,
> and it is often the most interesting part of the assignment. If you smooth it
> out here, you have made the scoping decision yourself, in private, before
> anyone proposed anything.>

## Constraints

> <Everything that binds this assignment and is not already in the
> constitution. Deadlines, a named file or subsystem to stay inside, an
> approach Scott ruled out, a dependency that cannot be added. Write "None
> beyond the constitution" if that is the truth, and do not pad it.
>
> Constitution rules (determinism, sim/render separation, no em-dashes, branch
> prefixes) bind every assignment and do not need repeating here. Repeat one
> only if this assignment brushes against it in a way worth flagging up front.>

## Protected paths touched

> <yes / no.
>
> If yes, list the entries from `.github/protected-paths.txt` this assignment
> is expected to touch, copied exactly as they appear there (`src/sim/`, not
> `src/sim/game_state.gd`). Expected, not certain: this is a forecast made
> before anyone has written anything, and phase 3 corrects it against what the
> synthesis actually calls for.
>
> Two consequences follow from a yes, and both are automatic:
>   - The assignment goes to full protocol. A protected path is design-level by
>     definition.
>   - The critic seat is invoked at synthesis, deadlock or not. See
>     `roles/critic.md`.>

## Triage lane

> <full protocol / fast lane, plus one line of reasoning.
>
> The reasoning line is not decoration. It is what a later run reads to judge
> whether the lane was right, and it is the thing you will not remember,
> because you will be dead. One line, stating the actual reason:
>
>   - "full protocol: touches src/sim/, protected"
>   - "full protocol: two reasonable engineers would pick different sprite
>     pipelines here"
>   - "fast lane: one-line typo in a comment, no design choice in it"
>
> Full protocol for anything design-level or contested: a reasonable engineer
> could pick a materially different approach, it touches a protected path, or a
> worker flagged it as contested. Fast lane for small scoped fixes only.
>
> Unsure means full protocol. Over-protocolling a small fix wastes tokens.
> Fast-laning a design decision puts an unreviewed architecture choice in the
> repo. Those costs are not comparable and you should not pretend they are.>

---

Once filled in: write this into `TEAM-STATE.md` (goal verbatim under
"Current assignment", lane plus reasoning under "Lane", dispatch timestamp
under "Dispatched"), post the phase-transition snapshot to the dashboard per
`roles/orchestrator.md`, then dispatch phase 1 with `1-proposal.md` if the lane
is full protocol, or dispatch the single worker directly if it is fast lane.
