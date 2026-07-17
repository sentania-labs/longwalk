#!/usr/bin/env bash
# Run the longwalk headless test suite. Fetches the pinned Godot binary first if
# it is not already present. This is the exact entry point CI invokes.
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

echo "=== test_player_world_contract.gd ==="
"${GODOT}" --headless --path "${REPO_ROOT}" --script res://test/active_path/test_player_world_contract.gd

echo "=== test_display_settings.gd ==="
"${GODOT}" --headless --path "${REPO_ROOT}" --script res://test/active_path/test_display_settings.gd

echo "=== test_player_zoom.gd ==="
"${GODOT}" --headless --path "${REPO_ROOT}" --script res://test/active_path/test_player_zoom.gd

echo "All active-path test suites passed."
