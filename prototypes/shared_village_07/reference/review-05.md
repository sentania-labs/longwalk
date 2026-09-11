# Separate review of Workshop 05

Software, isolated prototype under Scott's standing SDLC exception. Reviewed the implemented state transitions, persistence validation, area routing, item ownership and HUD separately from writing them. No live deployment in the build pass.

All player inventory and equipment mutations are server-owned and committed before success is returned. Repeated bundle/tool collection and repeated trade cannot award twice. Range and area are validated for workshop interactions. Full-health potions and full-stamina food are retained. Ready slots refer to owned inventory items. Only the recipient receives its private character state; visible traveler snapshots carry area for rendering and collision separation.

04 records upgrade in memory to save schema 2, retaining character identity, positions, owner and existing world facts. Old-schema backups upgrade on restore. 04 servers reject schema 2, so rollback requires the pre-upgrade backup. Protocol 05 is required on both ends. No world baseline migration.

Test-driven corrections: immutable JSON records decode numbers as floats, so schema validation compares numeric values instead of array membership; server packaging avoids eager loading of client-only HUD code. Character panels close on Escape before app exit, and new route/shortcut preferences participate in Reset.

Scope limits: one shared interior and one commission per character, a stationary carpenter, simple reused/primitive interior furnishings, four quick slots without slot-count progression yet, no combat damage or ring buffs, and daylight rendering while the location label follows server time. Body/feet represent starter clothing, with functional hand/finger equipment discovered through the loop. Existing append-only storage and private-LAN authentication limits remain.

Rendered final client passed with two travelers inside, Character open, discovered hand/finger equipment visible and route lines hidden. A simulated right-click selected the carpenter and Inspect displayed the correct description. Free inspection remained independent of the traveler. A second-player approach test exposed an occupied destination, so interaction approach selection now excludes other travelers' occupied cells.
