# Candidate B provenance (generative stylization arm)

Candidate B is the generative-stylization arm of the round-006 Meshy pilot
(decision 009, dual-candidate fidelity gate). The question the pilot measures:
does generative stylization close the fidelity gap to the spike better than
candidate A's deterministic NPR, judged anonymized against the spike under the
decision-009 rejection rules?

## Design choice (decision 009 Q1): option 1, texture-space albedo restyle

I chose **option 1: texture-space albedo restyle, applied once per asset**, over
option 2 (single fixed-seed whole-sheet pass).

Justification: option 1 structurally cannot boil. The generative step touches only
the mesh albedo, once per asset; every one of the 48 player frames and the cottage
frames is then produced by the SAME deterministic Blender render of that single
restyled texture. There is no per-frame generative call anywhere (decision 009
constraint, banned unanimously), so inter-frame temporal consistency is guaranteed
by construction rather than hoped for. Option 2 (stylize the assembled sheet once)
is admissible but would have to prove frame-to-frame landmark stability after the
fact; option 1 removes that risk at the source. It is also the form decision 009
names as "the recommended form."

Apples-to-apples with candidate A: candidate B renders the SAME cleaned geometry
(`cleaned/player_walk.glb`, `cleaned/cottage.glb`), through the SAME 30 degree
ORTHO isometric camera, the SAME warm-key + cool-fill lighting, 32 Cycles CPU
samples, 1024x1024 transparent output, into the SAME 160 px cells at the SAME
contact anchor with the SAME grounding shadow. The ONLY variable is the surface:
candidate A recovers painterliness with a deterministic 16-colour palette
quantisation + normal-derived NPR shading; candidate B uses a Meshy-restyled mesh
albedo and the 3D render lighting, with no palette quantisation and no synthetic
re-lighting (see `tools/art/treat_candidate_b.py`). This isolates the
fidelity-recovery MECHANISM, which is exactly what the gate compares.

The restyled albedo is applied onto the cleaned mesh's own UVs, NOT rendered from
the raw Meshy retexture mesh, so mesh, UVs, pose action, and silhouette stay
byte-for-byte candidate A's geometry. Meshy retexture was run on each cleaned
mesh's direct Meshy parent task with `enable_original_uv=true`, so the restyled
albedo occupies the same UV space the cleaned GLB already uses; a smoke render
confirmed the texture maps cleanly onto the mesh with no UV scrambling.

## Service / model version

- **Service:** Meshy AI, OpenAPI v2, via the wired `meshy` MCP server (service tag
  `meshy-6`).
- **Model:** both retexture calls used `ai_model = "meshy-6"` explicitly.
- **Seeds:** the retexture MCP interface exposes no seed parameter and the task
  responses return no server-side seed. This is an archival-reproducibility
  limitation identical to the generation slice: the prompts and every other
  parameter are recorded so a human could re-request an equivalent restyle, but
  byte-identical regeneration of the albedo is not guaranteed by the API. It does
  not affect determinism of the shipped pipeline: the restyled albedo PNGs are
  frozen and committed, and the render + composite + assemble chain downstream of
  them is a pure function of committed inputs with no further Meshy call
  (decision 009 constraint 7).

## Paid-call ledger (decision 009 paid-service discipline)

- **Balance before any call: 2990 credits.**
- **Balance after both calls: 2970 credits. Delta: -20, exactly the two declared
  calls. No anomaly, no speculative re-roll, no double-launch.**
- Player albedo retexture: 10 credits.
- Cottage albedo retexture: 10 credits.
- **Total: 20 credits. Two paid generative calls, within the <= 3 budget.**

Balance was checked with `meshy_check_balance` immediately before the first call
(2990) and immediately after both completed (2970).

### Task chain

| Asset | Parent task (retextured) | Retexture task ID | Params |
| --- | --- | --- | --- |
| player | rig `019f7212-389f-7836-84b3-d3dc5137864b` | `019f7275-96c8-7acf-94ac-cfa520a39eff` | retexture; ai_model=meshy-6; enable_original_uv=true; enable_pbr=false; remove_lighting=true; target_formats=[glb] |
| cottage | refine `019f720c-dc68-7777-9328-f9616788c3d0` | `019f7275-a259-76a1-a6c7-8d87bb7bf512` | retexture; ai_model=meshy-6; enable_original_uv=true; enable_pbr=false; remove_lighting=true; target_formats=[glb] |

The parents are the direct Meshy ancestors of the committed cleaned GLBs (the rig
task for the player, the refine task for the cottage), so their UV layout matches
the cleaned meshes.

### Prompts (verbatim)

Player `text_style_prompt`:

> Hand-painted painterly storybook texture, muted earthy Two Rivers village
> palette, soft matte non-photoreal brushwork. Grey-green homespun wool tunic, tan
> trousers, brown leather belt and worn boots, weathered natural skin, short brown
> hair. Desaturated warm earth tones, gentle soft diffuse shading, no glossy
> highlights, no metallic sheen, no bright saturated fantasy colors. Rustic humble
> medieval villager, clean readable silhouette at a distance.

Cottage `text_style_prompt`:

> Hand-painted painterly storybook texture, muted earthy Two Rivers village
> palette, soft matte non-photoreal brushwork. Weathered pale plaster walls, dark
> oak timber framing, golden-brown thatched straw roof, worn wooden plank door,
> brick chimney. Desaturated warm earth tones, gentle soft diffuse shading, no
> glossy highlights, no metallic sheen, no bright saturated fantasy colors. Rustic
> humble lived-in medieval village cottage.

Downloads used `meshy_download_model` with the default output location. `save_to`
was NEVER passed (binding constraint from the 2026-07-17 meshy-live directive); the
returned bytes were written under this worktree by copying the auto-saved
`meshy_output/` files (gitignored) into this directory.

## License note

Per Meshy's Terms of Service in effect at generation time, textures generated
under a paid Meshy subscription are owned by the account holder with commercial-use
rights. Recorded as the service reports it; re-verify against current Meshy ToS
before any production adoption (separately escalation-gated to Scott per decision
009 constraint 8). No second external dependency was used.

## Committed generative outputs (frozen; the reproduce chain re-renders from these)

```
df295f4f76b1ca2a0857053c555b3a324c3dcbf651be0c5ad698cfc8048570d6  player_restyled_albedo.png
f84c7b32abf9c52a0cb73866c0a716777818cba17afddc6e8bc1e156bdf18245  cottage_restyled_albedo.png
```

Both are 2048x2048 base-colour textures (the Meshy retexture output, `remove_lighting`
applied). The full retextured GLBs are redundant for this pipeline (they carry the
raw retexture mesh, whose cleanup we do not want) and are not committed; the albedo
PNGs are the load-bearing generative artifact, applied onto the committed cleaned
geometry at render time.

## Source inputs (identical to candidate A)

```
cb6198812bcba697740930be25a93ef01f265c4656d9a4f6602b87a96218f7e8  ../cleaned/player_walk.glb
465ac88c27e1b0940b6c2862e5d0546189cc81685fe1b2c31d42d215d45abdae  ../cleaned/cottage.glb
```

## Rejection-rule assessment (decision 009)

Checked against the four rejection rules the pilot measures. Assessment is from
the committed atlas and cottage sprite plus per-frame render inspection.

- **Landmark mutation (door/chimney move, limb count change): PASS.** The
  generative step is texture-only; geometry, UVs, and pose action are the cleaned
  mesh, untouched. No door, chimney, or limb can move or be added, because nothing
  regenerates geometry. Verified the player silhouette carries two arms, two legs,
  one head in every facing.
- **Boiling between frames: PASS by construction.** One albedo per asset, then a
  deterministic render of every frame. There is no per-frame generative pass, so
  there is no source of inter-frame texture churn. The albedo is identical across
  all 48 player frames.
- **Silhouette readability: PASS.** The restyle preserved the clean readable
  villager silhouette; the muted palette keeps figure/ground separation at iso
  distance. (See atlas.)
- **Palette drift into glossy fantasy: PASS.** `remove_lighting=true` and the
  prompt's explicit "no glossy highlights, no metallic sheen, no bright saturated
  fantasy colors" held: the output stayed on the muted grey-green / tan / brown /
  earth palette. No specular sheen, no saturated fantasy hues.

Honest finding for the gate (not a rejection): because the base Meshy albedo was
already muted and earthy, the restyle is SUBTLE at shipping iso size rather than a
dramatic painterly transformation. Whether that subtle restyle closes the fidelity
gap to the spike better than candidate A's deterministic NPR is precisely the
question the anonymized acceptance gate must answer; candidate B does not
pre-judge it. The restyle is faithful, in-palette, and mutation-free and
boil-free; its magnitude is a real data point.

## Cleanup-labor ledger (decision 009 constraint 6)

Generative-stylization side, candidate B:

- **Rejected generations: 0.** Both retextures were accepted on the first pass; no
  re-roll was launched (paid-discipline budget preserved).
- **Per-frame hand-painting: 0 minutes.** Every frame is scripted; the restyle is a
  single per-asset texture, applied identically on every render.
- **Texture/UV repair: 0 minutes.** `enable_original_uv=true` kept the restyle in
  the cleaned mesh's UV space; the smoke render confirmed correct mapping with no
  manual UV fix.
- **Stray-geometry note (shared with candidate A):** the cleaned
  `player_walk.glb` ships a stray, unparented, unskinned `Icosphere` at the origin
  (a unit sphere enclosing the legs) that would render as a blob. Candidate B's
  loader drops any non-armature-skinned mesh before rendering (0 minutes, scripted).
  Candidate A's loader does not strip it; flagged to the orchestrator so the
  comparison is not confounded by a blob in one arm only.

## Reproduction (no network)

From the repository root, after the pinned Blender archive is installed locally:

```bash
assets/art_src/pilot/candidate_b/reproduce.sh
```

The script re-renders both cleaned GLBs with the committed restyled albedos,
composites, assembles the atlas, and runs all three validators. No Meshy call, no
network access. Production render time on this CPU: PLACEHOLDER_RENDER_TIME.
