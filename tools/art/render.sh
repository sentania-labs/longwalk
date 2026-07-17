#!/usr/bin/env bash
# Render command wrapper (Decision 009, Constraint 1)
# Executes the Blender headless rendering and calibration scene.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$(dirname "${SCRIPT_DIR}")")"
BLENDER_BIN="${REPO_ROOT}/tools/blender/blender_bin"

if [ ! -x "${BLENDER_BIN}" ]; then
  echo "Blender binary not found. Please run tools/fetch_blender.sh first."
  exit 1
fi

echo "Running Blender Headless Render & Calibration..."
# Execute the scene authoring script in background headless mode
"${BLENDER_BIN}" -b -P "${SCRIPT_DIR}/blender_calibration.py"
