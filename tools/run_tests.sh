#!/usr/bin/env bash
# Run the longwalk headless test suite (currently the macro map determinism
# test). Fetches the pinned Godot binary first if it is not already present.
# This is the exact entry point CI invokes.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

"${SCRIPT_DIR}/fetch_godot.sh"

GODOT="${SCRIPT_DIR}/godot/godot"

echo "Running determinism test headless..."
"${GODOT}" --headless --path "${REPO_ROOT}" --script res://test/test_determinism.gd
