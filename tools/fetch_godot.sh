#!/usr/bin/env bash
# Fetch the pinned Godot 4 headless-capable Linux binary reproducibly.
# The binary itself is gitignored, this script re-downloads the exact
# pinned version so every dispatch and CI run uses the same engine.
set -euo pipefail

GODOT_VERSION="4.3-stable"
GODOT_ZIP="Godot_v${GODOT_VERSION}_linux.x86_64.zip"
GODOT_BIN="Godot_v${GODOT_VERSION}_linux.x86_64"
GODOT_URL="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/${GODOT_ZIP}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST_DIR="${SCRIPT_DIR}/godot"
mkdir -p "${DEST_DIR}"

TARGET="${DEST_DIR}/${GODOT_BIN}"
if [ -x "${TARGET}" ]; then
  echo "Godot ${GODOT_VERSION} already present at ${TARGET}"
  exit 0
fi

echo "Downloading Godot ${GODOT_VERSION} from ${GODOT_URL}"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT
curl -fsSL -o "${TMP}/${GODOT_ZIP}" "${GODOT_URL}"
unzip -q -o "${TMP}/${GODOT_ZIP}" -d "${DEST_DIR}"
chmod +x "${TARGET}"

# Stable symlink so callers do not hardcode the version string.
ln -sf "${GODOT_BIN}" "${DEST_DIR}/godot"

echo "Godot ${GODOT_VERSION} installed at ${TARGET}"
"${TARGET}" --version || true
