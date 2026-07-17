# Fix: process_assets.py positional manifest breaks the documented regen command

You are on branch `codex/005-manifest-doc-fix`, branched from the round-005 head
(`3513687`). This is a fast-lane fix addressing an external Codex review finding
on PR #21. Do the fix, run the suite, commit. Do NOT open a PR (the orchestrator
integrates locally).

## The finding (Codex review round 2, P2, `tools/art/process_assets.py:85`)

> Making `manifest` positional breaks the repository's documented `python3
> tools/art/process_assets.py` regeneration command in `tools/art/README.md`,
> which now exits in argparse without processing anything. The README still also
> describes outputs and appearance variants that this replacement no longer
> generates, so following the documented asset-regeneration workflow cannot
> reproduce the live assets. Update the invocation and legacy-output guidance,
> or retain a compatible default manifest.

## What to do

Make the documented asset-regeneration workflow actually reproduce the live
assets again. Two sanctioned approaches:

1. Restore a compatible DEFAULT for the manifest argument (so bare `python3
   tools/art/process_assets.py` runs against the canonical manifest the live
   assets were built from), OR
2. Update `tools/art/README.md` so the documented invocation matches the real
   CLI (the positional/required manifest arg) AND correct the stale
   outputs/appearance-variant descriptions so the README describes what this
   pipeline actually generates now.

Prefer whichever keeps the regen workflow both correct AND honest: if a canonical
default manifest exists and is the right one, restoring the default is cleanest;
otherwise fix the README to the real invocation and outputs. Whichever you pick,
the README and the CLI must agree, and following the README must reproduce the
committed assets.

## Constraints (constitution + round 005)

- No em-dashes anywhere (code, comments, docs, commit message). Hard repo rule.
- Determinism: generation must stay a pure function of (seed, position) style
  reproducibility. Do NOT introduce order-dependent or time/random-seeded
  behavior. If you touch generation ordering, keep it fully determined.
- Sim/render separation: `src/sim/` untouched.
- Do NOT regenerate or alter the committed asset PNGs; scope is the CLI + README
  so the documented path reproduces them. If you can cheaply prove reproduction
  (dry-run or hash-compare), say so in your report; do not commit regenerated
  binaries.
- Run `tools/run_tests.sh` and confirm green before committing.
- Commit with a `Co-authored-by: Codex <codex@sentania.net>` trailer. Message
  should name the finding ("external Codex review of PR #21 round 2, P2").

Commit on `codex/005-manifest-doc-fix`. Report the commit SHA and exactly which
approach you took (default manifest vs README correction).
