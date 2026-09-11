# Shared Village 04

Contextual actions and server-owned player avoidance, following the completed Windows playtest of 03a. The world baseline, saves and local traveler profiles remain compatible. Protocol 04 requires the matching client and server; old baseline-only handshakes are rejected with a version message before registration.

## Play

Extract the Windows ZIP and launch its EXE. Connect to the server address and UDP port shown in the connection panel (7777 by default). Run two clients using different traveler profiles. The project retains the 03 userdata directory so identities carry forward.

Right-click briefly on ground or scenery to open actions. Walk here and Run here request server movement. Inspect describes ground, buildings, firewood and the square oak. The oak offers Harvest only within range and while the world is running; after harvest it shows Already harvested. Click outside or press Escape to close the menu. Right-drag still controls the camera. Left-click and Shift-click remain movement shortcuts. The connection/owner panel can now be collapsed.

Other connected travelers obstruct movement. The server plans around their positions and replans when a traveler enters an existing route. If passage is blocked, a traveler waits rather than passing through someone. A newly requested occupied or unreachable destination is rejected. Offline saved characters do not block the map. This is modest local avoidance, not a crowd or queue simulation; tightly blocked passages may need someone to move. Route preview shows static terrain routing; the server may detour around travelers.

No interiors, functioning doors, lock picking, inventory or material collection beyond the existing tree-state proof. Inspecting firewood does not put it in inventory. No fictional locked-door actions are presented on scenery without door state.

## Server and compatibility

Load the bundled image with `docker load -i longwalk-shared-village-04.tar`. The included Compose file uses image longwalk-shared-village:04 and the existing /data layout. For an existing deployment, keep its Compose project name and named volume. Creating a different project creates a different world. Back up the existing volume before upgrading. The protocol change requires both sides to use 04, but no world-data migration or reset is required.

The handshake checks the world-baseline digest plus the explicit shared-village-04 protocol identifier, then validates the traveler credential. It is a compatibility check, not a security signature or internet account service. Existing private-LAN, first-owner and storage limits still apply. Storage remains append-only full snapshots; monitor disk usage. Included Kubernetes YAML is undeployed packaging.

## Verification

Headless checks exercise stationary detours, opposing travelers, an obstruction entering a route, offline characters, contextual action availability and old-protocol rejection against Docker. Packaged Linux clients exercise shared harvest and restore against a separate Docker test world. The rendered packaged client is checked with the contextual oak menu open. Windows still needs Scott's playtest for this build.

Software under Scott's standing isolated-prototype exception to full SDLC/CI. No main-project changes or automatic live-server replacement.
