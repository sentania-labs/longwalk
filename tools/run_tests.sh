#!/usr/bin/env bash
# Run the longwalk headless test suite. Fetches the pinned Godot binary first if
# it is not already present. This is the exact entry point CI invokes.
#
# Art-pipeline tests (test/art/), plain Python, no Godot:
#   - test_build_player_walk.py: asserts that no opaque generation-marker hue
#     survives into any shipping player atlas.
#   - test_check_walk_sheet.py: the pre-recolor walk-sheet rejection gate
#     (tools/art/check_walk_sheet.py). Asserts every rejection path fires
#     against a fixture built to trip it (leading-leg non-reversal traced from
#     the round-1 defect, missing chromatic markers, anchor drift, clipped
#     figures, malformed grids) plus a corrected control proving the gate does
#     not simply reject everything. See docs/art/walk-sheet-validation.md.
#
# Active-path tests (test/active_path/):
#   - test_boot_flow.gd: the M3 starter-town prototype boot flow (title
#     screen -> character creation -> starter town). Asserts the hand-authored
#     town layout (src/sim/town_layout.gd) is deterministic and sane, and that
#     every scene in the flow loads and instantiates headless.
#   - test_nav_grid.gd: the sim-side navigation grid (src/sim/nav_grid.gd).
#     Asserts the deterministic 8-connected A* (byte-identical output across
#     repeated calls, corner-cutting refused, routes around buildings), the
#     nearest_walkable search contract (bounds clamping, Euclidean metric,
#     cell-index tie-break), and the construction invariants that keep the
#     render layer's colliders in agreement with the grid.
#   - test_player_world_contract.gd: the shared decision 003 player origin,
#     feet anchor, world scale, and unchanged starter-town fixture.
#   - test_display_settings.gd: the display settings plumbing
#     (src/render/display_settings.gd). Asserts the ConfigFile round-trip
#     under user://, that a resolution this build does not offer is rejected
#     rather than pinning the window somewhere the settings screen cannot
#     undo, and that the fullscreen shortcut's F11 / Alt+Enter bindings are
#     registered (an unregistered action is a silently dead key).
#   - test_player_zoom.gd: tests the zoom control in the player controller.
#
# The runtime procedural world and its tests were parked under
# src/legacy_procedural/ and test/legacy_procedural/ during the docs/authored-map
# pivot (see src/legacy_procedural/README.md). To run that parked suite
# manually (it still passes against the parked code, it is just not part of
# the active project anymore):
#   tools/run_legacy_procedural_tests.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Art-pipeline tests run first: they are plain Python (PIL and numpy, the same
# deps process_assets.py already needs), they need no Godot binary, and they
# are fast, so a break here surfaces before the engine fetch.
# Static ban (decision 009 item 7): shipping game code under src/ must load
# textures through the resource system (preload / load / ResourceLoader), NEVER
# via raw Image.load / Image.load_from_file / FileAccess.get_file_as_image off
# res://. Those raw paths read the SOURCE tree and are silently EXCLUDED by a
# stock Godot export, so a packaged build ships default art instead (the
# round-006 carry-forward finding). This is a fast lexical backstop; the real
# proof is the isolated-packaged export gate (tools/art/village_export_gate.sh).
# Scoped to src/ (shipping runtime): tools/art/ capture scripts are dev-only and
# never ship inside the game's asset path.
echo "=== static game-asset image-load ban (src/) ==="
if grep -rnE 'Image\.load\(|Image\.load_from_file\(|FileAccess\.get_file_as_image\(' \
		"${REPO_ROOT}/src" --include='*.gd'; then
	echo "[FAIL] raw image loading of a game asset found in src/ (see decision 009 item 7)."
	echo "       Load textures through res:// (preload/load/ResourceLoader) instead."
	exit 1
fi
echo "[PASS] no raw game-asset image loading in src/"

echo "=== test_build_player_walk.py ==="
python3 "${REPO_ROOT}/test/art/test_build_player_walk.py"

echo "=== test_art_manifest.py ==="
python3 "${REPO_ROOT}/test/art/test_art_manifest.py"

echo "=== test_check_walk_sheet.py ==="
python3 "${REPO_ROOT}/test/art/test_check_walk_sheet.py"

"${SCRIPT_DIR}/fetch_godot.sh"

GODOT="${SCRIPT_DIR}/godot/godot"

# A first import pass builds the .godot resource cache the active scenes and
# autoload need (see project.godot's [autoload] section); without it a fresh
# checkout's first --script run can fail to resolve newly added resources.
"${GODOT}" --headless --path "${REPO_ROOT}" --import

echo "=== test_boot_flow.gd ==="
"${GODOT}" --headless --path "${REPO_ROOT}" --script res://test/active_path/test_boot_flow.gd

echo "=== test_nav_grid.gd ==="
"${GODOT}" --headless --path "${REPO_ROOT}" --script res://test/active_path/test_nav_grid.gd

echo "=== test_iso_projection.gd ==="
"${GODOT}" --headless --path "${REPO_ROOT}" --script res://test/active_path/test_iso_projection.gd

echo "=== test_player_world_contract.gd ==="
"${GODOT}" --headless --path "${REPO_ROOT}" --script res://test/active_path/test_player_world_contract.gd

echo "=== test_display_settings.gd ==="
"${GODOT}" --headless --path "${REPO_ROOT}" --script res://test/active_path/test_display_settings.gd

echo "=== test_player_zoom.gd ==="
"${GODOT}" --headless --path "${REPO_ROOT}" --script res://test/active_path/test_player_zoom.gd

echo "=== test_smoke_grade.gd ==="
"${GODOT}" --headless --path "${REPO_ROOT}" --script res://test/active_path/test_smoke_grade.gd

echo "=== test_ground_uv_spike.gd ==="
"${GODOT}" --headless --path "${REPO_ROOT}" --script res://test/active_path/test_ground_uv_spike.gd

echo "=== test_village_render.gd ==="
"${GODOT}" --headless --path "${REPO_ROOT}" --script res://test/active_path/test_village_render.gd

echo "=== test_lane_mask_consumption.gd ==="
"${GODOT}" --headless --path "${REPO_ROOT}" --script res://test/active_path/test_lane_mask_consumption.gd

echo "=== test_footprint_field_bake.gd ==="
"${GODOT}" --headless --path "${REPO_ROOT}" --script res://test/active_path/test_footprint_field_bake.gd

echo "=== deterministic dirt-detail repeat bake ==="
"${GODOT}" --headless --path "${REPO_ROOT}" --script res://tools/art/bake_dirt_detail.gd
DIRT_DETAIL_FIRST_SHA="$(sha256sum "${REPO_ROOT}/assets/village/ground_dirt_detail.png" | cut -d' ' -f1)"
"${GODOT}" --headless --path "${REPO_ROOT}" --script res://tools/art/bake_dirt_detail.gd
DIRT_DETAIL_SECOND_SHA="$(sha256sum "${REPO_ROOT}/assets/village/ground_dirt_detail.png" | cut -d' ' -f1)"
if [[ "${DIRT_DETAIL_FIRST_SHA}" != "${DIRT_DETAIL_SECOND_SHA}" ]]; then
	echo "[FAIL] repeated dirt-detail bakes are not byte-identical"
	exit 1
fi
echo "[PASS] repeated dirt-detail bakes are byte-identical (${DIRT_DETAIL_FIRST_SHA})"

echo "=== test_dirt_detail_bake.gd ==="
"${GODOT}" --headless --path "${REPO_ROOT}" --script res://test/active_path/test_dirt_detail_bake.gd

echo "All active-path test suites passed."
