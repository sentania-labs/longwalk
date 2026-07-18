# Binding QA rubric: the COMPOSED SCENE (decision 016)

Orchestrator-authored acceptance target for the composition/integration round.
This REPLACES the dirt-defect rubric (qa-agy-dirt-00N) as the round-016
acceptance bar. Scott directed this rewrite explicitly: eight prior passes
graded enumerable ground-texture defects while the two tells his eye caught
(contact shadows, cutout flora) were never on any rubric. This rubric grades
what his eye grades.

The agy QA seat applies this rubric and writes its report to
`docs/art/village/qa-agy-composition-0NN.md`. The orchestrator independently
decodes against it before believing any result.

## Rule 0: the unit of grading is the COMPOSED SCENE at 1x

Grade the whole district as one image at 1x zoom (0.5x and 2x are supporting
evidence, not the primary unit). The question is NOT "is there a named defect
in the dirt." The question is: **does this read as ONE painted world, the way
the spike does, or as separate sprites pasted onto a ground plane?**

Compare side by side against `docs/art/iso-five-asset-spike.png` every pass.
The spike is the bar. "Confusable" means a viewer cannot tell that our scene
was composed from parts and the spike was painted whole.

## The four graded dimensions

Each dimension is scored PASS / TELL. A TELL names the exact object(s), the
exact seam, and where in the frame (with a 1x crop reference). A single
un-mitigated TELL that Scott's eye would catch fails the pass. "No enumerable
defect" is NOT a pass; the composed-whole read is the pass.

### D1. Object grounding (contact shadow + seating)

Does each object sit IN the terrain or ON it? Check:
- Every ground-contact object (buildings, trees, bushes, fences, signs, rocks)
  has a grounding shadow that reads as cast onto the earth, consistent in
  direction and softness with the others and with the scene light.
- No object floats (shadow absent or too weak) and none looks stamped (shadow a
  hard uniform ellipse with no relation to the object's real base shape).
- Building foundations meet the ground without a visible hard sprite edge.
- TELL if: a building/tree reads as pasted-on; shadows disagree in direction;
  the shadow is a visible generic ellipse; an object hovers.

### D2. Object-terrain interaction (worn/transition zones)

Is there any earth-to-structure interaction, the way the spike has worn dirt at
thresholds and grass meeting foundations? Check:
- Some transition treatment (worn band, scuffed earth, grass creep, or painted
  interaction zone) where high-traffic structures meet the ground, not a razor
  boundary between sprite and plate.
- The treatment is consistent with the ground it sits on (palette, not a
  pasted-in different-dirt patch).
- TELL if: every structure meets the ground on a hard clean line with zero
  interaction; or an interaction band is itself a visible pasted patch that
  disagrees with the surrounding ground.

### D3. Flora integration

Do trees, bushes, and flowers belong to THIS ground, or are they grey-background
cutouts dropped in? Check specifically:
- No hard alpha-mask edge visible on any flora (the octagonal bush edge Scott
  caught is the canonical failure; look for it on `bush_a/b`,
  `flower_cluster_a/b` first).
- Flora palette and value sit in the scene's light, not brighter/cooler/flatter
  than the ground and buildings around them.
- Flora scale reads correct against the buildings and ground cells.
- Flora bases blend/feather into the ground (soft contact), not a clean cut.
- TELL if: any visible cutout edge; flora palette pops out of the scene; a bush
  looks like a sticker; flora shadow/grounding disagrees with D1.

### D4. Scene-level lighting coherence

Does one light govern the whole scene? Check:
- A single consistent light direction and warmth across ground, buildings, and
  flora (no object lit from a different angle or with a different white point
  than its neighbors).
- Highlights and shadow sides agree across objects.
- The global grade does not wash out or tint one object class differently.
- TELL if: an object class reads as lit by a different sun; the scene looks like
  a collage of separately-lit pieces.

## Verdict

- **CONFUSABLE**: all four dimensions PASS and the 1x composed scene reads as
  one painted world confusable with the spike. This is the trigger to surface a
  build to Scott for his OWN eye. It is NOT an auto-GO to expansion; Scott's
  playtest verdict on the composed scene gates expansion, the automated seat
  does not.
- **NOT-CONFUSABLE**: at least one dimension carries a TELL. Name it precisely
  (object + seam + frame location + 1x crop) so the next round can target it.

## Method notes for the seat

- Always render at spike framing and put the spike beside the district crop.
- Decode the actual committed PNGs, never a claim. Verify workdir is the real
  worktree, not an agy scratch project (check the marker).
- Texture fidelity is OUT of this rubric. Do NOT raise dirt-mottling,
  dirt-tone, stone, or fill-island tells; those are locked/closed. If the ONLY
  thing you can find is a dirt-texture nit, that is a PASS on this rubric.
