#!/usr/bin/env bash
# Run the longwalk headless test suite. Fetches the pinned Godot binary first if
# it is not already present. This is the exact entry point CI invokes.
#
# There are no active-path tests yet: the runtime procedural world and its
# tests were parked under src/legacy_procedural/ and test/legacy_procedural/
# during the docs/authored-map pivot (see src/legacy_procedural/README.md).
# The starter-town prototype (title screen, character creation, town, NPCs)
# lands in later dispatches and will bring its own tests here.
#
# To run the parked legacy suite manually (it still passes against the parked
# code, it is just not part of the active project anymore):
#   tools/run_legacy_procedural_tests.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"${SCRIPT_DIR}/fetch_godot.sh"

echo "No active-path tests yet (starter-town prototype work lands in a later dispatch)."
echo "Run tools/run_legacy_procedural_tests.sh to exercise the parked procedural-world suite."
