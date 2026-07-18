---
reviewed_branch: codex/017-impl
reviewed_sha: 6e31e7e00fe2c6f1275fe333344d70b5d93745b3
reviewed_by: claude-worker
authored_by: codex-worker
timestamp: 2026-07-18T21:35:10Z
tests_run: tools/run_tests.sh, tools/art/village_export_gate.sh
result: signed-off
---

Non-author peer review of codex's decision 017 base-vegetation implementation
(`6e31e7e`, off round head `fa09235`). I authored none of this commit; this is
my own review, not the earlier marker the orchestrator discarded as fabricated.

Reviewed against `docs/decisions/017-base-vegetation.md` and the constitution.

Faithful to 017:
- D2 discrete positional-hash placement, render-only in
  `src/render/town/village_render.gd` reusing existing flora/rock kits, no new
  assets, no spend. Confirmed.
- Derived-instance contract scales BOTH the object sprite (`_build_objects`,
  `sprite.scale = instance.scale`) AND the baked seam mask (`_add_seam_sprite`
  now takes and applies `scale`) plus the flora underlay (`_add_flora_base`),
  all fed from the shared `_render_instances` list built once in `_ready`, with
  a stable depth key from `instance.contact` / `instance.sort_id`. This is
  exactly the shared-contract finding the decision required; the previously
  independent `_build_shadows` / `_build_objects` iterations now consume one
  list.
- Rejection is the agreed middle ground: mandatory door-cell rejection
  (`_inside_door_exclusion`, real doors present in manifest.seam_policy) and
  hard-object rejection limited to fence/sign (`_overlaps_hard_object`), with
  tree and flora left open. Confirmed.
- D3 is the SEPARATE `flora_base.gdshader` underlay in the shared below-object
  shadow layer, not an on-sprite band. This is the ruling that beat my D3
  dissent 3-1; the impl holds it and does NOT drift toward my lost on-sprite
  approach. Correct per the record.
- Four invariants + export audit present and passing: byte-equal repeat,
  input-reversal invariance, >=2 mandatory anchors per building, no anchor in a
  door exclusion (`_check_base_vegetation`); the export audit counts derived
  sprites and re-resolves each through `ResourceLoader` (62 sprites reported).

Determinism: pure `(seed, position)`. `_mix_candidate` is integer mixing over
the fixed `BASE_VEGETATION_SEED` and canonical quarter-cell coordinates; no
`randi`/`randf`/`RandomNumberGenerator`, no GDScript `hash()`, no
iteration-order or accumulator dependence. Candidate coordinates are derived
from cell/footprint, and the final `sort_custom` by `sort_id` makes output
order independent of input placement order (the reversal invariant confirms
this). Meets the CLAUDE.md hard rule.

Sim/render separation: all changes are under `src/render/`, `test/`, and
`tools/art/`. Nothing under `src/sim/` is touched. Holds.

No em-dashes in the diff (verified). `assets/village/` is not mutated; the
export gate's non-mutation guard passes (checksum unchanged). Only
`docs/art/village/*.png` captures changed, which is expected.

Gates run by me in-worktree:
- `tools/run_tests.sh`: all active-path suites passed (exit 0), including the
  new base-vegetation invariants.
- `tools/art/village_export_gate.sh`: VILLAGE EXPORT GATE PASSED, no swallowed
  shader error, 62 derived sprites resolved through ResourceLoader,
  assets/village non-mutation guard green.

Verdict: signed-off. The mechanism is faithful to decision 017 and the
constitution. The remaining gap (composition/scale vs the spike) is a
perceptual tuning matter, which is my Job 2 slice on top of this commit, not a
correctness defect in codex's implementation.

Co-authored-by: Claude <claude@sentania.net>
