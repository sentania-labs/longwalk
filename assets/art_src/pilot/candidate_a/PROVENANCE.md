# Candidate A provenance

Candidate A is an offline deterministic NPR and compositing baseline. It uses
only the two cleaned GLB inputs already committed to this repository. No paid
service, network generation, Meshy call, or other remote service was touched.

## Inputs

- `cleaned/player_walk.glb`: SHA-256
  `cb6198812bcba697740930be25a93ef01f265c4656d9a4f6602b87a96218f7e8`
- `cleaned/cottage.glb`: SHA-256
  `465ac88c27e1b0940b6c2862e5d0546189cc81685fe1b2c31d42d215d45abdae`

The render uses Blender 4.0.2, the fixed 30 degree orthographic isometric
camera, Standard view transform, fixed warm key and cool fill lights, 1024 by
1024 transparent output, 32 Cycles CPU samples, and deterministic denoising.
It renders all eight player facings at six poses and all eight cottage facings
at pose zero. The finished cottage delivery selects the W view because its 440
by 437 pixel silhouette fits the 512 canvas intact at calibrated scale. The
other seven raw views remain reproducible inputs for later selection.

## Treatment and anchors

`tools/art/treat_candidate_a.py` applies a fixed earthy 16-color palette,
normal-derived light modulation, a one-pixel dark silhouette treatment, and a
soft fixed grounding shadow. It does not resample the rendered subject. Player
body contact remains at the scale-contract point `[80, 144]`; the cell pivot
and bottom of the grounding shadow are `[80, 159]`. The cottage uses the scale
contract canvas and contact anchor `[256, 448]`.

Cleanup labor was zero minutes of per-frame hand work. The treatment and every
placement are scripted and apply identically on every run.

## Reproduction

From the repository root, after the pinned Blender archive has already been
installed locally:

```bash
assets/art_src/pilot/candidate_a/reproduce.sh
```

The script runs render, treatment, atlas assembly, and all asset validators.
The full production reproduction took 841 seconds (14 minutes 1 second) on the
Codex worker CPU with fixed single-thread rendering. An independent second
reproduction took 832 seconds (13 minutes 52 seconds).
