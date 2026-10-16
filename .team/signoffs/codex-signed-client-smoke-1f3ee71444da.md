---
reviewed_branch: codex/signed-client-smoke
reviewed_sha: 1f3ee71444da4c42421cc202dcf8b4a91e477deb
reviewed_by: claude-worker
authored_by: codex-worker
timestamp: 2026-10-16T10:17:19-05:00
tests_run: build/linux/Longwalk-Shared-Village-07.x86_64 --headless --script res://test/exported_client.gd (plus missing-pack, corrupted-pack and editor-binary failure probes); actionlint .github/workflows/admin07.yml; shellcheck tools/ci/check-admin07.sh; full tools/ci/check-admin07.sh run recorded in /tmp/longwalk-exported-client-acceptance.log
result: signed-off
---

Adversarial review of a1aaee9..1f3ee71 (one commit) by Claude, acting as an
independent reviewer. Scope: verify exported executable integrity and the
external art pack after Windows signing without instantiating a 3D scene on
the dummy renderer, while retaining the strict error checks, a positive
completion marker, Windows diagnostic logs, and the existing real-renderer
smoke in the build job.

What changed: a new SceneTree script, test/exported_client.gd, runs inside
an exported client and asserts the editor feature is absent, the embedded
asset loader and release manifest are present with the expected protocol,
the art pack beside the executable passes the loader's sha256 validation and
mounts, a mounted art resource resolves, the boot scene and village script
load from the embedded pack, and the world baseline parses to a non-empty
dictionary. It prints a single EXPORTED CLIENT CHECK PASSED line and exits
zero, or push_errors and exits one. check-admin07.sh runs it against the
Linux export under timeout 120, prints the log, fails on SCRIPT ERROR or
ERROR lines, and requires the pass marker. The Windows sign job replaces the
old --quit-after 30 run with the same script, prints both logs, keeps the
exit code and error-pattern checks, adds the positive marker check, and
uploads windows-*.log as an artifact on every outcome.

Verified in the worktree, all passing:

- The Linux exported client runs the script and prints the pass marker,
  exit 0. Same result in the full acceptance log, which also shows import,
  the seventeen headless tests, art-pack, both exports, the admin smoke,
  the docker build and the kind cluster bring-up.
- Failure probes against a copy of the Linux client in a scratch directory:
  art pack absent gives ERROR plus exit 1; a byte-corrupted art pack is
  rejected by the sha256 comparison with ERROR plus exit 1. Both would trip
  the exit-code check, the ERROR grep, and the missing-marker check.
- Running the script through the editor binary is rejected by the
  has_feature("editor") guard, exit 1, so the check cannot pass against a
  development tree by accident.
- The art pack is beside both exported executables: build_playtest.py
  copies it into build/linux and build/windows after each export, and the
  handoff tar carries build/windows into the sign job, so the exe-relative
  path the script resolves exists after signing.
- The real-renderer smoke (xvfb-run with the offline capture, render.log
  gated on the same error patterns) is untouched in check-admin07.sh.
- actionlint clean on the workflow, shellcheck clean on the check script,
  set -euo pipefail still in force so the timeout, grep and marker steps
  each fail the build on their own.
- exported-client.log lands under build/ and is already covered by the
  existing smoke-evidence upload; the Windows logs get their own artifact.

Constitution: no em-dashes in the diff, no protected path touched
(workflows and tools/ci are not listed, export_presets.cfg is unchanged),
no sim-layer change, forward-slash res:// paths only.

Non-blocking observations, recorded for the author, no change requested:

- The positive marker check on Windows depends on the exported GUI
  executable writing print() output into the redirected stdout handle.
  Godot 4.3 preserves a redirected handle when it attaches to the parent
  console, and the previous merged workflow already relied on the same
  redirect for its error grep. If that assumption ever breaks the step
  fails closed rather than passing silently, and the new log artifact will
  show an empty windows-smoke.log, which is the right failure to see.
- The loader validates the pack by sha256 only; art_bytes in the manifest
  is informational. Pre-existing behaviour, outside this scope.
- The worktree carries an uncommitted release_manifest.json rewrite from
  the local build run. It is a build byproduct and not part of the reviewed
  commit.

Limits: no Windows runtime or Wine on this workstation, and the sign job
only runs on tag pushes, so the new Windows step has not been exercised on
a GitHub runner. The script, its gates and the pack layout are proven on
the Linux export, which is built from the same preset filters.
