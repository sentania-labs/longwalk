# Shared village first cut, proposed

Design only, 2026-09-10. After Scott accepts the village, prove two clients sharing one authoritative world and one change surviving restart. This proposes bringing server connection and a narrow persistence slice ahead of the older ecology milestone. Adoption of that sequencing and architecture needs Scott's explicit go. Nothing here implements or deploys a server.

## Runnable shape

One headless Godot world process in one Docker container owns the accepted 1024 by 1024 metre map. Two Godot clients send intentions and display results. One mounted data directory holds mutable state; the container image supplies the versioned authored baseline. A Docker launch definition ships with working defaults and a matching Windows client. No new database or messaging dependency is proposed for this cut.

The client opens a connection screen with address and port, a working localhost default, remembered last server, Connect, Retry, and clear connection status. A lab address is entered once through that screen. A private server administration screen exposes every configurable world setting with defaults, including save interval, connection limit and diagnostics. Bind/listen changes require a visible restart action. These screens must work in the package, without editing JSON or populating database rows.

First-cut scope is a private two-client lab session. Automatically issued local player credentials reconnect to the same server-side character; a display name alone cannot claim another character. Public accounts and internet hosting remain outside this milestone.

## Ownership and integration

The server validates walk/run destinations, computes routes, advances movement, checks interaction range, and owns the one resource change. Clients cannot submit final positions or declare a tree removed. State messages carry a world version and monotonically increasing revision. Each action has an identity so retries cannot apply it twice. Start with authoritative updates and client visual interpolation; add prediction only if measured latency makes walking unpleasant.

The prototype currently builds navigation footprints from rendered model bounds in `village.gd`, and advances its traveler there. Before networking, bake those footprints and stable placed-object IDs into the authored map data, then move route execution into the headless simulation. Rendering must consume that data rather than serve as the server's collision source. Existing `src/sim/town_layout.gd` demonstrates data-owned footprints, but its older 2D town is not interchangeable with this metre-based village.

## Persistence and recovery contract

| State | First-cut owner and storage |
| --- | --- |
| Baseline | Immutable map version, placements, stable tree IDs and navigation data shipped with server/client. Reject a mismatched client baseline. |
| Deltas | One tree's changed state, identified against that baseline. No entry means the original tree remains. |
| Entities | Stable character identity and saved position, separate from cells and resource changes. No full inventory or skill system required. |

Use versioned snapshots and an ordered mutation journal on the mounted volume. Persist an accepted tree change before acknowledging success; replay must not duplicate it. Write checkpoints without replacing the last valid recovery point until the new one validates. Test abrupt process death, incomplete writes and unavailable storage before promising durability. Saved movement has an explicit checkpoint interval shown in administration; a crash may roll position back to that checkpoint. Acknowledged tree changes must survive process restart.

On disconnect, the client stops accepting world actions and shows its state as disconnected. Reconnect replaces stale local state with a fresh server snapshot; it does not replay old clicks. The server stops a disconnected character after its session timeout. A restarted server loads and validates saved state before accepting players. Corrupt or incompatible saves produce a recovery error, never a silently empty world.

Provide an administration backup action and a recovery-mode restore screen. For the first cut, pause writes while making a consistent backup. Restore only while world writes are stopped, preserve the displaced state, and require a compatible baseline. A backup on the same volume handles accidental state changes, not loss of that volume; copy it elsewhere before claiming storage-loss recovery.

## Acceptance and scale boundary

Demonstrate both clients seeing movement and the same tree change, reconnect without duplicate characters or actions, abrupt server restart with the change intact, and restoration of an earlier backup that both clients then see. Run this through the packaged clients against the actual Docker artifact. Logs and administration show connected clients, tick delay, last saved revision and save failures.

Exactly one process may write this world. It has downtime on restart and no automatic failover. Later Kubernetes packaging should preserve one writer and persistent storage, with readiness gated on successful load. Replicas are not extra capacity for the same mutable world. Sustained tick delay may justify region ownership; measured distribution needs may justify messaging; storage throughput or recovery objectives may justify a transactional database and availability design. Those are separate demonstrated pressures, not prerequisites for two players.

Sources reviewed: `ARCHITECTURE.md` sections 3 and 5; `ROADMAP.md`; `src/sim/game_state.gd`; `src/sim/town_layout.gd`; `src/render/town/player_controller_2d.gd`; prototype `village.gd` and `src/sim/landscape.gd`. Transport, precise timing defaults, credential handling and on-disk format remain implementation decisions to review when this milestone is authorized.
