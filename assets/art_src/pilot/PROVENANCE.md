# Pilot asset provenance manifest

Decision 009 (constraint 8) provenance record for the round-006 Meshy pilot:
exactly one 2x2 half-timbered cottage and one player character, authored through
Meshy AI only. This is the generation slice (claude-worker). Blender cleanup,
rigging tuning, rendering, and in-engine integration are separate later slices.

- **Branch:** `claude/006-pilot-gen` (cut from `round/006-two-rivers`)
- **Generated:** 2026-07-17 (UTC), task IDs below carry exact timestamps.
- **Committed local inputs:** `assets/art_src/pilot/cottage/` and
  `assets/art_src/pilot/player/`. These are what the acceptance gate re-renders
  from (decision 009 constraint 7); raw `meshy_output/` scratch is gitignored and
  not committed.

## Service / model version

- **Service:** Meshy AI, OpenAPI v2, accessed via the wired `meshy` MCP server.
- **Model:** every 3D generation call used `ai_model = "latest"`, which the MCP
  server documents as resolving to **Meshy 6** (`meshy-6`). Preview and refine
  used the same model, as the server requires.
- **Seeds:** the MCP tool interface exposes **no seed parameter** for
  `meshy_text_to_3d` / `_refine` / `remesh` / `rig`, and the task responses do not
  return a server-side seed. Seeds are therefore server-assigned and unrecorded.
  This is an archival-reproducibility limitation: the prompts and every other
  parameter below are recorded so a human could re-request equivalent assets, but
  byte-identical regeneration is not guaranteed because the seed was never
  surfaced by the API. (This is acceptable per decision 009: the pilot freezes the
  committed outputs; it does not regenerate them per play session.)

## License note

Per Meshy's Terms of Service in effect at generation time, models generated under
a paid Meshy subscription are owned by the account holder with commercial-use
rights to the generated output. This is recorded as the service reports it and
should be re-verified against the current Meshy ToS before any production
adoption (which is separately escalation-gated to Scott per decision 009
constraint 8). No third-party asset packs and no second external service (e.g.
Mixamo) were used; the player's walk and run gaits are Meshy's own rig output.

## Cost ledger

Starting balance: **3100 credits**. Ending balance: **2990 credits**. Account
delta: **110 credits consumed**.

Per-task credits I authored and used (the delivered pipeline): **70 credits**
- cottage preview (text-to-3d, meshy-6): 20
- cottage refine (text-to-3d-refine): 10
- player preview (text-to-3d, meshy-6, t-pose): 20
- player refine (text-to-3d-refine): 10
- player remesh (305,823 -> ~120k faces, required to pass the 300k rig limit): 5
- player rig (includes free walk + run animations): 5

**Anomaly (40 credits, NOT authored by me):** the account delta is 110, not 70.
The task list shows two extra `text-to-3d` PREVIEW tasks created in the same
window as my refine calls, whose prompts I did not submit and whose outputs are
NOT in the committed deliverables (see the rejected/anomaly ledger below). They
account for the 40-credit gap and pushed the account total (110) over the ~90
rough ceiling. All generation was already complete when this was discovered from
the balance delta; no further credits were spent. Flagged to the orchestrator.

## Cottage

Two Rivers half-timbered cottage: steep golden thatched roof, dark timber framing
over pale plaster walls, plank door, shuttered windows, brick chimney, sits on a
small base. Modest and lived-in, not a manor.

Prompt (verbatim, both preview and used at refine as the base mesh):

> A small 2x2 half-timbered village cottage, single story, steep thatched straw
> roof, exposed dark timber framing over pale wattle-and-daub plaster walls, one
> low wooden door and small shuttered windows, modest lived-in rustic medieval
> English village dwelling in the spirit of the Two Rivers from Wheel of Time,
> weathered and humble, not a fantasy manor, plain and earthy

Refine texture_prompt (verbatim):

> weathered pale plaster and dark oak timber framing, golden-brown thatched straw
> roof, earthy muted rustic village palette, hand-painted storybook look

Task chain:

| Stage | Task ID | Params |
| --- | --- | --- |
| preview | `019f720a-b20d-7178-90f7-2bf5c7f21116` | text-to-3d; ai_model=latest (meshy-6); target_formats=[glb,obj,fbx]; model_type=standard (default); pose_mode=n/a; symmetry_mode=auto default (deprecated, no effect); should_remesh=default |
| refine | `019f720c-dc68-7777-9328-f9616788c3d0` | text-to-3d-refine; preview_task_id=019f720a-b20d; ai_model=latest (meshy-6); enable_pbr=false (default); remove_lighting=true (default); target_formats=[glb,obj,fbx]; texture_prompt above |
| download | (refine task, format glb/obj/fbx) | via meshy_download_model, default output location only (no save_to) |

Committed files and sha256:

```
e656f0d01ba87ba0a99903fe1864e64457d0991b8f4f5138fe86cb1acfb582c7  cottage/cottage.fbx
ba09b2e5f416f38e5e11afe0c0aa670b4f4fba7d006425686e0f076772d352ba  cottage/cottage.glb
302bc55ad90a1816dc56e9a9865d18d415083e07785bf04cc86ee706ae98f393  cottage/cottage_base_color.png
ad30b560a2f91564e726b5689784876c75a79ab680f0480dc120daeb83cd27dc  cottage/cottage_preview.png
```

`cottage.glb` is the primary, self-contained (embedded texture) Blender-friendly
input. `cottage.fbx` is provided for game-engine round-trip; it references
`cottage_base_color.png`. `cottage_preview.png` is Meshy's render thumbnail, for
reference only. The redundant 74 MB OBJ export was intentionally not committed
(glb + fbx cover the downstream Blender and engine paths).

## Player character

Plain Two Rivers villager: grey-green homespun tunic, brown leather belt, tan
trousers, brown boots, short hair, muted earthy palette, clean silhouette legible
at isometric distance, no tiny fiddly detail. Generated in T-pose for rigging.

Prompt (verbatim, both preview and used at refine as the base mesh):

> A plain medieval village adventurer standing in a neutral straight T-pose with
> arms out horizontal, simple humanoid full body, sturdy earth-toned tunic and
> trousers with a leather belt and boots, short hair, muted clothing colors, clean
> readable silhouette legible at a distance with no tiny fiddly details, a rustic
> humble Two Rivers villager, ordinary person not a hero in armor

Refine texture_prompt (verbatim):

> muted earth-toned homespun tunic and trousers, brown leather belt and boots,
> natural skin and hair, humble rustic villager, hand-painted storybook look, no
> glossy highlights

Task chain:

| Stage | Task ID | Params |
| --- | --- | --- |
| preview | `019f720a-bd35-7b7e-b151-2a906cfc8826` | text-to-3d; ai_model=latest (meshy-6); pose_mode=t-pose; target_formats=[glb,obj,fbx]; symmetry_mode=auto default (deprecated, no effect) |
| refine | `019f720c-e536-777d-8491-536911b702a2` | text-to-3d-refine; preview_task_id=019f720a-bd35; ai_model=latest (meshy-6); enable_pbr=false (default); remove_lighting=true (default); target_formats=[glb,obj,fbx]; texture_prompt above |
| remesh | `019f7211-5d58-72ea-aa17-637e04b62113` | remesh; input_task_id=019f720c-e536; target_polycount=120000; topology=triangle; target_formats=[glb,obj,fbx]. Required: refined mesh was 305,823 faces, over the 300k rig limit |
| rig | `019f7212-389f-7836-84b3-d3dc5137864b` | rig; input_task_id=019f7211-5d58 (remeshed); height_meters=1.75 (nominal, decision 010 player height; Blender slice re-scales). Rig includes free walk + run animations |
| download | (rig task, glb/fbx + walk/run/armature) | via meshy_download_model + curl of the returned signed URLs, default output location only (no save_to) |

`height_meters=1.75` was passed only as the rig's nominal proportion reference; it
does NOT bake final metric scale. These remain UNSCALED drafts; the later Blender
slice imposes decision 010 scale (player 1.75 m sole-to-crown, 32*sqrt(6) px/m
upright render rate). `check_scale_contract.py` is not run here (it validates
rendered sprites, not raw meshes).

Committed files and sha256:

```
30318dcc3f35b888654c77090c0ad76676b29afee7ec0da2629700fb66bba328  player/player_base_color.png
8fd4f365e27080d64bbbd3346e9653c3adb26a16b2e4d8ab515728792b97998f  player/player_preview.png
3e5e15d7f3cf099bca7b62c8917353432748c1f176fe55e86aba881bea0afa32  player/player_rigged.fbx
81cdd36754699d4b5f5f7fb7bcd0b4f25685d352a5dd816a6f5831f28ff04ec3  player/player_rigged.glb
ef59eb0f3475896459730f06815369267db4d67c55d26f9e42be22a7dc266960  player/player_run.fbx
9bb56046b378f7e627594ed6cff5f24e3a1913a67c672e462677911482397f73  player/player_run.glb
4c9ab47ab98529d273f5274b2f40a9889945b9e496f85c696363e68f89862981  player/player_run_armature.glb
da0f063cd2e1eb50ae112a97a50e3cf8708b853f43309cd5ea33df55850053db  player/player_walk.fbx
7dce9bdfa38eac11ac00d1031f8093596a784a778cb4e8e6a320a85158029062  player/player_walk.glb
a03fc4b3e7012aa3ad0312c9fb019b5d85e83b2b6533dc71eff9a495b0e97c6a  player/player_walk_armature.glb
```

- `player_rigged.{glb,fbx}`: bind-pose rigged mesh (Meshy `Character_output`).
- `player_walk.{glb,fbx}` / `player_run.{glb,fbx}`: the free skinned walk/run
  clips the gait-tuning slice needs (`_withSkin`). Both glb and fbx are kept
  because animation round-trip through Blender is often cleaner via fbx (decision
  009 allowed requesting fbx for the player for exactly this reason).
- `player_{walk,run}_armature.glb`: armature-only clips, for reference/reuse.
- `player_base_color.png`: texture referenced by the fbx exports.
- `player_preview.png`: Meshy render thumbnail, reference only.

These are 3D authoring sources, not game resources: `assets/art_src/` carries a
`.gdignore` so Godot skips the whole tree during its import scan (no
`.godot/imported/` bloat, no stray extracted textures next to the raw meshes).

## Cleanup-labor ledger seed (decision 009 constraint 6)

First entry of the cleanup-labor ledger the later Blender slice extends. This
slice is GENERATION only, so the human-minutes-by-category mesh/UV/rig columns are
zero here (they belong to the Blender slice); this seed records only the
generation-side rejection counts.

**Rejected generations, cottage: 0.** The single preview + refine was accepted on
first pass. The thumbnail shows a faithful Two Rivers cottage (steep golden
thatch, dark timber over pale plaster, plank door, shuttered windows, brick
chimney); no re-roll was needed.

**Rejected generations, player: 0.** The single preview + refine was accepted on
first pass. The thumbnail shows a readable plain villager in the target palette;
no re-roll was needed. The remesh step was a technical prerequisite (face-count
reduction to clear the 300k rig limit), NOT a quality rejection.

**Anomaly (not a rejection by me):** the Meshy task list shows two extra
`text-to-3d` preview tasks created during this session that I did not submit and
did not use, costing 40 credits:

- `019f720c-cbdc-7203-9da4-c9d00e66355b`: cottage-themed preview whose prompt
  ("...a simple stone chimney... Full standalone building, no base or ground
  plane.") is not the prompt I submitted. My delivered cottage has a BRICK chimney
  and a small base, matching MY prompt, confirming this orphan was not used.
- `019f720c-db8e-7126-b133-db35e09b1cc4`: player-themed preview whose prompt
  ("...a short cloak... young peasant commoner...") is not the prompt I submitted.
  My delivered player has NO cloak, matching MY prompt, confirming this orphan was
  not used.

These are recorded here for full accounting transparency (constraint 8 wants every
task ID) and flagged as an unexplained anomaly to the orchestrator. They are not
counted as quality rejections because I did not author or evaluate them; they are
orphan tasks whose origin I could not determine, spending 40 unaccounted credits.

## Binding-constraint compliance

- `save_to` was NEVER passed to `meshy_download_model`; all downloads used the
  default `meshy_output/` output location, and curl writes stayed under this
  worktree.
- No second external dependency entered the pilot (no Mixamo, no asset packs).
- `meshy_output/` is gitignored; only curated models, animation data, and this
  manifest are committed.
