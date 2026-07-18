# Antigravity Critique: Round 007 Village Production

## Critique of Claude's Proposal

**Steelman:**
Claude's proposal guarantees zero style drift and absolute "confusable with spike" fidelity by literally slicing and shipping the spike's own pixels, directly avoiding the medium mismatch that killed round 006. By constructing the village entirely from these sliced sprites, it seamlessly integrates with our proven `building_contact_cell` depth-sort contract and preserves the sim/render separation roadmap without inventing new scene assembly paradigms.

**Attack:**
Slicing the spike fails at village scale and breaks the cohesive ground composition.
First, the spike only contains three buildings. Cloning and recoloring three buildings 12 to 16 times will not look like a bespoke painted village; it will read as a cheap tile-set asset flip. The fallback of image-to-image conditioning is highly optimistic if we expect it to produce 5-9 completely new buildings that perfectly match the sliced ones without drifting.
Second, placing individual sliced sprites onto a grid fundamentally fails to capture the spike's integrated ground layer. The spike's magic comes from soft cast shadows, blended dirt lanes, and painted grass that do not tile cleanly on a diamond grid. The result will look like high-fidelity stickers pasted onto a rigid grid, failing the "no obvious repeated-tile grid" composition bar. Slicing shadows out of a painted scene and expecting them to layer perfectly over generic grass tiles will leave visible lighting seams and edge halos.

**What should happen instead:**
If we want a sprite-based assembly on the grid (which we do, to maintain depth-sort and sim data), we cannot rely on scavenging pixels from a single reference image. We need a reliable generation pipeline capable of producing the volume and variety of assets required (such as 3D blockouts rendered to 2D for consistency, then stylized) so we don't have to resort to recoloring three buildings to populate a town.

## Critique of Codex's Proposal

**Steelman:**
Codex correctly identifies that the spike's success comes from its cohesive, holistic composition rather than individual sticker-like assets. By generating large 2048px district plates, it perfectly captures the integrated lighting, shadows, and painterly ground blending that sprite-on-grid approaches inherently lose, producing a visually stunning and unified result that looks like a painting rather than a game board.

**Attack:**
Codex's approach fundamentally violates the roadmap's sim/render separation and breaks the depth-sort architecture. 
Baking "small props, fences, flowers, shadows, and most trees" into a static background plate means these objects cannot exist as discrete entities in the sim layer's `town_layout.gd`. The constitution explicitly dictates an upcoming ecology system where "flora regrows unless overharvested, and fauna hunt." If trees and flora are painted into a background plate, the sim layer cannot interact with, harvest, or remove them, violating sim/render separation.
Furthermore, extracting only "occlusion-crossing objects" as separate layers is a manual, brittle process. Under a free-cam that zooms in and out, the static 2048px plates will reveal their resolution limits, and the boundary between baked elements and extracted foreground crowns will expose edge artifacts and differing pixel densities. Finally, stitching six generated plates together seamlessly is a massive hidden cost; any prompt or seed tweak to fix one plate will break the overlap seams with its neighbors.

**What should happen instead:**
Every tree, fence, and prop must be a discrete entity in the sim data, rendered as an individual sprite and sorted dynamically by the `depth_key` contract. The ground layer can be painted, but all vertical or interactable elements must be independent sprites to ensure the world is fully interactive and respects the sim/render separation required for the future ecology milestone.
