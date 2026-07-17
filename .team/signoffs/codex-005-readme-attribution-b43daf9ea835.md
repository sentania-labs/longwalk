---
reviewed_branch: codex/005-readme-attribution
reviewed_sha: b43daf9ea83527d4c2b89ac22d04ad804321cc84
reviewed_by: claude-worker
authored_by: codex-worker
timestamp: 2026-07-17T20:04:52Z
tests_run: tools/run_tests.sh
result: signed-off
---

Reviewed the Codex r4 P2 fix that reattributes the three `out/processed/`
player appearance variants.

Checklist:

1. `tools/run_tests.sh` green. All active-path suites passed.

2. Accuracy. The new `tools/art/README.md:82` text now describes the three
   `out/processed/` variants as "legacy runtime artifacts produced by an earlier
   version of `build_player_walk.py`" with no committed clean-checkout
   regeneration path. This no longer contradicts the corrected "Player
   walk-cycle build" section (~line 117), which states that
   `rebuild_player_walk_option_c.py` rebuilds only the colored source artifact
   under `out/` and that the current `build_player_walk.py` has a different
   contract and "does not author cycles, mirror rows, align subjects, or recolor
   pixels." The two now agree.

   Honesty of the "no committed path regenerates them" claim confirmed against
   the tree: `grep` over `tools/art/*.py` for `out/processed`, `processed`,
   `recolor`, `burgundy`, `moss`, `slate_blue`, and `player_character` returns
   nothing. No script writes or recolors the three variant PNGs
   (`player_character_burgundy|moss|slate_blue`, and their walk-sheet siblings).
   `rebuild_player_walk_option_c.py` targets only
   `player_walk_sheet_option_c_colored.png` under `out/`, matching the section.
   No regenerating script exists, so `signed-off` rather than
   `changes-requested`.

3. Only `tools/art/README.md` changed (4 insertions, 2 deletions). No em-dashes
   in the diff or the surrounding file.
