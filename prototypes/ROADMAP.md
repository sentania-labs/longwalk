# Longwalk prototype roadmap

This is the current interactive prototype plan. The root ROADMAP.md and ARCHITECTURE.md describe the earlier authored-map project and have not been rewritten by this prototype work.

## Current baseline: Working Day 06

Delivered locally and exercised: a 1024 x 1024 metre village, rotating/ground-level inspection camera, shared server-authoritative movement and world changes, player avoidance, workshop entry, inventory/equipment, first and repeat carpenter commissions, recovering woodfalls, provisioner routine and bread trading, Running and observation practice, daylight and a small persistent moth ecology. Floating interfaces, item icons, local profiles and a reusable external art pack are present.

Fifteen rule checks and the project import passed. Final Linux packages completed the work loop, reconnect and recovery checks. Sixteen release clients ran 45 minutes through graceful and forced server restarts with identity and inventory retained. Windows was exported, not executed here. Distant-route bursts still cause multi-second server delays. See shared_village_06/FOLLOW-UPS.md and SESSION-HANDOFF.md.

## Active sprint: Administration 07

Approved by Scott: "okay go for the admins sprint".

- Replace first-player world ownership with a web admin console for pause/resume, clock, capacity, saves, backup/restore and diagnostics.
- Keep ordinary local player profiles without an account login.
- Grant admin/mod access to a connected client through server authorization. Initial powers: inspection, self teleport and admin skill adjustments. Show staff status in world.
- Use shared permissions and audit records for web and client actions. Keep admin identity outside world snapshots.
- Recover a frozen world without requiring a player to own or enter it.
- Introduce a separate stable compatibility handshake, including required/optional update status and release-manifest information.
- Prepare matching client/server artifacts and the GitOps deployment boundary. No registry publication or lab deployment has occurred.

Status: partial implementation only. shared_village_07 currently contains draft admin storage/permissions, threaded password derivation, HTTP handling and handshake modules. They are not yet wired into the game, tested or packaged. The live playtests remain 05 and 06.

## Following sprint: Automatic client and asset updates

The server advertises compatibility and the required release. A launcher downloads and verifies changed client/art packs, stages them, switches versions and relaunches with the same profile and endpoint. Include visible progress, interrupted-download recovery and a retained previous installation. Required updates block joining. Signed release manifests and verified hashes are part of the design, not implemented claims.

06 already separates its world art into Longwalk-Art-01.pck. Later split shared assets, regions, interiors and styles into independently updated packs. New content can ship without client code changes when its behavior is already supported. Streaming nearby regions is later scope.

## Release and Kubernetes

Scott wants Docker/Kubernetes deployment through Argo CD. A real release needs versioned matching client/server artifacts, immutable image publication, upgrade/rollback evidence and deployment-repo manifests pinned to the image. A plain source backup commit is not a release.

Begin with one simulation worker, then prove two adjacent regions on different workers with seamless player transfer and crash recovery. Adding replicas of the current world writer is not horizontal world scaling.

## Long-term world model

One persistent world distributed horizontally, not independent copies of the same world. Region services own local simulation and changes; a character directory knows the controlling region; inventory authority owns item/container transfers; a coordinator assigns region workers. Ownership versions and recoverable handoffs prevent duplicate writers and duplicate characters.

PostgreSQL plus versioned object storage is a proposed persistence direction, not implemented or a selected lab deployment. Separate logical authorities first; dedicated databases per service/region can follow measurements. Read caches and regional in-memory state reduce database traffic. Durable item transactions and bounded-loss movement checkpoints need explicit recovery guarantees.

## Later play and art

Improve close-view people, poses, furnishings and the balance of 3D depth with the Two Rivers concept-art feel. Broaden enterable buildings and useful ordinary activities. Doors, locks, climbing and swimming become explicit contextual actions. Develop equipment discovery and growing inventory/interface bars. Expand ecology and paths worn by repeated travel. The in-world god/mod role can gain additional carefully permissioned actions; smiting/combat and unrestricted editing are not part of 07.
