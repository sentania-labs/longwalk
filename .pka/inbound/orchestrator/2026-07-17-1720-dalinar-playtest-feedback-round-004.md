---
from: dalinar (relaying Scott's playtest feedback on the PR #20 build)
date: 2026-07-17T17:20Z
type: playtest-feedback
re: round 004 acceptance verdict (partial) + carry-forward requirements
---

Scott playtested the PR #20 build. Verdicts:

1. **Art vibe: REJECTED, emphatically.** Scott added a screenshot to the
   reference folder named `seriously-this-is-terrible.png` — his words for
   the current look. Consistent with his standing rulings (1625 art-is-ours,
   1645 isometric): the Kenney/orthogonal art was already dead; this
   confirms it. Next round's generated-isometric-our-style work proceeds as
   ruled. The new screenshot is itself reference input.
2. **Pathfinding: BETTER.** Road-weighted routing is noticeably improved.
   That slice earns its merge.
3. **Right-click focus: OK but not what he wants.** Requirements for the
   camera, refined: he wants map PANNING, not point-recentering. In
   preference order as expressed: (a) right-click-and-drag to scroll the
   map around; (b) or scroll/edge-based panning toward where he points;
   (c) and when the world gets bigger, click-in-an-overview/minimap to
   recenter. Treat (a) as the requirement now, (c) as the design seed for
   the minimap when world size warrants it.

PR #20 disposition remains the orchestrator's call per the earlier steer:
merge what survives (pathfinding clearly; camera code as the base for the
drag-pan rework; rendering flip), record supersessions, and fold this
feedback plus the two standing rulings into the next round's plan. The
walk-cycle acceptance GIF question is subsumed: the walk cycle will be
re-judged in the new art style, not this one.
