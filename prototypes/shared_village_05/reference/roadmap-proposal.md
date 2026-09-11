# Play roadmap, proposal

Knowledge work, 2026-09-09. This supplements the current roadmap for discussion. The village prototype is approved; later milestones below are proposed, with server work conditional on Scott's acceptance of the village. It does not authorize infrastructure deployment or change protected project documents.

| Next playable proof | What the player should experience | Evidence before expanding |
| --- | --- | --- |
| Rural village prototype, approved now | Explore a larger authored landscape with square, inn, hall, market, houses, farms and water crossing. Pan with WASD, rotate with Q/E, zoom with minus/equals, shift-click to run. | Run the packaged game, inspect multiple camera angles, walk and run routes through the settlement and outlying farms. Scott accepts the feel. |
| Shared world connection, conditional next | Two clients occupy the same village and see each other move. Disconnecting and reconnecting recovers the agreed state. | Server owns positions and movement decisions; both clients agree. Run the server headless in Docker and show a working client connection. |
| A persistent mark | One player changes a resource, the other sees it, and it remains changed after a server restart. | One narrow action, such as cutting a tree, survives restart. Baseline map, world changes, and character records stay distinct. Demonstrate restore as well as save. |
| Ordinary work becomes play | Collect material with a tool, improve one useful skill, and see a citizen keep a simple routine and interact at a shop. | A short repeatable session has a visible result. NPC schedules run on simulation ticks, independent of the camera. |
| Running and physical capability | Practice changes running speed and stamina efficiency; constitution affects stamina. | The player can understand why they tire and recover. Walk remains useful. Attribute and skill effects are visible in the interface. |
| A small living ecosystem | Harvested plants recover; one animal population feeds, moves and reproduces. | A bounded area changes over time without scripted spawn replacement. Measure population and server cost before increasing species or territory. |
| Memory and community | A citizen recognizes a repeated visitor or remembers an actual event. Information can travel between people. | Remembered facts trace to simulation events. Any AI interpretation cannot invent authoritative inventory, damage, or history. |
| Longer lives and wider regions | Explore family continuity, local economies, more settlements, and travel. | Choose lifespan, inheritance, loss and recovery rules through small play experiments before making them permanent. |

## Scale and operations

Scott approved a 1024 by 1024 metre playable area for the current village, approximately one square kilometre (1.048576 square kilometres exactly). Treat that landscape boundary, simulated population, and concurrent players as separate budgets. A large landscape does not demonstrate a large living simulation. The old chat's 10 km by 10 km request established the desired sense of countryside, not an obligation to process 100 square kilometres at full detail immediately.

The next server proof should reuse the accepted authored village and begin with two clients and one authoritative world process. Keep region identifiers and the simulation/rendering separation, so a later region split has a defined boundary. Decide sharding, database availability, messaging, and handoff from measured load and recovery needs. Kubernetes is the deployment target, not a reason to require a distributed cluster for the first playable connection.

Current architecture places persistence after the starter town and server evolution around ecology. Bringing the server connection earlier is a proposed sequencing change requested for discussion in this session. Adopt it explicitly after village acceptance; do not silently rewrite the current architecture or implement the whole persistence system during this art pass.

## Follow-ups already requested

- Remappable controls in the GUI, saved preferences, conflict handling, and reset to working defaults. Preserve the existing keyboard controls in the next build.
- A dedicated character appearance and movement pass. People remain provisional even if village art is accepted.
- A reusable terrain palette and a modest building kit, tested against the rotating camera. Add variation where the scene exposes repetition.

## Deliberately unresolved

Population targets and simulation detail need to match the approved 1024 by 1024 metre village build and its measured performance. Skill formulas, stamina balance, calendar speed, death and succession, destruction permissions, offline progress, and region handoff are future decisions. No additional feature is implied by listing it here.

Sources: [foundation supplement](foundation-supplement.md), the repository's `ROADMAP.md` and `ARCHITECTURE.md`, and Scott's current request for the larger village, conditional client/server work, and running skill.

## Pathfinding addendum from the village playtest

Scott wants players and NPCs to generally follow roads and paths while allowing deliberate shortcuts. The next comfort/layout pass should use weighted route costs, real gates and obstacles, plus an explicit player route preference with a preview. Shift-click remains a pace command, independent of road preference. NPC task routes may deliberately leave roads to reach work sites.

Future repeated footfall from players, NPCs and animals may wear paths and game trails into the landscape, with unused ground recovering. Actual traversal, not route requests or rendered frames, drives wear in the simulation. This remains future terrain-change and persistence work, not part of the first road-preference pass.
