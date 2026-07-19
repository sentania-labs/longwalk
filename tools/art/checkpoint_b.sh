#!/usr/bin/env bash
# Checkpoint B (decision 018 section 5): bake the grounded-building demo tile
# from two sim snapshots (age-1 low-use, age-40 high-use) and run the
# byte-difference assertion. Exits nonzero if the determinism or evolution or
# field-grammar checks fail. Fetches the pinned Godot binary first if needed.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

"${REPO_ROOT}/tools/fetch_godot.sh" >/dev/null
GODOT="${REPO_ROOT}/tools/godot/godot"

exec "${GODOT}" --headless --path "${REPO_ROOT}" --script tools/art/bake_checkpoint_b.gd
