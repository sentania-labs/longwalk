# 003: village feel round (walk cycle, click-to-move, zoom, visual feel)

- **Status:** accepted
- **Date:** 2026-07-17
- **Assignment:** one round delivering, in priority order: quality character
  animations (a real multi-facing walk cycle for the PC at minimum, beating
  round 1's named defect of foot alternation judged at shipping size); zoom
  control (scroll-wheel plus keybindable); click-to-move replacing WASD as the
  primary control scheme; and a visual-feel pass toward a Warcraft 2 / Ultima
  Online vibe "but for 2026". Flora as a stretch. No NPCs.
- **Orchestrator run:** `orchestrator-run-20260717-032957` (see TEAM-STATE.md)
- **Lane:** full protocol
- **Workers dispatched:** claude-worker, codex-worker, agy-worker

## Context

Round 1 (`001-town-motion.md`) shipped ambient motion but failed its walk-cycle
half: the art spike was rejected twice, both times for the same defect, the feet
do not reliably alternate at shipping size. Decision 001 step 4 armed a
procedural-bob fallback. The orchestrator escalated rather than shipping it,
because both workers agreed on the record that a bob on a rigid billboard is not
a walk cycle, and accepting it would have redefined the minimum Scott set.

Scott answered escalation `50ceed18` with option 2: spend more spike budget. The
bob fallback is superseded and out of bounds. He folded the walk cycle into this
larger round and added click-to-move as an explicit replacement for keyboard
driving ("NO more keyboard driving").

This is the first live three-doer round and the first real critic vote. Both
seats were created in PR #17 (`002-team-roster-and-critic-seat.md`) and neither
had been exercised.

## Proposals (phase 1, blind)

All three workers proposed independently, in isolated worktrees, none having
seen another's. Verified from end markers, not narration.

| Worker | Branch | Proposal commit SHA |
| --- | --- | --- |
| claude-worker | `claude/village-feel` | `b7faf4046a00871fdd0eb1a39f5bed623fdc4bc1` |
| codex-worker | `codex/village-feel` | `5effb7dbf12ebc1ddbff624c8a6a6deeba96c324` |
| agy-worker | `agy/village-feel` | `05e62658a1a6b0a650328e5e29c921392378dfd8` |

**claude-worker** argued the round-1 diagnosis stops one level short of the root
cause. A 3x4 sheet asks a diffusion model to satisfy constraints that are
relational *between cells* ("cell 3 is cell 1 with the legs reversed"), and
diffusion has no cross-cell state: it denoises one canvas, honoring the grid as a
spatial convention but not a temporal one. Candidate 2 is the proof, since its
revised prompt named the reversal about as explicitly as English permits and the
model still failed it while the unattended rows regressed. So a third 12-cell
wording spends budget on the thing that already failed twice. Proposed six calls
of two figures each (one relational constraint per call), a mechanical rejection
gate (`check_walk_sheet.py`) measuring signed leading-leg reversal calibrated
against the two known-bad sheets, A* in `src/sim/nav_grid.gd` as a pure function,
and a visual-feel pass whose central claim is that the tiling is the problem
rather than the palette (252 identical grass tiles, so the eye finds the grid
instantly). Cut flora to a data hook. Notably declined to claim the art
generation, arguing Codex's harness is natively better for it.

**codex-worker** also abandoned the single-composition sheet, but went per-pose
with the previously accepted pose supplied as a visual reference, one facing at a
time, five source rows mirrored to eight facings. Its central and best move was
relocating the gate: art is accepted in a running game at shipping size, under
motion, at zoom extremes, under partial occlusion, with direction changes, rather
than judged from the raw image. Proposed `src/sim/town_navigation.gd` as a
headless route model, discrete clamped zoom levels with cursor anchoring, and a
coordinated asset refresh plus tighter village clustering. Cut flora unless
priorities 1-3 pass.

**agy-worker** kept the 3x4 single sheet and attacked the defect by changing what
the model is asked to track: a magenta left boot and a cyan right boot, forcing
the attention mechanism to bind the leading-leg constraint to a visual signal,
then recolored to leather brown in `process_assets.py`. Proposed direct steering
for click-to-move (conceding it would wedge on buildings), lerped zoom, and a
`CanvasModulate` golden-hour grade to unify the existing assets.

## Critique (phase 2, adversarial)

| Worker | Critique commit SHA |
| --- | --- |
| claude-worker | `0b70f7b282117f046d84dd4c4dd2ac1541244710` |
| codex-worker | `4bd86c6514f0b68cc38af2fe789d37b9eb71adaa` |
| agy-worker | `67ae2dfdbb21671c1f7b9fe75cc423305aa21301` |

Each worker critiqued both peers. This round did its job: every worker conceded
something material, and no proposal survived intact.

**The exchange that decided the art slice.** Claude conceded agy's colored boots
beat its own pair-per-call ladder, and argued the case better than agy did: the
defect exists because "left leg" and "right leg" are semantically distinct but
visually identical, so the model has no image-space signal to bind the constraint
to. Colored boots change the constraint's *modality* from semantic (dropped
twice) to chromatic (held reliably, since both round-1 candidates preserved one
costume across twelve cells unasked). Claude's ladder only reduced the *number*
of relational constraints and hoped the model spent its budget better; agy's
changes the *kind* so it stops competing for that budget at all. Claude also
verified the recolor machinery already exists and cannot collide:
`process_assets.py:133` `recolor_tunic()` is an HSV mask hue-shift, and
`TUNIC_HUE_RANGE = (40, 80)` is nowhere near magenta (~300) or cyan (~180).

Claude then found the flaw agy missed, and it is load-bearing: **the recolor pass
maps the boots to brown unconditionally**, so a sheet carrying the exact round-1
defect passes through and emerges with the defect, its one diagnostic signal
deliberately destroyed. The hack's whole value was making the failure legible,
and the pipeline's last step makes it illegible again before anyone looks. Agy's
proposal contains no acceptance criterion for the walk cycle at all: not a
script, not a capture, not a stated pass condition. Round 1 failed twice under a
look-at-it-and-judge gate.

Claude further found that **mirroring inverts the color/leg binding**: a magenta
left boot mirrored horizontally is a magenta boot on the character's right side,
so the colored intermediate cannot validate a mirrored row. Only source rows can
be checked.

**Codex on agy:** colored boots do not *guarantee* alternation. A model can keep
magenta on the same screen-side boot every frame, swap which anatomical leg owns
a color, or paint colored light outside threshold ranges; a pixel remap then
removes the evidence without fixing the pose. Correct, and it is why the gate
below is a check on the colored image rather than a trust in the trick. Codex
also attacked agy's click-to-move as knowingly shipping the core interaction
broken: with WASD removed, a destination behind a building is an ordinary click,
not an edge case.

**Codex on claude:** the eight-facing question in reverse (codex defended its own
scope), plus `nearest_walkable` needing a specified search contract, plus the
constitution claim recorded under Dissent below, plus a finding that the repo has
no control-remapping UI, so "keybindable" cannot mean what it appears to mean.

**Claude on codex:** eight facings expands scope along the exact axis that failed
twice, adding the hardest pose class (diagonals have more self-occlusion and a
less canonical prior) to a round that has not cleared the easiest. Chained
reference generation makes drift cumulative rather than independently sampled.
And two findings that changed the plan structurally: the camera is a **child of
the player node** (`scenes/player.tscn:18`), so cursor-anchored zoom cannot work
without reparenting the camera or building a drag-pan system, neither of which is
in any estimate; and codex's labor split puts **two residents in
`src/sim/town_layout.gd`** (protected) in one round, with the nav slice's tests
asserting routes around `cottage_a` at its authored cell while the feel slice
concurrently moves the buildings.

**agy on both:** claude's art strategy leans on an undocumented `image_gen`
image-to-image capability, and a foot-placement check cannot save an animation
whose identity drifts frame to frame. Codex's four-cardinal fallback is
unacceptable for an isometric click-to-move game where diagonal travel is the
norm. Codex's asset refresh will starve priority 1. Agy conceded both of its own
contested positions.

## Decision (phase 3, synthesis)

1. **Art generation: agy's color-coded boots win**, on the 3x4 single-sheet
   composition that already succeeds at costume and baseline consistency.
   Magenta left boot, cyan right boot, recolored to leather brown in post. This
   is a 1-vote proposal that beat two better-resourced ones on the merits, and
   claude's concession is what carried it: changing the constraint's modality
   dominates reducing the constraint count. Codex's reference-image workflow is
   the **fallback** if identity drifts; claude's pair-per-call ladder is the
   fallback below that.
2. **The art gate is claude's check run PRE-recolor, then codex's in-game
   capture as the accept authority.** Grafted from all three. Pipeline order is
   binding and belongs in code comments, because the natural implementation
   (assemble sheet, then validate) does exactly the wrong thing:
   **generate colored, validate per source row pre-mirror and pre-recolor, then
   mirror, then recolor.** The check is a hue-centroid sign-flip in the
   bottom-40% leg region (magenta centroid vs cyan centroid along the stride
   axis, sign must flip between frames 1 and 3): no threshold calibration, a
   direct measurement of the named defect rather than a proxy. The pre-recolor
   image is the artifact of record and is kept under `tools/art/`. Codex's
   in-game capture at 160px under motion, occlusion, and zoom extremes is the
   final accept/reject authority; the script may only reject, never pass.
   Claude's own framing of its script as "the part I care most about" is
   withdrawn by claude and this record adopts the withdrawal.
3. **Three source rows (down, up, side), mirrored to left. Diagonals are a
   stretch.** Codex's eight facings lose. Round 1 produced 0 of 3 acceptable
   rows twice; spending the round's variance on facings 4-8 before facing 1 is
   proven optimizes past the named defect. Deferring is free: diagonals are
   additive rows on the same sheet with the same pipeline, so there is no
   architecture cost to being wrong about the order, only to being wrong about
   the floor. Agy's objection (4-cardinal snapping looks cheap under diagonal
   click-to-move) is real and is answered by making diagonals the first stretch,
   not by deleting them.
4. **Navigation: deterministic grid A* in `src/sim/`, physics and steering
   render-side.** All three converged here once agy conceded. 8-connected,
   corner-cutting forbidden, ties broken on a fixed total order so output is
   byte-identical. `nearest_walkable` gets the explicit search contract codex
   demanded (bounded region, stated distance metric, coordinate tie-break).
   Agy's "the collision and nav must agree by construction, not by runtime
   exception" is the sharpest line in its critique and is adopted as a design
   constraint on the slice: the repath-then-drop escape stays as a backstop, but
   it is not the answer to collider/grid disagreement.
5. **Zoom: player-centered discrete steps with easing, delta-correct.
   Cursor-anchored zoom is cut**, on claude's camera-parenting finding. If Scott
   wants it, it is a camera-rig dispatch with its own scene-contract change.
6. **No building moves this round.** Layout composition is cut from the feel
   pass, on claude's two-residents-one-protected-file finding. Deterministic tile
   variants, contact shadows, and a small finishing grade move the village toward
   the reference without moving a building. The grade is a *finishing* step over
   assets that already agree, not a *unifying* step over assets that do not: a
   `CanvasModulate` multiplies, so pushing it far enough to unify mismatched
   assets crushes the local contrast the Warcraft 2 read depends on. Codex's
   one-building palette-and-projection proof gates any variant generation.
7. **Flora: cut.** All three agreed.
8. **"Keybindable" is interpreted as InputMap actions ready for a later
   remapping UI**, not a remapping UI this round. Codex found the repo has no
   such UI to extend. This is a requirement interpretation and codex was right
   that it must not be presented silently as complete: it is flagged to Scott in
   this record rather than escalated as a blocker, because it does not stop the
   round.

### Ruling on codex's constitution claim against claude

Recorded verbatim under Dissent. The claim has two grounds and this record
splits them.

**The sim/render ground is adopted in full.** `sprite_key` does not go on
`TownLayout`. Sim carries semantic prop kinds and occupied cells; render maps
kind to texture. Codex is right, claude's own proposal conceded the tension
("the sprites it names are render's business"), and codex's remedy is better
than claude's design at no cost.

**The authored-baseline ground is ruled against.** The "no runtime computation"
line lives in CLAUDE.md's "Persistence design (documented only, not implemented
yet)" section, which describes a three-layer persistence model that does not
exist and that the constitution explicitly says not to implement yet.
`TownLayout` today is not that baseline layer. Ground-tile *variant* selection is
presentation, not map data, and the determinism section positively blesses pure
`(seed, position)` sampling as the established pattern.

**Resolution: the `(x, y)` hash survives but moves render-side.**
`starter_town.gd` selects the variant; no sim file and no protected path is
touched for that piece. This is claude's mechanism at codex's boundary, and both
halves were tested in the round: claude proposed hash selection, codex demanded
"keep all texture keys, sprite anchors, camera state, and cursor state in
render." It is not an unreviewed third thing.

This ruling was put to the critic as the specific question its tiebreaker-grade
vote was invoked on. See Critic vote below.

## Critic vote (phase 3)

The critic seat's first live vote. Tiebreaker-grade this round, because the
synthesis touches protected paths. Recorded verbatim, per `roles/critic.md`; the
critic writes nothing itself and the orchestrator commits its vote.

**Verbatim, as returned by the critic.** Quoted rather than restated, per
`roles/critic.md` ("the orchestrator incorporates it verbatim"). The block below
preserves the critic's own wording and typography exactly, including em-dashes,
which the repo style rule forbids residents from writing but which are preserved
here because this is quoted evidence rather than a resident's prose. Editing a
quoted vote to match house style is the same class of act as repointing a stale
sign-off marker: it launders the artifact.

**Model transparency line, as required:** the critic reports Composer (Cursor
Auto / agent router), and reports that no more specific model slug was surfaced.
It **established independence and did not disqualify itself**: Composer is not
Claude-family, so the seat's central purpose (an outside voice on a dispute the
Claude worker is party to, refereed by a Claude-harness orchestrator) holds this
round.

**Outcome: the critic voted WITH the orchestrator's ruling on both questions it
was asked.** That is the referee-plus-critic majority, so no escalation is owed
under "When the critic votes against you". The vote was not a rubber stamp: it
was asked a specific question with the orchestrator's reasoning attached and told
to vote the argument, and it independently contributed a finding no worker made
(see below).

**The critic found something all three workers missed**, which is the clearest
evidence so far that the seat earns its cost: `BuildingPlacement.sprite_key`
**already exists** in `src/sim/town_layout.gd:30` today. Verified against the
tree: the field is declared at line 30 and set in `_init` at line 41. So the leak
codex named is not hypothetical, it is pre-existing debt. This record adopts the
critic's framing: that is not a licence to deepen it, and semantic kinds are the
contract going forward for new props.

> # Critic vote: longwalk round 2 ("village feel"), phase 3
>
> **Model:** Composer (Cursor Auto / agent router). The harness system prompt identifies me as powered by Composer; no more specific model slug was surfaced beyond that.
> **Independence:** Established relative to the Claude worker and the Claude-harness orchestrator. Composer is not Claude-family. I do not disqualify. (Also independent of Codex / OpenAI and Agy / Gemini on this round.)
>
> **Weight:** Tiebreaker-grade (protected paths: `src/sim/`, `project.godot`).
>
> ---
>
> ## Primary vote: Codex critique item 4 (constitution claim)
>
> **I side with the orchestrator's split.** It is legitimate. It is not evasion by relocation.
>
> ### Ground 1 — sim / render (`sprite_key` in `TownLayout`): adopt Codex fully
>
> **Vote: WITH Codex / WITH orchestrator.**
>
> Claude's `PropPlacement.sprite_key` on sim data is a real hard-rule breach. Sim may carry semantic kinds (ground kind, prop kind, building id). Render owns texture paths, anchors, and sprite lookup. Codex's demand to keep texture keys out of sim is correct and load-bearing for the server path.
>
> Note for the record: `BuildingPlacement.sprite_key` already exists in `town_layout.gd` today (`"building_facade"`, `"cottage_facade"`). That is pre-existing debt, not a license to deepen it. New props must not copy the leak; synthesis should treat semantic kinds as the contract going forward.
>
> ### Ground 2 — authored baseline ("no runtime computation"): rule against Codex's violation finding
>
> **Vote: WITH orchestrator / AGAINST Codex's constitution-violation reading.**
>
> Codex overclaims. The quoted "no runtime computation" line sits in CLAUDE.md under **Persistence design (documented only, not implemented yet)**, which also says do not implement that stack yet. ARCHITECTURE §3.1 describes the *eventual* baseline as shipped static map data (tile ids, terrain, static objects), in contrast to the pre-pivot formula layer. It does not presently bind every presentation choice to a frozen table.
>
> `TownLayout` today is not that persistence baseline. It is a hand-authored constructor (`build_starter_town()` fills grass, carves path, places buildings). Semantic ground is already `GroundTile.GRASS` / `PATH`. Choosing among visually interchangeable grass textures does not change walkability, occupancy, or anything a future delta layer would override. That is presentation breakup, not map regeneration.
>
> Codex's own phase-1 proposal already allowed "tile variants selected from authored cell coordinates" with a position-derived, order-independent function. The critique then sharpened that into "bake only; hash only offline." That is a reasonable design preference, not a demonstrated constitution breach. Preferring bake-over-hash is style and authoring hygiene; calling the hash a constitution violation is the overclaim.
>
> ### On "relocating the mechanism"
>
> Moving `(x, y)` hash selection into `starter_town.gd` (render) while leaving sim on semantic kinds is **Claude's mechanism at Codex's boundary**, not a third unreviewed invention:
>
> - Claude proposed deterministic `(x, y)` selection and argued determinism correctly.
> - Codex demanded texture keys and camera/cursor state stay render-side.
> - The synthesis keeps the selection function and moves the boundary Codex named.
>
> That fixes the real violation (sim holding render identifiers). It does not smuggle a banned formula layer back into protected sim. A finite 18×14 hash-at-load and a pre-baked variant table are observationally equivalent for players and for future deltas keyed on semantic cell state. Baking remains a valid later authoring cleanup; it is not required to clear a constitution gate this round.
>
> **If the orchestrator had needed escalation:** only if it had ruled that runtime coordinate hashing of *map semantics* belongs in `src/sim/` as a substitute for authored layout. That is not what it ruled.
>
> **Dissent to preserve:** Codex's preference to bake variants into authored data (or an offline authoring step) remains a coherent dissenting design. Record it as losing design preference, not as a sustained constitution finding.
>
> ---
>
> ## Secondary vote: ruling 3 (three source rows vs eight)
>
> **Vote: WITH orchestrator. Three source rows (down, up, side), diagonals deferred.**
>
> Scott's "multi-facing … at minimum" sets a floor. Round 1 spent two attempts and cleared **0 of 3** rows. Expanding to five generated source rows (eight with mirrors) spends variance on facings 4–8 before facing 1 is proven. That optimizes past the named defect.
>
> Diagonals are additive sheet rows; deferring them costs no architecture. Temporary cardinal mapping on diagonal travel is uglier than true diagonals, but still a walk cycle that can pass the named gate. Eight rows of same-leg shuffle would not. Codex's "three as fallback, five as target" inverts the priority order after two failures at the floor. Agy's "better to burn the spike on eight" subordinates the defect Scott named to scope ambition.
>
> Prove three in-game at 160px under motion/occlusion/zoom; then extend.
>
> ---
>
> ## Brief assent on the rest of the intended ruling
>
> | Ruling | Vote |
> | --- | --- |
> | 1. Agy color-coded boots (magenta/cyan → leather in post); Codex reference workflow as fallback | **Agree.** Modality change beats Claude's pair-per-call constraint-budget bet. Claude conceded this. |
> | 2. Claude's check **pre-recolor / pre-mirror** on source rows; Codex in-game capture as accept authority | **Agree.** Recolor without a pre-recolor gate launders the diagnostic. Pipeline order is load-bearing. |
> | 4. Grid A* in `src/sim/`; physics/steering render-side | **Agree.** Agy conceded; two of three had this independently. |
> | 5. Player-centered discrete zoom; cut cursor-anchored | **Agree.** Camera is parented to the player (`scenes/player.tscn`); cursor-anchored zoom needs an unpriced rig change. |
> | 6. No building moves this round | **Agree.** Two residents on `town_layout.gd` with nav tests against a moving fixture is a consensus hazard, not a feel freebie. |
> | 7. Flora cut | **Agree.** All three said so. |
>
> ---
>
> ## Bottom line for the decision record
>
> 1. **Constitution claim:** Split stands. Sim/render ground wins (Codex). Authored-baseline "violation" loses as a constitution finding (orchestrator). Render-side `(x, y)` variant hash is allowed; bake-if-you-prefer is not mandatory this round.
> 2. **Facings:** Three source rows is the plan, not a demotion of an eight-facing target.
> 3. **Independence:** Composer; not disqualified.

## Division of labor

Assigned by capability, argued from each worker's phase-1 claim and from what
phase 2 revealed about each worker's grip on the problem. Claims are input, not
commitments.

| Piece | Assigned to | Why this harness |
| --- | --- | --- |
| Walk-cycle art generation (colored-boot sheet, 3 source rows) plus the in-game capture gate | codex-worker | `tools/art/generate.sh` is literally a bash wrapper around `codex exec`, so the pipeline *is* the Codex harness; codex calls `image_gen` natively rather than through a subprocess that diffs `~/.codex/generated_images` to find its own output. It ran the round-1 spike and holds the context on what those prompts actually did. Claude argued this against its own interest and was right: handing generation to the resident whose theory won would optimize for whose theory it is instead of whose harness it is. Codex also proposed the in-game gate and should own the gate it argued for. |
| `check_walk_sheet.py` pre-recolor validator | claude-worker | Claude found the defect the validator exists to catch (the unconditional recolor laundering a bad sheet), specified the exact check, and demonstrated the vision loop inline by independently identifying the same-leading-leg defect at cell size before reading the spike record. Splitting generate-from-verify puts each half of a generate-and-judge loop with the resident that does that half natively, which is the split claude proposed and the one this record adopts. |
| `src/sim/` navigation (grid A*, `nearest_walkable` contract) plus click-to-move controller and click feedback | claude-worker | The piece with a real correctness surface: a pure function, a determinism obligation claude argued rather than inherited, a protected path, and tests that mean something. Claude's proposal is the one both peers named as the right basis (codex: "Claude's navigation core is the right basis"; agy conceded to it). Its consequences land two dispatches out, since NPC schedules path on this grid. |
| Zoom control plus the visual-feel pass (tile variants render-side, contact shadows, finishing grade) | agy-worker | The two most separable items in the round: neither blocks nor is blocked by the art spike or the nav grid, so a genuinely independent lane is worth more than any resident's having read the references. Claude proposed this split explicitly and argued it on scheduling rather than politeness. Agy's own feel instincts (warm grade, immediate click reticle) are here, chastened by the ruling that the grade finishes rather than unifies, and agy claimed the zoom/input lane in phase 1. |

Agy's proposal won the round's central art argument and agy does not own the art
slice. That is deliberate and is not a slight: the winning *idea* is agy's and
the record says so, but the winning *harness* for executing an `image_gen` loop
is codex's. Owning an idea and owning its implementation are different questions,
and conflating them is how a round rewards authorship instead of outcome.

All three slices need one agreed player origin, feet anchor, world scale, and
test fixture before implementation begins. Codex named this and it is adopted.

## Dissent

### codex-worker, against claude's proposal, claiming a constitution violation

Recorded verbatim. This objection is **adopted in part and ruled against in
part**; see "Ruling on codex's constitution claim" above.

> **Runtime coordinate hashing is inconsistent with the authored-baseline
> direction and the proposed ownership leaks render identifiers into sim.**
> This attacks Claude's ground variants and `PropPlacement.sprite_key` in
> `TownLayout`. The constitution says the shipped authored baseline is frozen
> static game data with "no runtime computation." Selecting tiles from a hash
> during town construction recreates authored presentation from coordinates
> at runtime, when the result could simply be baked into the authored layout.
> Further, a `sprite_key` is a render asset concern under a sim data type. This
> is a constitution violation in Claude's proposal: it conflicts with the
> authored baseline layer and the hard simulation/rendering separation.
> Instead, commit explicit ground variant and semantic prop-kind values in
> authored data, with render mapping prop kinds to textures. A deterministic
> hash is appropriate in an offline authoring command, not in the shipped
> baseline assembly.

### codex-worker, against claude's proposal, on facing count

Codex's eight-facing scope lost to three source rows. Its own words on the
fallback it offered:

> If generation remains unstable, the honest scope reduction is four cardinal
> facings with diagonal movement choosing the dominant axis. That meets
> multi-facing but makes click-driven diagonal travel less polished, so it is a
> fallback that needs explicit synthesis approval, not a quiet implementation
> shortcut.

This record grants the procedure codex asked for and rules against the default:
three source rows is the plan, diagonals are the first stretch, and four-cardinal
snapping is not authorized at all. Agy's objection to it is sustained.

### claude-worker and codex-worker, against agy's proposal, claiming a constitution violation

Both filed independently, in the required terms. **Agy conceded** in its own
critique ("I concede my Click-to-Move approach (direct steering) is flawed"), so
this objection won and no escalation is owed. Recorded because a conceded
violation claim is still a violation claim, and the concession is the reason it
did not escalate.

claude-worker, verbatim:

> **This is a claim that agy's proposal violates the constitution.** The rule is
> CLAUDE.md's "Simulation/rendering separation (hard rule)": sim code "lives in
> its own module tree (`src/sim/`) and has zero dependencies on viewport, camera,
> or UI nodes. It must be runnable headless." [...] **(a) Sim moves the player
> body.** "In `src/sim/`, the player entity gains a `target_position`. During
> `_physics_process`, the sim calculates the vector to the target and moves the
> player at `SPEED`." The player is a `CharacterBody2D` in `scenes/player.tscn`
> and moving it means `move_and_slide()`, which is scene physics against
> `StaticBody2D` colliders that `starter_town.gd` builds. Sim cannot move it
> without holding a reference to a scene node, which is a dependency on the scene
> tree the rule forbids, and it cannot run headless in a test that does not
> instantiate the town.

codex-worker, verbatim:

> **The proposed sim movement is architecturally confused and, as written,
> violates the hard sim/render separation.** This attacks the combination of
> `GameState.set_player_target(pos)`, a sim entity moving during
> `_physics_process`, and the render `CharacterBody2D`. There is no current
> `GameState` contract to extend. `_physics_process`, collision response, and
> `CharacterBody2D` movement are scene/engine behavior, while a future
> headless server needs portable intent and route state. The proposal neither
> identifies which layer owns authoritative position nor how the sim result is
> synchronized back to the body. This is a constitution violation in
> Antigravity's proposal: sim/render separation forbids coupling sim logic to
> physics-frame scene behavior.

### agy-worker, against claude's proposal, on the nav/collider mismatch

Agy's objection is **sustained as a design constraint**, not ruled against, and
is recorded because it changed the slice:

> Claude admits that pathing over 128px cells while collision uses exact building
> footprints plus a 64px boundary will cause the player to get wedged against
> corners, because the two systems disagree. Claude's solution is a
> "repath-then-drop escape." This is a band-aid over a fundamental architectural
> mismatch. Shipping a movement system where the player visibly gets stuck on
> invisible collision bounds and then "drops" the route is an unacceptable
> degradation from WASD movement, which worked perfectly. The collision and nav
> must agree by construction, not by runtime exception.

## Protected paths touched

src/sim/
project.godot

## Sign-offs

    Signed-off-by: claude-worker <claude@sentania.net> 2026-07-17T03:46:30Z
    Signed-off-by: codex-worker <codex@sentania.net> 2026-07-17T03:46:22Z
    Signed-off-by: agy-worker <agy@sentania.net> 2026-07-17T03:46:00Z
