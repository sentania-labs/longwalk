# RESUME: finish the process_assets.py / README P2 fix (prior dispatch died uncommitted)

A prior dispatch of this exact fix ran in this worktree and DIED before
committing. Its work is still here, UNCOMMITTED, in `tools/art/README.md`: it
rewrote the "Current output" and post-processing sections to document the
manifest-driven pipeline and changed the documented invocation to
`python3 tools/art/process_assets.py tools/art/manifests/process-iso.json`.
Your job is to FINISH that: verify it is correct and honest, run the suite to
green, and COMMIT it. Do not start over unless the existing change is wrong.

Verify specifically, and this is the load-bearing part of the finding:
- The documented command `python3 tools/art/process_assets.py
  tools/art/manifests/process-iso.json` must ACTUALLY match the real CLI (the
  positional/required manifest arg) AND must actually reproduce the committed
  processed assets. Prove reproduction cheaply if you can (dry-run or
  hash-compare against the committed `out/iso/processed/` PNGs) and say so in
  your report. If it does NOT reproduce them, the README is still lying and the
  fix is not done: correct it until the documented path genuinely reproduces the
  live assets.
- The README must no longer describe outputs/appearance variants the current
  pipeline does not generate. Confirm the rewritten text matches what
  `process_assets.py` actually produces now.
- No em-dashes anywhere. Determinism preserved (pure function of seed/position;
  no time/random seeding, no order-dependence). `src/sim/` untouched. Do NOT
  regenerate or commit binary asset PNGs; scope is CLI + README so the documented
  path reproduces them.

Then:
- Run `tools/run_tests.sh` and confirm GREEN before committing.
- Commit on `codex/005-manifest-doc-fix` with a
  `Co-authored-by: Codex <codex@sentania.net>` trailer, message naming the
  finding ("external Codex review of PR #21 round 2, P2").
- Do NOT open a PR (the orchestrator integrates locally).

Report the commit SHA and exactly which approach you took (default manifest vs
README correction), plus the reproduction evidence.
