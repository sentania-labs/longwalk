# Longwalk session handoff

Saved 2026-09-10 for Scott's move to another tmux session.

## Working Day 06 sprint

Report and downloads: http://172.16.3.13:4387/session/7283efae94aedb81. Use the IP here: this host resolves worker.int.sentania.net to loopback while Lavish listens on its LAN address.

Scott authorized a three-hour autonomous prototype sprint; exact words and scope are in `shared_village_06/AUTHORIZATION.md`. Work stayed in the isolated prototype under the existing local SDLC/CI waiver. No commits, PRs, registry publishing, lab deployment or protected architecture edits.

Current 06 source and packages: `prototypes/shared_village_06/`. Build `b66cb8e51e26`, protocol `shared-village-06`, save schema 3. The Windows full ZIP includes the EXE and reusable `Longwalk-Art-01.pck`; the client-only ZIP needs that matching pack retained. Missing or wrong art opens a repair chooser. Windows still needs Scott's playtest; the actual Linux package completed the commission, repeat work and rendered interfaces.

The separate 06 playtest is `172.16.3.13` UDP `7778`, container `longwalk-sprint06-world-1`, Compose project `longwalk-sprint06`, volume `longwalk-sprint06_world-data`. It was populated from a verified read-only copy of 05: `/home/scott/.local/state/longwalk/backups/sprint06-source-20260910T234607Z`. All three migrated character records, their goods/progress, owner, harvested tree and resumed state matched exactly. The original 05 remains on UDP 7777 with `longwalk-playtest_world-data`. These are independent worlds after the copy. Use the matching client; an actual 05 client fails at the changed RPC layout before the friendly 06 version message.

Added: movable/closable panels, per-window saved placement, item icons and quick-slot context menus, character names, a join screen and build identifiers. First-commission messaging makes clear the free axe stays with the player and prepared wood earns the reward. Running practice follows distance, improves speed/efficiency and stops sprinting on exhaustion. Wood-grain and nocturnal-moth observations are one-time discoveries. Repeat carpenter orders use shared recovering woodfalls; a provisioner walks home/farm/market and sells bread. Daylight follows server time. A bounded moth population feeds, seeks mates, reproduces, ages and roosts independently of clients.

Operational additions: graceful final checkpoints, single-writer lock, reliable character facts plus compact replaceable motion, GUI timing diagnostics, bounded destination requests and collision replans, fixed-step catch-up, and tested single-writer Kubernetes packaging. A local kind cluster ran the actual image and retained commission goods after replacement. Thirty simulated ecology days stayed at 6 to 12 moths across supported day lengths. Damaged-save owner recovery, pause/restore/resume, and immutable snapshot validation passed.

The final sixteen-client test passed 45 minutes through a graceful restart and forced kill/restart, retaining identity and inventory with no unplanned reconnects. Observed worst tick was 3.47 seconds during long-route bursts. Temporary test containers and the kind node are stopped; their data is retained. Sustained-test result and final artifact report are finalized in `shared_village_06/artifacts/evidence/ACCEPTANCE.md` and `.lavish/longwalk-working-day-06/index.html`. Ongoing checkpoint notes are in `shared_village_06/SPRINT-STATE.md`; do not treat its earlier candidates as the delivered build. Long-distance route bursts remain a performance limit. Godot 4.3 can emit a nonfatal RPC-cache cleanup warning on reconnect. Fixed four-slot capacity, broader equipment/skills, close-view character art, snapshot retention, stable cross-version handshake and MMO distribution remain follow-ups.

The 05 and earlier notes below are historical context.

## Workshop 05 live

Scott selected UI C: the world is the main character, no permanent branding, one location/time callout, discoverable equipment and four starting quick slots. Accepted retained left-click walk / Shift-click run and optional route visualization off by default. Authorization: "okay let's progress".

Source: `prototypes/shared_village_05/`. Windows and server ZIPs are in its artifacts directory. This build implements the first shared interior and persistent commission: walk to the west workshop, enter, collect your bundle/tool, equip axe, prepare wood, exchange with carpenter, receive coins and a ring, discover/equip finger slot, exit and reconnect. The dropdown exposes Character, Inventory, Skills, Journal, Map / travel, Camera / controls and Connection / world. Journal has walk/action buttons for the loop. Food, potion and four assignable quick slots are server-owned. New item types fill empty quick slots only.

Both ends require protocol 05. 04 save schema 1 upgrades to schema 2 while retaining identity and world facts; 04 backups can restore into 05. Rollback to 04 requires the stopped pre-upgrade backup because 04 rejects schema 2. Userdata project name remains unchanged for existing profiles. Do not reset the live volume.

Packaged Linux tests passed the full walk-in loop, reconnect, abrupt-restart retention, return outside, protocol rejection and rendered interior/Character/right-click UI. Two participants each have one commission reward. Save migration and duplicate prevention tests passed. Preview: shared_village_05/artifacts/Workshop-05-preview.png. Windows still needs Scott's playtest. Furnishings are provisional reused art/simple geometry, not a polished interior kit. Slot-count progression, combat damage, ring buffs and broader skills remain future work.

Live service is now 05 at 172.16.3.13 UDP 7777, project longwalk-playtest, volume longwalk-playtest_world-data. Scott authorized "go for it" after the upgrade question. Stopped-volume backup: `/home/scott/.local/state/longwalk/backups/before-05-20260910T213815Z`. Backup checksums, actual save migration, retained volume files, healthy startup and live 05 handshake passed. Three characters, harvested tree and resumed state retained. Migration persists on the next normal save. Use the 05 Windows client with existing profiles. Details: shared_village_05/reference/upgrade-authorization.md. Older deployment notes below are historical and superseded.

## UI mockups awaiting direction

Scott completed all six 04 Windows checks, then authorized the interior/inventory work loop with UI polish, asking for a few mockups first. Three interactive UI studies are at `.lavish/longwalk-ui-mockups/index.html`: compact top bar (recommended), classic RPG and minimal world-first dropdown. Portable export: `prototypes/Longwalk-UI-Mockups.html`. Lavish URL: http://172.16.3.13:4387/session/d87f64a1bbf620b6.

Mockups use a clean render of the actual village and existing olive/cream/brass styling. Food, potion, equipment and status interactions use clearly labeled sample state only. Browser checks confirmed food changes stamina, potion changes health, axe updates equipment, the minimal dropdown opens Skills, and all three layouts render. No live world, game source or server changed in this design pass. Wait for Scott's UI direction before implementing that layout. The interior/inventory loop remains the approved objective after design review.

## Live server switched to 04

Scott authorized: "switch the world over". Server longwalk-playtest-world-1 now runs longwalk-shared-village:04 at 172.16.3.13 UDP 7777 using the existing volume. Stopped-world backup and full state equality verified; live protocol check passed without creating a traveler. World remains resumed and tree harvested. See shared_village_04/reference/upgrade-authorization.md. The older deployment-pending notes below are superseded.

## Shared Village 04 update

Scott completed the 03a Windows checks: movement, shared harvest, owner/non-owner reconnect, server restart persistence, free inspection and backup/move/pause/restore/resume. Then said "the world is resumed. go ahead" for contextual actions and player avoidance.

Source: `prototypes/shared_village_04/`. Packages: its artifacts/Longwalk-Shared-Village-04-Windows.zip and Server.zip. Runtime frozen art remains unchanged. Right-click offers Walk/Run/Inspect plus state-dependent square-oak Harvest. No doors/interiors/inventory yet. Right-drag remains camera; left-click movement shortcuts remain. Server avoids connected players, replans moving obstacles and waits in blocked corridors. The connection panel now has a collapse toggle and GUI UDP port.

Explicit handshake protocol `shared-village-04` plus the unchanged baseline digest gates registration. 03/03a clients must upgrade together with the server. Local userdata project name stays `Longwalk - Shared Village 03` so traveler profiles carry over. World save schema/baseline are unchanged.

04 was tested on an isolated Docker server at localhost UDP 17778 with throwaway profiles and its own volume. Packaged Linux rendering/menu, shared harvest/restore, protocol rejection, avoidance and menu-state checks passed. Windows needs Scott's playtest. The live 03 server is still on port 7777 with Scott's world. Do not replace it until the container replacement is authorized; retain Compose project `longwalk-playtest` and volume `longwalk-playtest_world-data` when upgrading. Back up that volume first. No commits/PRs/deployments in the build pass.

## Client 03a update

Scott reported the Windows 03 startup guard: rendered placements did not match the authored baseline. Approved fix: "okay go". Client 03a loads frozen visual/model transforms from world/visuals.json and validates identities against the unchanged baseline. Replacement ZIP: shared_village/artifacts/Longwalk-Shared-Village-03a-Windows.zip. The original ZIP is retained but should not be recommended. Exact original Windows mismatch remains unresolved; the fragile runtime recomputation has been removed. See shared_village/reference/client-03a-fix.md.

The live local server is longwalk-playtest-world-1 at 172.16.3.13 UDP 7777, using longwalk-playtest_world-data. Do not replace it or reset its volume for this client fix.

## Resume here

Read `AGENTS.md`, this file, then `prototypes/APPROVED-NEXT-STEPS.md`. Shared Village 03 now implements the approved shared-world proof in `prototypes/shared_village/`. See its README for operation and recovery limits. Windows and Docker server ZIPs are in its artifacts directory. Comfort 02 and original Two Rivers are retained.

Latest authorization: "Go ahead with the next phase." Scott proposed contextual right-click actions (Walk here, Run here, Open door, Inspect), changing with object state and capability. Record this as the next interaction direction, implemented JIT. Ordinary movement never silently chooses break-in, jumping or swimming. This build retains click/shift-click and a dedicated harvest button.

Implemented: authoritative headless Docker world, two clients, persistent profile identity, server-owned routes, one persistent square oak, owner GUI settings, pause, backup and restore. Inspection now flies through obstacles without moving the character. Storage is an append-only snapshot journal with one volume writer. Kubernetes YAML is packaged but not deployed. No main-project architecture changes.

Recovery checks cover abrupt process restart, corrupt latest save, owner-only restore, non-owner administration denial and volume writer exclusion. A regression check verifies that disconnecting in recovery cannot commit fallback state. Windows still requires Scott's playtest. Evidence and review notes accompany the build.

Next: Scott's shared-world and remaining control/UI feedback, then scope one ordinary work loop with one interior, a tool, inventory and a citizen exchange. No automatic expansion into a complete RPG. No installer, external asset patcher, skills, fauna or contextual menu in this slice.

## Latest implemented build: Comfort 02

Resume authorization: "okay let's resume". Source: `prototypes/two_rivers_comfort/`. Windows: `prototypes/two_rivers_comfort/artifacts/Longwalk-Two-Rivers-Comfort-02-Windows.zip`. Original Two Rivers source/ZIP are preserved.

Implemented: continuous held Q/E; reversed minus/equals; Tab ground-level perspective inspection with look-up and collision; Space returns overhead to traveler; sky/ground continuation; roads around fields and shared visual/collision gate barriers; road-preferring routes and explicit direct shortcuts; route hover preview; saved GUI control preferences and key remapping with conflict detection.

Reusable `src/sim/travel_grid.gd` has no rendering/input dependencies. It supports any traveler; this pass does not integrate NPCs. No terrain wear, server, world persistence, stamina, interiors, inventory, new art or app-icon change. Bridge models are unchanged as directed.

Headless navigation checks passed. The actual packaged Linux binary ran from its build directory and passed scene/input/preferences checks; its barn-look-up and gate-route captures were visually inspected. Windows was exported and packaged but needs Scott's playtest. Logs, screenshots, ZIP checksum and START-HERE are in the new artifacts directory. Separate post-implementation review notes are in `reference/review-notes.md`.

The remaining sections retain earlier context; where they describe original Two Rivers behavior, Comfort 02 supersedes that behavior. No commit, PR, push or deployment was made.

## Workspace and boundaries

- Workspace: `/home/scott/codex/longwalk`.
- Current branch: `codex/rotating-camera-prototype`.
- Plain interactive session, no injected orchestrator or worker role. Do not act as either.
- Software prototypes are isolated under `prototypes/`, ignored by the main Godot project through `prototypes/.gdignore`. Scott explicitly waived the full SDLC/CI flow for local prototypes earlier. No commits, pushes, PRs or deployments were made in this work.
- Documentation is knowledge work. This handoff and plan are local files, not committed. Preserve them across the tmux move.
- The workspace has extensive pre-existing untracked state and a deleted `TEAM-STATE.md`. Do not clean, restore, stage or commit unrelated state. Do not edit orchestrator machinery.
- Respect the current finite-authored-map constitution and simulation/rendering separation. Planet scale remains an aspiration, not permission to silently reverse the documented pivot. Server timing in the approved plan moves earlier than the old roadmap; formal protected architecture changes still follow repository rules.
- Scott is an infrastructure admin. Be concise; no em dashes. Every configurable feature gets a GUI and working defaults. Design feedback is not a build order. No manual infrastructure remediation or public DNS changes.

## Approved sequence

Full detail: `prototypes/APPROVED-NEXT-STEPS.md`.

1. Camera/layout/pathfinding comfort pass: continuous held Q/E; minus zooms in, equals out; retain pan dial; experiment with close inspection and looking up while keeping camera above ground; handle horizon/underside; correct farm paths and gates; road-preferring routes with deliberate shortcuts.
2. Shared world proof: one authoritative headless Docker world, two clients, reconnect identity, one persistent resource change, abrupt restart and backup/restore. Single-writer Kubernetes packaging follows container proof. No distributed regions/message bus without measured need.
3. One ordinary work loop: enter one building, use a tool, gather a material, exchange it with a citizen, retain inventory/progress. Add a small character panel and useful skill feedback.
4. In accompanying small passes: stylized 3D art comparison at three viewing distances, app icon, build identity, GUI preferences and clear playtest packaging.
5. Future: footfall-worn paths/game trails and recovery, ecology, wider settlements, relationships and other RPG systems.

Approval covers the plan. Do not interpret it as permission for an unreviewed live lab deployment or an immediate full RPG implementation.

## Scott's playtest verdict and steering

- Overall village is a solid base; zoomed-out graphics look good; open farm views work from different angles.
- Current 3D character feel is preferred. Seek a gradual balance between dimensional 3D, the cartoonish Two Rivers map reference, and sprite-like readability/polish. Close views remain rough. Do not replace all art now.
- WASD initially felt slow, but Scott found the speed dial. No automatic speed increase requested.
- Q/E must rotate continuously while held, rather than 45-degree steps.
- Looking up near a barn door matters. Current orthographic orbit cannot provide this merely by lowering its elevation limit. Propose/test explicit close inspection, retaining normal overhead mode.
- Pan should feel camera-relative at close distances. Code already uses yaw-relative ground vectors; it moves the focus point, not a first-person traveler.
- Reverse minus/equals zoom. Keep Shift-click as run, independent of route choice.
- Roads currently cut through fields/fences. Reproduce and fix farm entrances, visual paths and collision together.
- Players and NPCs should generally follow roads/paths, with deliberate shortcuts allowed. Prefer roads via route costs, not mandatory rails. Hard obstacles still block direct routes. Later repeated actual footfall creates trails; unused trails can recover. That terrain-change simulation is future scope.
- Current bridges are acceptable for the prototype but read as city/large-town infrastructure. This is art direction only. Keep them unchanged here; study simpler rural crossings later. Materials/design not yet selected.
- Eventual priorities: entering buildings, inventory, character control panel, other RPG systems and app icon.

## Runnable artifacts already delivered

All paths are relative to the workspace. Extract Windows ZIP and run the included EXE.

- `prototypes/two_rivers/artifacts/Longwalk-Two-Rivers-Windows.zip`, 159.7 MiB.
- `prototypes/character_comparison/artifacts/Longwalk-Character-Comparison-Windows.zip`, 75.5 MiB.
- `prototypes/building_kit/artifacts/Longwalk-Building-Kit-Windows.zip`, 33.4 MiB.
- `prototypes/npc_routine/artifacts/Longwalk-NPC-Routine-Windows.zip`, 28.9 MiB.
- Launch index: `prototypes/FIRST-CUTS.md`; ZIP integrity checked and hashes in `prototypes/FIRST-CUTS-SHA256SUMS.txt`.

Matching packaged Linux builds were actually run and rendered. Scott subsequently ran the Windows Two Rivers build and supplied the feedback above. Do not claim he tested the other Windows packages.

Two Rivers contains 19 buildings, 3 stalls, 8 fields, 4 bridges and 1671 trees across 1024x1024 metres. Finite authored scenery; no server, saves, interiors or living ecosystem. Camera and navigation work locally. Shift-click uses a real run animation. Village people and foliage remain provisional.

Character comparison is idle-only, four sprite facings alongside the existing 3D person, with normal/close/low angles. Walk drafts were excluded after visual review despite the second passing scale QC. They repeat the same leading leg. Do not enable them merely because PNGs exist.

Building kit has 3 layouts, shared 2m wall bays, thatch/slate and cutaway. It is a construction study, simpler than village landmark art. NPC routine is a separate schedule diagram with a headless simulation, not a citizen integrated into the village.

## Code and checks

- Engine: `tools/godot/godot`, Godot 4.3. Export templates are installed under `~/.local/share/godot/export_templates/4.3.stable/`.
- Village: `prototypes/two_rivers/village.gd`, `terrain.gd`, `terrain.gdshader`, `region_map.gd`, `src/sim/landscape.gd`, `src/sim/bridge_profile.gd`.
- Navigation is a 1m grid. Buildings/trunks/water block routes; farm-border fences were decorative. Before networking, bake stable IDs/footprints into authored data instead of deriving server collision from rendered model bounds.
- Bridges use deck profiles sampled from their actual GLB geometry. Preserve those profiles when touching routes. Movement consumes multiple path steps per frame to avoid speed depending on frame rate.
- Current elevation slider: 1 to 60 degrees. Q/E input asks for 45-degree rotations. Orthographic zoom changes camera size.
- Actual village package check output is saved at `prototypes/two_rivers/artifacts/linux-runtime-check.log`; rendered captures alongside it.
- Source capture: `xvfb-run -a tools/godot/godot --path prototypes/two_rivers --audio-driver Dummy -- --capture-dir=/tmp/two-rivers-check`.
- For changed exports, run the actual packaged Linux binary from its build directory and inspect captures. Windows runtime verification is Scott's playtest.
- Rendering uses software llvmpipe here and can take about a minute for the village. Avoid repeated full runs without a relevant change.

## Design records and art provenance

- Approved durable plan: `prototypes/APPROVED-NEXT-STEPS.md`.
- Reviewed HTML source: `.lavish/longwalk-next-steps/index.html`.
- Portable HTML: `prototypes/Longwalk-Next-Steps.html`.
- Foundation supplement: `prototypes/two_rivers/reference/foundation-supplement.md`.
- Earlier roadmap proposal with pathfinding addendum: `prototypes/two_rivers/reference/roadmap-proposal.md`.
- Server design detail: `prototypes/two_rivers/reference/server-client-first-cut.md`.
- New village assets consumed 240 Meshy credits total, already completed. Six building/prop/tree models used 180; bridge/well used 60. No active paid generation and no paid retries needed.
- Provenance: `prototypes/two_rivers/reference/art-generation/generation.json` and `reference/bridge-well-provenance.json`.
- Sprite study notes: `prototypes/character_comparison/reference/art-study-notes.md`. Raw image generation used built-in imagegen; processing used the generate2dsprite skill.
- Original foundation has 13 Markdown files. Shared chat tile-sheet references were recovered as messages, but original tile-sheet images were not recovered and must not be called production-ready.
- Shared conversation: https://chatgpt.com/share/6aa232c5-eba0-83ea-974c-7e2b98e01523
- Close art reference: https://chatgpt.com/s/m_6aa232a288408191a9dd7e986cb8fa1f
- Regional art reference: https://chatgpt.com/s/m_6aa232ba5fd48191af47b8e677554e8d

## Review page and session state

Verified Lavish URL: http://172.16.3.13:4387/session/45cb083db619a886

Lavish emitted a `worker.int.sentania.net` hostname URL that refused the connection here. The actual listener is bound to 172.16.3.13:4387. Do not repeat the broken hostname link. The review session remains open/resumable, with no active poll after the last browser-disconnected return. Do not claim to be monitoring it. No need to reopen or end it for the tmux move. Portable HTML works without Lavish.

Earlier agents foundation_review, terrain and village_assets completed their assigned work. No implementation task remains running. Do not depend on their live context in the new tmux session.
