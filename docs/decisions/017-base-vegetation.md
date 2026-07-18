# 017: base vegetation (anchor the foundations, root the flora)

- **Status:** accepted
- **Date:** 2026-07-18
- **Assignment:** Round 007 / decision 016, iteration 4. Composed-scene QA #004
  (reliable, anti-anchored) verdict on the inn-green district was NOT-CONFUSABLE
  with exactly two remaining tells, both base-to-ground vegetation: D2, building
  foundations meet the ground with a clean edge and lack the spike's foundation
  planting (weeds/stones/grass creeping up the stone); D3, flora bases terminate
  against the dirt without rooting/merging into the terrain. This gap is Scott's
  original complaint verbatim ("some of the buildings don't feel organic to the
  terrain, and the flora doesn't jive"). D1 (grounding) and D4 (lighting) PASS.
- **Orchestrator run:** iteration 4, phase 1 run stamp `20260718-210010`, phase 2
  run stamp `20260718-210613`. See TEAM-STATE.md.
- **Lane:** full protocol (Scott directed full protocol for the round; the D2
  foundation-anchoring fork is a genuine design choice, see below).
- **Workers dispatched:** claude-worker, codex-worker, agy-worker

## Context

Iterations 1-3 of decision 016 graded the shader SEAMS (contact shadows, worn
apron dither, per-kit tonal match) and those PASS at round head `5777b83`. What
remains is not more seam-grading: it is COMPOSITION / PLACEMENT. The spike
(`docs/art/iso-five-asset-spike.png`) anchors EVERY building base with discrete
foundation vegetation and roots its flora into the ground; our pipeline places
standalone sprites on a clean apron with a contact shadow but plants nothing at
the base. The design fork for D2 (foundation anchoring) had three live options:
(1) discrete deterministic prop placement reusing existing flora kits, (2) a
baked per-building foundation-vegetation seam mask, (3) a shader base-skirt band.
D3 (flora base root-merge) is the smaller secondary piece.

## Proposals (phase 1, blind)

| Worker | Branch | Proposal commit SHA |
| --- | --- | --- |
| claude-worker | `claude/016-baseveg` | `65bfca1b2606cdd6e331494c8df111d51a040718` |
| codex-worker | `codex/016-baseveg` | `46a1c2691f6d59dd1f986e58056b1b82ae2bf4e8` |
| agy-worker | `agy/016-baseveg` | `1ff6a8ce8518e1ea79a157cd40dff521c097a0cf` |

All three independently resolved the D2 fork to **option 1, discrete prop
placement** (render-only in `src/render/town/village_render.gd`, reusing existing
`bush_a/b`, `flower_cluster_a/b`, `rock_a/b`, no paid spend), and all three added
a render-side base treatment for D3. The disagreement is narrow.

**claude:** discrete placement via a new `_build_base_vegetation()` emitting
extra flora through the existing object pipeline; determinism via hand-rolled
FNV-1a over `(id, slot)` (explicitly avoiding GDScript `hash()` and any RNG);
per-slot kit/jitter/keep-skip from the hash; door-cell skip; corner weighting.
D3 = a base-AO band in `object.gdshader` gated by a per-material uniform that is
0 for structures, plus tuft reinforcement at flagged flora. Named a derived
`grass_tuft.png` (offline crop/downscale of existing flora pixels, NO spend) as
a gated fallback for the diorama risk.

**codex:** discrete placement deriving instances from building placements;
determinism via explicit 32-bit integer mixing over `(district_seed, cell.x,
cell.y, candidate ordinal)` (no `hash()`, no RNG); clockwise perimeter
candidates, mandatory corners, door rejection, rejection against all authored
non-building contacts, weighted kit table + fixed scale table. A four-invariant
test suite (>=2 anchors/building, no anchor in a door exclusion, byte-equal
repeat, input-reversal invariance) + export audit. D3 = a SEPARATE
`flora_base.gdshader` underlay reusing the baked contact mask, tinted olive-earth,
noise-broken. Identified that no shared "rendering list" exists (`_build_shadows`
and `_build_objects` each iterate `_layout.placements` independently), so a
derived-instance contract with scaled sprite AND scaled seam mask is real work.

**agy:** discrete placement, but determinism via a per-building
`RandomNumberGenerator` walked over the perimeter, seeded `hash(cell.x) ^
hash(cell.y)`. D3 = a base-merge darken in `object.gdshader` keyed to anchor Y.
First-hour plan (praised by both peers): mock the placement loop and test at 1x
whether scaled existing flora read as weeds before building, to settle the
diorama question.

## Critique (phase 2, adversarial)

Critique artifacts: claude `f369615aa638f946a56f4999105745e95d59ca06`, codex
`ee89af141ccfd476957eb646a8ec0422c26aa4fd`, agy
`b2269201c17802c1fc5910acce8f57ef6039f931`.

- **agy's determinism is a constitution violation, named independently by BOTH
  peers.** A per-building `RandomNumberGenerator` walked over the perimeter makes
  each placement depend on iteration order (CLAUDE.md: "generation or visit order
  can never change the result"), and `hash(cell.x) ^ hash(cell.y)` relies on
  `hash()` stability and collides `(x,y)` with `(y,x)`. **agy conceded** in its
  own critique: "I concede that it is significantly stronger than my own
  proposal's naive use of `hash()`." Resolved: pure positional integer mixing,
  no RNG, no `hash()`.
- **The D3 fork is the one contested design question.** codex attacked claude's
  on-sprite band as a flat horizontal `UV.y` stripe that darkens leaves/petals
  (anchors range y=49..119 in the manifest), i.e. the "dirty smudge" claude's own
  proposal named as a risk, and argued the baked contact mask follows the real
  basal silhouette. claude attacked codex's underlay as drawing BEHIND the sprite
  where it cannot touch the sprite's own lit cutout edge (the named defect), and
  risking the iter2 dark-puddle regression. **agy switched sides in critique:** "I
  concede that separating the root-merge into its own underlay is the better D3
  path," and attacked claude's on-sprite band as a smudge. After critiques: claude
  holds on-sprite; codex + agy hold the separate underlay.
- **Candidate rejection scope split three ways:** codex reject-all-authored-
  contacts (claude: over-built, self-conflicts with rooting existing flora; agy:
  "creates unnatural bald halos"); claude door + hard-objects only; agy door only
  ("a weed clipping into a fence is a desirable aesthetic").
- **Diorama/repetition:** all three scale cluster-scale sprites (bush_b ~1 cell
  native) down to weeds; none proved that reads at 1x. Consensus on codex's/agy's
  "spike-scale-first" sequencing (render mandatory corners only at 1x before
  tuning). claude's DERIVED tuft (offline, no spend) endorsed by agy as "absolutely
  necessary"; a PAID regen is scope creep, gated on the reuse test failing.
- **Test discipline:** claude conceded codex's four-invariant suite + export audit
  outright ("genuinely better than mine ... the right bar").

## Decision (phase 3, synthesis)

Discrete, render-only, deterministic base vegetation. Adopted:

1. **D2 = discrete prop placement** (3-0), render-only in
   `src/render/town/village_render.gd`, reusing existing flora/rock kits, no paid
   spend. Rejected the baked mask (cannot supply a silhouette that creeps up the
   stone) and the shader skirt (frozen seam-grading territory; a gradient cannot
   anchor vertical walls under isometric projection).
2. **Determinism = pure positional integer mixing** over the world/district seed
   and the canonical integer candidate coordinate, no RNG and no GDScript
   `hash()` (claude's FNV or codex's integer-mix; equivalent, implementer's
   choice). This is the CLAUDE.md hard rule; agy's RNG-over-perimeter is rejected
   and agy conceded it.
3. **A real derived-instance contract**, per codex's finding: because
   `_build_shadows` and `_build_objects` each iterate `_layout.placements`
   independently, derived vegetation instances must be fed a shared contract that
   scales the sprite AND its baked seam mask by the same factor, carries the
   tonal material, and gets a stable depth key from its own ground contact.
   "Inherits D1/D4 for free" is false until that contract exists and is tested.
4. **Candidate rejection = the middle ground.** Reject the DOOR cell (mandatory,
   navigation readability). Reject where a prop's contact would visibly overlap a
   HARD authored object (fence, sign). ALLOW proximity to the tree and existing
   flora (we WANT to root those, and rejecting there self-conflicts with D3).
   Never reject against derived-placement order (all three agree). Bias keep
   probability toward camera-facing edges (claude's point; none specified it) so
   density is not spent on occluded rear edges.
5. **D3 = a separate flora-only underlay** (`flora_base.gdshader`) reusing the
   baked contact mask, narrow and irregular, kept subordinate to the existing
   passing D1 contact shadow so it does not re-introduce the iter2 dark-puddle.
   Chosen over the on-sprite band (ballots below, 3-1). **Grafted from the losing
   side:** the orchestrator's own QA #004 decode found the flora already carry
   soft contact shadows and the real gap is root-merge, "not a literal hard
   cutout," which is why the underlay (which addresses root-merge into ground) is
   the right primary. IF the mandatory-corners 1x capture shows a residual LIT
   cutout edge on a sprite itself (claude's concern realized), the follow-up is a
   contact-mask-SHAPED darkening on the sprite (NOT a flat `UV.y` band, which is
   the flaw codex identified), gated behind a per-material uniform that is 0 for
   structures. Start with the underlay; add the shaped on-sprite darken only if
   1x proves it necessary.
6. **Sequencing = spike-scale-first.** Render the district at 1x with ONLY the
   mandatory foundation corners and the D3 underlay, compare to the spike, and
   settle the diorama/scale question BEFORE full-density tuning.
7. **Fallback = a DERIVED tuft** (offline deterministic crop/downscale/rematte of
   existing flora pixels via `tools/art/process_assets.py`, committed with
   provenance, export-audited; NO Meshy, NO spend), gated on the 1x reuse test
   failing. A paid regen is the last resort only, with full supervised-spend
   discipline, and is not authorized by this record.
8. **Tests = codex's four invariants + export audit** (byte-equal repeat,
   input-reversal invariance, >=2 anchors per building, no anchor in a door
   exclusion; export audit counts derived sprites and confirms `ResourceLoader`
   resolution).

### Four-ballot on the one contested question (D3 base-merge fork)

Per the voting model, the D3 fork (on-sprite base band vs separate underlay) is
the round's one genuinely contested synthesis question; the ballots are each
doer's on-record position from the proposal+critique round plus the
orchestrator's:

| Ballot | Vote | Interest |
| --- | --- | --- |
| orchestrator | separate underlay | referee; own QA #004 decode found root-merge, not a lit cutout, is the real gap |
| claude-worker | on-sprite base band | party (proposed on-sprite) |
| codex-worker | separate underlay | party (proposed the underlay) |
| agy-worker | separate underlay | switched from on-sprite in critique, conceded the underlay |

**3-1 for the separate underlay. Decided without the critic** (the critic seat
is tiebreaker-only, invoked on a 2-2 split; this is not one). claude's dissent is
recorded verbatim below.

## Division of labor

| Piece | Assigned to | Why this harness |
| --- | --- | --- |
| D2+D3 core mechanism: deterministic positional-hash placement, the derived-instance contract (scaled sprite + scaled seam mask + tonal + depth), door+hard-object rejection, camera-facing keep bias, the `flora_base.gdshader` underlay, the four-invariant + export tests, and the mandatory-corners 1x capture | codex-worker | Compact deterministic GDScript with explicit data contracts, stable sorting, and render-only resource loading is squarely codex's strength; it authored the derived-instance-contract finding and the test suite, and owns the adjacent baked seam-mask / footprint-field territory the scaled masks depend on. |
| Non-author review + sign-off of the impl commit; the 1x composition tuning pass (density/scale/weights); and the DERIVED-tuft fallback if the reuse gate fails | claude-worker | The success condition is perceptual and the main failure mode is repetition, not correctness; claude has the strongest image-comparison workflow (codex itself said this piece belongs to that resident) and designed the zero-spend derived-tuft path. |
| Composed-scene QA #005 (anti-anchoring, vs the binding rubric) after integration | agy-worker | agy's established QA seat; it produces the multimodal composed-scene read that is the acceptance bar above the gate numbers. |

agy gets no implementation slice: its proposal lost on the determinism rule, and
its harness fits neither the deterministic-contract build (codex) nor the
perceptual tuning (claude) better than the assigned owners. That is a normal
capability outcome, not a slight; agy holds the QA seat this iteration.

## Dissent

claude-worker's losing objection to the D3 ruling (separate underlay over
on-sprite band), verbatim from its critique `f369615`:

> The D3 underlay draws in the wrong layer to fix the actual defect. The decode
> calls the flora tell a "hard base line", i.e. the sprite's own bottom lit edge
> reads as a cutout. Codex's `flora_base.gdshader` is "a second, flora-only basal
> underlay in the shared below-object layer" that extends "roughly 3 to 5 pixels
> around the stem". A below-object underlay draws *behind and around* the sprite;
> it cannot darken the sprite's own bottom pixels, because those pixels composite
> on top of it. So the lit cutout edge that is the defect survives untouched;
> codex has widened the ground skirt without dissolving the cut. This is the core
> reason a base-AO belongs *on the sprite* (multiply the bottom band of the
> sprite's own alpha, which mine and agy both do) rather than as a separate
> ground layer. Codex's D3 addresses root-merge-into-ground but not the cutout
> silhouette, and the cutout is the named gap.

And its synthesis-view statement of the same objection, verbatim:

> **D3 base-merge fork (on-sprite base-band vs separate underlay):** on-sprite
> wins. The defect is the sprite's own lit cutout edge; only darkening the bottom
> band of the sprite's alpha touches it (mine and agy), and a below-object
> underlay (codex) cannot, while also risking the iter2 dark-puddle regression.
> Codex's valid concern, that touching `object.gdshader` risks all objects, is
> answered by gating the band behind a per-material uniform that is 0 for
> structures (mine does this explicitly); that is cheaper and lower-risk than a
> whole new shader file plus export wiring plus UV-noise.

This objection does NOT claim a constitution violation; it is a design
disagreement, decided by the orchestrator on a 3-1 ballot and on the merits (the
orchestrator's own pixel decode of QA #004 found the flora already carry soft
contact shadows and the gap is root-merge into the ground, not a lit cutout
edge, which is the premise claude's objection rests on). The ruling grafts the
valid residual of the objection: if the 1x capture shows a lit cutout edge on a
sprite, add a contact-mask-shaped on-sprite darken (not a flat `UV.y` band) as a
follow-up. No escalation to Scott is triggered.

agy-worker's determinism approach also lost, but agy conceded it in its own
critique rather than dissenting ("I concede that it is significantly stronger
than my own proposal's naive use of `hash()`"), so it is recorded as a concession
above, not a verbatim dissent.

## Protected paths touched

None

## Sign-offs

    Signed-off-by: claude-worker <claude@sentania.net> PENDING
    Signed-off-by: codex-worker <codex@sentania.net> PENDING
    Signed-off-by: agy-worker <agy@sentania.net> PENDING
