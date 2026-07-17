---
reviewed_branch: codex/005-readme-walkbuilder-fix
reviewed_sha: ec176dc32166ac7d4b9b916956798d4519f2c6ef
reviewed_by: claude-worker
authored_by: codex-worker
timestamp: 2026-07-17T19:47:03Z
tests_run: tools/run_tests.sh
result: changes-requested
---

The diff is well-formed on its own terms: it touches only `tools/art/README.md`,
adds no CLI change, and contains no em-dashes. `tools/run_tests.sh` passes in
this worktree, and the referenced positional manifest
`tools/art/manifests/player-walk-policy.json` does exist.

But the finding this fix targets is precisely "a documented command that does
not run," so I ran the exact documented invocation, and it does not run:

```
python3 tools/art/build_player_walk.py \
  tools/art/manifests/player-walk-policy.json \
  --output tools/art/out/player_walk_sheet_option_c_colored.png
```

fails with:

```
  File ".../tools/art/build_player_walk.py", line 27, in build
    frames = data["frames"]
             ~~~~^^^^^^^^^^
KeyError: 'frames'
```

Root cause: `build_player_walk.py` requires a manifest that declares a
top-level `frames` map (each `<FACING>_<index>` frame id pointing at a source
image, per `build()` and `test/art/test_build_player_walk.py`).
`player-walk-policy.json` is a *policy* manifest. It carries `facing_order`,
`frames_per_facing`, `cell_size`, and `mirroring`, so it clears every earlier
check and then dies on the missing `frames` key. No JSON under `tools/art/`
declares a `frames` key at all (`grep -rc '"frames"' tools/art --include=*.json`
returns nothing), so there is no manifest in the repo that this script can
consume to produce the committed artifact. The command therefore never writes
`player_walk_sheet_option_c_colored.png`; the committed artifact
(sha256 0e4c952b...) is not reproduced.

Separately, the surrounding README prose ("reads the committed colored-boot
revision 3 sheet, retains its passing side row, authors symmetric down and up
half-cycles") describes behavior the current `build_player_walk.py` does not
implement. The script composites individually declared frame images from a
manifest into an atlas; it does not read a rev-3 sheet or mirror rows. That
drift is out of scope for this doc fix, but it is a signal that patching only
the invocation line, without a runnable manifest and matching prose, leaves the
section still non-reproducible.

What is needed before sign-off: either commit a frames manifest that
`build_player_walk.py` actually consumes and document that path (verified to
regenerate the committed artifact), or correct both the command and the prose to
match whatever pipeline genuinely produces
`player_walk_sheet_option_c_colored.png`. As written, the documented command
errors out, which is the same defect the finding reported.
