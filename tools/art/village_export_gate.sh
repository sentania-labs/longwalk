#!/usr/bin/env bash
# Isolated-packaged export audit + capture gate for the inn-green village
# district (decision 009 item 2). This is the load-bearing proof that a STOCK
# packaged build ships the real village art (res://assets/village/, driven by
# manifest.json) rather than silently substituting engine defaults (the
# carry-forward finding from round 006).
#
# It:
#   1. imports + exports a PACKED bundle (.pck) from the stock "Windows Desktop"
#      preset (all_resources filter, no include-glob edit to the protected
#      export_presets.cfg), NOT the source tree;
#   2. copies that bundle into a temp dir with NO res:// source tree;
#   3. runs the pinned engine headless against the bundle (--main-pack), driving
#      tools/art/village_export_audit.gd, which asserts every manifest asset
#      resolves through ResourceLoader with nonzero declared dims, the four
#      registered landmarks project on-screen at 0.5x/1x/2x, and the capture is
#      non-blank (fails on a missing asset or a default/blank fixture);
#   4. captures the district PNG at 0.5x / 1x / 2x into docs/art/village/.
#
# Usage: tools/art/village_export_gate.sh
# Exit code 0 = gate passed. Any non-zero = gate failed.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
GODOT="${REPO_ROOT}/tools/godot/godot"
PRESET="Windows Desktop"

CAPTURE_OUT="${REPO_ROOT}/docs/art/village"
mkdir -p "${CAPTURE_OUT}"

WORK="$(mktemp -d)"
BUNDLE_DIR="${WORK}/bundle"
CAP_DIR="${WORK}/captures"
mkdir -p "${BUNDLE_DIR}" "${CAP_DIR}"
cleanup() { rm -rf "${WORK}"; }
trap cleanup EXIT

if [ ! -x "${GODOT}" ]; then
	"${REPO_ROOT}/tools/fetch_godot.sh"
fi

echo "=== village export gate: import + regenerate provisional assets ==="
# Regenerate the provisional placeholder assets so the bundle is built from a
# known set even on a clean checkout. (Codex's real assets, when integrated,
# overwrite assets/village/ and this same gate re-runs against them.)
python3 "${REPO_ROOT}/tools/art/village_placeholder_assets.py"
"${GODOT}" --headless --path "${REPO_ROOT}" --import >/dev/null 2>&1

echo "=== export packed bundle from stock preset (all_resources) ==="
"${GODOT}" --headless --path "${REPO_ROOT}" --export-pack "${PRESET}" "${BUNDLE_DIR}/village.pck"
echo "packed bundle: $(stat -c%s "${BUNDLE_DIR}/village.pck") bytes"

echo "=== run audit against the isolated bundle (no source tree) ==="
# Run from a directory that is NOT the repo, with only the .pck present, so
# res:// can only resolve from the packed bundle. A source-tree leak would
# defeat the whole point of the isolation.
#
# The audit renders and screenshots the district, so it needs a real GL context:
# a virtual X display (xvfb-run) drives the project's gl_compatibility renderer
# to draw actual pixels. Godot's --headless flag uses the dummy rendering driver
# instead, which produces no frames (RenderingServer.frame_post_draw never fires
# and the capture would hang / be blank), so it is deliberately NOT used here.
# "Isolated" is enforced by the packed bundle + non-repo cwd, not by --headless.
# A timeout backstops any future capture hang so the gate fails loudly instead
# of wedging.
set +e
(
	cd "${BUNDLE_DIR}" && \
	VILLAGE_CAPTURE_DIR="${CAP_DIR}" timeout 240 xvfb-run -a "${GODOT}" \
		--main-pack "${BUNDLE_DIR}/village.pck" \
		--script res://tools/art/village_export_audit.gd
)
GATE_RC=$?
set -e

if [ "${GATE_RC}" -ne 0 ]; then
	echo "GATE FAILED (audit exit ${GATE_RC})"
	exit "${GATE_RC}"
fi

# Collect captures into the repo for the side-by-side vs the spike.
cp "${CAP_DIR}"/village-inn-green-*.png "${CAPTURE_OUT}/"
echo "captures:"
for f in "${CAPTURE_OUT}"/village-inn-green-*.png; do
	echo "  ${f}"
done

echo "VILLAGE EXPORT GATE PASSED"
