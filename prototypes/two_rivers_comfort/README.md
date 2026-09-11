# Two Rivers Comfort 02

A separate local iteration of the accepted 1024x1024m village. The original Two Rivers source and Windows ZIP remain unchanged.

Software prototype under Scott's explicit local exception to full SDLC/CI. Approved plan: `../APPROVED-NEXT-STEPS.md`; resume authorization: "okay let's resume". No main-project, infrastructure, engine, dependency or bridge-art changes.

## Changes

- Hold Q/E for continuous rotation. Minus zooms in, equals out. Wheel keeps its previous direction.
- Tab or the on-screen inspection switch enters a ground-level perspective camera near the overhead focus. WASD moves relative to heading; right-drag looks around and upward. Tab returns overhead; Space returns to the traveler. Inspection respects navigation obstacles and stays above ground or the bridge deck. It does not possess the character.
- Sky and a distant ground continuation cover the horizon and underside. Terrain remains a flat prototype, not a finished landscape.
- Roads go around fields, with one visible gateway per field. Field fences now block navigation and use the same authored barriers for placement and routing.
- Prefer paths is the default route choice. Direct route permits deliberate open-ground shortcuts while still respecting fences, buildings, trunks and water. Hover to preview, click to travel, Shift-click to run. Route preference and pace are independent. Changing preference affects the next command.
- Camera controls include pan speed, rotation speed, keyboard zoom inversion and remappable keys, with conflict detection and reset. These preferences and route choice survive relaunch. Fixed Shift remains the run modifier; Escape cancels rebinding, exits inspection/closes controls, or quits.
- The reusable headless travel grid can route any traveler. This pass does not add NPCs to the village, footprint wear, stamina, interiors, inventory, persistence or a server.

## Run and verify

```sh
tools/godot/godot --headless --editor --path prototypes/two_rivers_comfort --import --quit
tools/godot/godot --headless --path prototypes/two_rivers_comfort --script test/travel.gd
xvfb-run -a tools/godot/godot --path prototypes/two_rivers_comfort --audio-driver Dummy -- --capture-dir=/tmp/comfort-check
```

The route checks cover every field gateway, solid fences, road preference versus shortcuts, and bridge-only water crossings. The rendered check also exercises held rotation/release, reversed zoom, populated field access, barn camera movement/look-up, returning overhead, key conflicts and preference save/reload. Test preferences use a separate file and never replace real control settings.

Rendered route previews are advisory. A click always computes a fresh route from the current character position. There are no dynamic obstacles or other travelers yet. Buildings still derive their navigation footprint from model bounds; baking stable simulation-owned footprints belongs to the next shared-world milestone.

The source-art quality and current bridge models are retained. No additional generated art or paid asset calls were needed.
