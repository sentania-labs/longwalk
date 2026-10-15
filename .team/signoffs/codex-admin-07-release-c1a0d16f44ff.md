---
reviewed_branch: codex/admin-07-release
reviewed_sha: c1a0d16f44ff1155614cb8f5cb51500a5747485f
reviewed_by: claude-worker
authored_by: codex-worker
timestamp: 2026-10-15T14:45:25-05:00
tests_run: python3 prototypes/shared_village_07/tools/smoke_admin.py; tools/godot/godot --headless --path prototypes/shared_village_07 --script res://test/admin_rules.gd; actionlint .github/workflows/admin07.yml .github/workflows/ci.yml
result: signed-off
---

Independent adversarial pre-PR review of Admin 07, base 99fd783, reviewed at
c1a0d16. The first review pass (working tree before this commit) raised one
critical, three high, five medium and four low findings. Each was re-verified
against the committed source, not the author's summary.

Verified fixed in c1a0d16:

- In-client staff RPC key mismatch (critical): staff_panel.gd now sends
  `operation`, matching world_link.gd. The network bot drives the panel's own
  `_send` path and smoke_admin.py asserts a self teleport moved the traveler
  and produced an audit row.
- Recovery without a backup (high): status exposes `recovery_points` (state
  and backup records) and `recovery_source`; restore accepts state records;
  the web console preselects the loaded checkpoint when frozen. The smoke test
  removes all backups, corrupts the newest checkpoint, plants an interrupted
  `.pending` audit file, and recovers from the prior checkpoint.
- Audit attribution (high): staff principals are named `traveler:<ident>` with
  `granted_by`; staff actions carry `actor_player` and `granted_by` details.
- Root Windows export job (high): restored in ci.yml with pinned actions; the
  unsigned artifact upload is dropped, which is acceptable.
- Pending audit files ignored on load; in-world grants cannot ticket, revoke
  or change release settings; deployment-managed admin origin cannot be
  changed through the console; both CI jobs pin Python 3.12; `rg` replaced by
  `grep -E`; smoke server logs copied into build/ unconditionally; public
  staff-role broadcast removed; legacy 06 server files redirect to the chart;
  template fetch message corrected.

Constitution checks: no em-dashes in the scoped files; no protected path
touched (root project.godot, export_presets.cfg, src/sim/ and the framework
paths are untouched; the prototype's own export_presets.cfg is not listed);
no sim-layer change in this commit.

What I ran, all passing in this worktree at c1a0d16: the admin smoke test
(web assets, setup token gate, login, compatibility rejection, mod grant and
self teleport through the panel path, revoke, skill persistence, backup and
restore, stop, corruption, checkpoint recovery with a pending audit file,
logout), the headless admin rules test, and actionlint on both workflows.

Limits: I did not run the kind chart smoke, the Linux render under xvfb, or
the full tools/ci/check-admin07.sh; the author's retained logs
(build/acceptance.log, smoke-chart.log, render.log) show them passing at
14:38 to 14:42 local on 2026-10-15. The GitHub-hosted workflow, the Windows
signing job and the publish job have not yet executed anywhere; the first PR
run is the proof. `main` has no branch protection, so admin07.yml is not a
required check; tracked separately per the author.
