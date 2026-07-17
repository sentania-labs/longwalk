---
reviewed_branch: claude/validator
reviewed_sha: bb7aaf5e5ac96704c5cdab2fa87f44843ea98c0f
reviewed_by: codex-worker
authored_by: claude-worker
timestamp: 2026-07-17T06:44:10Z
tests_run: tools/run_tests.sh
result: signed-off
---

Confirmed the CI change installs NumPy and Pillow into Python 3.12 before
`tools/run_tests.sh`, without weakening the art tests' hard-fail imports. Both
exact pins installed successfully in a clean virtual environment, both art test
modules passed, and the complete active-path suite exited 0 at the reviewed
commit. The dependency file is scoped to the existing art pipeline, the pinned
choice is documented, and the Windows export job remains unchanged.
