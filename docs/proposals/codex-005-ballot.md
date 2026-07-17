# Codex worker ballot: round 005

## Q-A: Generation method

**Vote: BOARD-LED.** A single non-runtime composition gives every generation call the same visible authority for projection, scale, palette, edge treatment, and light, while compact category sheets preserve shared geometry where it matters and individual calls give large or collision-sensitive buildings enough resolution and a practical regeneration boundary. A full village or 48-frame walk sheet puts incompatible cell needs into one render and correlates rejection: one malformed frame or building can invalidate otherwise usable output. Per-facing walk grids tied to one accepted neutral master still require strict identity and anchor gates, but they provide a more controllable failure unit than one crowded sheet. **Declared interest:** BOARD-LED is the option from my own proposal.

## Q-B: Movement authority under isometric projection

**Vote: KEEP-AUTHORITATIVE.** Isometric presentation does not justify replacing an existing, tested gameplay contract. Logical world position, `move_and_slide`, and footprint colliders should remain authoritative, with a render proxy projecting that position for display and inverse projection used only at the input boundary. This keeps movement and collision independent of viewport nodes, preserves the tested collider geometry, and keeps the simulation runnable headless on a server. DROP would create a second movement truth in a render controller and make colliders advisory just before planned NPC and ecology work makes collision semantics more important. **Declared interest:** KEEP-AUTHORITATIVE is the option from my own proposal and phase-2 critique.

## Q-C: Cast/silhouette shadow method

**Vote: OFFLINE-DERIVED.** Deterministic preprocessing keeps every shadow tied to the accepted asset, contact anchor, and one fixed light vector, avoiding a second generated artifact whose silhouette or lighting can drift. The processor must not naively shear the full isometric sprite alpha. For buildings and tall props, the cast source should be a declared ground-contact silhouette or footprint mask, optionally with manifest-provided height bands, projected outward from the contact anchor with a bounded length; elevated roof pixels are excluded from the source, so the roof shadow cannot begin detached at the roof's screen position. Contact darkening remains a separate tight mask at the base. **Declared interest:** OFFLINE-DERIVED is the option from my own proposal and phase-2 critique.
