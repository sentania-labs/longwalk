---
reviewed_branch: codex/release-tag-validation
reviewed_sha: 3f125a2fe4cdc2a890a1b24ef6e7b72f82c085b1
reviewed_by: claude-worker
authored_by: codex-worker
timestamp: 2026-10-16T09:55:00-05:00
tests_run: python3 tools/ci/test_release_tag.py; actionlint .github/workflows/admin07.yml; shellcheck tools/ci/validate-release-tag.sh
result: signed-off
---

Adversarial review of c08881c..3f125a2 (one commit) by Claude, acting as an
independent reviewer. Scope: the release tag guard must accept an annotated
remote tag at the event commit on main even after actions/checkout has
rewritten the local tag ref to a plain commit, and must reject lightweight,
invalid, missing, mismatched and off-main tags.

What changed: the inline validation in admin07.yml moves to
tools/ci/validate-release-tag.sh. Instead of inspecting the local tag ref
(which checkout rewrites to the commit SHA, so the old `cat-file -t` check
always saw `commit` and failed every real release), the script fetches
refs/tags/$TAG from origin without a destination refspec, so only FETCH_HEAD
is written and the local tag is left alone. It then requires FETCH_HEAD to be
a tag object, requires its peeled commit to equal GITHUB_SHA, and requires
GITHUB_SHA to be an ancestor of origin/main. A new regression test,
test_release_tag.py, builds a bare-bones remote plus clone, reproduces the
checkout refspec rewrite, asserts the local ref really is a commit, and
exercises six cases. check-admin07.sh now runs that test on every CI build.

Verified in the worktree, all passing:

- The regression test: accepts the rewritten annotated tag at the main
  commit, rejects lightweight, off-main, mismatched SHA, missing and
  non-semver tag names.
- actionlint on the modified workflow, clean.
- shellcheck on the new script, clean.
- Extra probes outside the test: a GITHUB_SHA equal to the tag object SHA
  rather than the commit is rejected (GitHub supplies the peeled commit for
  tag pushes, so this is the correct direction); an empty TAG or empty
  GITHUB_SHA fails on the parameter guards; a tag name carrying shell
  metacharacters fails the regex before any git command sees it.
- The build job keeps fetch-depth 0, so origin/main exists and the
  merge-base ancestry check is not running against a shallow history.
- Fail-closed under set -euo pipefail: a failed regex match, a failed fetch,
  a non-tag FETCH_HEAD, a SHA mismatch, or a non-ancestor each exit non-zero.

Constitution: no em-dashes in the diff, no protected path touched
(.github/protected-paths.txt lists workflows nowhere, and tools/ci/ is not
listed), no sim-layer change, cross-platform clean.

Non-blocking observations, recorded for the author, no change requested:

- A nested annotated tag (an annotated tag whose object is another annotated
  tag) is accepted, since cat-file reports `tag` and `^{commit}` peels all
  the way down. That is consistent with the stated scope and not a real
  attack surface, but it is not covered by the test.
- The fixture uses `git init -b main`, which needs git 2.28 or newer. Fine
  on ubuntu-24.04 and on this workstation.
- Because the script re-fetches from origin at run time, a tag moved on the
  remote between the push event and the job run is rejected by the SHA
  comparison rather than silently validated against the new target. That is
  the desired behaviour and worth knowing when a failed release is
  investigated.

Limits: I did not run the full tools/ci/check-admin07.sh (it needs the
pinned Godot, Docker and kind) and no real tag push has exercised the new
step on a GitHub runner yet. The checkout rewrite is proven by the fixture,
not by a live run.
