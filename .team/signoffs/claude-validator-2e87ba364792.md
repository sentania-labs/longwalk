---
reviewed_branch: claude/validator
reviewed_sha: 2e87ba364792805444e92c5372fc4ce112d19686
reviewed_by: codex-worker
authored_by: claude-worker
timestamp: 2026-07-17T05:32:29Z
tests_run: tools/run_tests.sh
result: signed-off
---

Rebuilt the per-frame mirrored colored side-row exploit and confirmed it now
parse-fails with exit 2, including through the removed `--rows side` path. Both
round-1 candidates still reject with exit 1, while a well-formed three-row
source fixture remains eligible for a rejection-only verdict. Mutation-tested
the new regression assertion and observed the suite fail, then restored it and
ran the full active test suite green. Also checked hard failures for missing
NumPy and Pillow, the 0.05 anchor-drift ceiling, edge-touch rejection, tracked
bytecode, em-dashes, protected paths, and the commit authorship trailer.
