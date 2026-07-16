#!/usr/bin/env bash
# Run the PARKED procedural-world test suite (src/legacy_procedural/, see its
# README.md). This is not part of the active CI gate; it is a manual check
# that the parked runtime procedural generator and walkable-world code still
# run headless and stay deterministic, in case a later dispatch wants to
# reuse them (for example as the seed for an offline map-authoring tool).
#
# Tests (all headless, no display server):
#   - test_determinism.gd:     M1 macro map byte-identical reproducibility.
#   - test_landmass.gd:        M1 continent-mask landmass isolation.
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
  "${GODOT}" --headless --path "${REPO_ROOT}" --script "res://test/legacy_procedural/${script}"
}

run_test test_determinism.gd
run_test test_landmass.gd
run_test test_sim_determinism.gd
run_test test_game_smoke.gd
run_test test_input_map.gd
run_test test_player_input.gd

echo "All parked legacy_procedural test suites passed."
