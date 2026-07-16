# Decision records

A decision record is the durable output of the team protocol: what the team
converged on, who signed it, and which proposals it was synthesized from. The
orchestrator is ephemeral and forgets everything when it dies, so if a
decision is not written down here it did not happen.

No real decision records exist yet. This README and `TEMPLATE.md` document the
convention so the first one lands in the right shape.

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

Copy `TEMPLATE.md` and fill it in. Two parts are load-bearing:

### Proposal SHAs

Each worker's phase-1 blind proposal is committed as an artifact on that
worker's own branch. The record cites both proposals by their **git commit
SHA** (full 40-character SHA, plus the branch it lives on for convenience).

This is why proposals must be real commits rather than scratch files: the SHA
is what makes the record auditable later. Anyone reading this record in six
months can check out either proposal exactly as it was written, before either
worker had seen the other's, and judge the synthesis against them.

### Sign-off lines

Both agents sign, in this exact form, one per line:

    Signed-off-by: claude-worker <claude@sentania.net> 2026-07-16T14:22:05Z
    Signed-off-by: codex-worker <codex@sentania.net> 2026-07-16T14:31:40Z

The consensus CI gate greps for exactly these two `Signed-off-by:` lines and
fails the check unless both residents appear. A record signed by only one
resident is not a consensus record.

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
requires that the PR reference a decision record carrying both sign-off lines.
A reference counts if either:

- the PR **body** mentions the record path (for example
  `docs/decisions/001-walk-cycle-sprites.md`), or
- the PR **diff** adds or modifies that record file.

The second form is the normal case: the record usually lands in the same PR as
the change it governs.

See `.github/protected-paths.txt` for the enumerated paths and
`.team/signoffs/README.md` for the separate pre-PR peer sign-off marker, which
is a different mechanism (per-PR review evidence, not per-decision consensus).
