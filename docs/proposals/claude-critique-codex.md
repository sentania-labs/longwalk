# Claude's critique of the Codex town-motion proposal

Peer proposal: branch `codex/town-motion` at
`ad0a0b3c77c930b6a5ac3306dad2c20766319f95`, `docs/proposals/codex-town-motion.md`.
All repo claims below were checked against `claude/town-motion` at
`00a717edb5f1d12d9f3a322ee0a680ed9868785d`, which is identical to `main` for
every file cited.

## 0. Steelman

The strongest version of the Codex proposal is not "generate a sprite sheet."
It is this: **the assignment says "walk cycle," and a walk cycle is legs. A
rigid billboard that bobs is not a walk cycle, it is a bouncing billboard, and
no amount of unit-testable purity converts one into the other.** The sheet is
12 poses, not 24, because it collapses left into a horizontal flip and collapses
diagonals onto the dominant axis, and it is generated as one image rather than
12, which means subject identity is held stable by the generator's own
within-image coherence rather than by prompt discipline across 12 independent
calls. That is the premise the proposal leaves implicit and it is a good one:
**a single generation is exactly the mechanism that defeats the identity-drift
objection, because there is only one generation.** All the frames come out of
one sampling pass and therefore agree by construction. And the risk that
remains is bounded and front-loaded, because the proposal spends hour one
generating a candidate and looking at it at game scale, with a stated
degradation path (three strips) rather than an open-ended re-prompt loop.

On the central aesthetic question I concede the peer is right and I was wrong to
wave it away. My proposal's "a bob and a lean reads as walking at this scale" is
an assertion I could not support, and I named it as my top risk precisely
because I could not. Codex names the same crux and picks the side that actually
produces legs. If the sheet comes out coherent, the sheet wins, and my
procedural cycle is the fallback rather than the plan.

What follows attacks the parts that are still weak, and several of them are
load-bearing.

## 1. The animation is driven by input, not by resolved velocity. This is a bug, not a preference.

Codex: "`_physics_process()` would continue to derive velocity from input, then
pass **the normalized input vector** to a render-only animation update method."

`src/render/town/player_controller_2d.gd` builds `input_vector` from
`Input.get_action_strength()` and then calls `move_and_slide()`. The starter
town is ringed by four `StaticBody2D` boundary walls and every non-placeholder
building gets a `StaticBody2D` (`starter_town.gd:_build_buildings()`,
`_build_boundary()`). So: hold W against a cottage wall. The input vector is
`(0, -1)`, nonzero, so `walk_up` plays at full cadence. The character is not
moving. The player watches a man jog in place against a wall.

This is the single most visible artifact in the whole feature and it is
entirely avoidable. `CharacterBody2D.get_real_velocity()` returns the velocity
*after* `move_and_slide()` resolved the collision, which is what the animation
actually wants. **Fix: drive the animation update from `get_real_velocity()`,
not from `input_vector`.** This costs one word in the proposal and zero lines of
extra code. It is not a scoping question.

The same sentence carries a second defect: "play at a **constant frame rate**
while velocity is nonzero." A constant cadence decouples stride from speed, so
the moment `SPEED` (currently `220.0`) is retuned, or the moment anything adds a
slow-walk or a sprint, the feet skate. Advancing the animation by distance
travelled rather than by wall clock costs the same one line and removes a second
constant that has to be kept in sync with `SPEED` by hand. I hold this position
from my own proposal and I think it survives the sheet-versus-procedural
argument intact, because it is orthogonal to it: a `SpriteFrames` sheet can be
distance-advanced by setting `frame` from an accumulator instead of calling
`play()`.

## 2. The player sprite offset is a hardcoded constant coupled to the current texture height. The sheet breaks it silently.

Codex: "I would replace `Sprite2D` with an `AnimatedSprite2D` **at the same
feet-relative offset**" and "I would preserve the current collision shape,
camera, and player origin, so y-sort and collision behavior remain unchanged."

The offset cannot stay the same, and the proposal does not appear to know why.

`scenes/player.tscn` hardcodes `offset = Vector2(0, -80)` on the Sprite2D. That
`80` is not a free parameter. `tools/art/process_assets.py` has
`SPRITES = {"player_character.png": 160}` and `resize_to_longest_side()` scales
the cropped sprite so its longest side is 160px; the processed player is 66x160
(stated in `project.godot`'s own stretch-mode comment, and consistent with the
prompt). So `-80` is exactly half of 160, which puts the texture's bottom edge
on the node origin, which puts the feet on the origin, which is the y-sort key
that `starter_town.gd:87-97` spends ten lines of comment explaining must stay at
the feet.

Now apply Codex's processor plan: "crop each cell to a **common union bounding
box**, normalize every frame onto an **equal transparent canvas** with feet
aligned to a shared baseline." The union bounding box across a passing pose, a
contact pose, and an up-facing pose is not 66x160. It is wider (legs and arms
out on contact frames) and almost certainly a different height. Whatever cell
height falls out of that union, the correct offset is minus half of *it*, not
`-80`. Nothing derives this. It is a literal in a `.tscn`.

The failure mode is nasty precisely because it is not a crash: a cell height of,
say, 176 with `offset` left at `-80` sinks the character 8px into the ground,
which reads as "slightly off" standing still and reads as a front/back sort flip
against building edges in motion. That is the exact bug class the y-sort comment
was written about, resurrected through a different door. Codex's own risk
section gets within one step of this ("changing from one texture to a sheet can
subtly shift the sprite's footprint, y-sort baseline, or perceived collision
position") but then proposes to catch it with "a feet-baseline assertion in the
processor," which asserts the *processor* is consistent and says nothing about
the *scene constant* that has to move with it.

**Fix: `resize_to_longest_side()` does not apply to a sheet at all (its
"longest side" is the whole sheet's width), so the sheet needs its own sizing
path that pins the per-cell height to 160 explicitly. Pin it, state the cell
size as the contract, and the `-80` stays correct by construction rather than by
luck.** If the cell height is allowed to float out of the union box, then the
offset must be computed rather than authored, and that belongs in the proposal.

## 3. The existing boot-flow test does not "remain part of the regression gate." It breaks.

Codex: "The existing boot-flow test would remain part of the regression gate."

`test/active_path/test_boot_flow.gd:_check_player_scene()` does:

```
var sprite: Sprite2D = player.get_node("Sprite2D")
failures += _check(sprite.texture != null, "player appearance texture loads")
```

That is a typed `Sprite2D` fetch of a node named literally `Sprite2D`, plus a
`.texture` access. Replacing the node with an `AnimatedSprite2D` fails on all
three counts: the node name changes, the static type is wrong, and
`AnimatedSprite2D` has `sprite_frames`, not `texture`. `set_appearance()` in
`player_controller_2d.gd` has the same `get_node("Sprite2D")` and the same
`sprite.texture = load(path)`, and its comment explains it uses `get_node()`
rather than `@onready` specifically so headless tests can call it on an
un-parented node.

This is small to fix and I am not claiming it sinks the proposal. I am claiming
the estimate is wrong because it does not contain it, and that "would remain" is
a factual claim about the repo that is false. The honest version is "the
boot-flow test's player check must be rewritten for `AnimatedSprite2D`, and that
rewrite is part of this change."

## 4. Per-variant sheets multiply the generation cost and the hue-mask blast radius, and the proposal prices neither.

Codex: "emit one processed sheet for each existing tunic variant. The hue-shift
logic would run across all cells."

`APPEARANCE_VARIANTS` in `process_assets.py` is `{moss, slate_blue, burgundy}`
and `TUNIC_HUE_RANGE = (40, 80)` with `TUNIC_MIN_SATURATION = 0.4`. The comment
above it states the range was set from "a manual sample" of *this specific
render's* olive at hue ~52-60.

Codex names this risk and I credit that. What it does not price is the
asymmetry: today a hue-mask miss damages one static pose that a reviewer sees
immediately on the character-creation screen. Under the sheet, the mask runs
across 12 cells, and a partial miss is per-cell. A tunic that recolors correctly
on the two contact frames and misses on the passing frames produces a garment
that **strobes between olive and burgundy at stride frequency**. That is not
"needs visual checks on all twelve frames," that is a defect that only exists in
motion, which is the one state `tools/run_tests.sh` cannot observe. The
mitigation Codex offers ("a prompt-level palette adjustment or a narrower
mask") both feed back into regenerating the sheet, so the cost lands in the
"one to two working days" estimate as an unbounded loop, not as the "two to four
hours for prompt iteration" it is budgeted at.

I concede my proposal has a weaker version of the same problem (three
directional poses, same mask) and I called it out. The difference is that three
static poses that miss are three static poses that miss; 12 cells that miss
unevenly is a strobe.

## 5. Where it breaks after the roadmap: the next dispatch is NPCs, and this approach does not have a second character in it.

The proposal scopes out "NPC motion, schedules" and "a general animation
framework," and explicitly wants the animation API to "stay local to the player
instead of becoming a premature general animation system." That is defensible
YAGNI in isolation. It is not defensible given what is queued.

CLAUDE.md names NPC schedules as "an upcoming dispatch," `town_layout.gd` already
carries `is_npc_placeholder` and the shopkeeper plot is already reserved and
already rendered as a marker (`starter_town.gd:_build_placeholder_marker()`),
and CLAUDE.md commits the sim layer to an ecology of fauna "modeled all the way
down to something as small as a fish, each as a minimal agent."

Cost per animated archetype under each approach:

- **Sheet:** one `image_gen` generation that must land a coherent 3x4 grid, plus
  a per-archetype hue-mask calibration (because `TUNIC_HUE_RANGE` is calibrated
  per render, not per project), plus a processed sheet per appearance variant.
  Call it a session per archetype, with a fat tail.
- **Procedural pose function:** zero. `pose(phase, speed_ratio)` applies to any
  billboard.

So the sheet approach is O(archetypes) generations and O(archetypes) hue
calibrations, and the procedural one is O(1). The shopkeeper alone makes this
concrete within one dispatch. This is the strongest surviving argument for my
approach and I do not think Codex's proposal answers it, because "stay local to
the player" is a decision to pay the full cost again for character number two.

The honest counter, which I will supply because the steelman rule demands it:
nobody is going to bob a fish, and the ecology layer's fauna are not going to
reuse a humanoid walk cycle either way. The scaling argument bites hardest at
the shopkeeper and other humanoid NPCs, and is close to irrelevant below that.

## 6. Smaller things

**GPU particles under `gl_compatibility`.** `project.godot` pins
`renderer/rendering_method="gl_compatibility"` with a comment explaining why
(headless CLI weight, Windows GPU compatibility). Codex's `GPUParticles2D` is
fine on the pinned 4.3, since 4.3 is the release that brought GPU particles to
the Compatibility renderer. But the hedge it reaches for is wrong: "If GPU
particles prove unreliable in the headless or compatibility renderer, I would
use a tiny `AnimationPlayer` scene with three `Polygon2D` circles." The
available answer between those is `CPUParticles2D`, which has the same
configuration surface as `GPUParticles2D`, works on every backend
unconditionally, and does not require rewriting the effect as hand-keyed
polygons. For two cottages' worth of low-count smoke, the GPU buys nothing.
**Use `CPUParticles2D` and delete the fallback branch.**

**`sprite_key`-keyed smoke: agreed, and Codex's version is cleaner than mine.**
We converged independently on keying ambient motion off `sprite_key` in the
render layer rather than adding a field to `TownLayout`, and on the same reason
(`src/sim/` is a protected path and must not carry pixel facts). I will note
that Codex's version is *better* than mine here: it attaches smoke at "a render
offset above each existing cottage sprite," one constant, whereas I proposed a
per-sprite-key table of normalized anchor positions that I hand-measured against
the current textures. My table is strictly more to maintain and strictly more to
break when the art regenerates, for a benefit (chimney-accurate placement) that
is invisible at 320px. **Concede: take Codex's single-offset approach over my
`SMOKE_ANCHORS` table.**

**Two cottages, not "each cottage" as an open set.** `town_layout.gd:122,126`
place exactly `cottage_a` and `cottage_b`. Nothing here scales badly; I mention
it only because "attach one instance at a render offset above each existing
cottage sprite" reads like an unbounded loop and it is n=2.

**`scenes/town/` does not exist.** Trivial, but `scenes/` is currently flat
(`player.tscn`, `starter_town.tscn`, `title_screen.tscn`,
`character_creation.tscn`, `settings_screen.tscn`). Introducing a subdirectory
for one particle scene is a convention change; either commit to it or put the
scene at `scenes/chimney_smoke.tscn`.

## 7. Constitution conformance

**I am not claiming a constitution violation.** Codex's proposal is clean on all
three of the rules that could plausibly bite:

- **Sim/render separation:** it explicitly does not touch `src/sim/`, keeps
  facing and cadence out of `GameState` and `TownLayout`, and correctly
  identifies that requiring authored smoke anchors would push the work into a
  protected path and trigger the decision-record process. Correct on all counts.
- **Determinism:** particle jitter is not a placement decision, and Codex says
  so in the right terms. Its "tests should assert node construction and
  configuration, not pixels" is the right call and matches what
  `test_boot_flow.gd` already does.
- **Cross-platform:** no platform-specific surface. `gl_compatibility` is if
  anything the conservative choice.

I want this on the record explicitly, since a losing objection framed as a
constitution violation escalates to Scott, and none of my objections are that.
They are correctness and cost objections, settleable by the orchestrator.

## 8. What I think should happen

1. **Sheet over procedural for the cycle, if and only if the first sheet is
   coherent.** Codex is right that a bob is not a walk cycle, and I concede the
   crux. Its hour-one plan (generate one candidate, view it at game scale) is
   the correct gate and it should be a real gate: if the grid is unusable after
   one prompt revision, the fallback should be my procedural pose function
   rather than Codex's "three separate four-frame strips," because the strips
   reintroduce the cross-generation identity drift that generating one image was
   the whole point of avoiding.
2. **Drive the animation from `get_real_velocity()`, and advance it by distance
   travelled rather than at a constant frame rate.** Non-negotiable; the
   input-driven version jogs in place against walls.
3. **Pin the sheet's per-cell height to 160 explicitly rather than letting it
   fall out of a union bounding box, so `player.tscn`'s `offset = Vector2(0,
   -80)` stays correct by construction.** If it is allowed to float, compute the
   offset instead of authoring it, and say so.
4. **Budget the `test_boot_flow.gd` player-check rewrite and the
   `set_appearance()` rewrite into the estimate.** Both are `Sprite2D`-typed and
   both break.
5. **`CPUParticles2D`, single render offset above the two cottages, no
   `SMOKE_ANCHORS` table.** This is Codex's design, and it beats mine.
6. **Say out loud what happens for the shopkeeper.** The next dispatch adds a
   second humanoid. If the answer is "generate a second sheet," that is a
   session per NPC and the team should know that before it picks the sheet, not
   after.

Co-authored-by: Claude <claude@sentania.net>
