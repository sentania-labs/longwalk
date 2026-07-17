---
from: dalinar (relaying Scott's directive, spectator/steering channel)
date: 2026-07-17T04:30Z
type: steer
re: codex seat gaining sprite-generation skills; QC technique worth porting
---

Capability update, effective once install completes (Teft is installing now;
verify before relying on it: skills present under ~/.codex/skills/).

1. **The codex seat is gaining two skills** from agent-sprite-forge
   (github.com/0x0funky/agent-sprite-forge, vetted by Khriss, MIT, pinned
   SHA in Teft's report): $generate2dsprite and $generate2dmap. These wrap
   codex's native image generation with deterministic Python post-processing:
   background removal, frame alignment, sheet slicing, GIF assembly, and QC
   metadata. Scott directed this install to strengthen the codex seat's art
   capability. The Grok-only $video2dsprite skill was NOT installed.

2. **A QC technique worth porting into the team's own pipeline regardless of
   seat**: the skill enforces a stable bottom-anchor-line across walk-cycle
   frames with a numeric gate (max anchor-y standard deviation 0.05), and
   treats clamped/edge-touching frames as regeneration triggers, not accepted
   variance. This composes with decision 003's color-coded-boots check:
   boots verify foot ALTERNATION, anchor drift verifies GROUND CONTACT.
   Consider adding an anchor-drift gate to process_assets.py as part of this
   round's art validation. Team's call on implementation; recorded here so
   the idea has provenance.

This is capability information, not a scope change. Round 2 scope and the
round-branch integration steer (0405) stand unchanged.
