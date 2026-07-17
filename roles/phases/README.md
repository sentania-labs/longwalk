# Phase prompt templates

Reusable prompt templates for the orchestrator's protocol. Each file is a
template the orchestrator fills in and injects, not documentation about
prompting.

| File | Who it goes to | When |
| --- | --- | --- |
| `0-assignment.md` | orchestrator's own working template | on receiving a goal statement, before anything else |
| `1-proposal.md` | injected into each worker's dispatch | phase 1, every dispatched worker in parallel |
| `2-critique.md` | injected into each worker's dispatch | phase 2, after every proposal is committed |
| `3-synthesis.md` | orchestrator's own working template | phase 3 |

`1-proposal.md` and `2-critique.md` are dispatched to workers, appended to the
worker's role brief. `0-assignment.md` and `3-synthesis.md` are the
orchestrator's own; nothing dispatches them anywhere.

These templates extend the phase descriptions in `roles/orchestrator.md`; they
do not replace them. Where a template and the orchestrator brief appear to
disagree, the brief wins and the template is a bug.

Angle brackets (`<like this>`) mark fill-ins. A dispatched prompt with an
unfilled `<placeholder>` in it is a dispatch bug, not a worker's problem to
interpret.
