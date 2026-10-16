# Longwalk playtest deployment

CI publishes a versioned OCI server image, an OCI Helm chart, and signed Windows
clients from an annotated release tag on main. Scott's deployment repository
pins the chart version and the image digest from `deployment-values.yaml`.
The source chart uses a `latest` placeholder; releases publish immutable version
tags only, so supply the release values when deploying.
This repository does not deploy through Argo or create DNS records.

Configure `admin.setupSecret` and `admin.setupSecretKey` to reference a Secret
managed by your deployment system. Its value must contain at least 32 random
characters. Supply it once in the console's initial setup screen to create a
separate administrator account. A restored world never grants a traveler admin
rights. Administrator credentials and audit records live under
`/data/administration`, outside world snapshots. Back up the entire volume for
disaster recovery, including that directory. Password reset without the saved
account is not implemented; preserve the account and your password manager entry.

The game uses UDP 7777. `service.type` defaults to ClusterIP; choose NodePort or
LoadBalancer according to your cluster. `service.nodePort` is optional for
NodePort. The separate admin service is always internal on TCP 8888. Configure
your own HTTPS proxy and `admin.origin` to its exact HTTPS origin. No ingress,
public DNS or cluster-specific load balancer is installed. Traffic from clients
to the game remains a private-network protocol.

Set `persistence.existingClaim` to retain an existing volume or let the chart
create a retained ReadWriteOnce claim. The deployment uses Recreate and one
replica, plus a writer lock. Do not scale replicas. The non-root process uses UID
and GID 1000 with fsGroup 1000; verify your storage class supports those permissions.
Health probes indicate a responsive process, including recovery mode. The console
shows whether world storage is frozen. Liveness does not mean the world is playable.

Before upgrading an existing world, stop its writer and take an off-volume copy.
07 accepts schema 3 saves; the previous owner field is retained as historical
save data but grants no privileges. To roll back to 06, stop 07 and restore the
pre-upgrade backup. Never run 06 and 07 against the same volume concurrently.

World restore requires pause, keeps newer character identities, preserves the
displaced state and leaves the world paused. Authentication and audit history do
not rewind. If the latest world record is corrupt, use the console to restore the
last readable checkpoint or a known backup without connecting a traveler.
An interrupted pending audit append is ignored at startup; corrupt committed
administrator or audit records fail closed and require restoring the separate
administration directory from your off-volume backup followed by a server restart. Snapshots have no automatic pruning.

Local verification: `tools/ci/check-admin07.sh`. It runs the same checks as CI,
including a disposable kind deployment with client and HTTP operations and pod
replacement. Real cluster storage, load balancing and Argo sync remain the
deployer's verification responsibility.

For a private registry package, configure imagePullSecrets and Argo registry
credentials in your deployment repository. CI does not change registry visibility.
