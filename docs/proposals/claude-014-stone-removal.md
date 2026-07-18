# Decision 014 proposal (claude): source-level de-clutter of the painted dirt stones

## Problem

After agy QA pass 6 the Two Rivers dirt path carries ONE dominant NOT-CONFUSABLE
tell: ~15-20 discrete, high-contrast grey lozenge STONES (plus a stray amber
rock and dry grass tufts) littering the open dirt. The spike path
(`docs/art/iso-five-asset-spike.png`) has none of these; its dirt is smooth dry
dusty tan with fine speckle, its only rocks being scenery-prop clusters at grass
edges. Decision 013's de-peak follow-on (`docs/art/village/dirt-depeak-013.md`)
PROVED by rendered measurement that no luminance-band operator dissolves these
stones at any strength: a painted rock is coherent across every frequency band
at once, so it is not a statistical outlier in any single band. The stones are
PAINTED CONTENT in the source plate
(`.pka/round007/ground-source/dirt-regen-nbpro-019f74b2.png`); they must be
removed at the source. Zero paid credits: this is an image-processing operation
on the existing source plate, not a Meshy regen.

## Approach (build, not just propose)

A new deterministic authoring pre-step, `tools/art/declutter_dirt_source.py`,
runs UPSTREAM of the existing multiband reshape. `grade_dirt_plate.py` imports
`declutter` and applies it in-memory as the first line of `grade()`, before the
reshape. The de-peak operator from `bdfaa28` is KEPT (it is now a near-noop on
the decluttered source, harmless, and preserves the established gate story).

### Detection (segment only the debris, keep the substrate)

The dusty-tan substrate between the stones is already spike-correct, so the mask
targets only the debris:

- **grey stones** by SATURATION, not luminance. The warm tan substrate sits at
  saturation ~0.44-0.48; the grey stones are the desaturated tail (absolute
  `sat < 0.40`) OR pixels markedly greyer than their own local dirt (local-sat
  deficit `> 0.06`). Saturation is the clean separator: the brown brush-stroke
  streaks that carry the accepted substrate richness are DARK but still
  saturated, so a saturation gate KEEPS them (a luminance/contrast gate would
  eat them and flatten the core). This was the decisive discriminator.
- **amber rocks**: redder than tan (`R-G > 44`) AND darker than the local field.
- **grass tufts**: green (`greenness > 11`), taken only where a solid core
  survives an erosion (isolated green substrate speckle is not a tuft), then
  dilated generously so thin blades are covered.

The chroma seeds are closed (bridge a stone interior), opened (drop sub-blob
substrate speckle), and dilated (cover each stone's soft cast-shadow halo).
Final debris coverage: **8.65%** of the plate.

### Fill (why this method, and why not the alternatives)

Fill = **smooth harmonic base + deterministic substrate-grain transplant**, in
pure numpy (no cv2, no scipy):

1. A weighted image-pyramid **pull-push** solves a smooth membrane across each
   masked region whose value matches the surrounding substrate EXACTLY at the
   mask boundary (Dirichlet). A few full-resolution Jacobi smoothing sweeps erase
   the pyramid's nearest-neighbour blockiness. Because the substrate under a
   stone is just smooth tan with no sharp content, this diffusion introduces no
   blur-smear tell: there is nothing sharp to smear.
2. The source's own dusty-dirt texture (the radius-16 high-pass) is transplanted
   back over the smooth base by a FIXED integer roll of the whole grain field.
   The roll lands each masked pixel on real substrate texture from elsewhere in
   the SAME source; grain sampled from a masked location is zeroed, so a stone's
   own speckle is never re-injected. Only the sub-16px residual moves (no rock
   bodies, which live in the low band the membrane replaced), so there is no
   visible clone-stamp of structure, and the fine-grain statistics that drive
   the core richness and the shimmer band are preserved.

Rejected alternatives and why: **cv2 Telea/NS inpaint** smears the boundary edge
inward and leaves a locally-flat smudge (a new tell), and cv2 is not even
available in this environment; **whole-patch exemplar transplant** risks the
visible clone-stamp/repetition tell; **pure harmonic infill** with no grain
re-injection reads as a flat smudge and drops the protected-core std. The
membrane+grain split takes the seamless boundary of the harmonic solve and the
real richness of a transplant while avoiding both of their failure modes.

### The flat-core coupling, and the elegant fix

Removing the stones removed real core variance: post-declutter the rendered
protected-core std fell to **16.81**, below the 18.44 floor, because the
high-contrast stones had been PROPPING UP that std. Widening the grain
transplant alone recovered only to ~17.0 (real substrate simply is not that
variable). The clean fix falls out of the history: decision 013 attenuated the
mid band (12-64 texels) gain HARD to 0.55 for ONE reason, to suppress the
stones' rock-blob prominence. With the stones now removed at the source, the mid
band carries only the substrate's dusty brush-streak tonal variation
(spike-consistent richness), not rock blobs, so that suppression is no longer
needed. Restoring **mid 0.55 -> 1.30** returns the dusty tonal richness to the
protected core (core std back to **19.22**) without reintroducing any tell: the
plate-rock <-> rendered-shoulder xcorr stays ~0 (the detail bake's R shoulder
reads the radius-3 fine band, not mid) and the macro mud band is untouched.

## Determinism (constitution)

Pure function of the committed source bytes. Every primitive is an
order-independent reduction: wrapped separable box blurs (kernel wrap only),
box-count morphology thresholds, fixed-count pull-push and Jacobi sweeps, and
fixed integer `np.roll` offsets. No `randi`/`randf`/`RandomNumberGenerator`, no
time, no visit-order accumulator. Re-running on the same source yields
byte-identical output. The `.pka` source is never overwritten; the declutter is
applied in-memory, and a cleaned-source PNG + a detection overlay are emitted to
`docs/art/village/dirt-source-declutter/` for review only.

## Gate numbers (rendered decode, `tools/art/decode_dirt_gates.gd`)

- **Flat-core gate: protected-core luminance std = 19.22** >= 18.44 pass-4 floor
  (margin 0.78). Trajectory: 19.90 shipped -> 16.81 declutter-only ->
  19.22 with the mid restoration. HOLDS.
- **Shimmer-ceiling gate: shoulder-dirt gradient 10.07** <= grass ceiling 10.28.
  The plate fine(<3) band RMS actually DROPPED (14.74 -> 13.02; the fine gain is
  untouched), so the 0.5x rendered fine-gradient can only fall relative to the
  prior 10.23. HOLDS.
- Gate 3 coverage 0.2947 (grass-dominant) unchanged; plate-rock <-> shoulder
  xcorr 0.021 (low, tiling not tracked).

## Stone-prominence proxy (before -> after)

- Debris mask coverage: **8.65%** (stones + amber rocks + grass tufts).
- Grey (sat < 0.40) pixel fraction, a direct stone-count proxy since the
  substrate is warm tan: **RAW source 2.68% -> CLEAN source 0.34%** (an 87%
  reduction in grey stone pixels).

## Artifacts

- Method: `tools/art/declutter_dirt_source.py` (new), pre-step wired into
  `tools/art/grade_dirt_plate.py::grade`, mid gain restored in `BAND_GAINS`.
- Regenerated committed assets:
  - plate `assets/village/ground_dirt_plate.png`
    sha256 `360af772ca2deed5ac7c45f8267316768904b3f1494560b06875bbcb4f547263`
  - detail `assets/village/ground_dirt_detail.png` (decoded RG8 fingerprint
    `d137cbbe6187b48e82faa0b6e583be74674e5ca9229e71ab258f6993ee6a659a`, test +
    bake header updated).
- Re-captured ground-only `0.5x/1x/2x` (+ shimmer pan) under
  `docs/art/village/ground-dirt-retune/`, district `village-inn-green-*` under
  `docs/art/village/`, cleaned source + detection overlay under
  `docs/art/village/dirt-source-declutter/`.

## Confusability verdict

The rendered open dirt is now smooth dusty tan with soft tonal mottling and fine
speckle; the discrete high-contrast grey lozenge stones are gone from the path,
and the only rocks left are small low-contrast clusters at the grass edges,
which is exactly the spike's scenery-prop-clusters-at-grass-edges signature. I
believe the result is now confusable with the spike dirt path.

## Residual risk for the critique to probe

1. A handful of small grey/amber pebbles at grass edges survive detection (the
   erode/open step drops sub-blob specks). I argue this is spike-consistent, but
   the critique should check the district capture for any that read as a tell on
   the path rather than the edge.
2. The mid restoration to 1.30 lifts the substrate brush-streak tonal amplitude.
   I argue this is accepted dusty richness (not the killed rock-blob/muddy
   tells, which are decoupled), but a critic could test whether it reads as
   blotchy at 1x/2x.
3. The single fixed grain-roll offset transplants one decorrelated copy of the
   substrate texture into all holes. Holes are small and scattered so no
   repetition is visible, but the critique could look for any faint ghost of a
   donor region.
