# 004: round-branch integration, four-ballot voting, and the codex sprite skills

- **Status:** accepted
- **Date:** 2026-07-17
- **Assignment:** none. This record captures three directives Scott issued
  mid-round, during round 2 (village feel), through the `.pka` steering channel.
- **Orchestrator run:** `orchestrator-run-20260717-032957` (see TEAM-STATE.md)
- **Lane:** not applicable, no worker round ran
- **Workers dispatched:** None (directive authority)
- **Authority:** Scott directive, 2026-07-17, relayed by dalinar through the
  `.pka` steering channel in three files, all preserved in
  `.pka/inbound/orchestrator/`:
  - `2026-07-17-0405-dalinar-steer-round-branch-integration.md`
  - `2026-07-17-0430-dalinar-steer-spriteforge-capability.md`
  - `2026-07-17-0435-dalinar-steer-voting-model.md`

## Why this record has no proposals

This is a directive-authority record, the category `docs/decisions/README.md`
describes and `002-team-roster-and-critic-seat.md` established. No worker round
ran, because none of these three changes were the team's to make: two of them
edit protocol text under `roles/`, a protected path, and `roles/orchestrator.md`
puts constitution-adjacent changes outside what the team decides for itself. The
third is capability information about an external install.

Requiring worker sign-off here would ask workers to ratify something no worker
proposed. The `Authority` line above stands in place of sign-offs, and the
category is narrow: it is not a shortcut around the protocol, and a change the
team *could* have proposed does not belong here.

Both steers directing codification say the same thing about the vehicle: fold
the `roles/` and `roles/phases/` text updates into **this round's single PR**,
with a decision record citing the steer, so the codification rides the round
rather than spawning another framework PR. That is what this record is for.

## Directive 1: round-branch integration replaces per-doer PRs

Scott's words, verbatim through the steer:

> "seems weird that each doer needs to do a PR for its piece versus a
> worktree-like approach that the orchestrator pulls back in the local dir."

Effective **immediately**, from this round's implementation phase:

1. The orchestrator creates ONE integration branch per round
   (`round/003-village-feel` for this one) off current `main`.
2. Doers branch their worktrees off the round branch, keep their `claude/`,
   `codex/`, `agy/` prefixes, and commit there. **Doers do NOT open PRs.**
3. Peer sign-off is unchanged: in-worktree, before integration, marker required.
4. The orchestrator merges each signed-off doer branch into the round branch
   **locally**, which is its merge authority made literal, resolves overlaps, and
   runs the suite on the integrated result. A slice that fails integration
   bounces back to its owning doer rather than to GitHub.
5. ONE PR per round, round branch to `main`. One external Codex review round
   covering everything. The consensus gate checks the round's decision record.
   The orchestrator addresses findings, routing substantive fixes to the owning
   doer, then merges and deletes all branches. The end-of-round sweep is
   unchanged.

Attribution survives through commit authorship and `Co-authored-by:` trailers;
the branch prefixes live on in the round branch's history.

### What this cost, and why nothing was lost

This directive landed while PR #18 (the nav slice) was open and blocked. **PR #18
is closed, superseded rather than abandoned.** Its work is integrated into
`round/003-village-feel` at `39fa6f7` as a `--no-ff` merge of the exact
peer-signed commit `49a7b39`, so the review history is preserved in the branch's
history rather than discarded with the PR. The integrated result passes the full
suite (106 checks). The peer sign-off marker still names the SHA that was
actually reviewed and remains valid, because integration was a **merge** and not
a rebase, so it renumbered nothing.

One consequence worth naming rather than discovering later: the external Codex
review gate that PR #18 was blocked on now happens **once, at round end, on the
round PR**. That is a consequence of the model, not a workaround for the blocker.
The escalation about the connector (`846fef69`) stays open on its own merits.

## Directive 2: the codex seat is gaining sprite-generation skills

Capability information, not a scope change. Effective once the install completes;
**verify before relying on it** (skills present under `~/.codex/skills/`).

The codex seat gains `$generate2dsprite` and `$generate2dmap` from
`agent-sprite-forge` (github.com/0x0funky/agent-sprite-forge, vetted by Khriss,
MIT, pinned SHA in Teft's report). They wrap codex's native image generation with
deterministic Python post-processing: background removal, frame alignment, sheet
slicing, GIF assembly, and QC metadata. Scott directed the install specifically
to strengthen the codex seat's art capability. The Grok-only `$video2dsprite`
skill was **not** installed.

This bears directly on decision 003's division of labor, which gave the art slice
to codex on the argument that the pipeline *is* the Codex harness. That argument
is now stronger rather than weaker, and the slice's owner does not change.

### The anchor-drift QC technique, and why it composes

Scott flagged a technique worth porting into the team's own pipeline regardless
of which seat runs it: the skill enforces a stable bottom-anchor-line across
walk-cycle frames with a numeric gate (max anchor-y standard deviation 0.05), and
treats clamped or edge-touching frames as regeneration triggers rather than
accepted variance.

This composes with decision 003's colored-boot check along an orthogonal axis,
and the pairing is the point: **the boots verify foot ALTERNATION, anchor drift
verifies GROUND CONTACT.** Decision 003's gate can pass a sheet whose feet
alternate correctly while the whole figure bobs off the baseline, which is
exactly the "reads as a shuffle at 160px" failure claude-worker warned its own
check could not catch. Adding an anchor-drift gate to `process_assets.py` is
recommended as part of this round's art validation.

Implementation is the team's call. Recorded here so the idea has provenance and
so the next round does not reinvent it or credit it wrongly.

## Directive 3: four-ballot voting, and the standing critic vote is rescinded

Scott's directive, refining the critic seat **after reading decision 003**: the
critic should only be needed when the orchestrator plus the three doers are split
2-2.

Revised voting model for contested synthesis questions (constitution claims,
protected-path decisions, deadlocks):

1. **FOUR ballots:** orchestrator, claude-worker, codex-worker, agy-worker. Every
   doer votes, **including parties to the dispute**; a party's vote and its
   interest are both recorded, and dissents are recorded verbatim as today.
2. **3-1 or 4-0: decided.** No critic invocation.
3. **2-2: the critic (cursor) is invoked as tiebreaker**, with the existing rules
   intact: non-doing, verbatim-quoted vote, model transparency line,
   independence check.
4. **The critic's standing synthesis-time vote from `002` / PR #17 is
   RESCINDED.** Tiebreaker-only, as originally designed, now with the four-ballot
   layer in front of it.

The escalation rule is unchanged: a losing objection claiming a constitution
violation still escalates to Scott.

### This is forward-looking, not a retroactive judgment on 003

Scott's steer says so explicitly and this record repeats it because the next
reader will wonder: **decision 003's process was valid under the rules in force
at the time.** The critic was invoked at 003's synthesis because the standing-vote
rule then required it, and its vote was tiebreaker-grade because 003 touches
protected paths. Nothing about 003 is reopened.

Worth recording alongside it, because it is the evidence this directive was
issued against: 003's critic vote was **not** a rubber stamp. It voted with the
orchestrator on both questions, but it also refused to over-read codex-worker's
constitution claim, preserved codex's losing position as a design preference
rather than a sustained finding, and independently found what all three workers
missed (`BuildingPlacement.sprite_key` already exists at
`src/sim/town_layout.gd:30`). Under the new model that round would have been
decided by four ballots without the critic, and that finding would not have
surfaced. That is the tradeoff Scott has chosen, and it is a real one in both
directions: the four-ballot layer makes every doer state a position and own it,
which the standing-critic model never required of them.

## Decision

All three directives are adopted as stated. They are Scott's to make and the team
does not get a vote on them.

The `roles/` and `roles/phases/` text codifying directives 1 and 3 is **not
written by this record**. The orchestrator does not write protocol text into a
protected path, and `roles/` is protected. That codification is a slice to be
dispatched to a doer, integrated into `round/003-village-feel`, and shipped in
this round's single PR, citing this record.

## Division of labor

Not applicable to this record. The codification slice's owner is assigned in
`TEAM-STATE.md` when it is dispatched.

## Dissent

None, and this is one of the rare cases where "None" is honest rather than a
failed round: no worker round ran, because these are directives rather than
proposals. No worker was overruled, so no worker has a dissent to record.

## Protected paths touched

roles/

## Sign-offs

None, and none owed. This is a directive-authority record: the `Authority` line
above stands in place of worker sign-offs, because no worker round ran and no
worker proposed any of it. See `docs/decisions/README.md` and
`002-team-roster-and-critic-seat.md` for the category.
