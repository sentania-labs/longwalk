# QA Report: Composed Scene #005

**Target:** `docs/art/village/village-inn-green-1x.png` (round 017) vs spike

## D1. Object grounding (contact shadow + seating)
**TELL**
- **Object:** Round dark green bushes (e.g., upper right of the 2x crop, right side of 1x image).
- **Seam:** The shadow underneath the bush.
- **Location:** Scattered in open ground, notably right side of the 1x frame.
- **Observation:** The shadows under these bushes are visible, hard, generic dark ellipses. They do not relate to the bush's real base shape and make the bushes look stamped ON the terrain rather than seated IN it.

## D2. Object-terrain interaction (worn/transition zones)
**TELL**
- **Object:** Blacksmith shop and its front work area.
- **Seam:** Where the anvil and forge tools meet the ground.
- **Location:** Bottom center of the 1x frame.
- **Observation:** The front work area sits directly on the generic dirt/grass ground texture. There is a hard clean line where the structure meets the earth and zero worn interaction zone, scuffed earth, or transition band beneath this high-traffic spot.

## D3. Flora integration
**TELL**
- **Object:** Tall sunflower clusters.
- **Seam:** The base of the stalks meeting the dirt.
- **Location:** Center right of the 1x frame, between the path and the bottom-right house.
- **Observation:** The base of the stalks has a hard, clean cut against the dirt with no feathering or blending into the ground, reading clearly as a pasted cutout.

## D4. Scene-level lighting coherence
**PASS**
- **Observation:** The scene shares a consistent light direction (sun from the top-left) and a generally warm olive palette across the ground, buildings, and tree. No single object class reads as lit by a completely different sun or washes out differently than the rest.

## Verdict
**Verdict: NOT-CONFUSABLE**

**What Scott's eye would catch first:** The hard, generic ellipse shadows stamped under the round dark green bushes, which immediately give away that they are pasted sprites rather than objects rooted in the scene.
