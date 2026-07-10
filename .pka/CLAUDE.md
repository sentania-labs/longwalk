# .pka/ — PKA Workspace Comms Zone

This directory is the communication boundary between the longwalk workspace and the PKA.

## .pka/updates/
Session-end notes from workspace Claude Code instances.
- current.md: rolling note, appended each batch session
- archive/: processed notes (moved by Riker after sweep)

## .pka/inbound/
Responses to cross-workspace requests you made. Delivered
automatically by the watcher when a downstream session writes
its response back through `agents/riker/inbox/`.

## Session log convention (background sessions only)

Write to `.pka/updates/current.md` **only when `PKA_MODE=batch`
is set in the environment** (set by `claim_and_dispatch.py` when
spawning workspace sessions). Interactive sessions where Scott is
typing do NOT write session logs.

Format:

```markdown
---
session_type: batch
dispatched_by: riker|adolin|heartbeat
request_id: <if responding to a cross-workspace request>
timestamp: <ISO8601>
---

## What was done
- <bullet points of work performed>

## Artifacts
- PR: <url if created>
- Files changed: <list>

## Status
<complete|partial|blocked: reason>
```

Riker reads this during workspace sweeps and folds it into the PKA status marker.

## Cross-workspace responses

When you are invoked to fulfill a cross-workspace request, write
your response to `agents/riker/inbox/` (absolute path:
`/home/scott/vault/agents/riker/inbox/`). The watcher delivers
it to the requester's `.pka/inbound/` automatically. Do NOT write
directly to another workspace's `.pka/inbound/`.
