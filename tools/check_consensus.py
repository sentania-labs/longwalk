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
import tempfile
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
PROTECTED_PATHS_FILE = REPO_ROOT / ".github" / "protected-paths.txt"
DECISIONS_DIR = "docs/decisions"

# A decision record is NNN-topic.md: exactly three digits, then a slug.
# TEMPLATE.md and README.md live in the same directory and are not records.
DECISION_RECORD_RE = re.compile(r"docs/decisions/(\d{3})-([a-z0-9][a-z0-9-]*)\.md")

# The residents that must both sign.
REQUIRED_SIGNERS = ("claude-worker", "codex-worker")

# A sign-off line is validated in full, not just by name:
#
#     Signed-off-by: claude-worker <claude@sentania.net> 2026-07-16T14:22:05Z
#
# The whole line matters because docs/decisions/TEMPLATE.md already carries
# both required worker names in its sign-off block. A record copied from the
# template and never actually signed would satisfy a name-only match, so an
# unsigned record would clear the gate. Requiring a real UTC ISO 8601
# timestamp is what separates a signature from the template's
# 'YYYY-MM-DDTHH:MM:SSZ' placeholder: a worker cannot sign without stating
# when, and a placeholder cannot spell a date.
SIGNOFF_RE = re.compile(
    r"^\s*Signed-off-by:\s*"
    r"(?P<name>[\w.-]+)\s*"
    r"<(?P<email>[^@<>\s]+@[^@<>\s]+)>\s*"
    r"(?P<timestamp>\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z)\s*$",
    re.MULTILINE,
)

# The record section naming the protected paths a record covers. A record
# authorizes only the paths it says it covers, so the gate reads this rather
# than accepting any signed record for any protected change.
COVERAGE_HEADING = "Protected paths touched"
COVERAGE_SECTION_RE = re.compile(
    r"^#+\s*" + re.escape(COVERAGE_HEADING) + r"\s*$(?P<body>.*?)(?=^#+\s|\Z)",
    re.MULTILINE | re.DOTALL,
)


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
    """Resident names with a complete, non-placeholder Signed-off-by line."""
    return {m.group("name") for m in SIGNOFF_RE.finditer(record_text)}


def covered_entries(record_text: str, protected: list[str]) -> set[str]:
    """Protected-path entries this record's coverage section claims to cover."""
    match = COVERAGE_SECTION_RE.search(record_text)
    if not match:
        return set()
    body = match.group("body")
    # Drop the template's own instructional prose so an unfilled section does
    # not accidentally 'cover' every entry it names as an example.
    lines = [ln for ln in body.splitlines() if not ln.strip().startswith(">")]
    text = "\n".join(lines)
    return {entry for entry in protected if entry in text}


def check_record(record_path: str, repo_root: Path, hit_entries: set[str], protected: list[str]) -> tuple[bool, str]:
    """Is this record present, signed by both residents, and does it cover these paths?"""
    full = repo_root / record_path
    if not full.exists():
        return False, f"{record_path}: referenced but does not exist in the repo"

    text = full.read_text(encoding="utf-8")

    signers = signers_of(text)
    missing = [s for s in REQUIRED_SIGNERS if s not in signers]
    if missing:
        return False, (
            f"{record_path}: missing a valid sign-off from {', '.join(missing)} "
            f"(found: {', '.join(sorted(signers)) or 'none'}). A sign-off line must "
            f"carry a name, an email, and a real UTC timestamp; template placeholders "
            f"do not count."
        )

    covered = covered_entries(text, protected)
    uncovered = sorted(hit_entries - covered)
    if uncovered:
        return False, (
            f"{record_path}: signed, but its '{COVERAGE_HEADING}' section does not "
            f"cover {', '.join(uncovered)} (covers: {', '.join(sorted(covered)) or 'nothing'})"
        )

    return True, (
        f"{record_path}: signed by {', '.join(REQUIRED_SIGNERS)} and covers "
        f"{', '.join(sorted(hit_entries))}"
    )


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

    hit_entries = {entry for _, entry in hits}

    records = referenced_records(changed_files, pr_body)
    if not records:
        print("FAIL: no decision record referenced.")
        print()
        print("A PR touching a protected path must reference a")
        print("docs/decisions/NNN-topic.md record signed by both agents, either by")
        print("adding/modifying the record in this PR or by naming its path in the")
        print("PR body. See docs/decisions/README.md.")
        return 1

    results = [check_record(r, repo_root, hit_entries, protected) for r in records]
    for ok, message in results:
        print(f"  {'OK  ' if ok else 'FAIL'} {message}")
    print()

    if any(ok for ok, _ in results):
        print("PASS: a referenced decision record is signed by both agents and covers")
        print("every protected path this PR touches.")
        return 0

    print("FAIL: no referenced decision record both carries valid sign-offs from")
    print("both agents and covers every protected path this PR touches.")
    print("See docs/decisions/README.md.")
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
    signoff_cases = [
        (signed, {"claude-worker", "codex-worker"}, "both residents signed"),
        (
            "    Signed-off-by: claude-worker <claude@sentania.net> 2026-07-16T14:22:05Z",
            {"claude-worker"},
            "indented (fenced) sign-off still counts",
        ),
        ("no sign-offs here at all", set(), "no sign-off lines"),
        # The template placeholder must never count. A record copied from
        # TEMPLATE.md and left unsigned would otherwise clear the gate,
        # because the template already names both required residents.
        (
            "Signed-off-by: claude-worker <claude@sentania.net> YYYY-MM-DDTHH:MM:SSZ\n"
            "Signed-off-by: codex-worker <codex@sentania.net> YYYY-MM-DDTHH:MM:SSZ\n",
            set(),
            "unedited template placeholder timestamps",
        ),
        (
            "Signed-off-by: claude-worker <claude@sentania.net>",
            set(),
            "name and email but no timestamp",
        ),
        (
            "Signed-off-by: claude-worker 2026-07-16T14:22:05Z",
            set(),
            "name and timestamp but no email",
        ),
    ]
    for text, expected, label in signoff_cases:
        actual = signers_of(text)
        if actual != expected:
            print(f"FAIL signers_of [{label}] = {actual!r}, expected {expected!r}")
            failures += 1

    # The real template must not read as a signed record. This is the exact
    # bootstrap trap: the template names both residents already.
    template = REPO_ROOT / "docs" / "decisions" / "TEMPLATE.md"
    if template.exists():
        template_signers = signers_of(template.read_text(encoding="utf-8"))
        if template_signers:
            print(f"FAIL docs/decisions/TEMPLATE.md reads as signed by {template_signers!r}")
            failures += 1

    # Coverage: a signed record authorizes only the paths it says it covers,
    # so an old record cannot be cited to wave through an unrelated protected
    # change.
    record = signed + "\n## Protected paths touched\n\nsrc/sim/\n"
    coverage_cases = [
        ({"src/sim/"}, True, "record covers the touched path"),
        ({"project.godot"}, False, "record does not cover the touched path"),
        ({"src/sim/", "project.godot"}, False, "record covers only some touched paths"),
        (set(), True, "nothing to cover"),
    ]
    for hits, expect_ok, label in coverage_cases:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "docs" / "decisions").mkdir(parents=True)
            (root / "docs" / "decisions" / "001-x.md").write_text(record, encoding="utf-8")
            ok, message = check_record("docs/decisions/001-x.md", root, hits, protected)
            if ok != expect_ok:
                print(f"FAIL check_record [{label}] ok={ok}, expected {expect_ok}: {message}")
                failures += 1

    if covered_entries("## Protected paths touched\n\nNone\n", protected) != set():
        print("FAIL covered_entries('None') was not empty")
        failures += 1
    if covered_entries("no such section", protected) != set():
        print("FAIL covered_entries(missing section) was not empty")
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
