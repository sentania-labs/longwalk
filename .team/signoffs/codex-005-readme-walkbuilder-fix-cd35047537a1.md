---
reviewed_branch: codex/005-readme-walkbuilder-fix
reviewed_sha: cd35047537a12f28cc898a5fc838df54ff3db32c
reviewed_by: claude-worker
authored_by: codex-worker
timestamp: 2026-07-17T19:55:00Z
tests_run: tools/run_tests.sh
result: signed-off
---

Re-review after my earlier `changes-requested` (the documented
`build_player_walk.py` command failed with `KeyError: 'frames'` and no `frames`
manifest existed). New head `cd35047` resolves it by splitting the two concerns
honestly.

Checks performed:

- Tests: `tools/run_tests.sh` green in this worktree. All active-path suites
  passed.
- Reproduction: ran the documented
  `python3 tools/art/rebuild_player_walk_option_c.py --output /tmp/regen.png`
  (exit 0). sha256 of the regenerated file is
  `0e4c952b4fd00719748091ff78f28c839c866b2876dcfbcc61232df4684ce242`, which
  matches both the expected value and the committed
  `tools/art/out/player_walk_sheet_option_c_colored.png`. Byte-identical.
- Determinism: read `rebuild_player_walk_option_c.py` end to end. No
  `randi`/`randf`/`random` or unseeded RNG, and no iteration-order-dependent
  accumulation. The operation is a pure sequence of deterministic PIL/numpy
  transforms (crop, horizontal flip, HSV hue-range masking, fixed hue reassign,
  paste) over the committed revision 3 source, keyed only on pixel values. The
  byte-identical reproduction confirms it.
- Prose accuracy: verified against source. `build_player_walk.py` does compose
  48 declared 160 px frames (FACING_IDS of length 8 x FRAMES_PER_FACING of 6)
  from a top-level `frames` map via `alpha_composite`, and does not author
  cycles, mirror rows, align subjects, or recolor. `check_walk_sheet.py`
  validates the 960 by 1280 (160*6 by 160*8) atlas. The README text is truthful
  on both scripts and no longer claims `build_player_walk.py` authors or
  recolors.
- No em-dashes anywhere in the diff.

Signed off.
