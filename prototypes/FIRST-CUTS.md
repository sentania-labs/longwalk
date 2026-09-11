# Longwalk first cuts

[Working Day 06 report and downloads](http://172.16.3.13:4387/session/7283efae94aedb81), or [offline report](Longwalk-Working-Day-06.html).

Latest: [Working Day 06 Windows](shared_village_06/artifacts/Longwalk-Shared-Village-06-Windows.zip), [server bundle](shared_village_06/artifacts/Longwalk-Shared-Village-06-Server.zip), and [run instructions](shared_village_06/README.md). Connect client 06 to 172.16.3.13 UDP 7778 with your existing traveler profile. This is a separate verified copy of the saved 05 world; 05 remains on 7777. Repeat work, Running/Observation skills, a daily provisioner, nighttime meadow fauna and movable character interfaces. Windows playtesting remains needed.

Prepared: [Workshop 05 Windows](shared_village_05/artifacts/Longwalk-Shared-Village-05-Windows.zip) and [05 server](shared_village_05/artifacts/Longwalk-Shared-Village-05-Server.zip). World-first UI, shared interior, inventory/equipment and one persistent commission. Both ends require 05. Live server upgraded to 05 with authorization and a verified stopped-world backup; existing world and characters retained.

Prepared: [Shared Village 04 Windows](shared_village_04/artifacts/Longwalk-Shared-Village-04-Windows.zip) and [04 server](shared_village_04/artifacts/Longwalk-Shared-Village-04-Server.zip). Both sides must upgrade together. Context actions, player avoidance and explicit protocol matching. The running server was upgraded to 04 with Scott's authorization, retaining the existing world.

Earlier: [Shared Village 03a Windows](shared_village/artifacts/Longwalk-Shared-Village-03a-Windows.zip) and [Docker server package](shared_village/artifacts/Longwalk-Shared-Village-03-Server.zip). Two travelers, server-owned movement, one persistent tree, backup/restore and free inspection flight. See [run instructions](shared_village/README.md).

Previous playtest: [Two Rivers Comfort 02 for Windows](two_rivers_comfort/artifacts/Longwalk-Two-Rivers-Comfort-02-Windows.zip). Continuous rotation, ground-level inspection, farm gates, road preference/direct shortcuts and saved control settings. Original builds below remain available.

Start with the [visual comparison page](character_comparison/artifacts/Longwalk-First-Cuts.html), a self-contained HTML file with switchable camera views. Its olive/cream palette follows the playable prototypes. Then try the village and character viewer.

| Windows package | What to try |
| --- | --- |
| [Two Rivers](two_rivers/artifacts/Longwalk-Two-Rivers-Windows.zip) | Explore the 1024x1024m village region. Shift-click to run; WASD, Q/E, minus/equals control the camera. |
| [Character comparison](character_comparison/artifacts/Longwalk-Character-Comparison-Windows.zip) | Current 3D person versus a four-facing classic sprite, normal/close/low views. |
| [Building kit](building_kit/artifacts/Longwalk-Building-Kit-Windows.zip) | Three layouts, two roof materials, roof cutaway. |
| [Citizen routine](npc_routine/artifacts/Longwalk-NPC-Routine-Windows.zip) | A separate schedule diagram with pause/reset/speed controls, not village-integrated NPCs. |

Extract each ZIP and run its EXE. Matching Linux builds were run and visually checked. Windows packages exported successfully but still need a Windows playtest here. Checksums are in FIRST-CUTS-SHA256SUMS.txt.

The character comparison is idle-only. Two generated walk sheets remain as source drafts, excluded after visual review. The building kit is a simpler construction study than the accepted village landmarks. The current village person and foliage remain provisional.

The shared-chat review is in [foundation supplement](two_rivers/reference/foundation-supplement.md), [play roadmap](two_rivers/reference/roadmap-proposal.md), and [server/client first-cut design](two_rivers/reference/server-client-first-cut.md). These supplement the existing foundation without changing the protected architecture. The subsequent positive verdict authorized Shared Village 03.

Software work stayed in local standalone prototypes under the explicit prototype exception. No commits, PRs or live-lab deployments. Shared Village 03 adds the isolated server/persistence proof. Existing prototypes and builds are preserved. New village Meshy generation used 240 credits; character sprites and the building-kit material sheet used built-in image generation.
