# Codex critique: village feel proposals

## Claude proposal

### Steelman

Claude's strongest argument is that the round should spend its uncertainty
budget on the known animation defect while giving click-to-move a deterministic,
headless navigation primitive that can survive the next simulation milestones.
Its pair-generation ladder, actual-velocity animation, explicit collider/grid
failure handling, and narrow flora hook form a more disciplined minimum than a
large asset or feature expansion.

The navigation portion is better specified than my proposal in one important
respect: it identifies the existing typed `Sprite2D` boot-flow assertion and
the runtime sprite-offset coupling as concrete integration failures, rather
than leaving them to implementation discovery. I concede both findings and
would carry them into synthesis.

### Attack

1. **The proposed alpha-mask gate cannot establish the claimed leg reversal.**
   This attacks Claude's walk-sheet verification harness. In the down and up
   facings, swapping the anatomical left and right legs need not reverse a
   vertical alpha-mask moment, especially when the boots overlap beneath a
   tunic. For the side facing, a signed horizontal silhouette moment can change
   because of the trailing coat, arm, weapon, or shadow while the same boot
   still leads. Hue stability likewise measures costume color, not character
   identity. The checks may reject gross duplicates, but calling the signed
   test "the actual named defect expressed as arithmetic" is too strong and
   risks another false pass with more authority attached to it. Instead, keep
   structural checks mechanical, label mask moments as diagnostics, and require
   anatomical landmark review on a shipping-size loop. If automation is
   load-bearing, source frames need explicit per-foot markers or masks that
   survive assembly, not an inference from the whole silhouette.

2. **Pair canvases do not make character consistency free, and splitting them
   at a gutter is underspecified.** This attacks Claude's six-call generation
   design. A model can draw the same canonical contact pose twice, swap costume
   details between figures, overlap shadows across the nominal gutter, or vary
   scale within one canvas. Cropping and baseline normalization repair
   translation and scale, but cannot repair camera angle, anatomy, lighting,
   or identity drift. The proposal acknowledges cross-call drift only at the
   fallback rung, although six independent calls already incur it. Instead,
   prove one facing end-to-end first, use image editing from the accepted base
   character if supported, preserve foot labels through processing, and fall
   back to controlled hand-authored limb corrections immediately if the proof
   fails. Do not schedule all six calls on the premise that within-call
   consistency is guaranteed.

3. **Three facings underserve click-driven diagonal movement.** This attacks
   Claude's explicit definition of quality as down, up, and side only. The
   assignment says a real multi-facing cycle "at minimum," but the feel target
   is an oblique Warcraft 2 / Ultima Online presentation and click-to-move will
   naturally produce sustained diagonals. Mapping those diagonals to a cardinal
   row makes the character appear to crab across the ground, particularly with
   actual velocity driving animation. My five source facings and mirroring are
   more expensive, so Claude is right that three is the safer minimum, but the
   synthesis should define three as a fallback acceptance floor, not the target.
   Prove cardinals first, then add up-right and down-right before visual-feel or
   flora work.

4. **Runtime coordinate hashing is inconsistent with the authored-baseline
   direction and the proposed ownership leaks render identifiers into sim.**
   This attacks Claude's ground variants and `PropPlacement.sprite_key` in
   `TownLayout`. The constitution says the shipped authored baseline is frozen
   static game data with "no runtime computation." Selecting tiles from a hash
   during town construction recreates authored presentation from coordinates
   at runtime, when the result could simply be baked into the authored layout.
   Further, a `sprite_key` is a render asset concern under a sim data type. This
   is a constitution violation in Claude's proposal: it conflicts with the
   authored baseline layer and the hard simulation/rendering separation.
   Instead, commit explicit ground variant and semantic prop-kind values in
   authored data, with render mapping prop kinds to textures. A deterministic
   hash is appropriate in an offline authoring command, not in the shipped
   baseline assembly.

5. **The zoom plan claims keybindability that the repository does not have.**
   This attacks Claude's reference to an "existing settings screen pattern."
   The current settings screen exposes window mode and resolution, while input
   actions are static entries in `project.godot`; there is no control-remapping
   UI or persistence pattern to extend. Mouse wheel plus keyboard defaults are
   useful bindings, but they are not user-keybindable. Instead, synthesis must
   either scope and estimate a controls-binding UI and persistence addition or
   explicitly interpret keybindable as InputMap actions ready for a later UI.
   The latter is cheaper but should be escalated as a requirement interpretation,
   not silently presented as complete.

6. **`nearest_walkable` needs a specified search contract.** This attacks a
   smaller gap in Claude's otherwise strong `NavGrid`. Without a maximum search
   region, distance metric, and total tie-break, a click on a roof or outside
   the map can select a surprising entrance-side cell or depend on neighbor
   insertion order. Instead, clamp outside clicks to bounds, search bounded
   cells by Manhattan or octile distance with a coordinate tie-break, and test
   equal-distance candidates. I concede that deterministic A* in sim, no corner
   cutting, and render-side `move_and_slide()` are the right core design.

## Antigravity proposal

### Steelman

Antigravity's strongest idea is to convert an ambiguous visual distinction into
an explicit, machine-detectable signal: colored boots could make pose review
and selective recoloring much easier while preserving the economy of a single
sheet. Its zoom, immediate click reticle, and restrained warm grade are small,
high-leverage feel improvements, and its risk section correctly admits that
direct steering will wedge on buildings.

The colored-foot concept is worth retaining as a diagnostic or source-art aid.
It is better than asking a reviewer to infer left and right from identical brown
boots, but it is not the guarantee the proposal claims.

### Attack

1. **Colored boots do not guarantee foot alternation or foot identity.** This
   attacks Antigravity's load-bearing animation claim. A diffusion model can
   keep magenta on the same screen-side boot in every frame, swap which
   anatomical leg owns a color, duplicate a pose with different colors, or
   paint colored light and shadow outside threshold ranges. A pixel remap then
   removes the only evidence of the error; it cannot turn a wrong pose into an
   alternating gait. The proposal repeats the already-failed single 3x4-sheet
   framing and adds another constraint to it. Instead, use foot colors only in
   source frames and validation, generate or edit opposite phases in controlled
   pairs from one accepted character, inspect anatomical continuity, and retain
   a hand-authored correction fallback. Color replacement must be mask-based
   with edge review, not a broad hue substitution.

2. **The click-to-move design knowingly ships the core interaction broken.**
   This attacks Antigravity's decision that getting stuck behind cottages is
   acceptable. Scott replaced all keyboard driving, so direct steering is now
   the only locomotion path. A destination on the far side of any building is
   an ordinary click, not an edge case, and collision sliding cannot route
   around it. Removing WASD while accepting that failure can strand the player
   and fails priority 2b's basic meaning. Instead, use deterministic grid A*
   over `TownLayout.is_cell_walkable()`, resolve blocked destinations, forbid
   diagonal corner cuts, and provide cancel/replan behavior. Claude's navigation
   core is the right basis.

3. **The proposed sim movement is architecturally confused and, as written,
   violates the hard sim/render separation.** This attacks the combination of
   `GameState.set_player_target(pos)`, a sim entity moving during
   `_physics_process`, and the render `CharacterBody2D`. There is no current
   `GameState` contract to extend. `_physics_process`, collision response, and
   `CharacterBody2D` movement are scene/engine behavior, while a future
   headless server needs portable intent and route state. The proposal neither
   identifies which layer owns authoritative position nor how the sim result is
   synchronized back to the body. This is a constitution violation in
   Antigravity's proposal: sim/render separation forbids coupling sim logic to
   physics-frame scene behavior. Instead, sim should expose pure navigation and
   route progression data; the render controller should convert mouse to world,
   steer the body, call `move_and_slide()`, and report waypoint outcomes.

4. **Raw world coordinates are not a sufficient movement contract.** This
   attacks Antigravity's instruction to send `get_global_mouse_position()` to
   sim. The authored world is a cell layout with blocked building footprints
   and bounds. A pixel coordinate alone does not define outside-map clamping,
   blocked-click resolution, deterministic equal-cost routing, or the relation
   between sim footprints and render colliders. Instead, define explicit
   world-to-cell and cell-center conversions at the navigation boundary and
   test those conversions at tile edges and bounds.

5. **The zoom proposal omits the two repository-specific failure modes and
   also overstates keybindability.** This attacks Antigravity's generic lerp
   design. `starter_town.gd` applies camera limits in town world coordinates,
   so zooming out can expose limit behavior when the visible rect approaches
   the whole town. Repeated `lerp(current, target, constant)` is frame-rate
   dependent unless the weight accounts for delta. Also, adding InputMap
   actions does not make them rebindable through the current display-only
   settings screen. Instead, use discrete clamped levels, delta-correct easing,
   test edge limits, and resolve the missing remapping UI requirement explicitly.
   I concede that the camera rig, not sim, is the correct owner.

6. **The feel pass is a tint, not a composition pass.** This attacks
   Antigravity's claim that prompt wording plus `CanvasModulate` delivers the
   requested Warcraft 2 / Ultima Online feel. The current repeated square
   ground, sparse building layout, hard path transitions, absent contact
   shadows, and projection coherence remain unchanged. A golden-hour tint can
   muddy UI-independent world colors and make separately generated lighting
   less coherent rather than more. Instead, prove a coordinated in-game
   palette and projection with the player, one building, one path junction,
   contact shadows, and smoke; then add authored ground variants and tighter
   clustering. Apply a subtle grade only after asset-level lighting agrees.

7. **Flora records should be semantic authored placements, not vaguely
   "static entities."** This attacks Antigravity's stretch design. Trees and
   bushes need defined collision footprints, y-sort anchors, and render asset
   mapping, but pushing sprite origins into `TownLayout` would leak render data
   into sim, while treating every tuft as an entity anticipates ecology and
   persistence work that is explicitly not designed. Instead, keep semantic
   prop kinds and occupied cells in authored sim data, and keep texture, origin,
   and sprite processing in render/art code. Cut flora entirely until the
   animation, route, zoom, and core composition gates pass.

## Synthesis recommendation

Use Claude's deterministic `NavGrid`, collision-aware follower boundary, and
actual-velocity animation findings. Use Antigravity's colored feet only as a
temporary source diagnostic. Target five generated source facings with mirrored
counterparts, but accept three cardinals only as an explicit fallback after an
end-to-end facing proof. Bake visual variants and semantic prop placements into
authored data rather than hashing them at runtime, and keep all texture keys,
sprite anchors, camera state, and cursor state in render. Finally, resolve the
meaning of "keybindable" before implementation because the present repository
has InputMap defaults but no rebinding UI.
