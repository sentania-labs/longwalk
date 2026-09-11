# Workshop 05

World-first UI C plus one complete, persistent workshop commission. Client and server must both use protocol 05. The running 04 world is not changed by this build.

## Playtest

Extract the Windows ZIP and run the EXE. No parameters. Open the small interface dropdown, choose Connection / world, and connect to the server host on UDP 7777. Existing local traveler profiles are retained.

Open Journal and choose Walk to workshop door, then Enter workshop when you arrive. Inside, use right-click actions or the Journal's walk/action buttons:

1. Collect your six-piece wood bundle.
2. Take the axe from the tool rack. A hand equipment slot appears.
3. Equip the axe through Inventory or quick slot 3.
4. Walk to the workbench and prepare the wood.
5. Exchange it with the carpenter. Receive five coins, a Woodcraft completion and a copper ring. A finger slot appears.
6. Equip the ring, then use the exit. Reconnect and inspect your equipment and progress.

The commission is once per character. Bundles are reserved for each participant; the visible pile is not a shared depletion system. Taking or trading twice cannot duplicate items or rewards. Multiple travelers share the same interior and avoid each other. The carpenter is stationary in this first loop.

## Interface

One upper-left location/time callout, no persistent branding, and a small dropdown for Character, Inventory, Skills, Journal, Map / travel, Camera / controls and Connection / world. The bottom-left status shows health and stamina; four quick slots sit at the bottom right. Character equipment categories appear as discovered. Body/feet describe starter clothing; hand/finger are functional equipment slots.

Left-click walks and Shift-click runs; these shortcuts can be disabled in Camera / controls. Right-click opens context actions; right-drag still rotates. A brief destination marker replaces the long route line. Route visualization remains an optional saved preference, off by default. Escape closes a panel before leaving the game.

Inventory can assign owned items to the four quick slots. Keys 1 through 4 use them. Bread restores 25 stamina when needed; a potion restores 30 health when needed. Full bars do not consume an item. Equipping a tool or ring does not remove it from inventory. New discoveries fill an empty quick slot without replacing a chosen assignment.

Running drains stamina; walking recovers it slowly. No combat damage, hunger or magical ring effects yet. Slot-count growth and broader skill progression remain future work. The location label follows server time, but scene lighting remains daylight in this art pass.

## Persistence and upgrade

The server owns movement, area transitions, inventory, equipment, ready-slot assignments and rewards. Successful item/commission actions commit before acknowledgment. Personal character details go only to that character's client. An old or mismatched protocol is rejected before registration.

04 save records load and upgrade to schema 2 while retaining identities, outdoor positions, ownership and harvested tree state. Existing 04 backups are supported on restore. Keep the same Compose project and named volume. Back up the stopped world before upgrading. Rolling back to 04 requires restoring that pre-upgrade backup, since 04 cannot interpret indoor locations or schema 2.

Server image: longwalk-shared-village:05. Load the bundled TAR, then use the provided Compose file. Fresh installs may use `docker compose up -d`; upgrades must retain their existing project name. Kubernetes manifests are included but undeployed. The world baseline itself is unchanged.

Existing prototype limits remain: private LAN with unencrypted transport, first registered traveler becomes owner, one volume writer, immutable full-state records without pruning and same-volume backups. Monitor disk usage and keep external copies for volume-loss recovery.

## Validation

Evidence accompanies the packages. Tests cover commission completion, range checks, duplicate reward prevention, equipment discovery, item use, old-save migration and storage round-trips. The packaged Linux client walked to the door and completed the full commission against Docker, reconnected with its equipment and progress, and rendered the shared interior with Character open. Windows export is packaged for Scott's playtest.

Software under the explicit isolated-prototype SDLC exception. No main-project architecture, registry, CI or live-world changes in the build pass. Interior furnishings are a first cut using existing art and simple geometry; no new art generation was needed.
