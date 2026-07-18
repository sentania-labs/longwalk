---
reviewed_branch: claude/007-village-render
reviewed_sha: c164ef7203226874ca8d89f7022f093d35c75a53
reviewed_by: codex-worker
authored_by: claude-worker
timestamp: 2026-07-18T05:41:10Z
tests_run: tools/run_tests.sh
result: signed-off
---

Confirmed that the export gate no longer invokes
`village_placeholder_assets.py`. It fails clearly when `manifest.json` is
absent, then imports, packages, and audits the files already committed under
`assets/village/`.

The non-mutation guard hashes the sorted tracked path set together with each
file's content hash before and after the gate, while naturally excluding
untracked `.import` sidecars. I also changed a tracked manifest in a temporary
detached worktree and confirmed that the before and after checksums differed,
so a tracked-art mutation does not false-pass. `tools/run_tests.sh` passed at
the reviewed head. This sign-off supersedes the changes-requested review of
`17611ace779a`.
