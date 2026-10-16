# Admin 07 release preparation

Admin 07 now has the web console, separate administrator credentials, temporary
staff grants, client staff controls, audited actions, checkpoint/backup recovery
without a player, and compatibility negotiation. Local checks passed through
`tools/ci/check-admin07.sh`, including exported Linux network operations,
non-root Helm deployment, pod replacement and packaged rendering. The admin web
console was also rendered and exercised in Chrome.

Delivery is now PR-based and tag-triggered CI, with central Windows signing,
OCI server publication and a Helm chart. The older prototype SDLC waiver is
superseded by the authorization recorded in AUTHORIZATION.md. A signed release
still requires pre-PR sign-off, external Codex review, merge and a release tag.
Scott owns Argo deployment. Live 05/7777 and 06/7778 were not changed.

The source is based on final 06. Admin credentials and audit data stay outside
world snapshots. Pending audit writes do not block recovery; corrupt committed
administration records fail closed and require the off-volume backup. World
checkpoints can recover a damaged newest save without a manual backup.
