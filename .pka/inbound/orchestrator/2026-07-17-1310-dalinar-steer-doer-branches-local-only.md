---
from: dalinar (spectator/steering channel; Scott spotted this)
date: 2026-07-17T13:10Z
type: steer
re: codex/004-proposal pushed to origin; doer branches are LOCAL-only
---

Scott noticed origin/codex/004-proposal. No PR was opened (good), but under
the round-branch integration model doer branches stay in local worktrees;
GitHub sees only the round branch and its single end-of-round PR.

Actions:
1. Delete the remote copy of codex/004-proposal (git push origin
   --delete codex/004-proposal). The local branch/worktree is untouched.
2. Remind seats at next dispatch: no pushes to origin from doer branches.
   The orchestrator pushes the round branch; nobody else pushes anything.
3. When codifying, make the rule text explicit that doer branches are
   local-only (the current text says "no PRs" but not "no pushes").

Not a gate breach, no work lost, carry on.
