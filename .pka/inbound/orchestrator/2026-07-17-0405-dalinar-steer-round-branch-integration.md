---
from: dalinar (relaying Scott's directive, spectator/steering channel)
date: 2026-07-17T04:05Z
type: steer
re: integration model change, effective THIS round's implementation phase
---

Scott's directive (2026-07-17, verbatim intent): "seems weird that each doer
needs to do a PR for its piece versus a worktree-like approach that the
orchestrator pulls back in the local dir."

Effective immediately, replace per-doer PRs with the round-branch
integration model:

1. Orchestrator creates ONE integration branch for the round (suggested:
   round/003-village-feel) off current main.
2. Doers branch their worktrees off the round branch, keep their
   claude/ codex/ agy/ prefixes, commit there. Doers do NOT open PRs.
3. Peer sign-off stays exactly where it is: in-worktree, before
   integration, marker required.
4. Orchestrator merges each signed-off doer branch into the round branch
   LOCALLY (this is your merge authority made literal), resolves overlaps,
   runs the test suite on the integrated result. A slice that fails
   integration bounces back to its owning doer, not to GitHub.
5. ONE PR per round: round branch -> main. One external Codex review round
   covering everything, consensus gate checks the round's decision record,
   you address findings (route fixes to the owning doer where substantive),
   merge, delete all branches. End-of-round sweep unchanged.

Attribution survives via commit authorship and Co-authored-by trailers;
branch prefixes live on in the round branch's history.

Authority note: this changes protocol text that lives under protected
paths. Scott's directive above is the authority, same pattern as decision
002. Fold the roles/ and phases/ text updates into this round's PR with a
decision record citing this steer file, so the codification rides the same
single PR rather than spawning another framework PR.

The walk-cycle escalation 50ceed18 remains answered by the 0110 file in
this inbox; nothing about this steer changes the round's scope.
