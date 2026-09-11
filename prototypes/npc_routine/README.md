# Citizen routine first cut

The standalone viewer labels Home, Work and Square and animates a gold citizen marker. Pause/resume, reset and a speed slider are available in the window. Launch the Windows ZIP in `artifacts/` or the Linux executable under `build/linux/`. The diagram represents a schedule, not final game art.

One citizen rests at home, walks to work, works, visits the square and returns home. A built-in 60-second day makes the whole routine easy to inspect. No setup or editable configuration is required.

Run from the repository root:

```sh
tools/godot/godot --headless --path prototypes/npc_routine --script test/run.gd
```

The script prints a complete sample day and exits nonzero if a check fails. It verifies locations and activities at schedule boundaries, movement halfway along routes, repeated days, invalid tick rejection and equivalent states after fine, coarse and irregular simulation ticks.

`src/sim/citizen_routine.gd` has no rendering, input or scene dependencies. The caller supplies simulation seconds to `advance()` and reads `state()`. Position is derived analytically from total simulation time, so a slow client or skipped rendering frame cannot change this citizen's schedule. Binary fractional ticks give exact agreement; decimal fractions agree within floating-point tolerance.

This first cut uses unobstructed straight routes and scheduled arrival times. It does not run collision or terrain navigation. The next integration needs a route adapter with path lengths, walking speed and an explicit policy for late or blocked arrivals. Working is currently an activity label, not production, inventory, skill progression or tool use. No server, persistence, fauna or Two Rivers scene integration is included.

This is an isolated local software prototype under Scott's approved first-cut queue. It does not alter the active game or use the full release process.

Packaged Linux viewer was run and visually checked. Its capture check exercises pause/resume, speed scaling and reset. Windows was exported and packaged, but requires a Windows playtest.
