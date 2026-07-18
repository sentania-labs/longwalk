# Phase-2 critique (round 007 GROUND sub-round) -- claude-worker

Adversarial critique of the two proposals that are NOT mine: codex's authored
district plate and agy's splat-mapped shader plane. Read read-only from their
branches; nothing edited in anyone's worktree.

Grounding numbers I use below (measured, not guessed). The inn-green district is
16 cells wide by 14 tall (`build_inn_green_district`). Through the frozen
`Iso.cell_to_screen` (HALF_W=64, HALF_H=32) the projected outer diamond spans
x in [-896, 1024] and y in [0, 960], i.e. a **1920 x 960 px** screen bounding box
at 1x zoom. The two existing ground PNGs are `ground_grass.png` /
`ground_lane.png`, **128 x 64 alpha DIAMONDS**, anchor (64,32), `provenance:
slice` (manifest.json confirmed).

---

## A. codex: one frozen authored district plate

### Steelman

A single hand-composited painterly plate is the ONLY one of the three methods
that can deliver true art direction on the ground: a junction that is irregular
in a way a human chose, dirt incursions and secondary wear branches placed by
eye, a lane silhouette that no procedural warp will ever match. A tiling swatch
plus domain-warp (mine and agy's) will always read as "proceduralish" up close;
codex's plate has no such ceiling. And its sim/render hygiene is genuinely the
cleanest of the three: the offline guide reads the grid, the runtime loads ONE
`Sprite2D`, `town_layout.gd` gains zero fields, and the semantic fingerprint is a
real, testable guard that the other two proposals do not offer at all. If ground
fidelity were judged only at 1x on this one district, this is the strongest
proposal on the table.

### Attack

**1. It does not survive 2x, and its risk section never mentions zoom.** This is
the fatal one and it is measured, not rhetorical. The plate is authored at
~2048 x 1152 to fill a 1920 x 960 district. That is ~1.07 native texels per
screen pixel at 1x: fine. The free-cam zooms to 2x, at which the same district
projects to 3840 x 1920 screen px, so the plate now resolves **~0.53 native
texels per screen pixel**, i.e. every source texel is magnified ~1.9x. That is a
raster magnified nearly two-fold with no mip or vector escape: it is soft. This
is the EXACT "blurs when zoomed" failure that sank codex's own Option G in
decision 009. The proposal's section 2 lists drift, model-invention, memory, and
shadow-synthesis as risks and **never once names 2x zoom**. The single most
important adversarial fact about a fixed-native-px plate is absent from its own
risk ledger.

**2. Fixing (1) blows up the memory story codex already calls a risk.** To hold
crisp at 2x the plate must be authored at ~3840 x 1920, which is ~4x the pixels,
so the "roughly 9 MiB" becomes **~28-30 MiB per district uncompressed**. Codex
already admits 9 MiB "does not scale indefinitely" for a 12-16-structure village;
at the resolution actually required to not blur at 2x, that admission becomes
disqualifying: ~28 MiB x 12-16 districts is a VRAM/pack budget the reusable-swatch
approach avoids entirely (two ~512px swatches shared across every district). Codex
is impaled on a dilemma it does not state: 2048 blurs at 2x, 4096 stays crisp but
quadruples an already-flagged cost.

**3. "Fingerprint catches drift" makes drift LOUD, not RARE, and that is the
wrong axis for a 12-16 village.** The fingerprint is a genuinely good guard, but
read what it buys: every time someone moves a PATH cell in any district, the test
goes red and a human must re-composite a ~9-28 MiB painterly plate for that
district by hand. Codex concedes this ("regeneration and repainting are still
manual work"). For a frozen single-district demo that is acceptable. For the
stated 12-16-structure village under iteration it means layout tweaks are gated on
hand-repaints. The fingerprint converts silent-wrong into loud-expensive; it does
not convert it into cheap. A derived-every-load mask (mine/agy) makes the same
drift a non-event.

**4. The lane-mask compositing has an internal tension codex half-notices.** The
guide applies hash-based lateral wander so the dirt "wanders INSIDE" the PATH
cells, yet codex also says "the main dirt lane must remain inside or immediately
adjacent to semantic PATH cells so the art does not advertise a traversability
rule the sim does not have." Those two constraints fight: wander that is visible
enough to break the straight diamond band is wander that pushes dirt pixels off
PATH cells at the fray, which is precisely advertising traversability the sim
lacks. This is the same visual-vs-semantic desync every proposal must manage, but
codex bakes it into frozen pixels, so it cannot be re-tuned by a uniform after the
fact the way a live shader edge can. Baked wander is un-retunable wander.

### What should happen instead

Keep codex's two genuinely-best ideas and drop the plate: (a) the deterministic
offline lane guide is a good ARTIFACT even for a shader approach -- it could bake
the CPU noise/warp texture the shader consumes, giving art-directed wander WITHOUT
freezing it into a raster; (b) the semantic fingerprint is worth adopting as a
test guard regardless of method. Ship the paint as tiling swatches sampled by a
shader (crisp at any zoom, reused per district), not as one frozen 2x-soft image.

---

## B. agy: splat-mapped single ground plane (CanvasItem shader)

### Steelman

agy and I converged, blind, on the same core method: one continuous
`Polygon2D`/`CanvasItem` plane, a small per-cell blend mask built at runtime from
the unchanged sim grid, a deterministic domain-warp for organic wander, tiling
paint uniforms, and a dedicated contact-shadow layer above ground and below
depth-sorted objects. That independent convergence is itself the strongest
evidence this method (not the plate, not autotiles) is the right family. agy's
determinism story is sound: a CPU-baked `FastNoiseLite` texture sampled as a
lookup sidesteps GPU-precision variance, which is the correct fix. Its sim/render
boundary is clean (mask is a pure downstream read of `ground`, `town_layout.gd`
untouched). On method, agy is right, and I say so plainly.

### Attack

The method is right; two of agy's IMPLEMENTATION choices are wrong, and agy flags
both as "maybe" when they are "certainly."

**1. Sampling the existing 128x64 DIAMOND PNGs as repeating tiles cannot work,
and agy hedges this as optional.** The manifest is explicit: `ground_grass.png`
and `ground_lane.png` are 128 x 64 alpha diamonds sliced from the spike. A diamond
sprite has TRANSPARENT triangular corners. Set `repeat_enabled` on it and tile it
across a plane and those transparent corners tile in as a lattice of alpha
gaps/hard diamond edges: you get the checkerboard back, now with texture. agy
writes "If the math causes artifacting, we might have to pre-process the diamonds
into rectangular seamless textures." There is no "if." A non-rectangular alpha
period does not tile, full stop. So agy's load-bearing texture source is
non-viable as stated, and the reslice-to-rectangular step it files under "a peer
MIGHT be better suited" is not optional, it is a hard prerequisite. This is the
same rectangular-tileable-swatch dependency my proposal names as the crux and puts
on codex's slice seat up front; agy defers the same dependency to a conditional.

**2. Sampling in SCREEN space and inverting screen->iso in-shader is brittle by
agy's own admission, and it is unnecessary.** agy proposes "mapping screen
coordinates back to isometric space within the shader" to lay the tiles, and lists
this as the top risk. It is avoidable. If you set the quad's `uv` array to the
CELL corners of the projected diamond, Godot interpolates UV affinely and the
fragment shader receives fractional cell space directly, so paint is sampled in
ground space with constant texel density and NO per-frame screen->iso inversion.
agy chose the harder, self-flagged-brittle coordinate path where a boundary-space
one exists. Where a proposal names its own top risk and a sibling method removes
that risk by construction, the sibling choice is the correct one.

**3. The 16x14 mask under pure bilinear is blocky at the lane edge, and agy leans
on "GPU linear filtering natively produces a smooth blend" as if that were
enough.** One texel per cell stretched over ~120 screen px per cell, then bilinear,
gives a soft but LOW-frequency gradient; the domain warp bends it but cannot add
detail that is not in a 16x14 source. Without rasterizing the mask at K texels per
cell (which agy does not mention and I flag explicitly as a knob), the wander
reads as a fuzzy wide band, not a frayed trail edge. Minor and tunable, but agy
presents the raw-bilinear result as the finished look.

### What should happen instead

Keep agy's method (we agree on it) and correct the two implementation choices:
sample in CELL space via UV=cell-corners (kills the screen->iso brittleness agy
itself flags), and treat the rectangular-tileable-swatch reslice as a hard
up-front dependency on the slice seat, not a conditional. Rasterize the mask at
K>1 texels/cell before the warp. With those three changes agy's proposal and mine
are the same shader; the disagreement is entirely about which coordinate space to
sample in and whether the swatch dependency is admitted or deferred.

---

## Summary for synthesis

- Both peers are on defensible ground on ONE axis each: codex on art-direction
  ceiling and sim/render hygiene, agy on method family (which matches mine).
- codex's plate has a MEASURED, un-conceded 2x-blur defect (~0.53 texels/screen-px
  at 2x) that is the same failure decision 009 already rejected, plus a scaling
  cost that quadruples once you fix the blur. Its two salvageable ideas (offline
  guide -> bake the shader's noise texture; semantic fingerprint as a test guard)
  should be lifted into the shader approach.
- agy's method is right and I concede convergence, but its two concrete choices
  (diamond-PNG tiling, in-shader screen->iso) are self-flagged brittle and one is
  outright non-viable; both are fixed by sampling in cell space over
  rectangular-tileable swatches, and the swatch reslice is a hard dependency, not
  an "if."
- Net: the synthesis is a tiling-swatch shader plane sampled in CELL space, fed a
  mask derived every load from the sim grid, wander baked into a CPU noise texture
  (borrowing codex's offline guide idea), guarded by codex's semantic fingerprint,
  with a render-side contact-shadow layer. That keeps ground crisp at 2x, reuses
  two swatches across all 12-16 districts, and never freezes a lane the sim can
  move.

Co-authored-by: Claude <claude@sentania.net>
