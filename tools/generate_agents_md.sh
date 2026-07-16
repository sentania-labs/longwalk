#!/usr/bin/env bash
# Generate AGENTS.md from CLAUDE.md so the two can never drift.
#
# CLAUDE.md is the one canonical source: the role-neutral constitution every
# resident honors regardless of which harness it runs on. AGENTS.md is the
# same text with a generated-file header prepended, so a Codex-side reader
# gets the identical rules and a hand edit to AGENTS.md is obvious in review.
#
# Deterministic and re-runnable: same CLAUDE.md in, byte-identical AGENTS.md
# out, no timestamps. Run with --check to verify AGENTS.md is up to date
# without writing (this is what CI does).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

SOURCE="${REPO_ROOT}/CLAUDE.md"
TARGET="${REPO_ROOT}/AGENTS.md"

render() {
	cat <<'EOF'
<!--
GENERATED FILE, DO NOT EDIT.

Produced from CLAUDE.md by tools/generate_agents_md.sh. CLAUDE.md is the one
canonical source for this constitution. To change anything below, edit
CLAUDE.md and re-run:

    tools/generate_agents_md.sh

Hand edits here will be overwritten and are flagged by CI.
-->

EOF
	cat "${SOURCE}"
}

if [[ "${1:-}" == "--check" ]]; then
	if ! render | diff -u "${TARGET}" - >/dev/null 2>&1; then
		echo "AGENTS.md is out of date with CLAUDE.md." >&2
		echo "Re-run tools/generate_agents_md.sh and commit the result." >&2
		render | diff -u "${TARGET}" - || true
		exit 1
	fi
	echo "AGENTS.md is up to date with CLAUDE.md."
	exit 0
fi

render > "${TARGET}"
echo "Wrote ${TARGET} from ${SOURCE}."
