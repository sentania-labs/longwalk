# Shared Village 03 (client 03a)

Local prototype following Scott's explicit go in AUTHORIZATION.md. The approved server sequence is implemented in this separate project; earlier village builds are retained. No main-project architecture, engine, CI, registry or live-lab deployment changes.

Client 03a fixes the placement-baseline startup failure reported on Windows. The server package and saved world remain compatible. See reference/client-03a-fix.md for evidence and remaining Windows verification.

## Run tonight

Windows client: extract Longwalk-Shared-Village-03a-Windows.zip and run its EXE.
Server: extract Longwalk-Shared-Village-03-Server.zip, then from that folder:

```sh
docker load -i longwalk-shared-village-03.tar
docker compose up -d
```

Connect to the server host's address in the client. Default is 127.0.0.1, UDP 7777. To test twice on one machine, launch two clients and select different traveler profiles. The first registered traveler is the world owner. This bootstrap and unencrypted ENet transport are for a private LAN prototype, not internet accounts. Keep the owner's local profile data to retain administration access.

The server container contains the world data and headless Godot runtime, not the art assets. Client art stays local. Client 03a loads frozen visual transforms rather than recomputing placements at startup. A versioned baseline with baked collision footprints and stable placement IDs is shared by both. A mismatched client baseline is rejected. No client-supplied positions are accepted: the server computes routes and advances movement.

## First persistent action

Use View square oak, Walk to square oak, then Harvest when nearby. Both clients see the tree disappear. The server validates interaction range and commits the change before acknowledging it. Repeated harvest requests cannot cut the same tree twice. This is a narrow resource-state proof, not an inventory or crafting system.

The owner has pause/resume, position checkpoint interval, player limit, backup and restore controls. Create a backup before harvesting to compare states. Restore requires the world to be paused and preserves the displaced state as another backup. Restoring keeps the world paused. Existing identities and owner access are retained; known character positions and world facts restore from the backup.

Disconnect stops new commands. Retry uses the same local credential/profile and replaces stale client state. A server restart may roll position back by the configured checkpoint interval, but acknowledged tree changes survive process restart. Tests include an abrupt process kill. No power-loss or storage-volume-loss guarantee is claimed.

## Storage and operation

The mounted /data directory holds immutable numbered full-state records, each with schema, baseline version and a checksum. A new record is flushed, closed, read back, validated and renamed from a pending file before it becomes a committed record. Pending files never supersede committed records. Backups are separate records. This deliberately small append-only journal has no automatic pruning yet; monitor volume usage.

A corrupt latest record does not silently create an empty world. If an earlier valid record establishes an owner identity, the server enters frozen owner-only recovery mode so that owner can restore a valid backup. With no valid identity-bearing recovery record, startup stops and reports an error. Storage failure during play freezes world actions. Backups on the same volume are not protection against loss of that volume; copy them elsewhere for that recovery objective.

Exactly one process owns a volume, enforced by an OS file lock in the container entrypoint. Restart downtime is expected. Docker health checks and Kubernetes probes track a fresh serving heartbeat. Serving includes authenticated recovery mode; the client displays storage errors and paused state separately. Health does not claim that the world is writable.

Kubernetes manifests are included as packaging only, with one replica, Recreate strategy, one PVC and a private UDP ClusterIP service. Load the bundled image into the development cluster before use. Storage class and access from Windows clients depend on the lab deployment; no DNS, route or cluster changes are performed here.

## Camera and interaction direction

Inspection flies through scenery independently of character collision. WASD follows the view direction; Page Up/Page Down changes height. Tab returns overhead and Space returns to the traveler. The camera stays above the terrain floor and within the prototype region.

Contextual right-click actions are the agreed next interaction UI: Walk here, Run here, inspect an object, and state-dependent actions such as Open, Unlock or Pick lock. Jumping, climbing, swimming and forcing doors remain explicit choices for future capabilities. An ordinary movement request does not choose a dangerous or destructive action. This slice retains existing movement controls and a dedicated harvest button.

## Evidence and limitations

Artifacts include runtime logs and client screenshots. Storage tests cover partial writes, corrupt records, incompatible baselines and unavailable storage. Two-client tests cover authoritative movement, shared harvest, owner identity after abrupt restart, backup restore and non-owner administration denial. The actual packaged Linux client was run against the final Docker image and visually inspected with two travelers. Its free-flight check crossed a barn without moving the traveler. Windows requires Scott's playtest.

No interiors, inventory, skills, fauna, trail wear, installer or asset patcher. The first scene still loads the village art up front. Control/UI refinement and the app icon remain follow-ups.

Implementation references: [Godot 4.3 high-level networking](https://docs.godotengine.org/en/4.3/tutorials/networking/high_level_multiplayer.html), [ENet peer timeouts](https://docs.godotengine.org/en/4.3/classes/class_enetpacketpeer.html#class-enetpacketpeer-method-set-timeout), [FileAccess](https://docs.godotengine.org/en/4.3/classes/class_fileaccess.html).
