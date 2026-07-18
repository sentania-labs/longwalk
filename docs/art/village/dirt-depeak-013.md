# Decision 013 follow-on: mid-band stone de-peaking (claude render slice)

Continuation of decision 013's settled multiband-reshape method (same file, same
two hard gates), targeting the ONE dominant tell that survived the pass-6
NOT-CONFUSABLE verdict: the open dirt carries ~15-20 discrete, high-contrast grey
lozenge stones (plus a stray amber rock) that agy reads as a clone-stamped motif.
The spike dirt path has none of these; it is smooth dry dusty tan with fine
speckle, its only rocks being scenery-prop clusters at the grass edges.

## The de-peak operator (what shipped)

`tools/art/grade_dirt_plate.py` gains a deterministic spatial outlier
soft-winsorize on the mid band (`_depeak_band`), applied to `mid = blur12 -
blur64` inside the multiband reshape, before recombination:

- Local field: `local_mean = box_blur(mid, DEPEAK_RADIUS)`, radius 40 texels
  (larger than a ~20-texel stone), and a local sigma from the box-blurred squared
  excursion. Using a LOCAL rather than global sigma is deliberate: a stone is an
  excursion large relative to its OWN neighborhood, not necessarily a global-tail
  outlier, so a global winsorize barely registers it.
- Soft clamp: excursions beyond `DEPEAK_SIGMA` (2.0) local sigma are compressed
  with residual slope `DEPEAK_SOFT` (0.25) toward the local mean.
- RMS hold: the band is rescaled back to its original RMS
  (`DEPEAK_RMS_RESTORE` 1.0), so the mid-band energy (hence protected-core
  richness) is preserved.

Pure function of the committed source bytes: box blurs wrap only the kernel,
sigma/mean are order-independent reductions, no RNG, no time, no visit order.
Byte-identical on re-run. The fine band is never touched (that keeps shimmer under
the ceiling); the detail bake is re-derived and its expected-sha header +
byte-identity test updated.

Stone-prominence proxy (source 12-64 mid band, reported by the tool):

| metric        | before | after |
| ------------- | ------ | ----- |
| RMS           | 8.04   | 8.04  |
| kurtosis      | 3.272  | 3.093 |
| tail > 3 sigma| 0.412% | 0.320%|

## The wall: band-winsorizing does NOT dissolve the painted stones

The shipped strength is CONSERVATIVE on purpose, because a direct measurement
established that no luminance-band de-peak dissolves these stones at all. Rendered
ground-only captures were taken with the de-peak pushed to (and past) the
flat-core floor on each band in turn:

- MID band (12-64) de-peaked hard: stones unchanged.
- LOMID band (3-12) de-peaked hard (its kurtosis is 10.3, the stone EDGES are
  strong outliers there): stones unchanged.
- FINE band (<3) de-peaked hard (kurtosis 7.9 -> 2.5): stones unchanged.

The reason is structural, not a tuning miss: a painted rock is coherent across
ALL frequency bands simultaneously (body in mid, edges in lomid, outline and
specular highlight in fine). It is not a statistical outlier in any single band,
so clamping one band's tail merely softens that band's slice and the rock
reassembles from the others. The orchestrator's root-cause hypothesis (a peaky
mid-band DISTRIBUTION) is only mildly present in the statistics (mid kurtosis 3.27
is barely non-Gaussian), and driving it to Gaussian moves the render not at all.
Chroma is not the lever either: the stones are only marginally greyer than the
dirt (source saturation 0.448 vs 0.458), and the reshape is luminance-only by
design.

An early round of "de-peak barely changes anything" captures was additionally
confounded by Godot serving a STALE imported `.ctex` (the raw PNG changes but the
scene loads the import cache); every render comparison here was taken after a
forced `--import` reimport so the texture matches the plate on disk.

## Hard fallback: TRIGGERED (stronger than anticipated)

Decision 013's dispatch anticipated a wall where the de-peak strength needed to
dissolve the stones would drop the protected-core luminance std below the flat-
core floor. The measured wall is more decisive: band-winsorizing at ANY strength
(including strengths that breach both the flat-core AND shimmer gates) does not
remove the painted rocks, because they are source content, not a frequency
artifact. Per the dispatch, the shipped candidate is the best NON-REGRESSING one:
it reduces the flagged mid-band peakiness metric while strictly holding both hard
gates and NOT reopening the flat core.

Fully removing the stones is a source-level operation (segment/inpaint the rocks
out of `.pka/round007/ground-source/dirt-regen-nbpro-019f74b2.png`, or a stone-
free paid regen), which is an orchestrator design decision, not a plate-grade
tuning knob.

## Gate numbers (rendered decode, `tools/art/decode_dirt_gates.gd`)

- Flat-core gate: protected-core luminance std 19.90 (baseline 19.91; -0.01,
  rounding-level, and 1.46 bytes above the 18.44 pass-4 floor). HOLDS.
- Shimmer-ceiling gate: the de-peak is mid-only, so the plate FINE band is
  byte-unchanged (fine RMS 14.738 -> 14.739, fine gradient 10.141 -> 10.142);
  shimmer cannot regress. Rendered 0.5x center-crop fine-gradient 10.23 <= grass
  ceiling ~10.75. HOLDS.
- Gate 3 coverage 0.2947 (grass-dominant) and plate-rock <-> shoulder xcorr
  -0.001 unchanged.

## Artifacts

- Plate sha256 `2c02444e270f58c51e4ce073130055617c983bde466720324bf21c7aca764d3d`
- Detail sha256 `057c7d38ccb3641749305bb433da8799884b64455a16b2ff6a4bdcb38c753cc0`
- Ground-only captures: `docs/art/village/ground-dirt-retune/ground-{0.5x,1x,2x}.png`
- District captures: `docs/art/village/village-inn-green-{0.5x,1x,2x}.png`
