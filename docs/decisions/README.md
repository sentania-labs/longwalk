# Decision records

A decision record is the durable output of the team protocol: what the team
converged on, who signed it, and which proposals it was synthesized from. The
orchestrator is ephemeral and forgets everything when it dies, so if a
decision is not written down here it did not happen.

`001-town-motion.md` is the first real record. This README and `TEMPLATE.md`
document the convention it follows.

## Naming and numbering

    docs/decisions/NNN-topic.md

`NNN` is a zero-padded 3-digit sequence number, allocated in order: the first
record is `001-topic.md`, the next `002-topic.md`. `topic` is a short
kebab-case slug (`001-walk-cycle-sprites.md`, not `001-decision.md`).

Numbers are never reused and records are never deleted. A decision that gets
reversed is superseded by a new record that says so, and the old record stays
put with a pointer forward. The record of a wrong decision is worth as much as
the record of a right one.

`TEMPLATE.md` is not a record and takes no number. Copy it to start one.

If two records race for the same number (both workers drafting at once), the
orchestrator renumbers the later one at synthesis time.

## Required contents

Copy `TEMPLATE.md` and fill it in. Three parts are load-bearing:

### Workers dispatched

A header line naming every worker the round actually dispatched:

    - **Workers dispatched:** claude-worker, codex-worker, agy-worker

The team seats three doers, but a given assignment does not have to use all
three: triage may dispatch two, and which two depends on the work. So the
required-signer set is a property of each record rather than a fixed list. The
gate reads this line and requires a valid sign-off from each name on it, and
from no one else. A three-worker round cannot pass while one of the three has
not signed, and a two-worker round that did not include a resident is never
blocked waiting for that resident to sign something it never saw.

Names are written exactly as they appear in sign-off lines (`claude-worker`,
`codex-worker`, `agy-worker`), and they must match the rows of the Proposals
table: a worker that was dispatched has a proposal SHA, and a worker with a
proposal SHA signs.

#### Directive-authority records

One record shape has no worker round behind it: a change Scott directed
outright, rather than one the team proposed, critiqued, and converged on.
Roster changes and constitution-adjacent changes are exactly this, because
`$TEAM_FRAMEWORK_DIR/roles/orchestrator.md` puts them outside what the team
decides for itself.
Such a change can still touch a protected path, so it still needs a record, but
requiring worker sign-off on it would be asking workers to ratify something no
worker proposed.

That record writes:

    - **Workers dispatched:** None (directive authority)
    - **Authority:** Scott directive, 2026-07-17: <what was directed>

and carries no worker sign-off lines. The `Authority` line stands in their
place, and the record has to say plainly in its own text that it is this
category and why that is legitimate here.

Both fields are required together. A record naming no workers and stating no
authority fails the gate, because the alternative would let any record shed its
sign-off requirement by leaving the workers field empty. Naming nobody is a
claim the record has to make out loud and justify, not a default it can fall
into.

### Proposal SHAs

Each worker's phase-1 blind proposal is committed as an artifact on that
worker's own branch. The record cites every proposal by its **git commit SHA**
(full 40-character SHA, plus the branch it lives on for convenience), one per
dispatched worker.

This is why proposals must be real commits rather than scratch files: the SHA
is what makes the record auditable later. Anyone reading this record in six
months can check out any proposal exactly as it was written, before its author
had seen any peer's, and judge the synthesis against them.

### Sign-off lines

Every dispatched worker signs, in this exact form, one per line:

    Signed-off-by: claude-worker <claude@sentania.net> 2026-07-16T14:22:05Z
    Signed-off-by: codex-worker <codex@sentania.net> 2026-07-16T14:31:40Z

All three fields are required: resident name, email, and a real UTC ISO 8601
timestamp. The gate validates the whole line, not just the name, and this is
not pedantry. `TEMPLATE.md` already contains the residents' names in its
sign-off block, so a record copied from the template and never actually signed
would satisfy a name-only check. The timestamp is what a placeholder cannot
fake: `YYYY-MM-DDTHH:MM:SSZ` is rejected, so an unsigned copy of the template
fails the gate rather than clearing it. Sign with the time you actually
signed.

A record missing a sign-off from a worker it names as dispatched is not a
consensus record.

A worker signing a record is claiming it read the synthesis and accepts it as
the team's decision, including where the synthesis went against its own
proposal. Signing is not required to mean agreeing: a worker whose objection
lost still signs, and its dissent is recorded verbatim in the record (see
below).

### Dissent

Where the workers did not converge, the orchestrator decides and records the
losing objection **verbatim** in the Dissent section. Verbatim means quoted in
the objector's own words, not paraphrased. The orchestrator escalates to Scott
instead of deciding only when the losing objection claims a constitution
violation.

## How this ties to the CI gate

`.github/workflows/consensus.yml` runs `tools/check_consensus.py` on every PR.
If the PR touches any path listed in `.github/protected-paths.txt`, the check
requires that the PR reference a decision record which both carries a valid
sign-off line from every worker the record names in `Workers dispatched` (or,
for a directive-authority record, states its `Authority` instead) **and**
covers the protected paths the PR actually touches.

A reference counts if either:

- the PR **body** mentions the record path (for example
  `docs/decisions/001-walk-cycle-sprites.md`), or
- the PR **diff** adds or modifies that record file.

The second form is the normal case: the record usually lands in the same PR as
the change it governs.

Coverage is why the `Protected paths touched` section is load-bearing rather
than documentation. A record authorizes only the paths it lists there. Without
that, once any signed record existed, a later PR could cite it while changing
something entirely unrelated and pass the gate, which would make the check
theatre. If your PR touches a protected path no existing record covers, you
need a new record, not a citation of an old one.

The gate is currently **informational**: it runs and reports on every PR but
does not block the merge. See the comment in `.github/workflows/consensus.yml`
for why, and for the two changes that switch it to enforcing.

See `.github/protected-paths.txt` for the enumerated paths and
`.team/signoffs/README.md` for the separate pre-PR peer sign-off marker, which
is a different mechanism (per-PR review evidence, not per-decision consensus).
