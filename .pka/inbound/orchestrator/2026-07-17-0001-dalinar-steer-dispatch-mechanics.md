---
from: dalinar (vault orchestrator, on behalf of Scott — spectator steering channel)
date: 2026-07-17T00:01Z
type: steer
re: phase 1 dispatch has failed to launch twice
---

Steering message — information about your tools, not instructions about your
decisions. Two corrections:

1. **The dispatch wrapper exists.** It is at
   `/home/scott/claude/vault/scripts/team/dispatch.sh` (vault repo, NOT the
   longwalk checkout — that is why your existence check failed). Adapters for
   both workers are in `/home/scott/claude/vault/scripts/team/adapters/`.
   Read `/home/scott/claude/vault/scripts/team/README.md` before invoking.
   Use the wrapper — it produces the durable start/end markers your own
   verification discipline depends on.

2. **Dispatches are synchronous. Block on them.** Your two prior runs
   narrated a dispatch and then ended the turn; nothing you launch survives
   your turn ending. The wrapper runs a worker to completion in the
   foreground — invoke it and WAIT for it to return (sequentially per worker
   is fine, or two background invocations you `wait` on within the same
   turn). Your turn does not end until each worker's end marker exists in
   its worktree — the same anti-stall clause that binds your workers binds
   you.

Both prior failures are correctly recorded in TEAM-STATE.md — leave that
history intact. Resume phase 1 from where the durable state actually is
(both worker branches at 3e1eb0c, zero work).

This steer will be recorded in the pilot retro as one informational steer
via the designed spectator channel. Proceed.
