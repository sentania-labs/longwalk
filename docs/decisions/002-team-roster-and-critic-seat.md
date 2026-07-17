# 002: seating agy as a third doer, and making the critic standing

- **Status:** accepted
- **Date:** 2026-07-17
- **Assignment:** "Wire agy in as a third doer, and make the critic a standing synthesis-time vote rather than a deadlock-only one."
- **Orchestrator run:** 2026-07-17 team-framework-hygiene dispatch, landing as PR #17.
- **Lane:** not applicable. No protocol round ran. See "Why this record has no proposals" below.
- **Workers dispatched:** None (directive authority)
- **Authority:** Scott directive, 2026-07-17: wire `agy` in as a third doer, and make the critic a standing synthesis-time vote rather than deadlock-only.

## Why this record has no proposals

This is a **directive-authority record, not a converged-synthesis record**, and
the distinction is the first thing a reader should have.

Every other record in this directory is the output of the team protocol: workers
proposed blind, critiqued each other, and the orchestrator synthesized and
recorded the dissent. `001-town-motion.md` is that shape. This one is not. No
worker proposed the third seat, no worker critiqued it, and no synthesis chose
between competing proposals, because none of those things happened. Scott
directed the change on 2026-07-17 and the team implemented it.

That is not the framework being bypassed. It is the framework's own rule being
followed. `roles/orchestrator.md`, under "Escalate to Scott, do not decide",
puts constitution edits outside what the team settles for itself, and the team's
own roster is the most constitution-adjacent thing there is: who is seated
determines who proposes, who critiques, and who signs. A team that could vote
itself a new member, or vote the critic's weight up, would be deciding the
composition of the body doing the deciding. The escalation rule exists to keep
that off the team's table, so a roster change arriving as a Scott directive is
the rule working rather than an exception to it.

What this record is for, then, is not recording a choice. It is recording that a
protected path changed, under whose authority, and on what date, so the change is
auditable later by someone who was not here. That is what the consensus gate is
actually protecting: not that the team agreed, but that a protected-path change
is never anonymous.

Fabricating a proposal SHA pair to fill the template's phase-1 table would have
made this record worse and not better. The SHAs are load-bearing precisely
because they are checkable: a reader can check out a proposal and read what a
worker actually wrote before it saw its peer's. Rows pointing at commits that
never existed would put a lie in the one field the whole auditability claim
rests on. The phase-1, phase-2, and phase-3 sections are therefore absent rather
than filled with plausible text.

## Context

The team ran `001-town-motion.md` as a two-doer round: a Claude worker and a
Codex worker, with the critic seat defined but conditional, invoked only on
deadlock or on a protected-path synthesis. That record notes at its end that
neither trigger fired and the seat was not invoked.

Two problems with that arrangement, both of which Scott's directive addresses:

**Two doers make the orchestrator a house referee.** The orchestrator runs on
Claude's harness. With exactly two workers, one of whom is also Claude, any
deadlock is settled by a Claude-family model refereeing a dispute that a
Claude-family model is a party to. A third doer from a third model family means a
disagreement can produce a 2-1 majority reading rather than a tie that the house
breaks.

**A conditional critic is a critic that never runs.** `001-town-motion.md` is the
proof: the seat existed through an entire pilot round and was invoked zero times,
because the round converged and touched no protected path. A seat whose triggers
are "things went wrong" only ever sees rounds that already went wrong, which is
the worst possible sample to calibrate on and no calibration at all in the rounds
that went fine.

## What was directed

1. **Seat `agy` (the Antigravity CLI, pinned to a Gemini-family model) as a
   third doer**, peer to the Claude and Codex workers: proposes blind in phase 1,
   critiques in phase 2, signs the record in phase 3.
2. **Make the critic seat standing.** It is invoked on every full-protocol
   synthesis, not only on deadlock or protected paths. What varies is the vote's
   weight (tiebreaker-grade on deadlock or protected paths, advisory otherwise),
   not whether it is asked.

The team's own scope, per the escalation rule, was the implementation of those
two directives and nothing above them: how the brief reads, how the templates
generalize, and how the gate parses. That work is what this PR contains.

## Protected paths touched

roles/

.github/protected-paths.txt

`roles/` is the substance: `roles/agy-worker.md` is new, and
`roles/orchestrator.md`, `roles/critic.md`, `roles/claude-worker.md`,
`roles/codex-worker.md`, and the `roles/phases/` templates change to describe a
three-doer team and a standing critic.

`.github/protected-paths.txt` is a one-line comment correction, not a change to
what is protected: its header described the gate as requiring a record "signed by
both agents", which stopped being true when `tools/check_consensus.py` moved to a
per-record signer set (see below). No path was added or removed. It is listed
here because the gate reads this section literally and a record authorizes only
what it names, not because the change is consequential.

## Sign-offs

None, and deliberately.

The convention is that every worker named in `Workers dispatched` signs. This
record names none, because no worker round happened: there was no synthesis for a
worker to read and accept, and no dissent for a signature to sit alongside. A
sign-off means "I read the synthesis and accept it as the team's decision." There
is no team decision here to accept. Collecting signatures anyway would make the
signature mean something weaker everywhere else it appears, which is a real cost
paid for the appearance of process.

The `Authority` field above stands in their place, and `tools/check_consensus.py`
enforces that substitution rather than merely permitting it: a record naming no
workers **must** state an authority, or it fails the gate. That asymmetry is the
point. Naming nobody is a claim this record makes out loud and defends in its own
text, not a default any record could quietly fall into to shed its sign-off
requirement.

This follows the precedent PR #14 and PR #15 set for the earlier protected-path
changes that had no live second-resident round to draw on: the bootstrap case is
resolved by making the authority explicit and auditable, not by simulating a
round that did not occur.
