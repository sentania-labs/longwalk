---
reviewed_branch: codex/005-manifest-doc-fix
reviewed_sha: 39f213026876cce688608fbef3994f62843bb349
reviewed_by: claude-worker
authored_by: codex-worker
timestamp: 2026-07-17T19:30:58Z
tests_run: tools/run_tests.sh
result: signed-off
---

Pre-integration peer sign-off for codex-worker's round-005 manifest/README
documentation fix (the P2 the external Codex review of PR #21 flagged).

Scope: documentation-only. The diff touches `tools/art/README.md` alone (27
insertions, 29 deletions); no source, no `src/sim/`, no binaries.

Checks performed:

1. Suite. `tools/run_tests.sh` passed (exit 0, "All active-path test suites
   passed"). The lone `get_node()` ERROR line in test_smoke_grade.gd is a
   pre-existing benign Godot message, not a failure; every PASS line reports
   green.

2. Documented command matches the real CLI and reproduces the assets. The
   README now documents
   `python3 tools/art/process_assets.py tools/art/manifests/process-iso.json`.
   `process_assets.py` declares `manifest` as a required positional argument
   (argparse), so the command is correct. I ran it verbatim from the repo
   root and then checked `git status --short tools/art/out/`: no changes. All
   twelve tracked processed outputs (cottage, player_neutral, E_0..E_5, and
   the cottage + player cast/contact shadow masks under
   `tools/art/out/iso/processed/`) regenerate byte-for-byte identical to the
   committed copies. The README's claim of "the committed cottage, neutral
   player, six east-facing walk frames, and the cottage and player shadow
   masks" matches the manifest and the reproduced set exactly. No regenerated
   binaries committed.

3. README honesty. The rewritten "Manifest-driven post-processing" section
   states process_assets.py "does not remove backgrounds, crop content,
   generate appearance variants, or choose animation frames." Confirmed
   against the code: `process_manifest` only normalizes to the declared anchor
   and, when shadows are enabled, derives cast/contact masks; a grep for
   hue/crop/flood/background/variant in process_assets.py returns nothing. The
   README correctly reattributes appearance variants to `build_player_walk.py`,
   which exists.

4. Constitution. No em-dashes in the diff. `src/sim/` untouched. Determinism
   preserved: doc-only change, and the pipeline itself uses a fixed
   LIGHT_VECTOR with no time or random seeding and no order-dependence.

The README no longer lies about the CLI or the pipeline's outputs. Signed off.

Co-authored-by: Claude <claude@sentania.net>
