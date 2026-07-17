#!/usr/bin/env bash
# Fetch the pinned Blender headless-capable Linux binary reproducibly.
# The binary itself is gitignored, this script re-downloads the exact
# pinned version so every dispatch and CI run uses the same engine.
set -euo pipefail

BLENDER_VERSION="4.0.2"
BLENDER_MAJOR_MINOR="4.0"
BLENDER_TARBALL="blender-${BLENDER_VERSION}-linux-x64.tar.xz"
BLENDER_DIR_NAME="blender-${BLENDER_VERSION}-linux-x64"
BLENDER_URL="https://ftp.nluug.nl/pub/graphics/blender/release/Blender${BLENDER_MAJOR_MINOR}/${BLENDER_TARBALL}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST_DIR="${SCRIPT_DIR}/blender"
mkdir -p "${DEST_DIR}"

TARGET="${DEST_DIR}/${BLENDER_DIR_NAME}/blender"
if [ -x "${TARGET}" ]; then
  echo "Blender ${BLENDER_VERSION} already present at ${TARGET}"
  exit 0
fi

echo "Downloading Blender ${BLENDER_VERSION} from ${BLENDER_URL}"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT
curl -fsSL -o "${TMP}/${BLENDER_TARBALL}" "${BLENDER_URL}"
tar -xf "${TMP}/${BLENDER_TARBALL}" -C "${DEST_DIR}"

# Stable symlink so callers do not hardcode the version string.
ln -sf "${BLENDER_DIR_NAME}/blender" "${DEST_DIR}/blender_bin"

echo "Blender ${BLENDER_VERSION} installed at ${TARGET}"
"${DEST_DIR}/blender_bin" --version || true
