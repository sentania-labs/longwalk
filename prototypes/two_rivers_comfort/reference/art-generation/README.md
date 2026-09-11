# Two Rivers generated village kit

Built-in imagegen produced six isolated references using the supplied Two Rivers close village image as the style reference. Meshy 7 converted each to a textured 2K GLB. Six successful tasks cost 180 Meshy credits total. Prompts, task IDs, settings, actual face counts and file sizes are in generation.json. Original imagegen files are retained in the default generated_images directory; these PNGs are project copies.

All six GLBs were imported into Godot 4.3 and rendered from four diagonal angles in an isolated inspection project. The saved *-45.png files show actual Godot output, not generation promises. Building fronts face +Z. Model origins are not ground normalized; use their actual world bounds to center X/Z and seat their minimum Y.

| Asset | Raw bounds size X/Y/Z | Suggested height | Assessment |
| --- | --- | --- | --- |
| inn | 1.901 / 1.221 / 1.154 | 8.5 m | Broad two-story thatch, full rear geometry, readable doorway |
| hall | 1.902 / 1.079 / 1.222 | 7 m | Broad rural meeting hall, small bell housing, shingle roof |
| farmhouse | 1.904 / 1.237 / 1.310 | 5.2 m | Thatch and timber cottage, side lean-to |
| barn | 1.165 / 1.023 / 1.898 | 6 m | Long timber barn, open front doors, interior is illustrative only |
| market | 1.902 / 1.491 / 1.059 | 2.8 m | Cloth canopy, produce counter, open supporting posts |
| oak | 1.871 / 1.684 / 0.979 | 9 m | Muted olive color and good trunk, but shallow crown and angular leaf clumps |

The oak does not meet the requested rounded foliage quality close up. Keep it a prototype or distant placement asset, pending a dedicated foliage workflow. No paid retries were made. These are complete static models, not modular construction kits or enterable interiors.
