# 010: upright render-scale reconciliation (30 deg camera + physical foreshortened height)

- **Status:** accepted
- **Date:** 2026-07-17
- **Assignment:** Round 006 execution (decision 009, Path 3). The primitive
  camera-calibration slice surfaced a conflict between two signed constraints of
  decision 009: constraint 2 (render-camera geometry) and constraint 3 (codex's
  scale contract, adopted wholesale). This record resolves it. It amends decision
  009 constraint 3's upright pixel-height numbers and clarifies constraint 2.
- **Orchestrator run:** `orchestrator-run-20260717-204425` (see TEAM-STATE.md)
- **Lane:** contested design question discovered in execution; resolved by a
  four-ballot with an adversarial critique round (decision 004 voting model).

## Context

Decision 009 chose Path 3: author assets in 3D, render from a fixed isometric
angle to 2D sprites. Constraint 2 required proving the render camera agrees with
`src/render/iso/projection.gd` on a primitive calibration scene, explicitly
"verify the elevation/azimuth rather than copying an angle into prose." Constraint
3 adopted codex's scale contract, which pins the upright axis at
`pixels_per_meter = TILE_H = 64` (one upright meter = 64 px, straight up,
un-foreshortened; player 1.75 m = 112 px, door 2.0 m = 128 px).

agy's calibration slice (`tools/art/blender_calibration.py`, Blender 4.0.2
headless) proved two things by measurement:

1. The 3D orthographic camera (azimuth 45 deg) reproduces Godot's 2:1 `(64,32)`
   ground basis only at elevation **arcsin(0.5) = 30 deg**. Ground-landmark error
   was 0.0002 px at 30 deg and 3 to 28 px at 26.565 deg. The `atan(0.5) ~= 26.565
   deg` figure in decision 009's phase-2 prose is the 2D diamond SCREEN-SLOPE, not
   the 3D camera elevation; the two are different quantities. Constraint 2 already
   said to verify rather than copy the prose angle, and the verified answer is 30
   deg. This record makes that explicit; it is a clarification, not a reversal.

2. At that correct 30 deg elevation, the orthographic camera FORESHORTENS vertical
   world height. Measured upright rate is ~78.4 px per meter, not 64. So a
   physically faithful render and codex's 64 px/m contract cannot both hold.

## The load-bearing geometric constraint

Screen-Y of any rendered point receives contributions from BOTH the ground-depth
axis (scaled by `sin(theta)`) AND the upright-height axis (scaled by
`cos(theta)`), and `theta` is LOCKED at 30 deg by the ground-2:1 requirement. To
keep the ground 2:1 AND make upright = 64 px/m, the required ratio upright/depth is
`sqrt(2)`; the actual ratio at 30 deg is `cot(30 deg) = sqrt(3)`. Because both axes
share the single screen-Y raster axis scaled by one `ortho_scale`, no
projection-stage scalar can compress upright height to 64 px/m without equally
compressing ground depth and breaking the just-calibrated 2:1. Therefore the only
realizations of "keep 64 px/m" (Option A) are:

- **A1:** scale mesh geometry in Z before render (the "squash"). Vertical walls
  survive, but every pitched surface (roofs, chamfers, terrain) has its normal
  rotated toward horizontal, and because lighting bakes into the sprite at render
  time, that shading error is welded irreversibly into every emitted asset.
- **A2:** a non-orthographic / sheared custom projection matrix in Blender
  headless. It preserves true normals (shading happens in world space before
  projection) but replaces the standard ortho camera with a hand-set matrix that
  the compositing/depth/shadow paths are not guaranteed to honor across Blender
  versions: a standing liability incurred to preserve an integer.

"A single anisotropic vertical term in the projection that keeps the ground true"
(the clean path both A-voters proposed in round 1) does not exist for an ortho
camera.

## Decision

**Option B: accept the physically foreshortened upright rate the 30 deg
orthographic camera produces, and revise the scale contract to it.** The upright
rate is the exact analytic constant

    pixels_per_meter_upright = 64 * sqrt(3/2) = 32 * sqrt(6) ~= 78.3837 px/m

which falls straight out of the locked geometry (`ortho_scale` fits the ground so
`P = 64*sqrt(2)` px per world unit; upright rate `= P * cos(30 deg) = 32*sqrt(6)`).
It is a derivable closed form, not an empirical fudge.

Consequences, to be implemented on the round branch:

1. **Camera:** elevation is `arcsin(0.5) = 30 deg` (not `atan(0.5)`), azimuth 45
   deg, orthographic. agy restores this in `blender_calibration.py` and the render
   spec; the ground-grid check stays green.
2. **Contract (`docs/art/scale-contract.md`, codex):** the UPRIGHT axis changes
   from `(0, -64)` / 64 px/m to `(0, -32*sqrt(6))` / `32*sqrt(6)` px/m. Re-derive
   the pixel-height table at the new rate:
   - player 1.75 m -> 137.17 px (was 112)
   - door 2.0 m -> 156.77 px (was 128)
   - eaves 2.4 m -> 188.12 px (was 153.6)
   - ridge 4.8 to 5.6 m -> 376.24 to 438.95 px (was 307.2 to 358.4)
   The GROUND/horizontal projection (`TILE_W=128`, `TILE_H=64`, the 2:1 diamond in
   `projection.gd`) is UNCHANGED; only the upright rate is corrected. `TILE_H = 64`
   remains the tile module; it is simply no longer equal to the upright px/m.
3. **No vertical correction step.** No mesh Z-squash (A1) and no custom projection
   matrix (A2). Assets are authored in real meters and rendered by the standard 30
   deg ortho camera; the render is the single source of truth for upright scale.
4. **Calibration/acceptance gate:** the upright rate is asserted by a golden-height
   check (render a known-height primitive, e.g. a 2.0 m pole, and assert
   `156.77 +/- 2 px` sole-to-crown; keep the height-landmark table check). This
   makes the rate drift-proof: any change to elevation or `ortho_scale` becomes a
   test failure, which fully defuses the "goes stale silently" concern both options
   otherwise shared. This extends decision 009 constraint 7.
5. **Downstream consumers:** codex runs a repository search for any consumer of the
   old upright numbers (64 as px/m, 112, 128, 153.6, 307.2, 358.4) and updates the
   render-contract constants. The simulation layer is meters-only and pixel-blind
   (constitution: sim/render separation), so no sim invariant changes. No pixel
   height is hard-coded in shipped code yet; this is a paper-contract re-derivation.

## Four-ballot vote

Per decision 004, a contested synthesis question collects four ballots
(orchestrator + claude-worker + codex-worker + agy-worker). This question ran in
two passes because the round-1 proposals rested on a geometry that does not exist;
the adversarial critique pass (decision 004's phase-2 analogue) put the coupling
constraint on the table and the team re-balloted.

**Round 1 (blind, stamp `20260717-211241`):** claude A, codex A, agy B,
orchestrator (leaning B on the coupling grounds). The two A ballots explicitly
premised on "a clean rig-level / projection-stage vertical correction that keeps
the ground true."

**Critique + re-ballot (stamp `20260717-211939`):** with the coupling constraint
shown (upright and ground share screen-Y; the clean projection scalar is
impossible; A reduces to A1 or A2), both A-voters withdrew Option A of their own
accord.

**Result: 4-0 for Option B.** Ballots: orchestrator B; claude-worker B;
codex-worker B; agy-worker B. No 2-2 split, so the critic seat was correctly not
invoked (decision 004).

## Dissent

**None survived.** The losing position was Option A (keep 64 px/m via a rig-level
correction), held by claude and codex in round 1 and **withdrawn by both of its own
proponents** once the coupling constraint was surfaced. For the record, per the
rule that losing objections are quoted verbatim, the round-1 Option-A position is
preserved verbatim from claude's round-1 ballot (`/tmp/round006-exec/BALLOT1-claude.txt`,
orchestrator run `20260717-204425`):

> Recommend Option A, implemented not as a per-mesh Z hack but as a single
> deterministic vertical scale baked into the render rig itself (equivalently, an
> anisotropic vertical term in the projection): the ground stays a true 30 deg
> ortho 2:1, and world-Y is compressed by 64/78 so one upright meter lands on
> exactly 64 px.

And claude's own withdrawal, verbatim from its critique
(`/tmp/round006-exec/crit-claude.log`):

> The constraint is correct and it demolishes the specific realization I signed in
> round 1. ... So my round-1 vote rested on a geometry that isn't real. That is the
> honest thing to say first.

No losing objection claimed a constitution violation, so this record is decided by
the team and not escalated to Scott. This decision changes no engine, no
architecture, no dependency, and no constitution text; it is implementation detail
(render-camera geometry and a scale-contract table), squarely the team's call.

## Amends

Decision 009 constraint 3's upright pixel numbers (64 px/m, 112 px player, 128 px
door, 153.6 px eaves, 307.2 to 358.4 px ridge) are superseded by the `32*sqrt(6)`
upright rate and the re-derived table above. Decision 009 is otherwise unchanged;
constraint 2's "verify the elevation" instruction is honored, with the verified
value recorded here as 30 deg.

## Protected paths touched

None. (`docs/art/scale-contract.md` and `tools/art/` are not protected paths;
`project.godot` is not touched by this decision.)

## Sign-offs

Each doer cast a round-2 ballot of B (adversarial critique pass, run
`20260717-211939`); the orchestrator folds those into these sign-off lines.

    Signed-off-by: claude-worker <claude@sentania.net> 2026-07-17T21:21:00Z
    Signed-off-by: codex-worker <codex@sentania.net> 2026-07-17T21:20:30Z
    Signed-off-by: agy-worker <agy@sentania.net> 2026-07-17T21:20:45Z
