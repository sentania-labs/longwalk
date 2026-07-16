# longwalk art style guide

Shared style scaffolding prepended to every asset prompt (see
`tools/art/generate.sh`). Keep this file the single source of truth for the
look; edit it, not individual prompts, when the house style changes, and
regenerate affected assets after.

## Reference point

Visual spirit of Warcraft 2, SimCity, and Theme Hospital: a top-down / gently
isometric 2.5D world, simple and readable at a distance, not photorealistic.
Ultima Online is the closer reference for mood (a lived-in persistent world),
not for rendering technique.

## Fixed style parameters (keep consistent across every asset)

- Perspective: top-down with a slight isometric lean, camera angle and light
  direction consistent across every sprite and tile so nothing looks pasted
  in from a different game.
- Rendering: flat, readable shading with simple, clean edges. Low-poly-flat
  3D render look or clean pixel art are both acceptable; do not mix the two
  within one asset set. Default to a low-poly-flat 3D render look unless a
  prompt says otherwise.
- Light direction: soft light from the upper left, consistent across assets,
  soft contact shadow beneath standing objects and characters.
- Palette: warm, readable, moderately saturated. Not neon, not desaturated
  or muddy. Avoid pure black outlines; use darkened versions of the fill
  color for edges if an edge line is needed.
- No baked-in UI text, no watermarks, no logos.
- Background: plain, flat, single light color (not transparent) unless a
  prompt explicitly asks for a tileable ground texture. True alpha
  transparency is out of scope for this pipeline for now; treat background
  removal as a manual post-process step done outside codex if needed later.
- Consistency matters more than beauty. Placeholder-quality output that
  reads clearly at small size and matches the rest of the set beats a
  striking one-off that clashes.

## What NOT to do

- No photorealism, no painterly/watercolor treatment, no anime style.
- No text rendered into the image.
- No signature-style flourishes that would stand out as "one artist's odd
  piece" next to the rest of the set.
