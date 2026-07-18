# Village seam bake contract

`footprint_interaction_field.png` is a 256x224 RGBA8 field at 16 texels per
authored layout cell. R is building-apron coverage. G encodes signed distance
to the nearest building footprint as `clamp(0.5 + distance_cells / 4.0, 0, 1)`,
so 0.5 is the footprint edge. B is deterministic threshold wear concentrated
at the manifest door positions. It is independent of `lane_density`. A is
opaque.

`manifest.json.seam_policy` is the render contract. `light_vector_px` applies
to every short cast. Each `shadows` record names same-sized contact and cast
RGBA masks whose alpha is derived only from the basal sprite slice. Door
positions are normalized footprint coordinates. Tonal targets name guarded
scene-key targets for the render grade, not destructive source transforms.

The five polygon-sliced flora sprites retain painted ground colors at their
boundaries. They are intentionally not eroded or rematted because no single
recoverable background explains those RGB values. `crown_foliage` already has
a generated neutral-background matte with feathered alpha. Its manifest tonal
target applies without adding a ground contact mask.
