# Admin 07

This sprint adds a separate web administration console and temporary staff access
to the Working Day 06 village. Traveler profiles never become administrators.
The workshop, repeat orders, provisioner, skills and moth ecology remain in place.

Download a tagged CI release for playtesting. Extract the full Windows ZIP and
keep the executable beside its matching `Longwalk-Art-01.pck`. Later client-only
updates can reuse that exact pack. Windows binaries are signed through the
sentania-labs central signing action. The Linux ZIP supports local validation.
Open Connection settings and enter your deployed server address and UDP port.

Administrators create their account in the web console using the setup token
provided by the deployment operator. The console handles pause/resume, time,
capacity, backups, recovery, skill changes, teleportation, release information
and audit history. Administrative records persist outside world snapshots.

To enable staff mode, connect a traveler first. Select that online traveler in
the console and grant administrator or moderator access. Enter the one-use code
in the client's Connection settings. The code expires after two minutes and
access after one hour or disconnect. Moderators may inspect travelers and
teleport themselves. Only administrators may adjust skills or administer the
world. Revoke access in the console or use Leave staff mode in the client.

The 07 handshake rejects incompatible baselines, protocol, art packs and required
exact builds before character registration. Optional update notices include an
HTTPS release link in Connection settings. Installation remains manual. Old
05/06 clients predate this negotiation, so upgrade client and server together.

For Argo configuration, storage, private networking and recovery, see
[the Helm chart instructions](../../charts/longwalk/README.md). CI publishes the
image and chart; Scott performs deployment. No live world is changed by local
verification. One writer and Recreate are required. Snapshot retention,
distributed simulation, automatic updates and close-view art remain follow-ups.

Run `tools/ci/check-admin07.sh` from the repository to lint, build, exercise real
client/API flows, test the chart in disposable kind, and render the packaged
Linux client. The release workflow additionally signs and launches the Windows
binary before packaging. Test artifacts stay under ignored build/artifacts
folders. Runtime rendering and Windows playtest verdicts are separate from CI
status.
