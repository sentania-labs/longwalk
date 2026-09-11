# Separate review of Shared Village 04

Reviewed simulation, menu picking and routing, protocol admission and persistence compatibility after implementation. No PR or live deployment in this pass.

Found and corrected during testing: opposing travelers repeatedly returned to their old grid center while replanning. Removing the obsolete initial waypoint permits detours to complete while swept clearance checks prevent overlap. Stationary, opposing and newly obstructed routes now pass. Temporary navigation blockers are removed after every plan, preserving static collision and road costs. Only connected travelers occupy the simulation.

Checked that movement remains server-owned, menu Harvest uses the existing range/pause/idempotency checks, manifest loading remains frozen and baseline bytes unchanged, and protocol rejection precedes registration. Saved profiles retain the original userdata directory. Right-click release is distinguished from right-drag; Escape closes the menu before exiting the app.

Known scope limits: no crowd queues, no door state or interiors, no item collection, static-only route previews and approximate visual bounds for object picking. Existing backups and first-owner administration remain prototype systems. No additional dependencies or generated art.

Rendered check passed with two connected travelers and the square-oak menu open, visually inspected. No script errors appeared. An additional narrow-corridor test verifies waiting until the obstruction leaves, then completing the route. Windows ZIP integrity passed; actual Windows testing remains with Scott.
