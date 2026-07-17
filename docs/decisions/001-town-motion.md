# 001: bringing motion to the starter town

- **Status:** accepted
- **Date:** 2026-07-17
- **Assignment:** "Bring motion to the starter town: player walk cycle at minimum, ambient town motion if cheap."
- **Orchestrator run:** 2026-07-17T00:02Z run, the third attempt at phase 1 and the first to actually dispatch workers. See TEAM-STATE.md for why the first two produced nothing.
- **Lane:** full protocol. Directed by Scott, not left to orchestrator triage: pilot run of the team framework, and the scoping fight was named as part of what the pilot was meant to test.

## Context

The starter town is static. The player is a single front-facing billboard
(`tools/art/out/processed/player_character_*.png`, one pose, three tunic
variants) that slides across the ground at `SPEED = 220.0` without animating,
and nothing else in town moves at all.

The assignment is a goal statement, not a scope, and the interesting question is
buried in the word "cycle": is a walk cycle something you generate as art, or
something you compute at runtime? That fight was left deliberately unresolved
going into phase 1, and both workers were told to resolve it themselves and
defend the choice. They picked opposite sides, which is what the protocol is
for.

## Proposals (phase 1, blind)

Both workers proposed independently, neither having seen the other's proposal.

| Worker | Branch | Proposal commit SHA |
| --- | --- | --- |
| claude-worker | `claude/town-motion` | `00a717edb5f1d12d9f3a322ee0a680ed9868785d` |
| codex-worker | `codex/town-motion` | `ad0a0b3c77c930b6a5ac3306dad2c20766319f95` |

**Claude proposed procedural animation.** A pure `WalkCycle.pose(phase,
speed_ratio)` function in `src/render/town/`, applying bob, lean, and squash to
the existing rigid billboard via `Sprite2D.offset/scale/rotation` only, never
`position` (because `starter_town.gd:87-97` documents a real y-sort bug of
exactly that shape). Phase advances by distance travelled rather than wall
clock, so pushing into a wall churns no legs. Generated art is used only for
three static directional poses, never for cycle frames. Its argument: a pure
pose function is headless-testable (periodicity, continuity across the wrap,
identity at rest, amplitude scaling) where a generated sheet gives CI nothing to
check except that the PNG loaded.

**Codex proposed generated sprite frames.** One `image_gen` call producing a 3x4
grid (down/up/side facings, four cycle frames each, left as a horizontal flip of
side), processed into a `SpriteFrames` resource driving an `AnimatedSprite2D`
that replaces the player's `Sprite2D`. Ambient motion via a `GPUParticles2D`
chimney-smoke scene attached by `sprite_key` in the render layer. Its argument:
the assignment says walk cycle, a walk cycle is legs, and no affine transform of
a one-pose billboard can produce legs.

## Critique (phase 2, adversarial)

Critique SHAs: Claude `6552e1df50434ab2a036db2181d71ba0a9c50573`, Codex
`4ab315e37da0d44413b75009c01959d87952865d`.

This round did its job. Both workers conceded the other's central point, and
both found real defects that the peer's proposal did not know it had.

**Claude conceded the crux and attacked the mechanics.** It granted outright
that "a bob and a lean on a rigid billboard" is an assertion it could not
support and that Codex "picks the side that actually produces legs." It then
found four concrete defects in Codex's plan:

1. **Animating from input rather than resolved velocity is a bug.** Codex's
   `_physics_process()` passes the normalized input vector to the animator. Hold
   W against a cottage wall and the input vector stays `(0, -1)`, so `walk_up`
   plays at full cadence while the character does not move. The player watches a
   man jog in place against a wall. `get_real_velocity()` is the value the
   animation actually wants.
2. **The sprite offset is coupled to texture height and the sheet breaks it
   silently.** `scenes/player.tscn` hardcodes `offset = Vector2(0, -80)`.
   That 80 is half of 160, which is `process_assets.py`'s
   `SPRITES = {"player_character.png": 160}` fed through
   `resize_to_longest_side()`. It puts the texture's bottom edge on the node
   origin, which is the feet, which is the y-sort key. Codex's "crop to a common
   union bounding box" produces a cell height that is not 160, and nothing
   derives the offset from it. The result is not a crash: the character sinks a
   few pixels into the ground and sort-flips against building edges in motion.
3. **The boot-flow test does not survive.** `test_boot_flow.gd` does a typed
   `Sprite2D` fetch of a node literally named `Sprite2D` and reads `.texture`.
   `AnimatedSprite2D` fails on all three counts, and `set_appearance()` has the
   same pattern. Codex's claim that the existing test "would remain part of the
   regression gate" is factually false against the repo.
4. **The hue mask across 12 cells can strobe.** Today a `TUNIC_HUE_RANGE` miss
   damages one static pose a reviewer sees immediately. Across 12 cells a
   partial miss produces a tunic that alternates olive and burgundy at stride
   frequency, a defect that exists only in motion, which is the one state
   `tools/run_tests.sh` cannot observe.

It also made the scaling argument: the next dispatch is NPC schedules,
`town_layout.gd` already carries `is_npc_placeholder`, and the sheet approach is
O(archetypes) generations plus O(archetypes) hue calibrations where a pose
function is O(1). It then supplied the counter itself: nobody is going to bob a
fish, and the argument bites at the shopkeeper and not below.

**Codex conceded the controller detail and attacked the deliverable.** It
granted that its input-driven animation "would visibly walk against a blocking
wall, so Claude is right and I was wrong about that controller detail," and that
smoke anchors are texture metadata rather than sim data. It then attacked:

1. **Phase A does not meet the minimum it claims to meet.** Claude's own
   proposal concedes the result may read as "gliding while bouncing." No pose
   transform of a single static image can produce alternating feet, leg
   articulation, or even a change of silhouette. Claude's tests prove
   mathematical smoothness, not the perceptual outcome, and all of them pass for
   something that unmistakably reads as a bouncing cardboard cutout.
2. **Claude's phase B does not define a cycle either.** Three static directional
   poses are still rigid billboards under the same transforms, and the side view
   makes the missing articulation easier to see, not harder. Three separate
   `image_gen` renders also maximize cross-view drift, which is the exact risk
   Claude used to reject generated cycle frames.
3. **The distance formula is underspecified.** `get_real_velocity()` is already
   displacement over delta; multiplying it by `_process(delta)` uses render
   delta while movement resolves in `_physics_process()`. Variable render timing
   can sample the same physics velocity twice or miss part of an interval, which
   undermines the claim that cadence is exactly distance-driven.
4. **Nobody owns last-facing state.** Resolved velocity is zero at rest, so it
   cannot select the retained idle facing. Claude never assigns ownership of
   that state, nor defines how it composes with `set_appearance()`, which the
   boot test calls before tree entry on an un-parented node.
5. **The particle determinism claim is stronger than the design supports.** A
   position-derived initial phase does not make `CPUParticles2D` deterministic;
   emission still randomizes velocity, scale, spread, and lifetime. The
   constitution only bars stateful RNG in *placement* decisions, so smoke need
   not be deterministic at all. Claiming the stronger property creates a review
   promise the implementation cannot keep.
6. **The estimate hides a rewrite.** If the bob fails, almost nothing of phase A
   survives: the representation, the appearance loading, and the tests all
   change. Presenting phase A as the cheapest shippable path encourages merging
   infrastructure with a known chance of immediate replacement.

## Decision (phase 3, synthesis)

**Codex wins the representation argument. Claude wins the mechanics. Neither
proposal is accepted as written.**

The crux was settled by concession rather than by the referee: Claude granted
that a bob is not a walk cycle, and it is right to have granted it. The
assignment says "walk cycle," and legs are not an implementation detail of that
phrase. Codex's single-generation insight is the load-bearing one, and Claude
stated it better than Codex did in its own steelman: generating one image rather
than twelve is exactly what defeats the identity-drift objection, because there
is only one sampling pass and the frames agree by construction.

But Codex is also right that this cannot be decided by argument, and its
time-boxed spike is the correct instrument. So:

1. **Art spike first, before any production code.** Codex generates one 3x4
   sheet candidate and views it at game scale. One prompt revision is allowed.
   This is a real gate with a real rejection criterion, not a formality.
2. **If the sheet is coherent, it wins.** `AnimatedSprite2D` driven by a
   processed `SpriteFrames`.
3. **If it is not, the fallback is Claude's procedural pose function, not
   Codex's three separate strips.** Claude's objection here is decisive and
   Codex did not answer it: the strips reintroduce exactly the cross-generation
   identity drift that generating one image existed to avoid. A degradation path
   that reintroduces the failure it was hedging against is not a degradation
   path.
4. **If the fallback is taken, that is a Scott escalation, not a team call.**
   Codex asked for explicit acceptance that "walk cycle" can mean whole-sprite
   bobbing. That is the right instinct and it is not the team's to grant: the
   assignment named the walk cycle as the minimum, and shipping something both
   workers agree is not a walk cycle is a change to the assignment. Escalate at
   that point rather than quietly redefining the word. This trigger is
   conditional and is not open today.

**Mechanics, binding regardless of which representation the spike selects:**

5. **Drive the animation from resolved motion, not input.** Claude found this,
   Codex conceded it.
6. **Advance by distance travelled, in the physics tick.** This is Claude's idea
   corrected by Codex's critique of it, and the corrected version is better than
   either proposal: pass actual per-tick displacement from `_physics_process()`
   rather than multiplying `get_real_velocity()` by a render delta. It costs
   nothing and removes the sampling mismatch Codex identified.
7. **The render-side animation state owns last nonzero facing and appearance
   variant explicitly, and must work when `set_appearance()` is called before
   tree entry.** Codex found this hole in Claude's proposal and it is a real
   repo constraint, not a hypothetical: `player_controller_2d.gd` uses
   `get_node()` rather than `@onready` specifically so the headless test can
   call it on an un-parented node. Do not break that.
8. **Pin the sheet's per-cell height to 160 explicitly.** Do not let it fall out
   of a union bounding box. `resize_to_longest_side()` does not apply to a sheet
   (its longest side is the whole sheet's width), so the sheet needs its own
   sizing path. Pinning it keeps `player.tscn`'s `offset = Vector2(0, -80)`
   correct by construction rather than by luck. If the cell height is ever
   allowed to float, the offset must be computed rather than authored.
9. **Budget the `test_boot_flow.gd` and `set_appearance()` rewrites.** They are
   `Sprite2D`-typed and they break. This is small, but it was missing from the
   estimate, and "would remain part of the regression gate" was false.
10. **Animate the visual child only, never `CharacterBody2D.position`.** Both
    workers agree. `starter_town.gd:87-97` explains why at length.

**Ambient motion:**

11. **`CPUParticles2D`, not `GPUParticles2D`.** Claude is right that for two
    cottages of low-count smoke the GPU buys nothing, and `CPUParticles2D` works
    on every backend unconditionally, which deletes Codex's fallback branch
    rather than hedging it. Codex conceded this.
12. **A single render offset above each cottage sprite, keyed by `sprite_key`.
    No `SMOKE_ANCHORS` table.** This is Codex's design and Claude conceded it is
    better than its own: one constant beats a hand-measured per-key table that
    nothing re-reviews when the art regenerates, for chimney accuracy that is
    invisible at 320px.
13. **No facade descriptor or render-prefab system.** This overrules Codex, see
    Dissent.
14. **Grass shimmer is cut.** Both workers agree; Claude proposed it as optional
    and Codex argued a UV wobble on 252 ground sprites can expose tile seams.
15. **Drop the smoke determinism claim.** Codex is right and Claude over-claimed.
    Smoke is presentation-only and makes no placement decision, so it does not
    participate in authoring determinism at all. Say that narrowly rather than
    promising a property the implementation cannot establish.
16. **Smoke ships independent of the character-art decision.** Codex's point: it
    should not be blocked behind the spike.

**`src/sim/` is not touched.** Both workers converged on this independently and
for the same reason, which is the strongest signal in the round that the
protected-path boundary is drawn where the team actually understands it: where a
chimney sits is a fact about a texture, not about a town, and pixel offsets in
the headless sim layer are the exact leak `src/sim/` is protected against.

## Division of labor

Split by capability. The evidence used is what each worker demonstrated in phase
2, not what each claimed in phase 1.

| Piece | Assigned to | Why this harness |
| --- | --- | --- |
| Art spike: generate the 3x4 sheet candidate, view at game scale, call the gate | codex-worker | `tools/art/generate.sh` literally shells out to `codex exec` and drives its `image_gen` tool. This is Codex's harness, not a courtesy split, and Claude said so unprompted in its own proposal. |
| Sheet processing path: per-cell height pinned to 160, feet baseline, hue mask across cells, per-variant sheets | codex-worker | Contiguous with the spike and inside the art pipeline it already owns. Splitting the generator from its processor would put the sheet's producer and its consumer in different harnesses. |
| Chimney smoke: `CPUParticles2D` scene plus attachment in `starter_town.gd` | codex-worker | Self-contained, independent of the spike, and the design being built is Codex's own. |
| Player controller and animator: resolved-motion drive, per-tick displacement, facing state, `set_appearance()` lifecycle | claude-worker | Overruling Codex's phase-1 claim on this slice. Claude's critique traced `offset = -80` through `resize_to_longest_side()` to the 160px contract and out to the y-sort key, and caught the typed-`Sprite2D` test breakage that Codex's proposal asserted would not happen. That is demonstrated command of exactly these files. |
| Tests: pose or frame invariants, walking into a collider, idle-facing retention, appearance-before-tree-entry | claude-worker | Same reasoning, and the integration tests Codex asked for are tests of the contract Claude is building. |

Codex claimed the "Godot integration and verification slice" in phase 1 and does
not get it. This is the one place the capability split contradicts a phase-1
claim outright, and the reason is that phase 2 produced evidence phase 1 could
not: Codex's proposal made three factual claims about these specific files that
turned out to be wrong, and Claude's critique is what established that.

## Dissent

Codex's facade-descriptor argument lost. Recorded verbatim:

> **What I am attacking:** A render-side table keyed only by `sprite_key`
> supplies one normalized smoke anchor for every instance of a facade, and
> `starter_town.gd` attaches `CPUParticles2D` while building sprites.
>
> **Why it is wrong or costly:** Claude is correct that pixel offsets do not
> belong in `TownLayout`; putting them in `src/sim/` would violate the
> simulation/rendering separation rule. But `sprite_key` alone only works while
> every use of a texture has identical orientation, scale, and chimney
> configuration. It cannot represent a mirrored cottage, a chimneyless damaged
> variant, multiple chimneys, or instance-level visual overrides. The proposal
> admits regeneration can move the chimney, but the larger hidden cost is that
> the table becomes an implicit render-prefab system inside `starter_town.gd`.
> As authored towns grow, every facade-specific effect would add another lookup
> and attachment branch to the town assembler.
>
> **What should happen instead:** Keep smoke wholly render-side, as Claude
> proposes, but make the facade a render prefab scene or give the render layer a
> small facade descriptor containing texture plus effect anchors. `TownLayout`
> can continue to expose only its existing semantic `sprite_key`. Cut grass
> shimmer from this dispatch unless an in-engine prototype shows that it
> preserves seams. This preserves the constitution while leaving a path beyond
> two identical cottages.

Overruled on YAGNI grounds. `town_layout.gd:122,126` place exactly two cottages,
`cottage_a` and `cottage_b`, both unmirrored and identically configured. The
mirrored cottage, the chimneyless variant, and the multi-chimney facade are all
hypothetical, and a descriptor layer built for them today is a render-prefab
system with two entries and no second caller. Claude's own critique makes the
narrower version of this point well: "attach one instance at a render offset
above each existing cottage sprite" reads like an unbounded loop and it is n=2.

The objection is not wrong about the direction of travel, and it is recorded
here rather than dismissed because it is likely to become right. The trigger to
revisit is the second facade-specific effect, or the first facade that is
mirrored or differently configured, whichever lands first. At that point the
descriptor is worth building and this record should be superseded rather than
argued with.

**No constitution violation was claimed by either worker.** Claude stated
explicitly and unprompted that none of its objections were that, and that it
wanted this on the record precisely because such an objection would escalate to
Scott rather than being settled here. Codex claimed none either. This record is
therefore the orchestrator's to decide, and it was decided.

**The critic seat was not invoked.** Neither trigger fired: the round converged
rather than deadlocking (each worker conceded the other's central point), and
this decision touches no protected path. Per `roles/orchestrator.md`, routine
synthesis stays two-voice and the critic is not invoked because a decision feels
weighty.

## Protected paths touched

None.

Both proposals independently avoid `src/sim/`, and the synthesis holds them to
it. Note for the reader who checks: TEAM-STATE.md's phase-0 forecast flagged
`src/sim/town_layout.gd` as a live possibility, on the theory that ambient town
motion might want authored anchors. It did not. Both workers rejected that move
on their own, unprompted, and for the correct reason.

## Sign-offs

    Signed-off-by: claude-worker <claude@sentania.net> 2026-07-17T00:13:00Z
    Signed-off-by: codex-worker <codex@sentania.net> 2026-07-17T00:13:44Z
