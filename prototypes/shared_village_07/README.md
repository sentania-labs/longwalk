# Working Day 06

A shared workshop, repeat work outside, a provisioner with a daily routine, and usable character interfaces. Both client and server require protocol 06. An actual 05 client is rejected by the changed RPC layout before the friendly version message, so upgrade both ends together. The existing live 05 world is retained separately.

Extract the Windows ZIP and launch the EXE. The join screen shows the selected server, traveler profile and build. Choose Connection settings to edit them. Scott's separate sprint playtest is at 172.16.3.13 UDP 7778, using a verified copy of the 05 save. The original 05 remains at UDP 7777; later progress in the two worlds is independent. No launch parameters are needed. Open Journal for the work loop, Inventory for items, Skills for practice, and Activity for recent saved-action receipts.

## Reusable art and client updates

The complete Windows ZIP contains an EXE and Longwalk-Art-01.pck. Keep them together for the default launch. Later client-only updates can reuse the matching art pack; no asset download service is required. Startup checks the embedded manifest and file checksum. Missing or mismatched art opens a file chooser and Quit, and selecting a verified pack in another folder repairs the launch. Connection / world also exposes the art location. This uses [Godot resource packs](https://docs.godotengine.org/en/4.3/tutorials/export/exporting_pcks.html).

The local build script, tools/build_playtest.py, runs the headless checks, caches art by its source fingerprint, exports both clients, and optionally bundles the Docker world with --server. Packaged runtime checks remain a separate acceptance step. tools/package_server.py can refresh deployment docs and evidence while verifying that the tested image archive is unchanged.

## What works

- Character names are editable and persist on the server. Nearby remote traveler names can be shown or hidden in Camera / controls.
- Inventory and quick slots use item icons; right-click a slot to inspect or clear it. Drag interface title bars to move them. Close buttons and Escape dismiss panels. Positions are remembered; Camera / controls includes Reset window positions.
- The first commission supplies a free axe that you keep. Collect six wood, equip the axe, prepare the wood, then deliver it for five coins, a copper ring and Woodcraft practice. Prepared wood is a distinct item.
- After the first commission, accept another order from the carpenter. Gather two lots of fallen branches outside, prepare six wood at the bench, and return them for three coins and practice. Shared woodfall piles recover after three minutes of running world time. Right-click or use Journal to find and interact with them.
- The provisioner walks between home at night, the west farm in the morning, and the market from 11:00 until 20:00. At the market, buy bread for one coin. Map / travel locates the citizen. Players and the citizen avoid one another.
- Running practice comes from distance actually traveled. Each level grants a small speed and stamina-efficiency improvement, capped at ten levels. Constitution currently stays at ten and gives a stamina capacity of 100. Exhaustion switches the remaining journey to walking until you request another run. Walking recovers stamina; bread restores 25 when needed. Study the wood bundle nearby to discover Reading the Grain once.
- A small fictional lantern-moth colony feeds in the south meadow after sunset, reproduces within a population limit and roosts by day. Age and feeding follow the configured day length. It persists independently of camera visibility. Watching a moth nearby discovers Watching the Small Hours once; Journal points to the meadow.
- Daylight follows server time. Owners can set the hour and full-day duration in Connection / world. The default day lasts 144 real minutes. Pausing stops time, routines and resource recovery.
- Personal inventory and equipment remain server-owned and private to that client. Four assignable quick slots support bread, potions and equipment. Route lines remain off by default; left-click walking and Shift-click running remain optional shortcuts.

The window icon is a provisional winding-path mark. Windows Explorer resource branding is still a later packaging detail. Human models and interior furnishings remain provisional; this slice normalizes lighting across local, remote and NPC characters.

## Operations

The Docker world has one writer lock. A second container using its volume exits instead of opening another writer. Normal container shutdown asks the world to commit before exiting; a forced kill can lose movement since the last checkpoint. Acknowledged item exchanges have already committed. World owner settings, pause, backup and restore remain in the game GUI, with timing and packet-size diagnostics. Destination requests coalesce per player and route solving is spread between network updates. Collision replans have a shared frame budget; small fixed simulation steps catch up ordinary planning delay. Long-range bursts are still a performance limit, not an MMO capacity claim.

The Kubernetes package uses one replica, Recreate, a persistent volume, a private UDP service, startup/heartbeat probes and a thirty-second stop grace period. It was exercised in an isolated local kind cluster, including the workshop loop and deployment restart. The lab cluster and public DNS were not changed. Heartbeat readiness means the process is serving, including owner-only recovery mode; the in-game status reports whether play is frozen by storage failure.

## Saves and recovery

Schema 3 loads 04 and 05 saves. Existing identities, equipment, coins and world marks are retained. A 05 character midway through preparation receives six prepared wood in place of the six raw wood already marked prepared. Earlier work contributes initial Woodcraft practice. Keep the same volume when upgrading, after taking a stopped-world backup. Rollback to an older server requires its matching pre-upgrade backup.

Records and backups are immutable full snapshots on the world volume. There is no automatic pruning or database failover. Copy backups outside that volume for volume-loss recovery and monitor storage growth. The world advances while the server runs, including when no players are online; downtime does not fast-forward it. Recovery and restore retain the owner and existing identities.

## Evidence and limits

Headless rules tests, a full network work day, sixteen concurrent clients, packet-size checks, actual rendered day/night interfaces, packaged Linux commission/reconnect/crash recovery, backup/restore and isolated Kubernetes execution were exercised. Evidence is bundled with the server artifact. Windows is exported for Scott's playtest, not executed here. Godot 4.3 can emit a nonfatal RPC-cache signal warning during reconnect; the final reconnect checks record behavior separately from log cleanliness.

This remains a private LAN prototype with unencrypted transport, local bearer profiles and a temporary world owner. It is a single village simulation, not a sharded MMO. No main-project architecture, CI, registry or lab deployment changed. Software under Scott's explicit local prototype SDLC/CI waiver; see AUTHORIZATION.md.
