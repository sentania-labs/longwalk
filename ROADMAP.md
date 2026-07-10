# ROADMAP.md, longwalk

Milestone ladder for longwalk. Each milestone builds on the constraints in
[CLAUDE.md](CLAUDE.md) and the design in [ARCHITECTURE.md](ARCHITECTURE.md). No
milestone may violate the determinism rule or the world topology rule.

## M1: project scaffold and macro planet map generator (this milestone)

- Godot 4.3 project scaffold, headless-capable, cross-platform-clean.
- Deterministic macro planet map generator, runnable headless.
- Layered noise elevation, latitude-plus-noise temperature, noise moisture, and
  a seven-biome lookup table (ocean, beach, plains, forest, desert, tundra,
  mountain).
- East-west cylindrical wrap, verified seamless.
- Output: a rendered PNG map plus a JSON summary (land fraction and biome
  distribution).
- Determinism test asserting byte-identical PNG and JSON for a fixed seed, run
  headless by CI.
- Sample maps committed under `examples/`.

Status: delivered in this bootstrap dispatch.

## M2: walkable chunk

- Heightmap-to-mesh terrain rendering for a single local area, sourced from the
  macro map so the local terrain agrees with the macro biome and elevation.
- Character controller: walk, run, swim, sleep.
- Switchable first-person and third-person camera.
- Begin the origin-shifting work described in ARCHITECTURE.md, since this is the
  first milestone with a walkable world.

## M3: chunked streaming

- Stream chunks of the world in and out as the player moves.
- Biome texturing on the streamed terrain.
- Flora scattering (grass, trees, and similar), deterministic from (seed,
  position). No fauna.
- Chunk positions tracked in the large logical coordinate space and converted to
  shifted local coordinates per the origin-shifting plan.

## M4: persistence

- Implement the delta / override layer and save/load, building on the three-layer
  persistence design in ARCHITECTURE.md.
- The formula layer stays stateless. Saves store only deltas and entities.

## M5 and beyond: fauna (deferred)

- Fauna, explicitly deferred. Modeled as agent-based ecosystem processes, not
  scripted spawners. Not designed yet, noted here only as future scope.
