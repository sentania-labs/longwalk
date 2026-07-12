#!/usr/bin/env bash
# Fetch the pinned Godot export templates reproducibly and install the Windows
# templates where the engine looks for them, so
# `godot --export-release "Windows Desktop"` can produce a Windows build. The
# templates archive is not committed; this script re-downloads the exact pinned
# version, parallel to tools/fetch_godot.sh.
#
# The full templates archive carries every platform (Android, iOS, web, macOS,
# Linux, Windows) and is multiple gigabytes unpacked. M2 only exports Windows
# x86_64, so this installs just the Windows templates (release plus its console
# wrapper) and the version marker. That keeps the install and the CI cache
# small. Add more members here if a future milestone exports other platforms.
#
# Godot release asset naming for the templates is
# `Godot_v<version>_export_templates.tpz` (a zip). Its members live under
# `templates/`, and `templates/version.txt` (for example "4.3.stable") names the
# versioned install directory the engine reads:
#   $HOME/.local/share/godot/export_templates/<version.txt>/
set -euo pipefail

GODOT_VERSION="4.3-stable"
TPZ="Godot_v${GODOT_VERSION}_export_templates.tpz"
URL="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/${TPZ}"

# Only the members needed for a Windows x86_64 export.
MEMBERS=(
  "templates/version.txt"
  "templates/windows_release_x86_64.exe"
  "templates/windows_release_x86_64_console.exe"
)

# Templates install root. Respect an override so CI can place them on a cached
# path; default to the standard per-user Godot data directory.
TEMPLATES_ROOT="${GODOT_TEMPLATES_ROOT:-${HOME}/.local/share/godot/export_templates}"

# If the Windows release template is already installed for this version, skip.
if [ -f "${TEMPLATES_ROOT}/${GODOT_VERSION%-*}.stable/windows_release_x86_64.exe" ]; then
  echo "Windows export templates already present under ${TEMPLATES_ROOT}"
  exit 0
fi

TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

echo "Downloading Godot export templates ${GODOT_VERSION} from ${URL}"
curl -fsSL -o "${TMP}/${TPZ}" "${URL}"

# Extract only the Windows members to avoid unpacking the multi-gigabyte set.
unzip -q -o "${TMP}/${TPZ}" "${MEMBERS[@]}" -d "${TMP}"

VERSION_NAME="$(cat "${TMP}/templates/version.txt")"
DEST="${TEMPLATES_ROOT}/${VERSION_NAME}"
mkdir -p "${DEST}"
for member in "${MEMBERS[@]}"; do
  cp -f "${TMP}/${member}" "${DEST}/"
done

echo "Installed Windows export templates ${VERSION_NAME} into ${DEST}"
ls "${DEST}" | sed 's/^/  /'
