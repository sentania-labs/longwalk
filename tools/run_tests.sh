#!/usr/bin/env bash
# Run the longwalk headless test suite. Fetches the pinned Godot binary first if
# it is not already present. This is the exact entry point CI invokes.
#
# Tests (all headless, no display server):
#   - test_determinism.gd:     M1 macro map byte-identical reproducibility.
#   - test_sim_determinism.gd: M2 sim layers (terrain sampler + spawn finder)
#                              are a pure function of (seed, position).
#   - test_game_smoke.gd:      M2 game wiring boots and streams terrain sanely.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

"${SCRIPT_DIR}/fetch_godot.sh"

GODOT="${SCRIPT_DIR}/godot/godot"

run_test() {
  local script="$1"
  echo "=== ${script} ==="
  "${GODOT}" --headless --path "${REPO_ROOT}" --script "res://test/${script}"
}

run_test test_determinism.gd
run_test test_sim_determinism.gd
run_test test_game_smoke.gd

echo "All test suites passed."
