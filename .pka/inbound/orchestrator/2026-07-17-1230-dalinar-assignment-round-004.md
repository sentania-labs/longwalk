---
from: dalinar (relaying Scott's playtest feedback and round 4 assignment)
date: 2026-07-17T12:30Z
type: assignment
re: round 004, "make it look like a game" (Scott playtested build 29564548380)
---

Scott playtested the round-003 build. Machinery verdict was good; the game
verdict was mixed. His feedback, verbatim in spirit, forms this round's
requirements. Protocol: FULL (art strategy is contested ground again).
Round-branch integration and four-ballot voting per decisions 004/005 apply.

## Scott's playtest findings (all are requirements, not suggestions)

1. **Walk animation is "just okay, really rudimentary, sort of skipping."**
   The colored-boots QC verified foot ALTERNATION but nothing verified GAIT
   QUALITY. New acceptance bar: a side-by-side animated GIF of our walk
   cycle next to a reference-game walk cycle (from the reference folder),
   attached to the decision record, judged on stride length, contact
   frames, and vertical bounce. "The frames are in the right order" no
   longer passes.
2. **No visible change in art vibe** despite the WC2/UO direction. The feel
   pass produced a color grade, not a style change. This round's vibe work
   is judged against the reference images, with before/after screenshots
   in the round PR.
3. **FLORA IS NOW A HARD REQUIREMENT, not a stretch goal.** Scott has asked
   three times. Trees, bushes, at least one flower patch. Decision 003 cut
   it; that cut does not carry forward.
4. **Pathfinding must know roads exist.** The traveller should prefer
   roads/paths when routing (weighted navigation costs), leaving them only
   when the destination requires it.
5. **Click-to-move is good enough. ADD right-click to focus/recenter the
   view** on a location (pan the camera there) independent of where the
   character is pathing.
6. **Building shadows must conform to building silhouettes.** Current
   rounded blob shadows on the two houses read as wrong.
7. **The traveller floats on the road.** Ground him: anchor contact with
   the surface, plus a contact shadow under him consistent with the
   building shadow direction.

## Strategy changes authorized by Scott (Dalinar-relayed)

- **Licensed asset packs are AUTHORIZED as a base layer.** CC0 or CC-BY 2D
  pixel tilesets/sprite packs (e.g. itch.io, Kenney, OpenGameArt) may be
  adopted for terrain, buildings, flora, and props, with AI generation
  reserved for custom pieces (the traveller, unique buildings). Every
  adopted asset must be recorded in a CREDITS.md with source URL and
  license. CC-BY attribution requirements must be honored. NO
  noncommercial-only or unclear-license assets. This is the likely biggest
  single unlock for the vibe gap; treat "which pack(s)" as a phase-1
  contested question with links and sample screenshots in proposals.
- **The codex seat MUST exercise its agent-sprite-forge skills this round**
  ($generate2dsprite / $generate2dmap in ~/.codex/skills/) for whatever
  generation remains, and the round retro must report whether they
  materially helped. They went in after round 003's art slice was
  underway, so this is their first real test.
- **Reference folder expanded**: /home/scott/claude/vault/tmp/longwalk-inputs
  now has additional screenshots from Scott. Read-only. Study before
  proposing.
- **IMPORTANT (Scott clarification): some of the new reference images are
  AI-GENERATED ART SHEETS from the reddit vibecoded city-builder** whose
  look Scott wants. They are an existence proof that generation can reach
  this bar. Study them as a generation TARGET, not just inspiration: note
  that they appear to be coherent full sheets (tiles/props/buildings
  generated together with a shared palette and lighting), not per-sprite
  piecemeal generation. The team's phase-1 art proposals should weigh
  full-sheet coherent generation against asset packs as competing (or
  complementary) strategies; the vibe gap so far may be a METHOD problem
  (piecemeal generation producing non-cohering assets), not a capability
  problem.
- **Technique reference**: CorsixTH (github.com/CorsixTH/CorsixTH), the
  open-source Theme Hospital engine, is citable for HOW Bullfrog-era games
  did building shadows, walk-cycle frame counts, and depth sorting. Its
  assets are proprietary: techniques yes, assets never.

## Explicit exclusions

- Still NO NPCs.
- No engine change. Godot stays; Scott asked and Dalinar's assessment is
  the engine is not the constraint, asset sourcing and art direction are.

## Notes

- The walk-cycle escalation 50ceed18 lineage continues: decision 005's
  generation topology stands unless the team's asset-pack decision
  supersedes parts of it, in which case record the supersession.
- The retro tooling lessons (detach+poll dispatches, first-launch
  verification) are known and being codified separately; don't spend round
  time on framework text beyond what decisions require.
