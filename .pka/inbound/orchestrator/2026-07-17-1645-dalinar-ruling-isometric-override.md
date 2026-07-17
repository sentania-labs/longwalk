---
from: dalinar (relaying Scott's ruling, spectator/steering channel)
date: 2026-07-17T16:45Z
type: escalation-reply + steer
re: decision 006 ground 1 (orthogonal vs isometric) — OVERRIDDEN by Scott
---

Scott's ruling (2026-07-17, verbatim): "I veto the group: isometric"

Context: Scott was walked through the visual difference between top-down
oblique and isometric, including the costs the 4-0 vote weighed (walk-sheet
rework, projection math, depth sorting) and the fact that WC2 is oblique
while AoE/UO/Theme Hospital are isometric. He is overriding with full
knowledge of the trade. The diamond view is itself part of what he wants.

What this decides:

1. **Longwalk moves to isometric projection.** Decision 006 ground 1
   (stay orthogonal) is overridden by Scott's authority; record the
   supersession in the round's decision record.
2. **The sim/render hard rule is NOT relaxed.** This is the architectural
   condition of the override: the sim keeps its square grid, tile
   coordinates, and walkability logic untouched and projection-ignorant.
   ALL isometric math (world-to-screen diamond transform, screen-to-world
   picking for click-to-move, depth/Y-sorting by projected position) lives
   strictly render-side. The projection is a view of the grid, never a
   property of it. The team's own architecture makes this override cheaper
   than the vote assumed.
3. **Art generation targets isometric sheets.** This composes with the
   art-is-ours ruling (1625 file): sheets were being regenerated to the new
   bar anyway, so the sunk-cost ground of the vote has largely evaporated.
   The reference images (AoE, UO, Theme Hospital, the reddit sheets) are
   predominantly isometric, so generation now aims at what the references
   actually show. Character sheets need the isometric facing set the team
   judges sufficient (typically 4 diagonal facings minimum, 8 preferred);
   that facing-count call is the team's to make and record.
4. **Still-standing grounds of 006:** nearest-neighbor at fixed art scale,
   weighted road costs (sim-side, projection-agnostic), the camera
   focus/follow state machine (retarget to projected coordinates), and the
   shadow-mask approach (regenerate masks for isometric building sprites).

Sequencing is the orchestrator's call: re-open synthesis for the affected
slices versus completing projection-agnostic work first. Claude's
road-routing slice is sim-side and unaffected. If the round needs to grow
or split to absorb this, say so in TEAM-STATE and the round PR rather than
rushing a half-projection hybrid out the door.

Scott's acceptance gate stands, now with isometric eyes: side-by-side
walk-cycle GIF and before/after vibe screenshots.
