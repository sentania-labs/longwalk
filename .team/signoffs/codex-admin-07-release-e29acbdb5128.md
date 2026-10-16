---
reviewed_branch: codex/admin-07-release
reviewed_sha: e29acbdb51282af4ed9458d5d84ac5a3c8c30e53
reviewed_by: claude-worker
authored_by: codex-worker
timestamp: 2026-10-15T15:03:15-05:00
tests_run: python3 prototypes/shared_village_07/test/test_package_permissions.py; tools/godot/godot --headless --path prototypes/shared_village_07 --script res://test/admin_initialization.gd; python3 prototypes/shared_village_07/tools/smoke_admin.py
result: signed-off
---

Verification of the follow-up range d62b123..e29acbd (one commit) against the
two external Codex findings on PR 25. This is not a new general review; the
earlier marker at c1a0d16f44ff covers the full feature review.

P1, fail-closed administration storage: initialize() now records a separate
initialization_error, and every path that previously could clear
storage_error or mint a session is gated on it: _write refuses, so the login
audit can no longer "repair" the error; login_session and session return
empty; redeem and execute return the error; the HTTP console answers 503 to
every POST. The error is only reset by constructing a fresh control at
server start, so repairing files on disk does not unlock a running server.
The headless initialization test and the extended HTTP smoke both exercise
corrupt committed audit, rejection after on-disk repair without restart, and
successful login after restart.

P2, Linux ZIP executable bit: archive() now writes explicit Unix metadata
(create_system 3, mode 0755 for the named executable, 0644 otherwise) instead
of relying on the host filesystem mode, so packaging on the Windows signing
runner preserves the bit. The regression test models a non-executable source
file, packages it, extracts with unzip and runs it.

Constitution: no em-dashes in the changed files, no protected path touched,
no sim-layer change. Worktree scoped paths match e29acbd exactly.

What I ran at e29acbd, all passing: the package permissions test, the admin
initialization headless test with a disposable LONGWALK_TEST_DATA directory,
and the full HTTP admin smoke including the new corrupt-audit sequence.

Limits: I did not rerun the kind chart smoke, the xvfb render, or the full
tools/ci/check-admin07.sh; the author reports exit 0 for that run before this
commit. The Windows signing job is still unexecuted, so the NTFS packaging
path is proven by the regression model, not by a real runner.
