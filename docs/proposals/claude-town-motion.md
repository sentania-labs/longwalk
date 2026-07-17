# Proposal: town motion (Claude resident)

Assignment: "Bring motion to the starter town: player walk cycle at minimum,
ambient town motion if cheap."

## 0. How I scoped it

The goal statement is ambiguous in two places and I resolved both rather than
asking:

1. **"Walk cycle" does not necessarily mean "sprite-sheet frames."** It means
   the player reads as walking rather than sliding. I am reading it as the
   perceptual requirement, not the implementation.
2. **"If cheap" is a budget, not a maybe.** I am treating ambient motion as in
   scope only at the price of zero new art and zero sim changes. If it cannot
   be had for that, it is out.

What I am building: a procedural walk cycle for the player, plus render-side
ambient motion (chimney smoke, a gentle grass shimmer) driven by a lookup table
that lives in the render layer.

What I am deliberately leaving out: multi-directional player art (I specify it
below and hand it off rather than build it), NPCs of any kind, and the
shopkeeper plot, which is a following dispatch and stays a flat marker.

## 1. Approach

### The scoping fight: procedural, not generated frames

I am arguing for **procedural animation in Godot for the cycle itself, with
generated art used only for static directional poses**. These are two separate
decisions on two separate axes, and calling the pair a "hybrid" undersells how
one-sided each one is:

- **The cycle (the per-frame motion) is 100% procedural. No generated frames,
  ever.**
- **Directional identity (what the character looks like facing away from the
  camera) is generated art, because procedural code cannot invent a back.**

Why not generated sprite-sheet frames for the cycle. `tools/art/` generates one
image per prompt through `codex exec`'s `image_gen` tool. A four-direction,
six-frame cycle is 24 renders that must agree with each other on the
character's identity down to the pack strap, under a generator that (per
`tools/art/README.md`) has already needed a moderation retry on this exact
subject once. Image generators do not hold subject identity stable across
frames; that is the well-known failure mode, and it is the whole job here. The
committed prompt would say "frame 3 of 6" and the reviewer would have no way to
check that claim except by looking. A drifting frame is not a test failure, it
is a taste failure, and this repo's gate (`tools/run_tests.sh`) is a headless
CI script that cannot see it. That is disqualifying for the *cycle*
specifically, not for art in general.

Procedural motion inverts every one of those properties. The pose is a pure
function, so CI can assert it. The whole cycle is a few dozen lines that a
reviewer reads rather than eyeballs. Retuning the bob amplitude is an edit, not
24 regenerations. And the existing player sprite is, by its own prompt file, an
"explicit placeholder, not final character-creation art"; spending 24
generations locking a walk cycle onto a placeholder silhouette is buying
expensive frames for art we intend to throw away.

The honest cost: procedural motion on a single front-facing sprite is a bob and
a lean, not articulated legs. I claim that reads as walking at 128px tiles with
a 160px character, which is the actual visual target (Warcraft 2, not
Hollow Knight), and I name it as my top risk below.

### Files and data flow

**New: `src/render/town/walk_cycle.gd`** (`class_name WalkCycle`, extends
`RefCounted`). Pure math, no nodes, no `Input`, no `Engine` singletons:

```
static func pose(phase: float, speed_ratio: float) -> Dictionary
    # -> { offset: Vector2, scale: Vector2, rotation: float }
```

`phase` is a cycle position in `[0, 1)`. `speed_ratio` in `[0, 1]` scales
amplitude so the pose collapses continuously to the identity pose at rest. The
pose is a vertical bob at twice the stride frequency (two footfalls per stride,
which is what sells a gait), a small counter-phase side lean, and a slight
squash on the contact beat. Being a plain static function on a `RefCounted`,
this is trivially unit-testable headless.

**New: `src/render/town/walk_cycle_animator.gd`**, a `Node` child of the player
scene. Each `_process(delta)` it reads the parent's `get_real_velocity()` and
advances phase, then writes the pose onto the sibling `Sprite2D`.

**Phase advances by distance travelled, not by wall-clock time:**

```
_phase = fposmod(_phase + velocity.length() * delta / STRIDE_LENGTH_PX, 1.0)
```

This matters twice. It means holding a direction into a building wall churns no
legs, because `get_real_velocity()` after `move_and_slide()` reports the
*resolved* velocity, not the input. And it makes the cycle automatically correct
if `SPEED` is ever retuned, with no second constant to keep in sync.

**Modified: `scenes/player.tscn`** gains the animator node. **Modified:
`src/render/town/player_controller_2d.gd`** gains a `facing` concept only if
phase B (below) lands; phase A needs no controller change at all, which is a
property I like.

**The animator only ever touches `Sprite2D.offset`, `Sprite2D.scale`, and
`Sprite2D.rotation`. It never touches `CharacterBody2D.position`.** This is
load-bearing, not hygiene: `starter_town.tscn` has `y_sort_enabled` on `World`,
and `starter_town.gd:87-97` carries a long comment about a real bug where a
sprite's `position` being the y-sort key flipped front/back ordering against the
player. A bob applied to `position` would resurrect exactly that bug in a
oscillating, intermittent form, and would also jitter the collision shape and
the camera. The sort key must stay nailed to the feet.

### Phase B: directional poses (specified here, generated separately)

Three new prompt files under `tools/art/prompts/`
(`player_character_back.md`, `player_character_side.md`, and I would try
`player_character_three_quarter_back.md`), each reusing the committed
`player_character.md` verbatim except for the facing line, so the diff between
prompts is one line and the reviewer can see that the subject brief did not
drift. `process_assets.py` gains them to `SPRITES` and extends
`process_appearance_variants()` to recolor each view's tunic. Left-facing is the
right-facing texture with `flip_h`, so it is free.

`player_controller_2d.set_appearance()` becomes a small facing-to-texture
lookup, and the animator picks the texture from the quantized facing of
`get_real_velocity()`.

This is the piece where generated art is genuinely the only option, and it is
three static poses rather than 24 cycle frames, so the identity-drift risk is
proportionate rather than fatal.

### Phase C: ambient motion, and why it touches no protected path

**My proposal does not touch `src/sim/`, and that is a deliberate design
choice rather than an accident of scope.**

The tempting move is to add a `smoke_anchor: Vector2` to
`TownLayout.BuildingPlacement`. I am rejecting it. Where the chimney sits on the
cottage is a fact about the `cottage_facade.png` *texture*, not a fact about the
*town*. Putting it in `TownLayout` would mean the headless, server-bound sim
layer carries pixel offsets into an art asset it must never load, which is
exactly the leak `src/sim/` is protected to prevent. Regenerate the cottage art
with the chimney on the other side and you would be editing a protected sim file
to fix a render bug.

So: **`src/render/town/ambience.gd`**, a render-side table keyed by the
`sprite_key` that `starter_town.gd` already reads:

```
const SMOKE_ANCHORS := {
    "cottage_facade": Vector2(0.32, 0.12),   # normalized within the sprite rect
    "building_facade": Vector2(0.70, 0.08),
}
```

`starter_town.gd._build_buildings()` consults it and attaches a
`CPUParticles2D` (a slow, small, warm-grey drift, alpha fading out) at the
anchor. Buildings absent from the table simply get no smoke, so the shopkeeper
plot stays inert with no special-casing.

Second ambient element, if it stays cheap: a `grass_ground_tile` shimmer via a
small `CanvasItemMaterial` shader doing a low-amplitude UV wobble on the ground
layer. If it costs more than one shader file, I cut it rather than negotiate.

**Determinism.** Per-building smoke phase offsets come from a hash of the
building's `cell`, not `randi()`. Strictly, CLAUDE.md's rule binds *placement
decisions*, and a puff's timing offset is not one. But keying the offset off
position is free, costs one line, and keeps the "pure function of position"
habit intact everywhere in the repo rather than establishing a first exception
that a later reader has to adjudicate.

### Tests

**New: `test/active_path/test_walk_cycle.gd`**, wired into
`tools/run_tests.sh`. Asserts:

- `pose(p, 0.0)` is the identity pose at every `p` (no motion at rest).
- `pose()` is continuous and periodic across the `phase` wrap at 1.0, so the
  cycle does not visibly pop each stride.
- The bob is symmetric across the two footfalls in a stride.
- Amplitude scales monotonically with `speed_ratio`.

**This is the argument for procedural stated in its strongest form: it makes
the walk cycle the first animated thing in this repo that the CI gate can
actually check.** A sprite sheet would give CI nothing to assert except that
the PNG loaded.

## 2. Risks

**A bob and a lean might just not read as walking, and that is my top risk.**
Real walk cycles carry articulated legs; I am substituting whole-body motion of
a rigid billboard. It may read as "gliding while bouncing," which is arguably
worse than the honest slide we have now, because it looks like an attempt that
failed rather than a placeholder. I cannot resolve this by reasoning, only by
looking at it. **Mitigation that makes my own proposal look worse: the pose
function is cheap enough to build and look at within the first hour, so if it
reads badly the team learns that before committing to it, and the fallback is
the generated-sprite-sheet approach I argued against.** I would rather lose this
argument early than defend it into the merge.

**Phase B's poses may not match the front sprite.** Three generations of the
same subject from the same prompt still drift; the back view's pack may be a
different pack. Less damaging than 24-frame drift, since a mismatch between two
views the player never sees simultaneously is much more forgiving than a
mismatch between consecutive frames of one cycle, but the tunic hue mask in
`process_assets.py` (`TUNIC_HUE_RANGE = (40, 80)`) is calibrated against one
specific render's olive, and a new render landing outside that hue window would
silently break the appearance presets on the new views only. That is a real
trap: character creation would still work, and would only look broken while
walking north.

**No smoke anchor survives an art regeneration.** My normalized anchors are
hand-measured against the current processed textures. Regenerate `cottage_facade`
and the smoke pours out of a window. This is a genuine cost of keeping the
anchors render-side rather than authored, and it is the strongest argument
against my protected-path reasoning: an authored anchor would at least be
reviewed when the art changed. I still think render-side is correct, because the
sim layer must not know about pixels, but I am not pretending the alternative is
baseless.

**The `y_sort` interaction is the one that would bite silently.** I am confident
in the `offset`-not-`position` rule, but `scale` on a Y-sorted `Sprite2D` with a
non-zero `offset` scales the offset too, so a naive squash will also translate
the sprite vertically. That is a fixable coupling, but it is precisely the kind
of thing that looks fine standing still and wrong in motion.

**The one hour and one question:** build the pose function and the animator,
run it, and watch the character walk down the main street. The question is
"does a rigid billboard with a bob read as walking at this scale, or does it
read as broken?" Everything else in this proposal is contingent on that answer,
and nothing else in this proposal can be settled by argument.

## 3. Division-of-labor claim

**I should own `walk_cycle.gd`, `walk_cycle_animator.gd`, the y-sort/collision
interaction, and `test_walk_cycle.gd`.** This is the piece that is pure GDScript
math with a subtle existing-bug interaction, and it wants someone who has read
the y-sort comment in `starter_town.gd:87-97` and understands why it is there.
It is also the piece with a real test surface, and specifying pose invariants
(periodicity, continuity across the wrap, identity at rest) is squarely the kind
of work I am good at.

**The Codex resident is genuinely better suited to phase B's art generation, and
not by a little.** `tools/art/generate.sh` literally shells out to `codex exec`
and drives codex's built-in `image_gen` tool. The Codex resident is the harness
this pipeline is built on top of. It can also judge the moderation-retry and
identity-drift behavior from inside rather than by reading a README about it.
Handing it the three directional pose prompts plus the `process_assets.py`
`TUNIC_HUE_RANGE` recalibration is not a courtesy split, it is the piece where
its harness is the tool.

Ambient motion (phase C) is small enough that either of us can take it; I have
no claim there beyond having already worked out the protected-path reasoning.

## 4. Rough estimate

Order of magnitude, in agent sessions:

- **Phase A (procedural walk cycle plus tests): ~1 session.** The code is
  small. The tuning pass is the unknown.
- **Phase B (three directional poses plus pipeline wiring): ~1 session of code,
  plus an unbounded number of generation attempts.** This is the estimate that
  blows up. If the generator will not hold the character's identity across three
  views, this is not a longer session, it is a different plan.
- **Phase C (smoke plus optional shimmer): ~0.5 session.**

**What blows it up:** (a) the bob does not read as walking, and we fall back to
sprite sheets, which is a rewrite of phase A and a large multiple of the whole
estimate; (b) phase B's generations drift and we burn a session re-prompting;
(c) somebody talks the team into putting smoke anchors in `TownLayout`, which
adds a signed decision record and a consensus round to what is currently a
zero-protected-path change.

**Honest floor:** phase A alone, front-facing only, no ambient motion, satisfies
"player walk cycle at minimum" and is genuinely about one session. Everything
past that is the "if cheap" clause, and I would ship phase A rather than hold it
hostage to phase B.
