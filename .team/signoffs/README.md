# Pre-PR peer sign-off markers

The first of the three review layers: before a worker opens a PR, the *other*
resident reviews the diff in-worktree and writes a marker here. **No marker,
no PR.**

This is deliberately not the same thing as the external
chatgpt-codex-connector review that posts on the PR after it opens (layer 2),
and not the same thing as the consensus decision record (layer 3, see
`docs/decisions/README.md`). Layer 1 catches problems while the branch is
still cheap to change. The other two are still required on top of it.

The tooling that writes and verifies these markers is a future dispatch.
This README is the spec that dispatch implements against. Until then, workers
write markers by hand in this format.

## Filename pattern

    .team/signoffs/<branch-slug>-<short-sha>.md

- `<branch-slug>`: the reviewed branch with `/` replaced by `-`, so
  `claude/walk-cycle-sprites` becomes `claude-walk-cycle-sprites`.
- `<short-sha>`: the first 12 characters of the reviewed commit SHA.

Example: `.team/signoffs/claude-walk-cycle-sprites-9f3a1c4d8e02.md`

The SHA is in the filename on purpose. A marker is evidence about one specific
commit, not a standing blessing of a branch: if the author pushes more commits
after the sign-off, the marker no longer covers the branch head and the peer
reviews again. A future verifier can enforce that by comparing the marker's
SHA to the PR head SHA without parsing the file.

## Required contents

Front matter, then a short prose review note:

```markdown
---
reviewed_branch: claude/walk-cycle-sprites
reviewed_sha: 9f3a1c4d8e02b7f5a3c1d9e8f7b6a5c4d3e2f1a0
reviewed_by: codex-worker
authored_by: claude-worker
timestamp: 2026-07-16T14:22:05Z
tests_run: tools/run_tests.sh
result: signed-off
---

What the reviewer actually checked, and anything the author changed in
response before this marker was written.
```

Field notes:

- `reviewed_sha` is the full 40-character SHA of the commit reviewed. The
  filename carries a short form for readability; this field is authoritative.
- `reviewed_by` must **not** equal `authored_by`. A resident never signs off
  its own change. That is the whole point of the gate and a verifier should
  reject a marker that violates it.
- `timestamp` is UTC, ISO 8601, `Z` suffix.
- `tests_run` records the command the reviewer actually ran in the worktree
  (normally `tools/run_tests.sh`). A sign-off is a claim the reviewer ran
  them, so an honest `tests_run: none` beats a decorative entry.
- `result` is `signed-off` or `changes-requested`. Only `signed-off` clears
  the gate. A `changes-requested` marker stays in the repo as history; the
  re-review after the fixes writes a new marker at the new SHA.

## What the reviewer checks

At minimum, before writing `result: signed-off`:

1. The tests run and pass in the worktree.
2. The diff conforms to the constitution: determinism (no stateful or
   unseeded RNG in placement decisions), sim/render separation (nothing under
   `src/sim/` reaching for a viewport, camera, or UI node), no em-dashes.
3. The diff matches the synthesis the team agreed on, rather than the
   author's own preference having drifted back in during implementation.
4. If the diff touches a protected path
   (`.github/protected-paths.txt`), a signed decision record exists to cover
   it.

A sign-off is a claim that you checked these. Do not write one you did not
earn.
