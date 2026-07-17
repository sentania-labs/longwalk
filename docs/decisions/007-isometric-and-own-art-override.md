# 007: Scott's isometric + our-own-art override, and the round-004 split

- **Status:** accepted (by Scott's authority, recorded by the orchestrator)
- **Date:** 2026-07-17
- **Supersedes:** decision 006 on grounds 1 (projection) and 2 (asset pack).
  Records the survival and amendment of 006's remaining grounds.
- **Orchestrator run:** `orchestrator-run-20260717-163924`
- **Workers dispatched:** None (directive-authority record; it ratifies Scott's rulings, so there is no worker proposal round to sign)
- **Authority:** Scott, relayed by Dalinar (inbox rulings 2026-07-17 1625 and 1645, cited below)
- **Lane:** not a team synthesis. This record ratifies two external rulings by
  Scott delivered through the Dalinar steering channel and mid-round, after
  round 004's implementation dispatches were already committed. The rulings are
  authoritative; the orchestrator records them and derives the consequences.

## Why this record exists

Two rulings from Scott landed in the orchestrator inbox mid-round and were not
read or acted on by the two runs that followed, because the check-inbox
convention in the orchestrator brief only fires at spawn while those runs were
deep in implementation. They are:

- `.pka/inbound/orchestrator/2026-07-17-1625-dalinar-ruling-art-is-ours.md`
- `.pka/inbound/orchestrator/2026-07-17-1645-dalinar-ruling-isometric-override.md`

Both overturn ground that decision 006 and PR #20's art slice were built on.
This record is the durable supersession so the reversal is not lost again.

## The rulings, verbatim

**Art sourcing (2026-07-17T16:25Z):** Scott, verbatim:

> We can reference outside sources for inspiration on art, etc - but the art is
> our vibe/style.

Consequences the ruling itself states: Tiny Swords declined; the round-004
asset-pack authorization RESCINDED (it was Dalinar's proposed strategy, flagged
for Scott's veto, and vetoed); third-party packs including Kenney, despite clean
CC0, do NOT ship as longwalk art; outside art is REFERENCE ONLY (palette,
proportion, framing, readability, animation timing); shipped assets are
generated/authored by the team in longwalk's own style. Decision 006's Kenney
adoption is superseded on the asset-sourcing ground. In-flight: codex's
pack-ingestion slice pivots to generation; the reddit reference sheets remain
the existence proof that generation can reach the bar; the sprite-forge skills
mandate stands; full-sheet coherent generation (shared palette/lighting across
tiles, props, buildings) remains the method hypothesis to test. Ingest-pipeline
code already built may survive as the ingestion path for OUR generated sheets
rather than third-party packs. The human acceptance gate is unchanged:
side-by-side walk-cycle GIF and before/after vibe screenshots for Scott's eyes.

**Projection (2026-07-17T16:45Z):** Scott, verbatim:

> I veto the group: isometric

Context recorded in the ruling: Scott was walked through the visual difference
between top-down oblique and isometric, including the costs the 4-0 vote weighed
(walk-sheet rework, projection math, depth sorting) and the fact that WC2 is
oblique while AoE/UO/Theme Hospital are isometric. He overrides with full
knowledge of the trade; the diamond view is itself part of what he wants.
Consequences the ruling states: longwalk moves to isometric; decision 006 ground
1 is overridden; the sim/render hard rule is NOT relaxed and is the
architectural condition of the override (sim keeps its square grid, tile
coordinates, and walkability logic untouched and projection-ignorant; ALL
isometric math, world-to-screen diamond transform, screen-to-world picking for
click-to-move, depth/Y-sorting by projected position, lives strictly
render-side; the projection is a view of the grid, never a property of it); art
generation targets isometric sheets and composes with the art-is-ours ruling;
character sheets need the isometric facing set the team judges sufficient
(typically 4 diagonal facings minimum, 8 preferred), that facing-count call is
the team's to make and record. Sequencing is the orchestrator's call.

## Supersession map of decision 006

| 006 ground | Fate | Note |
| --- | --- | --- |
| 1. Orthogonal / top-down, isometric rejected | **OVERRIDDEN** (1645) | Now isometric. Sim stays square-grid and projection-ignorant; all iso math render-side. |
| 2. Kenney Roguelike/RPG pack (CC0) | **RESCINDED** (1625) | No outside pack ships. Reference-only. Generation is the method. Kenney assets and their CREDITS entry must not appear in any merged result. |
| 3. Nearest-neighbour render flip at fixed art scale | **STANDS** | Confirmed by 1645 ground 4. Now targets isometric sheets. Only ships WITH pixel-art assets (see split, below): the flip on our current smooth AI art with no pixel assets makes it worse, not better, so it moves to the art round. |
| 4. Road costs `PATH=1.0 / GRASS=2.25`, heuristic untouched | **STANDS, unaffected** | Sim-side, projection-agnostic. Both rulings confirm. Already implemented and shipping in the round-004 split. |
| 5. Camera FOLLOW/FOCUSED rig, reparented off player | **STANDS mechanically; amended** | State machine, follow, pan, spacebar recenter survive. Click-to-focus PICKING retargets to projected coordinates (iso screen-to-world) as a render-side amendment in the art round. Current orthogonal picking is correct for the still-orthogonal shipped render until the flip lands. |
| 6. Preprocessed per-asset shadow masks, one light vector | **STANDS as approach; regenerate** | Masks regenerate for isometric building sprites (1645 ground 4). Part of the art round. |
| 7. Decision 005 walk topology stands | **METHOD stands; facing set superseded** | Per-facing generation, colored boots, deterministic assembly survive. The FACING SET changes: isometric needs diagonal facings (4 minimum, 8 preferred) where 005 shipped cardinal. The art round records the facing-count call and the 005 facing-set supersession in its own decision. |
| 8. Pixelization is not gait evidence | **STANDS, unaffected** | Principle survives untouched. |

The constitution-violation resolution in 006 (no `src/sim/` file acquires a
projection; if an art pack forces a change in `src/sim/`, the pack is wrong, not
the sim) is REINFORCED by 1645, not weakened. Isometric was previously rejected
partly to keep projection math out of `src/sim/`; Scott's override keeps that
protection as its explicit architectural condition. The rule stands unchanged:
all projection math lives render-side, the sim grid never learns it is being
drawn as a diamond.

## The round-004 split

PR #20 as assembled ships Kenney assets and an orthogonal composition proof,
both overturned. It cannot merge as-is. Per 1645's explicit allowance to grow or
split the round, the round is **split**, not amended into one growing PR:

- **Round 004 (this branch) is reconstituted to the projection-agnostic
  survivors only** and ships reqs 4 and 5:
  - Road-weighted routing (`src/sim/`, req 4), claude-worker, reviewed SHA
    `49eb63a`, signed by agy-worker. Sim-side, unaffected by either ruling.
  - Camera FOLLOW/FOCUSED rig + right-click focus (req 5), agy-worker, reviewed
    SHA `77846f8`, signed by claude-worker. Render-side mechanics; orthogonal
    picking is correct for the current render.
  - The round branch is reset to `b9d1d46` (the post-road+camera integration
    state, which preserves decisions 006 and this record and both signed
    slices) plus this record. The Kenney art slice (`34db981` / merge
    `aa109d5`) and the moot walk-capture fix (`aad6125b` / merge `b6bf7a0`,
    which only serviced the now-moot orthogonal walk-capture acceptance
    workflow) are dropped from the branch tip. No reviewed SHA is rebased;
    the dropped slices are simply not integrated.
  - Reqs 4 and 5 are mechanical and testable and carry NO Scott visual gate.
    Round 004 merges on the normal gates (peer sign-offs present, CI green,
    external Codex review, consensus gate against decision 006 grounds 4/5,
    which are unaffected).
  - The moot acceptance artifacts (`docs/art/round-004-walk-comparison.gif`,
    `round-004-before.png`, `round-004-after.png`, `round-004-acceptance.md`)
    are NOT presented to Scott and do not ship. They were built on Kenney art
    and orthogonal projection, both overturned.

- **The art work is re-planned as round 005**, a fresh full-protocol contested
  round under fixed constraints from these rulings (see next section). It
  carries reqs 1 (walk cycle), 2 (art vibe), 3 (flora), 6 (building silhouette
  shadows), 7 (grounding + contact shadow), plus the render-flip (now targeting
  iso sheets), the camera iso-picking amendment, and the repurposed ingest
  pipeline. It gets its own decision record, its own PR, and its own external
  review. Scott's visual acceptance gate (walk-cycle GIF, before/after vibe
  screenshots, now with isometric eyes) belongs to round 005, not round 004.

## Round 005 scope (the art re-plan), for the next run to dispatch

Fixed by Scott, not up for team debate:

- **Isometric projection.** Sim stays square-grid and projection-ignorant. All
  world-to-screen diamond transform, screen-to-world picking, and depth/Y-sort
  by projected position live render-side. If any slice needs a change in
  `src/sim/`, the slice is wrong (006's rule, reinforced).
- **Own generated art only.** No third-party pack ships. Reference folder
  (`/home/scott/claude/vault/tmp/longwalk-inputs`, predominantly isometric:
  AoE, UO, Theme Hospital, the reddit vibecoded city-builder sheets) is the bar
  and is REFERENCE ONLY. The reddit sheets are the existence proof and the
  generation TARGET (coherent full sheets, shared palette/lighting), not
  per-sprite piecemeal generation.
- **Sprite-forge mandate stands.** The codex seat exercises its
  `$generate2dsprite` / `$generate2dmap` skills; the round retro reports whether
  they materially helped.

Genuinely contested, for phase-1 blind proposals:

- The generation method for coherent isometric sheets (full-sheet coherent
  generation vs. per-asset with a shared palette/lighting harness). The vibe gap
  so far may be a METHOD problem, not a capability problem.
- The isometric facing count: 4 diagonal minimum vs. 8 preferred, and the
  frame-selection policy fixed in code before generation (006 ground 7's
  no-laundering rule carries forward). This call supersedes decision 005's
  cardinal facing set; the round-005 decision records that supersession.
- How the existing ingest pipeline (`tools/art/ingest_kenney_roguelike.py` and
  the generic `process_assets.py` / `build_player_walk.py` /
  `build_walk_comparison.py` / `capture_art_acceptance.gd`) is repurposed to
  ingest OUR generated sheets. The 1625 ruling explicitly allows this code to
  survive retargeted. The Kenney-specific entrypoint is renamed/rewritten; the
  generic tooling survives.
- The isometric shadow-mask and grounding/contact-shadow approach for the new
  sprites (006 grounds 6 and 7, regenerated for iso).

## Protected paths touched

src/sim/
project.godot

These are round 004's paths (road in `src/sim/`, camera input map in
`project.godot`), authorized primarily by decision 006 grounds 4 and 5, which
the rulings leave standing, and co-affirmed by Scott's directive authority
recorded here. Round 005's protected-path art work (render-side plus
`project.godot`, no `src` sim change permitted under the isometric override)
will be authorized by the round-005 decision record with four ballots and both
agents' sign-offs before any of it merges.

## Sign-offs

This record ratifies Scott's authority rulings and does not itself decide a
contested team question, so it takes no four-ballot vote. The round-005 decision
record it scopes WILL carry four ballots and both agents' sign-offs before its
protected-path work merges, per the constitution and decision 004.

Recorded-by: orchestrator (run `orchestrator-run-20260717-163924`), 2026-07-17
Ruling-authority: Scott, relayed by Dalinar (1625 and 1645 inbox files, cited above)
