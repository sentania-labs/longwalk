#!/usr/bin/env bash
# Run the longwalk headless test suite. Fetches the pinned Godot binary first if
# it is not already present. This is the exact entry point CI invokes.
#
# Tests (all headless, no display server):
#   - test_determinism.gd:     M1 macro map byte-identical reproducibility.
#   - test_landmass.gd:        M1 continent-mask landmass isolation.
#   - test_polar_caps.gd:      polar cap bands are uniform featureless ice, so
#                              the sphere-consistent polar crossing is seamless.
#   - test_sim_determinism.gd: M2 sim layers (terrain sampler + spawn finder)
#                              are a pure function of (seed, position).
#   - test_game_smoke.gd:      M2 game wiring boots and streams terrain sanely.
#   - test_input_map.gd:       every input action the controller polls is
#                              registered, so WASD/Esc can never be silently dead
#                              in an export.
#   - test_player_input.gd:    mouse look and keyboard yaw/pitch actually reach
#                              and rotate the player/camera, not just that the
#                              action names exist.
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
run_test test_landmass.gd
run_test test_polar_caps.gd
run_test test_sim_determinism.gd
run_test test_game_smoke.gd
run_test test_input_map.gd
run_test test_player_input.gd

echo "All test suites passed."
