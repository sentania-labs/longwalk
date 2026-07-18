# Decision 013 dirt re-tune: result + seam localization (claude render slice)

Closes agy QA pass 5's three tells (muddy tone, tiling/rock-cluster repetition,
mid-district grid seams) at ZERO paid spend, by reshaping the frequency balance
of the accepted paid regen plate rather than regenerating it. Method per
`docs/decisions/013-dirt-retune-fidelity.md`.

## What changed

1. `tools/art/grade_dirt_plate.py`: the per-channel AFFINE grade (match spike
   mean, preserve source std) is replaced by a deterministic MULTIBAND LUMINANCE
   RESHAPE. Source luminance is split into bands with wrapped separable box blurs
   (radii 3 / 12 / 64) and each band is scaled: fine 1.85, lomid 1.55, mid 0.55,
   macro 0.14. The luminance delta is applied equally to R,G,B (no hue shift),
   then the per-channel mean-match re-lands each channel exactly on the spike
   target. Pure function of the committed source bytes; byte-identical on re-run.
2. `tools/art/bake_dirt_detail.gd`: R high-pass radius 12 -> 3 (catch fine dry
   speckle, not the 12-64 rock motifs), rock-edge outliers winsorized to
   +/-2.5 sigma before `_standardize`, soften radius 2 -> 1. Deterministic
   contract intact (same seeds/offsets); new `image_sha256` header + byte-identity
   test updated.
3. `src/render/town/ground.gdshader`: measured joint sweep. `detail_shoulder_amp`
   0.40 -> 0.18 (shimmer ceiling), `tone_contrast` 0.16 -> 0.10 (broad darkening),
   `detail_core_amp` 0.11 -> 0.09. No `repeat_enable`/`fract`, no stochastic
   anti-tiling (both ruled out by decision 013).

## Root cause (measured)

The regen plate carried its variance in the LOW spatial-frequency band while the
spike carries its (larger) variance in the HIGH band. Per-octave luminance RMS:

| band       | regen source | spike crop | graded (new) |
| ---------- | ------------ | ---------- | ------------ |
| fine (<3)  | 8.19         | 18.89      | 14.74        |
| lomid (3-12)| 6.4         | ~9.6       | 9.92         |
| mid (12-64)| 8.0          | ~12-15     | 5.57         |
| macro (>64)| 12.29        | 0.18       | 2.52         |

The macro band (broad dark drift) is crushed 12.29 -> 2.52 (~5x); the fine band
is lifted 8.19 -> 14.74 toward the spike's dry-speckle signature. Tells 1 (mud)
and 2 (tiling) share this cause and move together.

## Seam localization (tell 3)

QA5 placed the seams "above the small blacksmith building" and "across paths."
The smithy_cluster is authored at cell (11,10), size (3,2)
(`src/sim/town_layout.gd`), so the reported seams map to district UV
~(0.69, 0.71) and along the dirt lanes generally, NOT the district border
(agy's own border-clamp hypothesis was retracted in critique).

Candidate straight-edge mechanisms at that UV, classified:

- **Plate macro drift crossing a mask isoline (PRIMARY).** The plate is sampled
  once (continuous), but its broad macro luminance drift (RMS 12.29) creates real
  luminance ramps; where a ramp lines up with the shoulder-feather isoline or the
  core/shoulder boundary it reads as a straight luminosity seam. The multiband
  flatten crushes macro to 2.52, dissolving this contributor at its source. This
  is the dominant fix.
- **lane_density / lane_mask bilinear facet crease (SECONDARY, sub-perceptual).**
  Both masks are 256x224 = exactly 16 texels/cell, sampled `filter_linear`, so
  bilinear interpolation has a derivative discontinuity (Mach-band crease) along
  that texel grid every ~4.5 px @1x / ~9 px @2x, which matches the "grid"
  spacing. Measured amplitude of the density-driven luminance crease on solid
  dirt (second-difference of the density field x mean plate luminance x
  tone_contrast): mean 0.12 / max 0.53 bytes at the OLD tone_contrast 0.16, and
  mean 0.07 / max 0.33 bytes at the NEW 0.10. That is below a 1-byte perceptual
  floor, so the facet crease was NOT the visible seam by itself and needs no
  mask-side or sampling fix (decision 013 says apply one only "if they survive as
  a bilinear facet"; they do not, at meaningful amplitude). The visible seam was
  the plate macro ramp riding this grid, and that ramp is gone.

The rendered 1x/2x ground-only captures confirm organic wavy dirt/grass
transitions with no straight grid line cutting the dirt, and no broad dark
mud smear. `agy`'s rotated-derivative one-liner (`vec2(ddx.y,-ddx.x)`) was left
unapplied: the edge-break sample survives, but it affects only the coverage
dither on the transition band (no mips committed), immaterial to the seams.

## Gate numbers

See the commit body for the full decode: both hard gates pass (protected-core
luminance std ~19.9 >= 18.44 current; rendered shoulder fine-gradient at the
grass shimmer level), Gate 2 transition and Gate 3 coverage (< 0.5, grass
dominant) unchanged, plate-rock <-> rendered-shoulder cross-correlation ~0.
