# Flora regen provenance (decision 016, D3)

Supervised paid Meshy regeneration of the 5 polygon-sliced flora that carried
unrecoverable chromatic painted-grass edge chroma (bush_a, bush_b,
flower_cluster_a, flower_cluster_b, tree_large). crown_foliage was already
generated-clean and is NOT part of this batch. Goal: clean neutral-grey-bg,
spike-style sprites that decontaminate/matte trivially.

## Authorization + guard

- Orchestrator-authorized under deliberate-spend (Scott pre-authorized Meshy for
  in-context flora integration in the composition reframe; precedent: dirt regen
  019f74b2). Not a Scott-escalation category.
- Pre-spend guard: `meshy_check_balance` = 2937 before; `meshy_list_tasks` had
  NO PENDING/IN_PROGRESS tasks (all 27 SUCCEEDED). No double-spend hazard.
- Recipe validated on ONE object (tree) before committing the remaining 4.

## Method

- Tool: `meshy_image_to_image`, model `nano-banana-pro` (9 credits each).
- Conditioning: per-object STYLE CROP from the spike
  (`docs/art/iso-five-asset-spike.png`), so each regen inherits the spike's
  painterly palette/brushwork AND that object's identity. Crops in `crops/`.
- Prompt pattern (per object): "single isolated <object> ... EXACT painterly
  hand-painted style, muted earthy palette, flat even lighting of the reference
  ... Plain flat neutral mid-grey background, no ground plane, no cast shadow,
  crisp edges so it cuts out cleanly as a game sprite." NO grass/ground/rocks/
  buildings/people.
- Downloaded via signed URL curl (NOT `save_to`) to this directory as
  `<id>_regen.png` (1024x1024 RGB each).

## Tasks (all SUCCEEDED, 9 credits each)

| sprite            | task_id                                | source crop           |
|-------------------|----------------------------------------|-----------------------|
| tree_large        | 019f7663-59d6-7a9e-8775-9f6f83301151   | crops/spike_tree.png        |
| bush_a            | 019f7664-558a-74a3-aad8-bccc3d93f885   | crops/spike_bush_red.png    |
| bush_b            | 019f7664-7716-7462-809b-a3a3996b9af4   | crops/spike_shrub_rocks.png |
| flower_cluster_a  | 019f7664-9844-76eb-b247-10a7f358f21f   | crops/spike_flowers_smi.png |
| flower_cluster_b  | 019f7664-b820-7ad9-a2a1-566be8a825da   | crops/spike_flowers_cot2.png|

## Spend

- Balance before: 2937
- Balance after:  2892
- Consumed: 45 credits (5 x 9), matches API `consumed_credits` per task exactly.

## Downstream

These are RAW neutral-bg sprites. codex FINISHES impl slice 1 (decision 016 D3):
rematte (decontamination now trivial on neutral grey) + feather + per-kit tonal
match + basal contact nest, then re-bake seam masks and update manifest, off the
integrated round head. Orchestrator-verified visually: all 5 are clean isolated
objects on uniform mid-grey, spike style, crisp edges.
