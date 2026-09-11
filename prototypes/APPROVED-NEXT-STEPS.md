# Approved next steps

Knowledge artifact, 2026-09-10. Scott approved this plan: "the plan looks good - let's document it, write a session handoff and I'm going to move you to a different tmux session".

This preserves the reviewed plan, including pathfinding and bridge-art addenda. Approval is recorded here. Since the subsequent "okay let's resume", the camera/layout/pathfinding pass has been implemented as `two_rivers_comfort/` and packaged for a Windows playtest. Server and RPG implementation have not begun. See `SESSION-HANDOFF.md` for current evidence and remaining work. Protected architecture and the main project remain unchanged.

Browser version: http://172.16.3.13:4387/session/45cb083db619a886

Portable version: [Longwalk-Next-Steps.html](Longwalk-Next-Steps.html).

## Make it comfortable. Make it shared. Give someone a life here.

The village has earned another iteration. My recommendation is a focused camera and layout pass, then a small authoritative server, followed by one complete ordinary-work loop.

Your preferred direction is a dimensional, non-sprite character in a stylized world. The next art work should find the balance between the Two Rivers illustration, the clarity of the sprite reference, and a camera that can get close. We do not need to settle the entire art pipeline before connecting two players.

## Next playable build: camera and layout: A bounded comfort pass before the server work.

- Hold Q/E for continuous rotation. Turn while held, stop on release, with a rotation-speed setting. Optional 45° buttons can remain in the camera panel.

- Reverse minus and equals as requested: minus zooms in, equals zooms out. Keep wheel behavior unchanged unless separately requested. Put bindings, inversion and reset-to-defaults in the interface.

- Keep the existing pan-speed dial. Test its useful range at both village and doorway distances. WASD already rotates with camera yaw; its current map-focus movement is what needs a closer-view behavior.

- Add a close inspection camera experiment. At a doorway, move the camera forward/back and strafe relative to its heading, keep it above ground, and allow looking upward toward the roof. Make mode entry, exit and return-to-traveler explicit. This is a camera study, not a commitment to first-person combat or full character possession.

- Handle the horizon and underside. Keep the camera out of terrain, add a convincing sky/horizon and distant ground skirt, and prevent views through the underside of the playable plane. Simply letting the orbit angle go negative would put the current camera underground.

- Give the farmer their field back. Route roads around planted plots, put paths through actual gates, and connect farm doors to those entrances. Check visual fences, collision and route data together so a fence that looks closed is not silently walkable.

The current main camera is orthographic: zoom changes the view width rather than walking the camera toward the barn. That is why a close inspection mode deserves a small prototype of its own. Keep the familiar overhead mode available throughout.

Seen working: hold Q/E through a full turn; approach the barn and look at its roof without exposing the void; walk from road to farm door through a gate; verify movement after rotating to several headings.

## Pathfinding: prefer the road, allow the shortcut: Road-aware travel now; paths worn into the landscape later.

Default behavior: players and NPCs generally use roads, paths, gates and bridges. Prefer a sensible established route over a small off-road distance saving, without forcing a huge detour when open ground offers a reasonable alternative.

### First pathfinding pass

- Use travel costs, not mandatory road rails. Roads and paths are easier to traverse than open ground. Fields and rough vegetation are less attractive. Buildings, closed fences and water without a crossing remain genuine obstacles, not merely expensive tiles.

- Allow deliberate shortcuts. Add an explicit route choice in the interface, such as “Prefer paths” versus “Direct route,” with a route preview. A direct route reduces the preference for roads but still respects obstacles and any rules about access. Clicking a reachable point off-road must remain possible.

- Keep pace and route choice separate. Shift-click continues to mean run. Walking or running should both support a deliberate shortcut; running does not automatically mean leaving the road.

- Give NPCs the same navigation rules. Their normal routines prefer established routes. Task needs can justify open-ground travel, for example a farmer working inside a field. Later behavior can choose shortcuts intentionally rather than doing so accidentally because distance is the only cost.

- Show and save route preferences. Player controls and tuning belong in the GUI with working defaults. Once networked, the server owns valid routes and their costs.

Seen working: normal travel between village landmarks follows paths and gates; a player can explicitly cut across reachable open ground; neither choice walks through a closed fence; an NPC can leave a road to reach its work site. Running does not change the selected route preference.

### Future: repeated travel changes the ground

Record actual footfall from players, NPCs and eventually animals. Repeated passages gradually wear vegetation and establish paths or game trails. Unused tracks can recover over time. A planned route alone causes no wear, and a single crossing should not instantly draw a permanent road.

Accumulate wear in the headless simulation, independent of camera visibility and frame rate. When persistence exists, store it as a change to the authored baseline. Let an established trail eventually affect travel cost, but tune formation and recovery carefully so a few accidental shortcuts do not erase every field. Ownership and land-use consequences remain later gameplay decisions.

Scope: road preference and deliberate shortcuts belong with the next camera/layout pass. Terrain wear, regrowth and animal-made trails remain future work.

## Next foundation: two people in the same village: Start server/client integration after the comfort pass, before a large gameplay buildout.

Your positive village verdict satisfies the earlier playtest condition. I recommend moving the shared-world proof forward now. Scott has now approved this sequence. Implementation has not started, and the repository constitution is unchanged.

- Separate world decisions from presentation. Give placed objects stable identities and authored collision footprints. Move route execution and movement into the headless simulation so camera changes cannot change game rules.

- Connect two packaged clients. One headless Godot world process runs in Docker. Clients ask to walk or run; the server validates routes and owns positions. Both clients see the same travelers.

- Make reconnect boring. A remembered connection address, clear status and Retry belong in the GUI. Reconnecting recovers the same character rather than creating a duplicate. A dropped connection stops accepting new world actions.

- Leave one lasting mark. Change one tree, show it on both clients, restart the server and see that it remains changed. Keep the authored map, changes to the map, and character records separate.

- Prove recovery. Demonstrate abrupt restart, a backup and a restore. A save failure must be visible, and damaged state must never silently become a fresh world.

Seen working: two Windows clients against the actual container, shared movement, disconnect/reconnect, one persistent resource change and a demonstrated restore.

### Kubernetes without premature distribution

Target one world writer and persistent storage. Package a single-instance Kubernetes deployment once the container proof works, with startup/readiness tied to loading valid world state and a controlled shutdown. A second replica must not write the same world. This first version has restart downtime.

Database choice, transport and save format need a bounded implementation decision. We should prefer established durability mechanisms over inventing a large storage subsystem. Do not add a message bus or multi-region ownership before there is a measured reason.

Connection and world settings get GUI controls and working defaults. Deployment packaging remains versioned; any actual lab rollout follows the infrastructure process separately.

## First RPG slice: one ordinary working day: Bring interiors, inventory, character information and NPCs together in one useful loop.

Proposed loop: enter a workshop, take a tool, gather wood nearby, return it to a citizen, and see both the world and your character reflect what happened. The exact trade can change; the point is a complete activity with a visible result.

### One enterable building

Start with a workshop or inn, a real doorway transition, a modest interior and a reliable exit. Compare a roof cutaway with a separate interior scene before committing the whole village. Both must preserve shared-world identity and interaction rules.

### Inventory with real consequences

Pick up, carry, inspect, equip and hand over a small set of items. Start with one tool and one gathered material. The server owns transfers so reconnecting or retrying cannot duplicate goods.

### Character panel

Name, equipped tool, carried items, stamina, constitution and a short skill list. Show why a value changed. Avoid filling the first panel with speculative attributes that do nothing yet.

### A citizen in the village

Move the isolated schedule experiment into the authored map. One citizen routes between home, work and the square and supports one useful exchange. A moving schedule marker is not yet a shopkeeper.

### Skills with the DCC sense of possibility

Begin with Running and one work skill. Running practice can affect speed and stamina efficiency, while constitution affects stamina capacity. Add one small observational or whimsical skill to test the discovery tone. Not every skill needs a combat bonus, but learning should have context rather than reward unattended repetition.

Seen working: complete the activity, disconnect, return, and retain the agreed inventory, character progress and world consequences. Another player sees the same resource change.

## Art direction: stylized 3D with deliberate close-up limits: An ongoing comparison track, not a demand to replace every asset now.

Keep the 3D character feel you prefer. Borrow the sprite's readable silhouette, simplified shading and forgiving detail budget, and the Two Rivers image's warm materials, shapes and pastoral composition.

- Choose a small visual test scene: one person, a barn doorway, a stretch of path, grass and one tree. Judge the same scene from village distance, over-the-shoulder distance and near the doorway.

- Fix shape before more texture detail. Natural arms and idle pose, cleaner building edges, believable door sizes and softer foliage matter more than blindly increasing texture resolution.

- Make materials agree. Reduce noisy surface detail and baked-in highlights that fight the scene lighting. Use a consistent palette and clear large shapes. Keep weathering selective.

- Set a close-view quality target. Decide how close normal play is supposed to get. A doorway interaction has a different asset requirement from inspecting every nail in first person.

- Match bridges to the settlement. Scott finds the current bridges appropriate for this prototype, but visually closer to a city or large town. Keep them unchanged here. Future village crossings should explore simpler rural construction; retain the current style for larger settlements. Materials and specific designs remain open.

- Keep region variety. Thatched farms, slate-roofed towns and later city architecture can share construction rules while having different materials and silhouettes.

Suggested experiment: compare the existing model with one cleaned, more stylized 3D treatment in identical framing. Keep the sprite study as a reference for readability. Only widen the art pass once that small comparison establishes a direction.

Seen working: one approved person-and-doorway scene reads coherently at all three intended distances. Record that as the art target before mass-producing variations.

## Packaging and identity: Make each new playtest easy to find, launch and distinguish.

- App icon: first study a simple Longwalk mark that reads at taskbar size, such as a winding path or a traveler silhouette. Compare a few small-size options before choosing. Apply the chosen mark to the EXE and window.

- A useful start screen: Play locally during prototyping, Connect when networking exists, Settings and Quit. Show build identity so feedback can be tied to the right artifact.

- One clear download entry: a named Windows ZIP, the EXE inside, concise controls and a visible build label. Keep prior playtests available for comparison and recovery.

- Preferences survive relaunch: camera sensitivity, zoom direction and key bindings should save, detect conflicts and offer reset to working defaults.

This can accompany the camera pass. It should not become a branding project that delays the next playable build.

## Growing toward a larger living world: Keep the planet ambition, scale what we can demonstrate.

The immediate working area remains 1024×1024m. Landscape size, concurrent players and simulated population are separate capacity questions. The current repository direction is a finite authored map; a planet-scale runtime is a future architecture decision, not something this plan silently reinstates.

- Ecology after the work loop: vegetation recovery and one animal population with feeding, movement and reproduction. Measure its cost and behavior before adding many species.

- Offscreen activity: decide which facts must remain exact and what can advance at lower detail. Keep simulation independent of what any camera sees.

- More settlements: add regional building styles, travel and local work once one village has a reason to live in it.

- Region ownership when needed: use measured tick delay and population load to justify a split. Then design handoff, messaging and failure recovery together.

- Database availability from recovery needs: choose acceptable data loss and downtime, then add the storage and failover mechanisms that meet them. Kubernetes replicas alone do not make a mutable world highly available.

Combat, extensive crafting, economy, families, inheritance and relationship memory remain later playable slices. Listing them does not make them prerequisites for the first satisfying session.

## Playtest feedback and evidence: What is observed, what is inferred, and what this document changes.

- Accepted: the overall prototype is a solid base; farm views from different angles work; zoomed-out graphics read well; the dimensional character feel is preferred.

- Requested: continuous Q/E, looking up near buildings, reverse minus/equals, handle the under-world void, eventually interiors, inventory, character panel and app icon.

- Reported: roads cross a field and fence. The next layout pass should reproduce and fix those specific crossings, then check every farm access route.

- Clarified by you: pan speed already has a dial. No new speed increase is presumed.

- Verified in code: Q/E currently request 45° turns; elevation is limited to 1–60°; keyboard pan uses yaw-relative ground vectors; zoom changes orthographic camera size; farm-border fences are currently documented as decorative.

Sources: this playtest feedback; prototypes/two_rivers/village.gd and README.md; the existing foundation supplement, play roadmap proposal and server/client first-cut design. Earlier documents remain historical proposals; this page records the new positive playtest verdict and recommended next sequence.

Work classification: knowledge. This is a planning artifact only. It changes no game code, infrastructure, dependencies or protected architecture. The sequence is approved; this session stops after documenting it for handoff.

## Shared Village 03 update

The shared-world proof is implemented separately in `shared_village/`, including Docker packaging and undeployed Kubernetes manifests. See its README and evidence. The inspection camera now crosses obstacles independently of the traveler.

Scott's next interaction direction is a contextual right-click menu: Walk here, Run here, Inspect, Open door, with available actions reflecting locks, keys and later skills. Keep deliberate traversal actions explicit. Implement the menu JIT with the next playable interaction, then scope the first interior/work loop after feedback.
