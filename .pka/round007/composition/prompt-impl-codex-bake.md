# Implementation slice (decision 016): the OFFLINE seam bake (codex-worker)

Full synthesis is `docs/decisions/016-composition-integration.md` on your branch
(read it). You are building the OFFLINE-BAKE half of the converged approach. The
RENDER integration (wiring into `ground.gdshader` / `village_render.gd`,
tuning against captures) is claude-worker's separate slice and is NOT yours;
your job is to produce the baked assets + the manifest schema/contract claude
consumes, plus the tests. Branch: `codex/016-bake`, already checked out off
round head `4022fb8` (contains the decision record).

## What you own (offline, deterministic, render-side)

1. **Footprint interaction field baker.** A new offline baker (follow the
   decision-011 pattern in `tools/art/bake_lane_mask.gd`, `TEXELS_PER_CELL := 16`,
   i.e. 256x224 for the 16x14 district) that reads
   `src/sim/town_layout.gd::build_inn_green_district()` (READ-ONLY; the baker is
   a tool, it does not modify `src/sim/`) and emits a committed, export-visible
   asset under `assets/village/`: a signed-distance / coverage field to building
   footprints for the worn apron, plus its OWN deterministic wear channel and
   explicit per-kit DOOR metadata (concentrate threshold wear at entrances; do
   NOT reuse `lane_density`, which is seed-7007 lane-shoulder wear and is
   semantically wrong for foundations). Pure function of layout + fixed params,
   no RNG/time. Document the exact channel layout in a short note so claude can
   sample it.

2. **Per-object grounding shadows.** EXTEND the ALREADY-EXISTING
   `tools/art/process_assets.py::derive_shadows()` (line ~157: it derives cast +
   contact from a basal `footprint_slice` with a `light_vector` + `GaussianBlur`).
   Produce, per placement kit, a basal-alpha CONTACT mask + a SHORT directional
   CAST under ONE measured light vector inferred from the spike
   (`docs/art/iso-five-asset-spike.png`). Casts stay SHORT grounding pools (do
   NOT attempt long physically-accurate casts). Basal silhouette only, never a
   full-sprite shear (that projects roof/canvas and is invalid). These replace
   the generic `shadow_decal.png` ellipse; commit them under `assets/village/`
   and declare them in the manifest.

3. **Flora rematte.** For `bush_a`, `bush_b`, `flower_cluster_a`,
   `flower_cluster_b`, `tree_large`, `crown_foliage`: ground-aware matte + RGB
   DECONTAMINATION against the estimated background + tight 1-2px feather + keep
   small leaf/flower components + per-kind tonal nudge toward the scene key + a
   basal contact nest (crown gets decontamination + tonal only, no ground
   contact). A runtime alpha-smoothstep is NOT sufficient (the polygon crops are
   alpha 255/0; grey is IN the RGB). **HARD STOP:** if the boundary RGB is not
   explained by a recoverable background (the `provenance: slice` crops may carry
   painted grass from the spike, not uniform grey), do NOT destructively erode
   petals. Commit what is recoverable, write a `.team/blocked/` marker naming
   which flora need a scoped regeneration, and report it. Paid Meshy regen is
   NOT your call to make unilaterally; escalate it.

4. **Manifest schema / contract.** Extend `assets/village/manifest.json` (and
   whatever `process_assets.py` manifest drives the bake) with the render-only
   records claude needs: field asset path + channel semantics, per-kit shadow
   (contact/cast) paths + the shared light vector, per-kit tonal targets, door
   metadata. This schema is the contract; write it so claude can consume it
   without guessing.

5. **Byte-stability / layout-drift test.** Add a test asserting the field bake
   is byte-identical for the same layout + params, and that it FAILS if the
   layout-derived bytes drift (the CI drift guard the decision record requires).
   Wire it where the suite runs (`tools/run_tests.sh`) if appropriate.

## Constraints (from the constitution + the decision record)

- Sim/render separation is HARD: the baker READS the texture-free layout; it
  must NOT write to `src/sim/` or move visual data into it.
- Determinism: pure function of inputs, no unseeded/time RNG, no order-dependence.
- Export-safe: every asset ships through `ResourceLoader` off
  `res://assets/village/` (proven by the export gate). No `Image.load` of a game
  texture at runtime.
- Ground/dirt TEXTURE is frozen (decisions 010-015). You may read/sample the
  ground but must not retune the plate/detail/lane bakes.
- No em-dashes anywhere (code, comments, commits). Hard rule.

## Deliver

- Commit progressively on `codex/016-bake` (each coherent piece its own commit
  with your `Co-authored-by: Codex <codex@sentania.net>` trailer) so a cap-kill
  never loses finished work. Do NOT push (only the orchestrator pushes).
- After the bake, run `tools/run_tests.sh` and the export gate
  (`tools/art/village_export_gate.sh` or the documented gate) and confirm GREEN
  on your tree; if regenerating assets changes the export checksum, that is
  expected (new seam/field assets), but the suite must pass.
- Report every commit SHA (full 40-char) and the branch, plus a one-paragraph
  note to claude describing the manifest schema / field channel layout so the
  render slice can consume it. Your turn is over when the bake is committed and
  the SHAs + schema note are reported, not before. If you hit the flora HARD
  STOP, that is a reported partial with a blocked marker, not a failure.
