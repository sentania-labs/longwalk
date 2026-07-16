#!/usr/bin/env bash
# Generate one AI art asset via the local `codex` CLI's built-in image_gen
# tool. See tools/art/README.md for the pipeline overview and a sandbox
# caveat this script works around.
#
# Usage: tools/art/generate.sh <prompt-file> <output-name.png>
# Example: tools/art/generate.sh prompts/ground_path_tile.md ground_path_tile.png
#
# Requires the codex CLI installed and authenticated (`codex login`).
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <prompt-file> <output-name.png>" >&2
  exit 1
fi

PROMPT_FILE="$1"
OUT_NAME="$2"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STYLE_FILE="${SCRIPT_DIR}/style.md"
OUT_DIR="${SCRIPT_DIR}/out"
mkdir -p "${OUT_DIR}"

if [ ! -f "${PROMPT_FILE}" ]; then
  echo "Prompt file not found: ${PROMPT_FILE}" >&2
  exit 1
fi

# codex's built-in image_gen tool writes the raw generated PNG under
# ~/.codex/generated_images/<session>/<call>.png. Diff the directory before
# and after the run to find the new file, and copy it out with plain `cp`
# here rather than asking codex to resize/rename it itself: in this
# environment, codex's own follow-up shell (`exec`) tool calls hit a
# filesystem-sandbox networking bug (`bwrap: loopback: Failed RTM_NEWADDR:
# Operation not permitted`) even though image generation itself works fine.
# Keeping all post-processing outside codex sidesteps that entirely.
GEN_DIR="${HOME}/.codex/generated_images"
mkdir -p "${GEN_DIR}"
BEFORE="$(mktemp)"
AFTER="$(mktemp)"
trap 'rm -f "${BEFORE}" "${AFTER}"' EXIT
find "${GEN_DIR}" -type f -name '*.png' 2>/dev/null | sort > "${BEFORE}"

PROMPT="$(cat "${STYLE_FILE}" "${PROMPT_FILE}")"

codex exec \
  --sandbox workspace-write \
  --skip-git-repo-check \
  "${PROMPT}

Generate the image described above with the image_gen tool. Do not run any
shell commands to resize, convert, or move the file; just generate it and
stop."

find "${GEN_DIR}" -type f -name '*.png' 2>/dev/null | sort > "${AFTER}"
NEW_FILE="$(comm -13 "${BEFORE}" "${AFTER}" | head -1)"

if [ -z "${NEW_FILE}" ]; then
  echo "No new generated image found under ${GEN_DIR}." >&2
  echo "Generation may have failed; rerun 'codex exec' directly with the same prompt to see the transcript." >&2
  exit 1
fi

cp "${NEW_FILE}" "${OUT_DIR}/${OUT_NAME}"
echo "Wrote ${OUT_DIR}/${OUT_NAME} (from ${NEW_FILE})"
