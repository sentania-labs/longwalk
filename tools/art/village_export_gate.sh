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
ASSETS_DIR="${REPO_ROOT}/assets/village"
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

echo "=== village export gate: audit COMMITTED assets (no regeneration) ==="
# This gate packages and audits whatever is COMMITTED under assets/village/. It
# must NEVER mutate that tree: doing so would let the gate "prove" a build of art
# it just wrote itself, defeating the entire point of decision 009 item 2 and the
# round-006 carry-forward finding. The real art is proven at integration, when the
# orchestrator merges the real sliced assets over assets/village/ and re-runs this
# same, honest gate.
#
# A fresh checkout with no assets yet can bootstrap the provisional placeholders
# by hand: python3 tools/art/village_placeholder_assets.py. The gate does NOT run
# that tool; it fails loudly if the manifest is missing.
if [ ! -f "${ASSETS_DIR}/manifest.json" ]; then
	echo "GATE FAILED: ${ASSETS_DIR}/manifest.json is missing." >&2
	echo "The gate audits committed assets and never regenerates them. On a fresh" >&2
	echo "checkout, bootstrap the provisional set by hand first:" >&2
	echo "  python3 tools/art/village_placeholder_assets.py" >&2
	exit 1
fi

# Non-mutation guard: capture a checksum of the committed asset tree BEFORE the
# gate runs so we can prove the gate did not alter the art it audits. We hash the
# COMMITTED art only (git-tracked files: the PNGs and manifest.json), not the
# working tree, because --import legitimately writes generated .import sidecars
# that are not committed and are not art. A change to any tracked file, its name,
# or the set of tracked files is caught.
assets_tree_checksum() {
	( cd "${REPO_ROOT}" && git ls-files -z -- assets/village/ ) \
		| LC_ALL=C sort -z \
		| ( cd "${REPO_ROOT}" && xargs -0 sha256sum ) \
		| sha256sum \
		| awk '{print $1}'
}
ASSETS_BEFORE="$(assets_tree_checksum)"
echo "assets/village/ checksum before gate: ${ASSETS_BEFORE}"

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
AUDIT_LOG="${WORK}/audit.log"
set +e
(
	cd "${BUNDLE_DIR}" && \
	VILLAGE_CAPTURE_DIR="${CAP_DIR}" timeout 240 xvfb-run -a "${GODOT}" \
		--main-pack "${BUNDLE_DIR}/village.pck" \
		--script res://tools/art/village_export_audit.gd
) 2>&1 | tee "${AUDIT_LOG}"
# Preserve the audit's own exit status through the pipe (tee would otherwise mask it).
GATE_RC=${PIPESTATUS[0]}
set -e

if [ "${GATE_RC}" -ne 0 ]; then
	echo "GATE FAILED (audit exit ${GATE_RC})"
	exit "${GATE_RC}"
fi

# Shader-compile gate (decision 016 iter2). A shader that fails to compile makes
# Godot silently fall back to default canvas rendering, so the graded/feathered
# output never runs while the audit still screenshots a (wrong) scene and exits 0.
# That is exactly how a broken MODULATE built-in passed this gate green once. Treat
# any shader compile failure on the audit run as fatal so the next shader bug fails
# loudly instead of shipping the fallback.
if grep -qiE 'SHADER ERROR|Shader compilation failed' "${AUDIT_LOG}"; then
	echo "GATE FAILED: the audit run emitted shader compile errors." >&2
	echo "A failed shader compile falls back to default canvas rendering, so the" >&2
	echo "captured scene is NOT the real shader output. Offending lines:" >&2
	grep -niE 'SHADER ERROR|Shader compilation failed' "${AUDIT_LOG}" >&2
	exit 1
fi

# Collect captures into the repo for the side-by-side vs the spike.
cp "${CAP_DIR}"/village-inn-green-*.png "${CAPTURE_OUT}/"
echo "captures:"
for f in "${CAPTURE_OUT}"/village-inn-green-*.png; do
	echo "  ${f}"
done

# Non-mutation guard: prove the gate did not alter the committed art it audited.
ASSETS_AFTER="$(assets_tree_checksum)"
echo "assets/village/ checksum after gate:  ${ASSETS_AFTER}"
if [ "${ASSETS_BEFORE}" != "${ASSETS_AFTER}" ]; then
	echo "GATE FAILED: assets/village/ was mutated by the gate run." >&2
	echo "  before: ${ASSETS_BEFORE}" >&2
	echo "  after:  ${ASSETS_AFTER}" >&2
	echo "The gate must audit committed art without altering it." >&2
	exit 1
fi
echo "non-mutation guard: assets/village/ unchanged (${ASSETS_AFTER})"

echo "VILLAGE EXPORT GATE PASSED"
