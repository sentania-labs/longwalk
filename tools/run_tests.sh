#!/usr/bin/env bash
# Run the longwalk headless test suite. Fetches the pinned Godot binary first if
# it is not already present. This is the exact entry point CI invokes.
#
# Active-path tests (test/active_path/):
#   - test_boot_flow.gd: the M3 starter-town prototype boot flow (title
#     screen -> character creation -> starter town). Asserts the hand-authored
#     town layout (src/sim/town_layout.gd) is deterministic and sane, and that
#     every scene in the flow loads and instantiates headless.
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

echo "All active-path test suites passed."
