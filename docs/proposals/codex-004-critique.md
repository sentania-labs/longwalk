# Codex critique: round 004 look like a game

This critique covers both peer proposals after phase 1 closed. I read each
proposal from its committed branch, then checked the current implementation,
Decision 005, and the asset publishers' source and license pages.

## Claude worker

### Steelman

Claude's strongest case is that the current scene cannot reach the references
through warmer grading because its smooth, arbitrarily scaled assets lack a
coherent rendering grammar. A top-down pixel reset preserves the authored
square map and the expensive four-cardinal traveller topology while attacking
the gap through scale, filtering, palette, terrain detail, density, and light
direction as one system.

That preservation argument is stronger than my phase 1 proposal's attempt to
adapt 2:1 isometric ground art into square top-down cells. I was too willing to
treat projection mismatch as a crop-and-resample problem. Claude is right that
a native orthogonal family is a safer basis if Decision 005 remains binding.

### Attacks

1. **The claimed primary license is outside Scott's authorized set.** Claude
   calls the Sharm and Redshrike subset of the LPC base archive "CC-BY 3.0."
   The actual OpenGameArt submission lists the archive as CC-BY-SA 3.0 and GPL
   3.0, then says those two authors' assets are additionally available under
   **OGA-BY 3.0**, not CC-BY 3.0. The OGA FAQ describes OGA-BY as a derivative
   license with different DRM terms. Scott authorized CC0 or CC-BY, not
   "attribution-like licenses." Per-file authorship could isolate the subset,
   but it cannot turn OGA-BY into CC-BY. The primary therefore fails the stated
   authorization unless Scott explicitly expands it. Use Kenney CC0 as the
   licensed orthogonal baseline, find an actual CC-BY orthogonal pack, or
   escalate OGA-BY before importing anything. Sources checked:
   <https://opengameart.org/content/liberated-pixel-cup-lpc-base-assets-sprites-map-tiles>
   and <https://lpc.opengameart.org/content/faq>.

2. **The rendering reset is broader than its sequencing admits.** Nearest
   filtering, a 32px grid, fixed art scale, palette lock, four subtiles per sim
   cell, replacement buildings, and traveller pixelization are not one pack
   integration. They are a project-wide art-direction migration whose failure
   modes interact. The proposal budgets one or two dispatches for it while
   acknowledging that every later visual item depends on it. A pack proof
   containing only a tile and building will not test the hardest seam, the
   smooth AI traveller after quantization at shipping motion and zoom. The
   proof must include the actual traveller, one shadow, a path transition, and
   y-sorted flora before the rendering reset is selected. Keep the current
   pipeline intact until that composite proof wins.

3. **Pixelization is not evidence of improved gait.** Downsampling and palette
   quantization can hide foot detail, but they cannot add a missing passing
   pose, lengthen stride, or correct planted-foot motion. Re-running the
   alternation gate only proves that leading-leg color still reverses. It does
   not prove the three acceptance properties Claude itself names: stride,
   contact, and bounce. This risks making the defect less legible and calling
   that improvement. Use the shipping-size side-by-side motion capture as the
   go or no-go test before adopting pixelization, and hand-correct the existing
   four-frame source poses if stride or contact still fails. Pixelization can
   be a style transform after gait passes, not the gait fix.

4. **The LPC reserve is neither license-clean nor authorized character art.**
   Claude proposes an LPC Universal Sprite Sheet as an automatic fallback even
   though it concedes that Scott reserved the traveller for AI generation. The
   base character's licensing also inherits the same OGA-BY versus authorized
   CC-BY problem above unless a different exact file and license are proven.
   Decision 005's reserve clause authorized hand-authoring the generated
   traveller's down and up rows. It did not authorize replacing the traveller
   with third-party art. Keep Decision 005's shipped topology and improve its
   source frames, or escalate a traveller replacement explicitly.

5. **The built-in `hash()` claim overstates the constitution.** The
   constitution requires positional purity for placement decisions in reused
   generation logic. `_build_ground()` choosing render-only flips does not
   place entities, change walkability, or generate an authored draft. Replacing
   it with a documented integer mix may still be good reproducibility hygiene,
   but Claude calls the present code a constitution issue without establishing
   that it is a placement decision or that Godot changes the hash within the
   pinned engine. This is not a demonstrated constitution violation. Prefer
   authored variants or an explicit stable selector, but do not make that
   cleanup a gate on the visual round.

6. **The proposed generic silhouette shadow is not automatically a building
   shadow.** Shearing the full facade alpha treats every visible pixel as if it
   occupied one vertical plane. Roofs, walls, and overhangs occupy different
   heights and can produce a stretched duplicate rather than a conformant
   ground projection. Claude concedes this only as a fallback risk, but the
   cited Bullfrog technique favors authored artifacts. Generate or author one
   inspectable shadow mask per accepted building during preprocessing, with a
   shared light vector, and reserve the runtime transform for low-risk props.

Claude is right about scaling the A* heuristic if road cost is represented as
a multiplier below 1.0, about preserving total-order ties, about bottom-edge
y-sort anchors, and about separating cast shadows from contact shadows. Those
parts should survive synthesis.

## Antigravity worker

### Steelman

Antigravity's strongest case is that Scott identified projection and pack
coherence as the largest visual unlock, and Screaming Brain Studios offers a
large, genuinely old-school 2:1 isometric family under an unusually permissive
license. A decisive projection change could close more of the vibe gap in one
move than incremental tuning of the existing soft top-down assets.

The license premise is correct. The publisher states that every asset pack is
CC0 and may be modified and redistributed, and its itch catalog specifically
lists the Town, Overworld, and Floor packs. Sources checked:
<https://screamingbrainstudios.com/> and
<https://screamingbrainstudios.itch.io/>. This pack family is legally cleaner
than Claude's LPC primary.

### Attacks

1. **The projection change silently invalidates Decision 005.** The current
   runtime atlas has down, up, and side source rows mirrored into four screen
   cardinal facings. In a 2:1 isometric world, movement along the four world
   grid axes appears along four screen diagonals. Antigravity says to retain
   Decision 005 Option C, but its pack choice requires exactly the diagonal
   facings that Decision 005 leaves as the first stretch and makes the shipped
   cardinal rows wrong for ordinary road travel. This is not a small asset
   mismatch. It is a direct topology conflict that must explicitly supersede
   Decision 005 or reject full isometric projection. Instead, either keep the
   orthogonal projection this round or first prove four coherent diagonal
   traveller rows and record the supersession.

2. **The proposal has no coordinate contract for isometric input, rendering,
   collision, or sorting.** It acknowledges that the grid may need a rewrite,
   but does not choose between preserving square sim coordinates behind a
   render transform and changing the sim topology. Rewriting `TownLayout` or
   A* for perspective would be an architecture change and would wrongly put a
   camera concern into the headless model. Preserving the sim grid still needs
   explicit world-cell to screen-diamond and inverse click transforms,
   diamond-aware camera bounds, projected collider footprints, and a depth key
   such as `x + y`. Keep `src/sim/` square and projection-free, prove those
   render-side transforms in a spike, and do not adopt the pack until routing,
   click resolution, occlusion, and Decision 005 are demonstrated together.

3. **The 12 to 16 hour estimate excludes the proposal's own largest work.** A
   projection conversion plus three large pack ingestions, chroma-key cleanup,
   new traveller facings, collision reprojection, click inversion, camera
   limits, shadow sorting, flora placement, and all seven acceptance outcomes
   is not bounded by "could double" to 24 to 32 hours. The publisher notes that
   its renderer emits solid-color backgrounds, so transparent prop extraction
   is an actual preprocessing task, not a ready-made Sprite2D import. Scope the
   first delivery to a reversible one-camera interactive spike, then estimate
   the migration from measured asset and coordinate work.

4. **The camera behavior contradicts the stated requirement.** Antigravity
   makes a movement command snap the camera back to player tracking. Scott's
   requirement says focus must be independent of where the character is
   pathing. A left-click path command therefore must not cancel a right-click
   focus. Use an explicit FOLLOW and FOCUSED state, preserve FOCUSED across
   route changes, and provide a separate recenter action or an explicit
   right-click-on-player behavior.

5. **The road-cost promise is mathematically false.** `PATH = 1` and
   `GRASS = 3` expresses a preference. It does not ensure that the traveller
   leaves roads only when the destination forces it. A sufficiently long road
   detour still loses to a short grass crossing. That preference is likely the
   desired behavior, but the proposal must not claim a stronger invariant than
   it implements. Specify cost-on-entry, scale the heuristic by the minimum
   terrain multiplier even though that minimum remains 1 here, and test an
   exact threshold where grass becomes cheaper.

6. **The shadow plan repeats the pack mismatch at runtime.** Duplicating and
   shearing a full 2:1 pre-rendered building sprite does not infer the height of
   its roof and walls, and solid magenta source backgrounds would become giant
   parallelograms unless preprocessing is perfect. A shader also adds runtime
   complexity for a frozen authored map with few buildings. Chroma-key and QC
   selected assets first, then preprocess a separate inspectable mask per
   building under one shared light direction.

7. **Flora semantics are underspecified for future scale.** "Static props via
   `town_layout.gd`" does not say which props block, where the trunk footprint
   lies, or how the render layer maps a semantic kind to an asset without
   putting texture concerns into `src/sim/`. With future ecology agents, a tree
   cannot be both a decorative sprite and an implicit collision guess. Author
   stable IDs, cells, and blocking footprints in sim data, keep texture keys
   and y-sort anchors render-side, and keep bushes and flowers nonblocking.

Antigravity is right that Screaming Brain Studios is a verified CC0 family and
that a coherent pack can unlock more visual progress than another grade. It is
also right to identify shadow-layer sorting and camera parenting as real risks.
Its proposal fails by selecting full isometric projection before resolving the
traveller and coordinate contracts that make that selection viable.
