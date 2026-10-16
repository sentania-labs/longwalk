# Admin sprint authorization

Scott: "okay go for the admins sprint"

Approved scope: web admin console replacing player ownership; server-authorized admin/mod client access; inspect, self teleport and administrative skill adjustment; common permissions and audit history; recovery without a player; stable compatibility/update handshake; release and Argo preparation. Automatic updater and distributed storage/regions are later sprints.

Software under Scott's existing local prototype SDLC/CI waiver ("since we are prototyping we can probably skip the full SLDC/CI approach"). New work stays in shared_village_07, with isolated test data and local packaging. Preserve live 05 and 06. No registry publication, tag release, main-project architecture edits or lab/Argo deployment is authorized by this local preparation step.

## Delivery update, 2026-10-15

Scott: "okay.  going forward i'd liek actual clients delivered via CI and server builds for play testing deliver via CI with OCI containers /w a helm chart for k8s deployment.  I will seperately deploy the server via argo to a target k8s cluster.

we'll do this by following the SDLC and CI skill to utilize PRs, external codex review and tagging."

Scott: "you should still do local smoke testing, but when you reach scott playtests points.  tagged release.  Also plesae use the sentania-labs central CI actions to sign the windows binaries."

Scott: "proceed with the approved work"

This supersedes the local prototype delivery waiver above for this sprint.
Finish Admin 07, smoke-test locally, use independent review and a PR with
external Codex review, and deliver the playtest through a tagged CI release.
Publish Windows clients signed with the central action, server OCI images,
and a Helm chart. Scott owns deployment through Argo. Preserve existing live
worlds and unrelated working tree changes. Repository merge restrictions
continue to apply.

Scott's standing scope rule: "Same for scope found mid-task: new imperfections
become issues, not initiative." Repository branch protection is tracked as a
separate issue; this sprint does not change repository protection settings.
