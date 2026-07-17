# agy-worker, round 005 phase-3 ballot

## Q-A: Generation method
**Vote:** BOARD-LED
**Interest:** FULL-SHEET is my own proposal.
**Rationale:** My peers are correct that a massive single sheet (such as 48 cells for an 8-facing walk cycle) starves individual assets of resolution and correlates extraction failures, where one malformed frame ruins the entire generation. While full-sheet generation theoretically guarantees coherence, the AI generator's pixel density cannot realistically support a whole village while maintaining the strict grid alignment required for blind slicing. BOARD-LED is the pragmatic engineering choice: it preserves necessary resolution and avoids mega-sheet fragility, while using a non-runtime master reference to aggressively constrain category-handoff drift.

## Q-B: Movement authority under isometric projection
**Vote:** KEEP-AUTHORITATIVE
**Interest:** I have no direct interest (my proposal did not alter sim movement authority).
**Rationale:** Dropping `move_and_slide` and making colliders advisory breaks the tested collider geometry and creates immediate technical debt for future dynamic obstacles like NPCs and fauna. Keeping movement and collision authoritative in the existing logical world coordinate space preserves the strict sim/render separation mandated by the constitution. This ensures the simulation remains completely runnable headless on a server, while the isometric projection remains a purely visual proxy for display.

## Q-C: Cast/silhouette shadow method
**Vote:** OFFLINE-DERIVED
**Interest:** GENERATED-SHEET is my own proposal.
**Rationale:** I initially proposed a generated sheet because naively shearing a 2D isometric sprite's full alpha stretches and detaches the roof shadow, which decision 006 correctly rejected. However, OFFLINE-DERIVED is the superior deterministic method because this detachment can be avoided by casting the shadow only from the ground-contact silhouette (the bottom base portion of the sprite's mask), rather than the upward-projected roof pixels. This offline pass mathematically guarantees that all shadows share an identical, fixed light vector, avoiding the severe risk of a generated shadow sheet disagreeing with the accepted sprite.
