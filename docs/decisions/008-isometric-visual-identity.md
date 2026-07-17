# 008: Round 005 isometric visual identity (generation, facings, pipeline, shadows, camera)

- **Status:** accepted
- **Date:** 2026-07-17
- **Supersedes:** decision 005's cardinal facing SET (four cardinal facings).
  Decision 005's generation *method* (per-facing generation, deterministic
  assembly, no laundering of frame selection) survives and is extended here.
- **Assignment:** "Make longwalk look like the game in the reference folder: an
  ISOMETRIC, our-own-style world with a believable walking character, a coherent
  art vibe, living flora, and grounded buildings that cast shadows, at a bar
  Scott will accept on sight." Round 004 shipped the mechanics (road-weighted
  pathfinding, a camera rig); this round is the visual identity, rebuilt under
  Scott's isometric override (decision 007) and his own-art ruling, after Scott
  playtested the previous look and rejected it emphatically
  (`seriously-this-is-terrible.png`).
- **Orchestrator run:** `orchestrator-run-20260717-170912`
- **Lane:** full protocol (contested)
- **Workers dispatched:** claude-worker, codex-worker, agy-worker

## Context

Decision 007 fixed the frame Scott imposed: isometric projection with the sim
staying square-grid and projection-ignorant (ALL iso math render-side, any
`src/sim/` change is out of scope by construction), and own generated art only
(no third-party pack ships; the reference folder is the bar and reference-only).
Within that frame, five things were genuinely open going into this round:
generation method for coherent iso sheets, iso facing count and frame-selection
policy, repurposing the ingest pipeline for our own generated sheets, iso
shadows/grounding, and the camera drag-pan rework (Scott's 1720 playtest
refinement: replace round-004's right-click point-recenter with map panning,
right-click-drag being the requirement).

This is the record of what three blind proposals, three adversarial critiques,
and a four-ballot vote converged on.

## Proposals (phase 1, blind)

Each worker proposed independently, none having seen another's.

| Worker | Branch | Proposal commit SHA |
| --- | --- | --- |
| claude-worker | `claude/005-proposal` | `adb79abe62ee1e294bfc22dbe5365b7ac8e4f4dc` |
| codex-worker | `codex/005-proposal` | `b42081c8a328b8caeb3d38b7d4d13fa8cc4f945c` |
| agy-worker | `agy/005-proposal` | `35d7d342399c634ad4f132f1600708d6694e6d6c` |

- **claude-worker** framed the rejection as a *staging* problem isometric fixes.
  A render-side projection module (`src/render/iso/`), sim untouched, with
  Godot's `y_sort_enabled` fed projected positions so iso depth "falls out for
  free." Generation via **coherent plates** (per-family sheets plus
  carry-forward reference). **4 diagonal facings** (data-driven to extend to 8)
  on walk-sheet cost. Proposed **dropping `move_and_slide`** for fractional
  grid-space steering. Drag-pan as a new `DRAG` camera state. Claimed the render
  spine + camera.
- **codex-worker** proposed a **style-board-led** generation flow: a non-runtime
  dressed style board as the single visible coherence reference, then compact
  category sheets plus individual large/collision-sensitive buildings, and
  **8 per-facing walk grids** tied to one neutral character master. Caught that
  camera bounds must come from the projected diamond corners, not
  `_layout.pixel_size()`, and that Y-sort needs a stable placement-id tie key.
  Kept movement/collision authoritative. Claimed the generation pipeline.
- **agy-worker** proposed **full-sheet coherent generation** (lock scale,
  perspective, lighting of many objects in one physical render), **8 facings**
  with strict blind slicing, a **generated shadow sheet**, and drag-pan on the
  round-004 rig it authored. Claimed the camera + ingest + picking.

## Critique (phase 2, adversarial)

Critique SHAs: claude `e54a3358348f09053f1df79355d73f1c807517d6`, codex
`dec9f002976d61ea3ff0745e6ef55025db015e1c`, agy
`966c4381a0d0b367dc5ba75f1da62b66da68ac66`.

The round was genuinely adversarial and produced real, load-bearing findings:

- **Phantom files (claude, orchestrator-verified against the round base).** All
  three proposals named files that do not exist on the integration base.
  `ingest_kenney_roguelike.py` was dropped with the round-004 art slice per 007;
  `build_walk_comparison.py` and `capture_art_acceptance.gd` never existed. The
  real files are `tools/art/build_player_walk.py`, `tools/art/process_assets.py`,
  `tools/art/check_walk_sheet.py`, `tools/art/capture_player_walk.gd` (with
  `test/art/test_check_walk_sheet.py`).
- **Facing count (claude conceded).** claude's own math undid its 4-facing
  choice: a grid-axis road step projects to a screen angle of
  `atan2(TILE_H/2, TILE_W/2) ~= 27deg`, whose nearest 4-facing pose is 45deg, so
  the character walks the most-common path permanently ~18deg off its facing (a
  constant skate). 8 puts a pose within 22.5deg of every direction.
- **Camera bounds (claude conceded to codex).** `camera_rig_2d.gd` computes
  `limit_*` and `min_zoom` from `_layout.pixel_size()` as an axis-aligned
  rectangle; under iso the walkable diamond does not inscribe that rectangle, so
  bounds must come from the four projected corners.
- **Y-sort hardening (claude conceded to codex).** Bare `y_sort_enabled` on
  projected Y leaves same-row ties to unstable tree order and mis-sorts a
  tall/multi-cell building whose single front anchor sorts the whole sprite;
  needs a stable placement-id secondary key and a footprint-aware occlusion
  contract, tested with the actor at every footprint edge.
- **agy drag-pan bugs (claude + codex).** No `/zoom` divide (screen pixels vs
  world units, wrong at every zoom except 1.0); FOLLOW `_process` overwrites the
  pan every frame unless an explicit DRAG state transition occurs; `pan_drag`
  bound to RMB without retiring the existing `focus_view` RMB bind double-fires.
- **Camera ownership (unanimous split).** claude *withdrew* its "fold the camera
  into my render spine" overreach; codex and agy both hold that the round-004
  rig author (agy) owns the drag-pan state machine, consuming a frozen
  render-side `projected_bounds()` + `screen_to_cell()` contract from the
  projection owner.
- **Movement (codex attacked claude).** Dropping `move_and_slide` invalidates
  tests that assert exact footprint collider geometry against `TILE_SIZE` and
  creates "two movement truths," bad for the planned headless server sim and the
  ecology dynamic-obstacle work.
- **Shadow method (mutual).** claude/codex attacked agy's generated shadow sheet
  as non-deterministic (a shadow that can disagree with the accepted silhouette,
  reintroducing the float defect); agy attacked codex's offline shear as
  mathematically detaching the roof shadow (006 rejected runtime facade shear for
  exactly this).
- **Constitution conformance.** claude checked all three: no determinism, no
  sim/render, no cross-platform violation. Nothing to escalate to Scott.

## Decision (phase 3, synthesis)

Converged in critique (no ballot needed):

1. **8 facings.** Supersedes decision 005's four-cardinal set. Frame-selection is
   blind code committed *before* any final generation: transform sim-space motion
   into projected screen space, quantize `atan2` to eight fixed 45deg sectors
   with a documented boundary convention, map to immutable facing ids, advance a
   six-frame cycle from accumulated distance traveled (not wall-clock), freeze on
   a neutral frame at rest. No frame is ever chosen because it looks better in a
   direction. Mirroring only if declared in the manifest before generation.
2. **Render-side projection spine, sim untouched.** A render-only projection
   module (`src/render/...`, pure `cell_to_screen`/`screen_to_cell`), ground
   diamonds in a non-y-sorted base layer, one y-sorted world-object layer for
   player/flora/buildings each anchored at ground-contact, sorted on projected
   contact Y with a **stable placement-id secondary key** and a **footprint-aware
   occlusion contract** for multi-cell buildings. No projection symbol or screen
   coordinate enters `src/sim/`.
3. **Camera ownership split.** claude's projection module exposes
   `projected_bounds()` (from the four projected diamond corners plus sprite
   headroom) and `screen_to_cell()` as a **frozen render-side contract**; agy's
   rig consumes them. agy owns the DRAG state, the click-vs-drag pixel threshold,
   `relative / zoom` panning, retiring `focus_view` as the primary verb,
   cursor-preserving zoom, and the `project.godot` binding.
4. **Pipeline names the files that exist.** CREATE a new generic
   `tools/art/ingest_generated_sheet.py` (manifest-driven: prompt provenance,
   grid geometry, cell roles, magenta key, per-cell ground-contact anchors,
   expected dims, output ids; rejects missing provenance, wrong grid, edge-touch,
   empty cells, undeclared runtime assets). Make `process_assets.py` and
   `build_player_walk.py` manifest-driven (drop hard-coded asset lists and the
   cardinal Option-C policy; the processor may normalize by declared feet/contact
   anchor but never choose aesthetically preferred frames). Retarget
   `check_walk_sheet.py` and `capture_player_walk.gd` for the iso 8-facing sheet
   and real-engine acceptance capture. Author the walk-preview / before-after GIF
   producers fresh (there is no `build_walk_comparison.py` to rename). No
   third-party pack appears in any merged result.

Decided by four-ballot vote (all 4-0; the critic seat is invoked only on a 2-2
split per decision 004, so it was correctly not invoked):

5. **Q-A Generation method -> BOARD-LED (4-0).** A non-runtime style board as the
   single visible coherence reference, then compact category sheets where cell
   geometry is shared, with large/collision-sensitive buildings generated
   individually against that same board, and the 8-facing walk as per-facing
   grids tied to one accepted neutral character master. Full-sheet was rejected
   because it starves buildings and the 48-cell walk of resolution, correlates
   every extraction failure (one bad cell rejects the sheet), and makes
   single-building regeneration destructive. Drift is bounded by a real-camera
   composition gate that rejects whole passes. Grafted from the losing side:
   agy's insistence that coherence needs one *shared render context* is honored
   where it matters (compact families sharing cell geometry render together), and
   agy's blind-slicing / regenerate-never-relaunder policy survives at category
   and per-facing granularity.
6. **Q-B Movement authority -> KEEP-AUTHORITATIVE (4-0).** Movement and collision
   stay authoritative in the existing logical square world space (`move_and_slide`
   and the tested footprint-collider contract retained unchanged); the render
   layer projects a display proxy. The projection is render-side and the sim
   stays square, so there is no physics-through-a-diamond problem that dropping
   physics would solve. This keeps the sim runnable headless on a server (no
   dependency on a render node's fractional interpolation) and honors the tested
   collider geometry. Inverse projection is used only at the input boundary.
7. **Q-C Cast/silhouette shadow -> OFFLINE-DERIVED (4-0), with agy's constraint
   grafted in as binding.** Contact and cast shadow masks are derived
   deterministically from the cleaned accepted alpha under one shared fixed light
   vector in `process_assets.py`, so each shadow is a pure function of the art it
   grounds. The processor MUST NOT naively shear the full iso sprite alpha: the
   cast source is the **ground-contact silhouette** (the bottom footprint slice of
   the mask at the contact line), projected along the fixed light vector on the
   ground plane; the upward-projected roof pixels are excluded, so no shadow
   begins detached at the roof's screen position (this is exactly the failure
   decision 006 rejected). A separate, tighter contact-darkening pass keeps
   objects grounded even where a long cast shadow crosses a similar-valued road.

**What ships this round vs. what is cut.** Ships: the iso projection spine +
reworked ground/building/player render, drag-pan camera + iso picking, iso
shadows/grounding, one board-led coherent asset set (ground + the existing
buildings + a flora family + 8-facing walk), the repurposed pipeline, and the
acceptance artifacts (iso walk GIF + before/after vibe screenshots) for Scott's
visual gate. Cut/deferred: seasons, weather, day/night, animated interiors, NPC
crowds, minimap, generalized authored-map tooling, persistence, and any second
biome. Flora is in scope (asked three times); breadth of flora is not. Flora
animation is deterministic (phase a stable function of authored placement id,
fixed period, roots held fixed, no RNG, no time seed).

**Scott's visual acceptance gate belongs to this round** and is a taste gate no
automated check can substitute for. De-risk it by putting one building + player +
contact shadow in front of Scott early (the five-asset composition spike) rather
than a full town late.

## Division of labor

Capability-matched and unanimous across all three critiques' synthesis
recommendations.

| Piece | Assigned to | Why this harness |
| --- | --- | --- |
| Art generation + full art pipeline: style board, category sheets, individual buildings, 8-facing walk grids, `ingest_generated_sheet.py`, manifest-driving `process_assets.py`/`build_player_walk.py`, deterministic shadow-mask derivation, walk/before-after GIF producers, provenance manifests | codex-worker | Scott's sprite-forge mandate binds the codex seat specifically (`$generate2dsprite`/`$generate2dmap`), and the retro must report whether those skills helped, which only works if codex runs them. The pipeline is tightly coupled to the generation manifests codex authors, so ingest and assembly live with generation. |
| Render spine: iso projection module, `starter_town.gd` render rework, footprint-aware y-sort + placement-id tie key, `screen_to_cell` picking inverse, `projected_bounds()`, keep-authoritative movement with a projected render proxy, `capture_player_walk.gd` acceptance-capture retarget | claude-worker | This is the architectural condition of the whole override (all iso math render-side, sim untouched) and the piece every other slice depends on. It should be owned by whoever defends the sim/render boundary hardest in review; claude did the round-004 road slice and the boundary argument in decision 006. |
| Camera drag-pan rework: DRAG state, click-vs-drag threshold, `/zoom`-correct pan, retire `focus_view` primary verb, cursor-preserving zoom, clamp to `projected_bounds()`, `project.godot` input binding | agy-worker | agy authored `camera_rig_2d.gd` in round 004 (sole `Co-authored-by: Antigravity` on that file), so the FOLLOW/FOCUSED state machine and input context live in its head with the least rediscovery. It consumes claude's frozen projection contract rather than re-deriving projection. |

The projection <-> camera interface (`projected_bounds()`, `screen_to_cell()`)
is frozen between claude and agy before either implements against it. The
manifest/anchor contract is frozen between codex (generator) and claude
(consumer) before final art is generated.

## Dissent

The four-ballot vote was **4-0 on all three contested questions**. No dissent
survived: each minority proposer voted for the winning option and said why in
its own ballot. For the record, the losing *original positions* (each abandoned
by its own author in the ballot) are quoted verbatim below.

**agy-worker's original FULL-SHEET position (Q-A), from its proposal
`35d7d34`, abandoned in ballot `8bcb7c11963a62f3b298ce1e9bccee1886f6d57e`:**

> I propose **full-sheet coherent generation**. We will prompt the generation
> tools to output complete, grid-aligned spritesheets (e.g., an entire
> character's 8-facing walk cycle on one image, or a full village set). The vibe
> gap in previous attempts comes from the model losing context between
> invocations; a single-sheet generation enforces a shared palette, consistent
> lighting, and uniform proportions across all tiles/frames.

agy's ballot conceded: "My peers are correct that a massive single sheet (such
as 48 cells for an 8-facing walk cycle) starves individual assets of resolution
and correlates extraction failures... BOARD-LED is the pragmatic engineering
choice."

**claude-worker's original DROP position (Q-B), from its proposal `adb79ab`,
abandoned in ballot `12c328a9fd902285b0784cdc1dd0c416c2d4f041`:**

> I would drop `move_and_slide` for movement (nav is authoritative; colliders
> become advisory for future dynamic obstacles) rather than try to run physics
> through a diamond.

claude's ballot voted KEEP-AUTHORITATIVE against its own proposal: "My DROP
rested on a premise codex correctly dismantled: that you would otherwise 'run
physics through a diamond.' You would not."

**agy-worker's original GENERATED-SHEET position (Q-C), from its proposal
`35d7d34`, abandoned in the same ballot:**

> *Shadows*: We will use a secondary generated sheet for shadow masks (or extract
> a pure black/alpha layer if the generator provides it), applying it identically
> to decision 006's approach but tailored to the isometric silhouettes.

agy's ballot conceded OFFLINE-DERIVED while its roof-detachment insight was
grafted into the winning option: "OFFLINE-DERIVED is the superior deterministic
method because this detachment can be avoided by casting the shadow only from the
ground-contact silhouette... rather than the upward-projected roof pixels."

No losing objection claimed a constitution violation, so nothing here is
escalated to Scott. The four recorded ballots per question:

- **Q-A:** orchestrator BOARD-LED; claude-worker BOARD-LED (interest: its own
  option); codex-worker BOARD-LED (interest: its own option); agy-worker
  BOARD-LED (interest: FULL-SHEET was its proposal). **4-0 BOARD-LED.**
- **Q-B:** orchestrator KEEP-AUTHORITATIVE; claude-worker KEEP-AUTHORITATIVE
  (interest: DROP was its proposal, voted against it); codex-worker
  KEEP-AUTHORITATIVE (interest: its own option); agy-worker KEEP-AUTHORITATIVE
  (interest: none). **4-0 KEEP-AUTHORITATIVE.**
- **Q-C:** orchestrator OFFLINE-DERIVED; claude-worker OFFLINE-DERIVED (interest:
  its own option); codex-worker OFFLINE-DERIVED (interest: its own option);
  agy-worker OFFLINE-DERIVED (interest: GENERATED-SHEET was its proposal). **4-0
  OFFLINE-DERIVED.**

## Protected paths touched

project.godot

## Sign-offs

Every dispatched worker signs after reading this synthesis. Signing means "I read
the synthesis and accept it as the team's decision," including where it went
against the signer's own proposal.

    Signed-off-by: claude-worker <claude@sentania.net> YYYY-MM-DDTHH:MM:SSZ
    Signed-off-by: codex-worker <codex@sentania.net> YYYY-MM-DDTHH:MM:SSZ
    Signed-off-by: agy-worker <agy@sentania.net> YYYY-MM-DDTHH:MM:SSZ
