#!/usr/bin/env python3
"""Consensus gate: PRs touching protected paths need a both-agent decision record.

Layer 3 of the review architecture (see docs/decisions/README.md). If a PR
touches any path enumerated in .github/protected-paths.txt, it must reference a
docs/decisions/NNN-topic.md record carrying sign-off lines from both residents.

A reference counts if either:
  - the PR body mentions the record path, or
  - the PR diff adds or modifies that record file (the normal case: the record
    usually lands in the same PR as the change it governs).

Stdlib only, no Godot, no network. Deliberately cheap enough to run on every
PR without caring about it.

Usage:
    tools/check_consensus.py --changed-files changed.txt --pr-body body.txt
    tools/check_consensus.py --changed-files changed.txt          # no body
    tools/check_consensus.py --self-test

--changed-files takes a file with one repo-relative path per line (what
`git diff --name-only` emits). Exit 0 = pass, 1 = gate failed, 2 = bad usage.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
PROTECTED_PATHS_FILE = REPO_ROOT / ".github" / "protected-paths.txt"
DECISIONS_DIR = "docs/decisions"

# A decision record is NNN-topic.md: exactly three digits, then a slug.
# TEMPLATE.md and README.md live in the same directory and are not records.
DECISION_RECORD_RE = re.compile(r"docs/decisions/(\d{3})-([a-z0-9][a-z0-9-]*)\.md")

# The residents that must both sign. Matched against the name field of a
# "Signed-off-by: <name> <email> <timestamp>" line.
REQUIRED_SIGNERS = ("claude-worker", "codex-worker")

SIGNOFF_RE = re.compile(r"^\s*Signed-off-by:\s*([\w.-]+)\s*<", re.MULTILINE)


def load_protected_paths(path: Path) -> list[str]:
    """Parse the protected-paths config. One path per line, # comments, blanks ignored."""
    if not path.exists():
        raise FileNotFoundError(f"protected paths config not found: {path}")
    entries = []
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.split("#", 1)[0].strip()
        if line:
            entries.append(line)
    if not entries:
        raise ValueError(f"protected paths config is empty: {path}")
    return entries


def is_protected(changed_path: str, protected: list[str]) -> str | None:
    """Return the protected entry matching this path, or None.

    A trailing '/' entry matches that directory and everything under it.
    Anything else matches the exact path.
    """
    normalized = changed_path.strip().replace("\\", "/")
    # Strip a leading './' only. Not str.lstrip('./'), which strips leading '.'
    # and '/' characters individually and so turns '.github/x' into 'github/x',
    # silently unprotecting every dot-prefixed path.
    while normalized.startswith("./"):
        normalized = normalized[2:]
    for entry in protected:
        if entry.endswith("/"):
            if normalized.startswith(entry):
                return entry
        elif normalized == entry:
            return entry
    return None


def protected_hits(changed_files: list[str], protected: list[str]) -> list[tuple[str, str]]:
    """Every (changed path, matching protected entry) pair in the diff."""
    hits = []
    for changed in changed_files:
        if not changed.strip():
            continue
        match = is_protected(changed, protected)
        if match:
            hits.append((changed.strip(), match))
    return hits


def referenced_records(changed_files: list[str], pr_body: str) -> list[str]:
    """Decision records this PR references, via the diff or the PR body."""
    found = set()
    for changed in changed_files:
        for match in DECISION_RECORD_RE.finditer(changed.strip().replace("\\", "/")):
            found.add(match.group(0))
    for match in DECISION_RECORD_RE.finditer(pr_body or ""):
        found.add(match.group(0))
    return sorted(found)


def signers_of(record_text: str) -> set[str]:
    """The resident names appearing in Signed-off-by lines."""
    return set(SIGNOFF_RE.findall(record_text))


def check_record(record_path: str, repo_root: Path) -> tuple[bool, str]:
    """Is this record present and signed by both residents?"""
    full = repo_root / record_path
    if not full.exists():
        return False, f"{record_path}: referenced but does not exist in the repo"
    signers = signers_of(full.read_text(encoding="utf-8"))
    missing = [s for s in REQUIRED_SIGNERS if s not in signers]
    if missing:
        return False, (
            f"{record_path}: missing sign-off from {', '.join(missing)} "
            f"(found: {', '.join(sorted(signers)) or 'none'})"
        )
    return True, f"{record_path}: signed by {', '.join(REQUIRED_SIGNERS)}"


def run_check(changed_files: list[str], pr_body: str, repo_root: Path) -> int:
    protected = load_protected_paths(repo_root / ".github" / "protected-paths.txt")
    hits = protected_hits(changed_files, protected)

    if not hits:
        print("No protected paths touched. Consensus record not required.")
        return 0

    print("This PR touches protected paths:")
    for changed, entry in hits:
        print(f"  {changed}  (matches '{entry}')")
    print()

    records = referenced_records(changed_files, pr_body)
    if not records:
        print("FAIL: no decision record referenced.")
        print()
        print("A PR touching a protected path must reference a")
        print("docs/decisions/NNN-topic.md record signed by both agents, either by")
        print("adding/modifying the record in this PR or by naming its path in the")
        print("PR body. See docs/decisions/README.md.")
        return 1

    results = [check_record(r, repo_root) for r in records]
    for ok, message in results:
        print(f"  {'OK  ' if ok else 'FAIL'} {message}")
    print()

    if any(ok for ok, _ in results):
        print("PASS: a referenced decision record carries both agents' sign-offs.")
        return 0

    print("FAIL: referenced decision record(s) are not signed by both agents.")
    print("See docs/decisions/README.md for the required sign-off line format.")
    return 1


def self_test() -> int:
    """Lightweight checks on the matching logic. No network, no fixtures on disk."""
    protected = [
        "project.godot",
        "ARCHITECTURE.md",
        "src/sim/",
        "roles/",
        ".github/protected-paths.txt",
    ]
    cases = [
        ("project.godot", "project.godot"),
        ("src/sim/game_state.gd", "src/sim/"),
        ("src/sim/nested/deep.gd", "src/sim/"),
        ("roles/orchestrator.md", "roles/"),
        # Dot-prefixed paths: str.lstrip('./') used to mangle these into
        # 'github/...' and silently unprotect them.
        (".github/protected-paths.txt", ".github/protected-paths.txt"),
        ("./.github/protected-paths.txt", ".github/protected-paths.txt"),
        ("./project.godot", "project.godot"),
        (".github/workflows/ci.yml", None),
        ("src/render/town/starter_town.gd", None),
        ("src/legacy_procedural/sim/spawn_finder.gd", None),
        ("src/simulation_notes.md", None),  # 'src/sim' prefix but not the dir
        ("README.md", None),
    ]
    failures = 0
    for path, expected in cases:
        actual = is_protected(path, protected)
        if actual != expected:
            print(f"FAIL is_protected({path!r}) = {actual!r}, expected {expected!r}")
            failures += 1

    record_cases = [
        (["docs/decisions/001-walk-cycle.md"], "", ["docs/decisions/001-walk-cycle.md"]),
        ([], "see docs/decisions/002-npc-schedules.md", ["docs/decisions/002-npc-schedules.md"]),
        (["docs/decisions/TEMPLATE.md", "docs/decisions/README.md"], "", []),
        (["docs/decisions/1-short.md"], "", []),  # not zero-padded to 3
    ]
    for changed, body, expected in record_cases:
        actual = referenced_records(changed, body)
        if actual != expected:
            print(f"FAIL referenced_records({changed!r}, {body!r}) = {actual!r}, expected {expected!r}")
            failures += 1

    signed = (
        "Signed-off-by: claude-worker <claude@sentania.net> 2026-07-16T14:22:05Z\n"
        "Signed-off-by: codex-worker <codex@sentania.net> 2026-07-16T14:31:40Z\n"
    )
    if signers_of(signed) != {"claude-worker", "codex-worker"}:
        print(f"FAIL signers_of(both) = {signers_of(signed)!r}")
        failures += 1
    if signers_of("Signed-off-by: claude-worker <claude@sentania.net> 2026-07-16T14:22:05Z") != {"claude-worker"}:
        print("FAIL signers_of(one) did not return just claude-worker")
        failures += 1
    if signers_of("no sign-offs here at all") != set():
        print("FAIL signers_of(none) was not empty")
        failures += 1

    # The real config must parse, so a malformed edit to it fails here rather
    # than at the first PR that happens to touch a protected path.
    try:
        entries = load_protected_paths(PROTECTED_PATHS_FILE)
    except (FileNotFoundError, ValueError) as exc:
        print(f"FAIL loading the real protected-paths config: {exc}")
        failures += 1
    else:
        for required in ("project.godot", "ARCHITECTURE.md", "src/sim/", ".github/protected-paths.txt"):
            if required not in entries:
                print(f"FAIL protected-paths config is missing required entry: {required}")
                failures += 1

    if failures:
        print(f"\n{failures} self-test failure(s).")
        return 1
    print("All consensus-gate self-tests passed.")
    return 0


def read_lines(path: str | None) -> list[str]:
    if not path:
        return []
    return Path(path).read_text(encoding="utf-8").splitlines()


def read_text(path: str | None) -> str:
    if not path:
        return ""
    return Path(path).read_text(encoding="utf-8")


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--changed-files", help="file with one changed repo-relative path per line")
    parser.add_argument("--pr-body", help="file containing the PR body text")
    parser.add_argument("--repo-root", default=str(REPO_ROOT), help="repo root (defaults to this checkout)")
    parser.add_argument("--self-test", action="store_true", help="run the matching-logic self-tests and exit")
    args = parser.parse_args(argv)

    if args.self_test:
        return self_test()

    if not args.changed_files:
        parser.error("--changed-files is required unless --self-test is given")

    return run_check(
        changed_files=read_lines(args.changed_files),
        pr_body=read_text(args.pr_body),
        repo_root=Path(args.repo_root).resolve(),
    )


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
