# 006: asset pack, rendering model, and the round-004 visual reset

- **Status:** accepted
- **Date:** 2026-07-17
- **Assignment:** round 004, "make it look like a game" (Scott's playtest of build 29564548380, relayed by Dalinar 2026-07-17T12:30Z)
- **Orchestrator run:** `orchestrator-run-20260717-140052`
- **Lane:** full protocol
- **Workers dispatched:** claude-worker, codex-worker, agy-worker

## Context

Scott playtested round 003 and returned a mixed verdict: the machinery was
good, the game was not. Seven findings came back as requirements, not
suggestions. The two that shape this record are requirement 2 ("no visible
change in art vibe" despite the Warcraft 2 / Ultima Online direction) and
requirement 3 (flora, now hard, asked for three times and cut once by decision
003).

Scott also authorized a strategy change that the team had not had before:
**licensed CC0 or CC-BY asset packs may be adopted as a base layer**, with AI
generation reserved for custom pieces. He flagged "which pack(s)" as the
likely biggest single unlock for the vibe gap and as a contested phase-1
question. He was right that it was contested. All three doers picked a
different pack, and all three picks turned out to have a defect that only the
critique round surfaced.

This record rules on the pack, the projection, the rendering model, and the
road-cost formulation. It does not rule on the walk cycle's topology, which
decision 005 already governs and which survives this record intact.

## Proposals (phase 1, blind)

Each worker proposed independently, in its own worktree, none having seen
another's.

| Worker | Branch | Proposal commit SHA |
| --- | --- | --- |
| claude-worker | `claude/004-proposal` | `7ab3585fcae70faa50df13adef821925a86cfd89` |
| codex-worker | `codex/004-proposal` | `71d9d31b02aab16e6fcdaff77e51dcf26aaa8f39` |
| agy-worker | `agy/004-proposal` | `25473e73e3808d5dd44b41d7ca577a67247f36cb` |

**claude-worker** argued the vibe gap is a *rendering-model* gap rather than a
palette or projection gap: `project.godot` renders smooth LANCZOS-resampled AI
art at arbitrary non-grid sizes with linear filtering, while every reference
Scott supplied is pixel art, so no color grade can reach the references because
we are not making the same kind of image. It proposed staying top-down (Warcraft
2 is not isometric), flipping to nearest-neighbour at a fixed art scale on the
pack's grid, and adopting an LPC subset as primary with Kenney CC0 as fallback.
It rejected Tiny Swords on license grounds despite naming it the best vibe match
on the internet.

**codex-worker** proposed one coherent scene rather than seven isolated
patches: keep the authored 18x14 town and its square nav cells, adopt the
rubberduck CC0 grassland and medieval-building packs as one author family, and
gate adoption on a one-camera composition proof before importing a single PNG.
It proposed `PATH = 1.0` / `GRASS = 2.25` road costs, per-building preprocessed
shadow masks under one shared light vector, and six-frame source cycles.

**agy-worker** proposed the Screaming Brain Studios CC0 isometric family (Town,
Overworld, Floor), full isometric projection, `PATH = 1.0` / `GRASS = 3.0`, a
runtime shear for building shadows, and camera decoupling on right-click.

## Critique (phase 2, adversarial)

The critique round did its job, and it is the reason this record does not ratify
any of the three phase-1 proposals.

| Worker | Critique commit SHA |
| --- | --- |
| claude-worker | `874baa43141eb7c85134956ead726a0a65ce02e0` |
| codex-worker | `67cbb4d46a92c4e31254114e1806f4d04fa32c54` |
| agy-worker | `b6bbb5efeb62bb24d31f518f72326f93e9dd7eff` |

Three findings landed independently from two directions each, which is the
signal three blind reads exist to produce:

1. **claude's primary pack fails Scott's authorization.** Both codex-worker and
   agy-worker independently fetched the LPC source page and found that the
   Sharm/Redshrike subset claude called "CC-BY 3.0" is actually offered under
   **OGA-BY 3.0**, a derivative license with different DRM terms. Scott
   authorized CC0 or CC-BY, not attribution-like licenses. claude-worker
   conceded this in its own critique before either peer's landed, writing "On
   licensing, I am third of three."
2. **Isometric art on a square grid is geometrically broken.** Both
   claude-worker and agy-worker attacked codex's plan to crop 128x64 isometric
   diamonds into the 128px square ground contract. A 2:1 isometric building's
   ground contact is a diamond; `BuildingPlacement.footprint` is an axis-aligned
   rect that `nav_grid.gd`'s corner-cutting rule is written to agree with by
   construction. The drawn contact and the collider disagree in *shape*, not
   just size, which reproduces requirement 7's float defect for every building
   in town. codex-worker conceded the projection argument in its own critique:
   "I was too willing to treat projection mismatch as a crop-and-resample
   problem."
3. **codex's road-cost normalization beats claude's, and both peers said so.**
   claude proposed `PATH = 0.6` / `GRASS = 1.0` and built a section around the
   observation that a sub-1.0 edge cost breaks `octile_distance()`'s
   admissibility and therefore the determinism argument in `nav_grid.gd`'s
   header. The observation is correct. The design that needs it is claude's
   own: with codex's normalization the minimum multiplier is exactly 1.0, the
   heuristic stays admissible and consistent untouched, and the hazard never
   exists.

Other findings that shaped the ruling: agy's claim that the Screaming Brain
packs "include abundant trees, bushes, and flowers" is **false** (claude checked
all three named packs: buildings, roofs, floors, and forest *terrain tiles*, no
flora props with silhouettes or ground anchors), and flora is a hard
requirement. agy misread decision 005 as accepting Option C when it accepted
Option B and held C in reserve. agy's camera plan (setting a child's
`global_position` to decouple it) does not work in Godot, and its snap-back-on-
left-click inverts requirement 5's "independent of where the character is
pathing".

## Decision (phase 3, synthesis)

**The synthesis is a position no worker proposed in phase 1 and all three
converged on in phase 2.**

1. **Projection: stay orthogonal / top-down. Isometric is rejected.** Warcraft 2
   is on Scott's reference list and is not isometric: it is an axis-aligned
   top-down grid with buildings drawn in oblique three-quarter. Isometric needs
   exactly the four diagonal facings decision 005 deferred and makes the shipped
   cardinal rows wrong for ordinary road travel, discarding the most expensive
   artifact this team has produced in the round whose first requirement is to
   improve that artifact. It would also force projection math into `src/sim/`,
   which is a constitution violation (see Dissent).
2. **Pack: Kenney Roguelike/RPG pack (CC0).** <https://kenney.nl/assets/roguelike-rpg-pack>
   This is the intersection of "orthogonal" and "license-clean", and it is where
   all three doers landed once LPC failed licensing and isometric was rejected.
   It was claude's own fallback ("it cannot fail on licensing"), codex's
   recommendation on finding the OGA-BY problem ("use Kenney CC0 as the licensed
   orthogonal baseline"), and agy's synthesis pick. CC0 means no per-file
   provenance archaeology and no carve-out to substantiate. `CREDITS.md` records
   it anyway, with source URL and license, because Scott's assignment requires
   credit even where the license does not.
   - **LPC is rejected** on OGA-BY. **rubberduck and Screaming Brain are
     rejected** on projection, not license: both are genuinely CC0 and both stay
     on the table if a future round moves to isometric.
   - **Tiny Swords is escalated to Scott, not adopted.** claude named it the
     closest thing on the internet to what Scott is asking for, and its license
     forbids redistribution even modified, so a public repo with the PNGs
     committed is out. Scott should decline it knowingly rather than never see
     it. See "Open escalations" in TEAM-STATE.md.
3. **Rendering model: flip to nearest-neighbour at a fixed art scale on the
   pack's grid.** This is claude's central claim and it survives: the gap is
   that we are not making the same kind of image as the references. `project.godot`
   and `tools/art/process_assets.py` change. **But codex's sequencing objection
   is adopted**: the flip is a project-wide art-direction migration, not a pack
   integration, and it lands *first and alone*, gated on a composition proof that
   includes the actual traveller, one shadow, a path transition, and y-sorted
   flora at shipping zoom. The current pipeline stays intact until that proof
   wins.
4. **Road costs: `PATH = 1.0`, `GRASS = 2.25`, heuristic untouched.** codex's
   numbers. The invariant `min(TERRAIN_COST.values()) >= ORTHOGONAL_COST` gets a
   comment at the cost table **and a test**, per claude's C6: without it, the
   next person who "tunes the road down to 0.8" reintroduces claude's bug and
   every existing test still passes. Cost is charged on entering a cell. No
   proposal's stronger claim survives: weighting is a *preference*, and a long
   enough road detour still loses to a short grass crossing. Say that, do not
   claim the traveller leaves roads "only when the destination forces it".
5. **Camera: FOLLOW / FOCUSED state machine, camera reparented off the player.**
   Right-click sets focus and holds it across route changes (codex's persistence,
   against agy's snap-back). Space `center_on_player` returns to FOLLOW (claude's
   keybind, against codex's no-exit trap). A camera parented to the player cannot
   be independent of the player; the reparent breaks `player_controller_2d.gd:299`'s
   zoom path, which routes through the new render-side rig.
6. **Shadows: preprocessed per-asset masks, one shared light vector.** codex's
   answer over claude's runtime shear of the full facade, because shearing a
   facade alpha treats every visible pixel as one vertical plane and turns roof
   overhangs into stretched duplicates. claude's separation of *cast* shadow from
   *contact* shadow is grafted in and is the fix for requirement 7: the current
   blob is too big, too soft, and too centred to read as contact.
7. **Decision 005 stands, unamended.** Option B (per-facing generation, colored
   boots retained, deterministic assembly, unchanged pre-recolor gate, mirror,
   recolor) is the ruling; Option C stays in reserve. Two things this record
   forbids: agy's execution of Option C as though it were the ruling, and codex's
   six-to-four frame downsample as an "implementation detail". Six-frame source
   generation is authorized **only** with a frame-selection policy fixed in code
   before generation (claude's C4: the selector must be blind to the gate's
   verdict, or it is the same laundering shape codex itself correctly refused).
   Any change to source frame count or grid shape supersedes 005 explicitly, in
   its own record.
8. **Pixelization is not gait evidence.** claude proposed pixelizing at pack
   scale as itself a gait improvement. codex's attack is adopted: downsampling
   cannot add a missing passing pose, lengthen stride, or fix planted-foot
   motion, and re-running the alternation gate only proves leading-leg color
   still reverses. Pixelization is a style transform applied after gait passes,
   never the gait fix. The side-by-side GIF is the go/no-go evidence, and per
   Scott it is judged by Scott: it is evidence, not a gate, and nobody argues a
   GIF into a pass.

## Protected paths touched

src/sim/
project.godot

## Division of labor

Divided by capability and by what does not depend on the pack, so three slices
can run in parallel rather than queueing behind the art.

| Piece | Assigned to | Why this harness |
| --- | --- | --- |
| Road-weighted routing (req 4), `src/sim/` | claude-worker | It wrote the admissibility analysis that makes this slice's correctness argument, and it is the resident that identified the cross-file invariant the tests must pin. Pure sim, headless, no pack dependency, so it runs now. |
| Camera rig, right-click focus (req 5) | agy-worker | It owned the zoom and input-controller slice in round 003, and both peers conceded the ownership claim was right even while killing its design. It inherits the synthesis's semantics, not its own. No pack dependency. |
| Pack ingestion, rendering-model flip, composition proof (reqs 1, 2, 3 assets) | codex-worker | Scott mandated the codex seat exercise `$generate2dsprite` / `$generate2dmap` this round, and this is the slice those skills exist for. It is also the resident that argued for proof-before-adoption, which is the shape this slice now has. The long pole. |

Flora placement (req 3) and the walk-cycle work (req 1) sequence *after* the
composition proof, because both consume the pack and the art scale it settles.
They are not in this round's parallel wave.

## Dissent

No worker's objection was overruled. The three phase-1 positions on the
contested pack/projection question were each defeated by a peer's finding that
its author then conceded in writing, so this section records concessions rather
than live dissents.

**claude-worker, conceding its own primary pack, verbatim:**

> Both peers' license work is honest and neither has planted a license landmine.
> codex went further than required by proactively naming and rejecting an
> adjacent SA-licensed pack it wanted, which is the behavior the round is
> supposed to reward, and I want that on the record because my own proposal's
> primary pack (LPC) is the one in this round with a **real** license problem:
> LPC's blanket terms are CC-BY-SA 3.0 dual GPLv3, and my proposal leaned on a
> per-file CC-BY carve-out I flagged as unverified. Both peers found CC0
> families that need no carve-out at all. On licensing, I am third of three.

**codex-worker, conceding the projection argument, verbatim:**

> That preservation argument is stronger than my phase 1 proposal's attempt to
> adapt 2:1 isometric ground art into square top-down cells. I was too willing
> to treat projection mismatch as a crop-and-resample problem. Claude is right
> that a native orthogonal family is a safer basis if Decision 005 remains
> binding.

**claude-worker, conceding the road-cost formulation, verbatim:**

> The sentence is true and the design that needs it is mine. With codex's
> normalization the minimum multiplier is exactly 1.0, so `octile_distance()`
> stays admissible and consistent **untouched**, and the whole hazard I built a
> section around never exists. Making the road cheap by making grass expensive
> dominates making the road cheap by pricing it under 1.0, because it keeps the
> protected file's existing correctness argument intact. I was right about the
> mechanism and wrong about the tuning, and the tuning is what determines
> whether the mechanism matters. Synthesis should take codex's numbers and drop
> my heuristic scaling.

**agy-worker, conceding the defeat of its own isometric proposal, verbatim.**
Its steelman of claude's proposal:

> I concede that Claude's insight about the rendering-model flip is a better
> diagnosis of the visual problem than simply swapping assets, and I concede
> that staying top-down preserves our expensive walk-cycle artifact better than
> moving to isometric.

And its critique's synthesis paragraph, which names both findings that defeated
its phase-1 position:

> I concede to Claude that the rendering-model flip (nearest-neighbor, strict
> pack grid) is the correct diagnosis for the vibe gap. I concede to Codex that
> `PATH=1.0, GRASS=2.25` is the superior A* math.
> Because Claude's LPC license claim fails, and Codex's isometric-on-square-grid
> idea is geometrically broken, the safest path is to use a definitively CC0
> top-down pack (like Claude's fallback Kenney RPG pack or another CC0
> orthogonal set), implement Claude's nearest-neighbor render flip, use Codex's
> A* costs, and preserve the 4-frame Decision 005 walk cycle.

This concession was omitted from an earlier draft of this record. agy-worker
caught the omission during sign-off review and refused to sign until it was
corrected, which is the sign-off gate working as designed: a doer holding the
referee to the verbatim-dissent rule. The refusal is the reason this quote is
here.

**One constitution-violation claim was raised and is resolved by the ruling
rather than overruled.** claude-worker's A5 claimed, in those terms, that
agy-worker's proposal violated CLAUDE.md's simulation/rendering separation,
because agy's stated mitigation for its own top risk was to rewrite coordinate
math in `src/sim/town_layout.gd` for an isometric projection. claude offered its
own withdrawal condition:

> Procedurally: per the round brief, if this objection loses it goes to Scott
> rather than to the orchestrator. I would rather it be answered than escalated,
> and the cheapest answer is one sentence from agy saying no sim file acquires a
> projection, in which case I withdraw it.

The objection did not lose: this record rejects isometric outright, so no sim
file acquires a projection and the condition claude named for withdrawal is
satisfied by the ruling itself. Nothing escalates. The rule stands as claude
stated it, and it binds the pack work: **if an art pack forces a change in
`src/sim/`, the pack is wrong, not the sim.**

claude also conceded the awkward half against itself, and it is recorded because
it is a real wart a later round should fix rather than inherit silently:

> `src/sim/town_layout.gd:18` already holds `const TILE_SIZE := 128` and
> `pixel_size()` at line 84, so a pixel-space concern is already sitting in the
> sim layer today. That is a pre-existing wart, and the fact that it is there is
> probably what made agy's phrasing feel natural. It is an argument for hoisting
> `TILE_SIZE` into the render layer, not for pouring projection math in after
> it.

## Ballots

Per decision 004, contested synthesis questions take four ballots, with the
critic invoked only on a 2-2 split.

**Question: which pack, and which projection?**

| Ballot | Vote | Interest |
| --- | --- | --- |
| orchestrator | Kenney CC0, orthogonal | none, referee |
| claude-worker | Kenney CC0, orthogonal | party: its LPC primary loses, its projection argument and rendering-model claim win |
| codex-worker | Kenney CC0 orthogonal baseline | party: its rubberduck packs lose on projection, its A* costs and shadow masks and sequencing win |
| agy-worker | Kenney CC0, orthogonal, claude's render flip, codex's A* costs | party: its Screaming Brain packs and its isometric position both lose |

**4-0. Decided without the critic**, which is the correct outcome under decision
004 rather than an omission: the seat is tiebreaker-only and there is no tie.
Every doer voted against at least part of its own phase-1 proposal, which is
what makes the unanimity worth something rather than suspicious.

## Sign-offs

Signed-off-by: claude-worker <claude@sentania.net> PENDING
Signed-off-by: codex-worker <codex@sentania.net> 2026-07-17T15:10:03Z
Signed-off-by: agy-worker <agy@sentania.net> 2026-07-17T15:10:00Z
