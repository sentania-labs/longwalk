---
reviewed_branch: claude/006-integrate
reviewed_sha: ae74a8a5fd0fd76bf97ffa1c0f2a6d10aa4467f2
reviewed_by: codex-worker
authored_by: claude-worker
timestamp: 2026-07-18T02:39:41Z
tests_run: tools/run_tests.sh
result: changes-requested
---

The active suite exited 0, including the known benign absolute-path Godot
warning. Both requested headless commands, with LONGWALK_ART_CANDIDATE set to
`a` and `b` respectively, exited 0 and reported that both candidates resolved
all 8 facings by 6 frames and conformed to the player and cottage pivots. All
four direct `check_scale_contract.py` invocations passed. No runtime sprite
scaling was introduced.

I confirmed that the unset/default path skips `set_candidate()`, retains the
four-facing proxy fold, and uses the existing facade texture and mathematically
identical bottom-center offset. Each candidate octant directly selects its own
atlas row. The cottage offset uses `cottage_scale.json` `contact_px` at the
existing `building_contact_cell` contact position. The reviewed diff contains
no U+2014 character, touches no protected path or `src/sim/` file, and adds no
simulation dependency on rendering, camera, viewport, or UI code. Meshy was not
invoked, so the balance stayed 2970.

Mutation probe: I temporarily changed candidate A `frames_per_facing` from 6 to
7. The proof exited 1 with `atlas is 6x8 cells, expected 7x8`. I restored the
manifest and confirmed it has no diff.

Changes requested: candidate cell size does not actually drive atlas regions.
`set_candidate()` reads `cell_size` only to assert that it equals the hardcoded
`WALK_CELL_SIZE.x` of 160, while `_apply_walk_frame()` continues to calculate
regions from hardcoded `WALK_CELL_SIZE`; the integration verifier independently
hardcodes `CELL := 160`. This does not meet the slice requirement that facing
and frame counts, cell size, and contact anchor come from the manifest rather
than being hardcoded. Store and use the manifest cell size for the active atlas
region and derive the proof's cell dimensions from the manifest.
