Admin 07 separates world administration from traveler profiles. The web console provides pause, clock and capacity settings, backups and recovery, traveler inspection, skill adjustment, teleportation, staff grants and an audit trail. A stable negotiation endpoint rejects incompatible clients before registration and advertises manual client updates.

Download the full Windows ZIP for a first install. Client-only updates require the exact matching art pack. Windows executables are signed by the sentania-labs central signing action before packaging. Use the accompanying checksum manifest to check downloads.

The server image is `ghcr.io/sentania-labs/longwalk-server` and the Helm chart is `oci://ghcr.io/sentania-labs/charts/longwalk`. Use this release's chart version and `deployment-values.yaml` image digest in your Argo configuration. Supply your own existing setup Secret, persistent storage and private UDP access. The admin service is internal and should sit behind your HTTPS proxy. CI publishes artifacts; Scott deploys them.

This remains one world writer. Take an external stopped-world backup before upgrading an existing save. Rollback to 06 requires that matching pre-upgrade backup. Existing 05/06 clients must be replaced together with the server; the new stable handshake governs 07 and future compatible releases. There is no automatic updater or public DNS provisioning.
