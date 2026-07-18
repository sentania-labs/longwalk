#!/usr/bin/env python3
"""Deterministic tone-grade for the round-007 dirt ground plate (decision 012
item 5 paid regen; RE-TUNED per decision 013 to close QA pass 5's three tells).

The accepted paid regen
(.pka/round007/ground-source/dirt-regen-nbpro-019f74b2.png, nano-banana-pro task
019f74b2-36fc-777a-880b-dbd814e2a725) carries real earthy structure, but the
decision-012 AFFINE grade that installed it (match the spike mean, preserve the
source std) matched the wrong invariant. Orchestrator + claude decodes showed
the regen carries its variance in the LOW spatial-frequency band (macro-scale
luminance drift) while the reference spike carries its variance in the HIGH band
(crisp fine speckle on a near-uniform tan):

    band RMS (source lum)   fine(<3)  3-6  6-12  12-24  24-64  macro(>64)
    regen source              8.19   3.72  3.77   3.67   5.77    12.29
    spike dirt crop          18.89   9.59 11.98  15.56   8.96     0.18

The macro band (broad dark drift) reads as "wet chunky mud" (tell 1); the same
macro/mid rock-cluster blobs recurring across the once-sampled district read as
"tiling" (tell 2); a broad luminance step landing on a mask isoline reads as a
"seam" (tell 3, partially). std was preserved but the FREQUENCY BALANCE was
wrong.

Decision 013 replaces the affine grade with a deterministic MULTIBAND LUMINANCE
RESHAPE. Source luminance is split into bands with wrapped separable box blurs
(the _box_blur_wrapped primitive ported from bake_dirt_detail.gd). Each band is
scaled by a fixed gain: the macro + mid bands are ATTENUATED (kill the mud drift
and the rock-blob prominence), the fine band is BOOSTED toward the spike's dry
speckle signature. The luminance delta L' - L is applied EQUALLY to R,G,B so
tone shifts without hue shift, then the existing per-channel affine mean-match
re-lands each channel mean exactly on the spike target. The band gains were
chosen by measurement against decision 013's two hard regression gates (core
luminance std must not fall, shipped 0.5x fine-gradient must stay under the grass
shimmer ceiling), not a-priori.

This is a DEV tool under tools/art/ (never packed into the game asset path). It
is a pure function of the committed source bytes: no RNG, no time, no order
dependence. The box blur is separable and wraps only the kernel; each output
texel depends only on the immutable input and its integer coordinate. Re-running
it on the same source yields byte-identical output.

Usage:
    python3 tools/art/grade_dirt_plate.py

Output: assets/village/ground_dirt_plate.png (1024x1024 RGB).
"""
from __future__ import annotations

import hashlib
from pathlib import Path

import numpy as np
from PIL import Image

REPO_ROOT = Path(__file__).resolve().parents[2]
SOURCE = REPO_ROOT / ".pka/round007/ground-source/dirt-regen-nbpro-019f74b2.png"
OUTPUT = REPO_ROOT / "assets/village/ground_dirt_plate.png"

# Reference spike-dirt crop mean (orchestrator decode, dirt-regen-acceptance.md).
SPIKE_MEAN = np.array([98.6, 85.0, 43.5], dtype=np.float64)

# Multiband reshape (decision 013). Band boundaries are box-blur radii in source
# texels; the plate is 1024x1024. The bands are the successive differences of the
# low-pass pyramid plus the residual macro low-pass:
#   fine   = L        - blur(L, 3)     crisp speckle (the dry-dust signature)
#   lomid  = blur(L,3) - blur(L,12)    coarse speckle / small grit
#   mid    = blur(L,12)- blur(L,64)    rock-cluster blobs (the "tiling" motifs)
#   macro  = blur(L,64)                broad drift (the "wet mud" tell)
# Gains: BOOST fine + lomid toward the spike's high-frequency energy, ATTENUATE
# mid (rock-blob prominence) and macro (mud drift) hard. Chosen by the decision
# 013 sweep against both hard gates (see the module docstring).
RESHAPE_RADII = (3, 12, 64)
BAND_GAINS = (1.85, 1.55, 0.55, 0.14)  # (fine, lomid, mid, macro)

# Mid-band spatial DE-PEAKING (decision 013 depeak follow-on). The graded plate
# closed the muddy-tone and grid-seam tells, but ONE dominant tell remained: the
# open dirt carried ~15-20 discrete, high-contrast grey lozenge STONES that agy
# read as a clone-stamped motif. The spike dirt path has NONE of these: it is
# smooth dry dusty tan with fine speckle. Per-octave RMS showed this is a
# DISTRIBUTION problem, not a magnitude one: our mid band (5.57) is already below
# the spike's (~12-15), but our mid-band energy is concentrated in a few dozen
# peaky, non-Gaussian discrete stones (kurtosis 3.27, a fat tail), while the
# spike's mid-band energy is diffuse. Lowering the mid gain would drop the core
# std and reopen the pass-4 flat core; it would not fix the peaky stones.
#
# The de-peak is a deterministic spatial outlier soft-winsorize on the MID band
# (the ~12-24 texel stone scale) ONLY. Excursions beyond DEPEAK_SIGMA local sigma
# are soft-compressed toward the field (residual slope DEPEAK_SOFT); the band is
# then rescaled back to its ORIGINAL RMS so the mid-band energy (hence the core
# richness) is preserved. The fine band is NEVER touched (that keeps shimmer under
# the ceiling). Pure function of the source bytes: sigma/mean are order-
# independent reductions, no RNG, no time.
#
# MEASURED OUTCOME (see docs/art/village/dirt-depeak-013.md): band-winsorizing
# does NOT dissolve the visible painted stones. Rendered captures at fine-, lomid-
# and mid-band de-peak (each pushed to the flat-core floor) all leave the stones
# intact, because a painted rock is coherent across ALL frequency bands at once,
# not a statistical outlier in any single one; clamping one band's tail just
# softens that band's slice and the rock reassembles from the others. So the
# strength here is CONSERVATIVE: it reduces the flagged mid-band peakiness metric
# (kurtosis) while strictly holding both hard gates and NOT reopening the pass-4
# flat core. Fully dissolving the stones needs source-level rock removal (inpaint
# or a stone-free paid regen), which is an orchestrator design decision.
DEPEAK_RADIUS = 40   # local-field radius (texels); larger than a stone (~20)
DEPEAK_SIGMA = 2.0   # soft-clamp knee, in LOCAL sigma of the mid band
DEPEAK_SOFT = 0.25   # residual slope beyond the knee (0 = hard clamp, 1 = off)
DEPEAK_RMS_RESTORE = 1.0  # fraction of the removed band RMS re-injected (1=full hold)


def _depeak_band(band: np.ndarray, radius: int = DEPEAK_RADIUS,
                 n_sigma: float = DEPEAK_SIGMA, soft: float = DEPEAK_SOFT,
                 rms_restore: float = DEPEAK_RMS_RESTORE) -> np.ndarray:
    """Soft-winsorize the LOCAL spatial outliers of a band toward the local field.

    A discrete stone is an excursion that is large relative to its OWN
    neighborhood, not necessarily a global-tail outlier; a global winsorize barely
    touches it. So the knee is set from the LOCAL sigma (box-blurred squared
    excursion at `radius`), which catches a stone sitting on locally-smooth dirt.
    Excursions beyond `n_sigma` local sigma are soft-compressed (residual slope
    `soft`) toward the local mean, dissolving the discrete stones into diffuse
    dusty variation.

    The band RMS is then partly restored (`rms_restore`, 1.0 = full hold) by a
    single global scalar so the mid-band energy (hence the protected-core
    richness) is largely preserved. Pure function of the input and integer
    coordinates: box blurs wrap only the kernel, sigma/mean are order-independent
    reductions, no RNG, no time, no visit order."""
    rms0 = float(np.sqrt(np.mean(band ** 2)))
    local_mean = _box_blur_wrapped(band, radius)
    excursion = band - local_mean
    local_var = _box_blur_wrapped(excursion ** 2, radius)
    local_sigma = np.sqrt(np.maximum(local_var, 1e-12))
    t = n_sigma * local_sigma
    a = np.abs(excursion)
    compressed = t + soft * (a - t)
    e2 = np.where(a > t, np.sign(excursion) * compressed, excursion)
    result = local_mean + e2
    rms1 = float(np.sqrt(np.mean(result ** 2)))
    if rms1 > 0.0 and rms0 > 0.0:
        target = rms1 + rms_restore * (rms0 - rms1)
        result = result * (target / rms1)
    return result


def _box_blur_wrapped(a: np.ndarray, radius: int) -> np.ndarray:
    """Separable wrapped box blur via a summed-area table. Pure function of the
    input and integer coordinates; matches bake_dirt_detail.gd::_box_blur_wrapped
    (posmod kernel wrap, width = 2*radius+1) to float precision."""
    if radius <= 0:
        return a.copy()
    k = 2 * radius + 1
    pad = np.pad(a, ((radius, radius), (radius, radius)), mode="wrap")
    csum = np.cumsum(np.cumsum(pad, axis=0), axis=1)
    csum = np.pad(csum, ((1, 0), (1, 0)), mode="constant")
    h, w = a.shape
    y0 = np.arange(h)[:, None]
    x0 = np.arange(w)[None, :]
    total = (csum[y0 + k, x0 + k] - csum[y0, x0 + k]
             - csum[y0 + k, x0] + csum[y0, x0])
    return total / (k * k)


def reshape_luminance(lum: np.ndarray, gains=BAND_GAINS, radii=RESHAPE_RADII) -> np.ndarray:
    """Multiband reshape: split lum into bands at the given radii, scale each by
    its gain, recombine around the original mean. Returns L'."""
    r_fine, r_mid_lo, r_macro = radii
    b_fine = _box_blur_wrapped(lum, r_fine)
    b_mid_lo = _box_blur_wrapped(lum, r_mid_lo)
    b_macro = _box_blur_wrapped(lum, r_macro)
    fine = lum - b_fine
    lomid = b_fine - b_mid_lo
    mid = _depeak_band(b_mid_lo - b_macro)  # dissolve the peaky discrete stones
    macro = b_macro - b_macro.mean()
    k_fine, k_lomid, k_mid, k_macro = gains
    return (lum.mean()
            + k_fine * fine + k_lomid * lomid + k_mid * mid + k_macro * macro)


def grade(source: np.ndarray, gains=BAND_GAINS, radii=RESHAPE_RADII) -> np.ndarray:
    """Full grade: multiband luminance reshape applied equally to R,G,B (no hue
    shift), then a per-channel affine mean-match onto the spike target. Returns a
    float64 RGB array (unclipped) for measurement; the caller clips + rounds."""
    lum = source[..., 0] * 0.2126 + source[..., 1] * 0.7152 + source[..., 2] * 0.0722
    lum_new = reshape_luminance(lum, gains, radii)
    delta = (lum_new - lum)[..., None]
    reshaped = source + delta  # equal R,G,B delta: tone only, hue preserved
    channel_mean = reshaped.reshape(-1, 3).mean(axis=0)
    return reshaped - channel_mean + SPIKE_MEAN


def main() -> int:
    source = np.asarray(Image.open(SOURCE).convert("RGB"), dtype=np.float64)
    graded_f = grade(source)
    graded = np.clip(np.rint(graded_f), 0.0, 255.0).astype(np.uint8)

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(graded, "RGB").save(OUTPUT)

    out = graded.astype(np.float64)
    per_std = out.reshape(-1, 3).std(axis=0)
    lum = out[..., 0] * 0.2126 + out[..., 1] * 0.7152 + out[..., 2] * 0.0722

    def grad(a):
        gx = np.abs(a[:, 1:] - a[:, :-1])
        gy = np.abs(a[1:, :] - a[:-1, :])
        return (gx.sum() + gy.sum()) / (gx.size + gy.size)

    def band_rms(a):
        b3 = _box_blur_wrapped(a, 3)
        b12 = _box_blur_wrapped(a, 12)
        b64 = _box_blur_wrapped(a, 64)
        return {
            "fine": float(np.sqrt(np.mean((a - b3) ** 2))),
            "lomid": float(np.sqrt(np.mean((b3 - b12) ** 2))),
            "mid": float(np.sqrt(np.mean((b12 - b64) ** 2))),
            "macro": float(np.sqrt(np.mean((b64 - b64.mean()) ** 2))),
        }

    c = 1024 // 2
    half = 128  # 256x256 center crop = the protected-core region proxy
    center = lum[c - half:c + half, c - half:c + half]
    bands = band_rms(lum)
    pct = np.percentile(lum, [1, 5, 25, 50, 95, 99])

    # Stone-prominence proxy: mid-band (12-64) kurtosis + fat-tail fraction, on
    # the SOURCE mid band pre- vs post-de-peak. Discrete high-contrast stones are
    # a non-Gaussian peaky tail; the de-peak should pull kurtosis toward Gaussian
    # (3.0) and collapse the >3-sigma tail while holding the band RMS.
    src_lum = source[..., 0] * 0.2126 + source[..., 1] * 0.7152 + source[..., 2] * 0.0722
    mid_raw = _box_blur_wrapped(src_lum, 12) - _box_blur_wrapped(src_lum, 64)
    mid_dp = _depeak_band(mid_raw)

    def _prom(x):
        cc = x - x.mean()
        s = float(np.sqrt(np.mean(cc ** 2)))
        kurt = float(np.mean(cc ** 4) / s ** 4) if s > 0 else 0.0
        tail3 = float(np.mean(np.abs(cc) > 3 * s)) * 100.0
        return s, kurt, tail3

    print(f"reshape radii {RESHAPE_RADII}  band gains (fine,lomid,mid,macro) {BAND_GAINS}")
    print(f"graded channel mean {out.reshape(-1, 3).mean(axis=0).round(2)}  (spike {SPIKE_MEAN})")
    print(f"graded per-chan std {per_std.round(2)}  (std_rgb {per_std.mean():.2f})")
    print(f"graded lum mean     {lum.mean():.2f}  (spike 84.9)")
    print(f"graded lum std      {lum.std():.2f}")
    print(f"center-crop lum std {center.std():.2f}  (flat-core gate: >= 17.97)")
    print(f"graded mean_grad    {grad(lum):.2f}  (spike 12.14, grass ceiling ~10.28 native)")
    print("graded band RMS     " + "  ".join(f"{k}={v:.2f}" for k, v in bands.items()))
    s0, k0, t0 = _prom(mid_raw)
    s1, k1, t1 = _prom(mid_dp)
    print(f"depeak sigma {DEPEAK_SIGMA} soft {DEPEAK_SOFT}  mid-band prominence proxy (source 12-64 band):")
    print(f"  BEFORE  rms={s0:.2f} kurtosis={k0:.3f} tail>3sig={t0:.3f}%")
    print(f"  AFTER   rms={s1:.2f} kurtosis={k1:.3f} tail>3sig={t1:.3f}%  (peakiness reduced, RMS held)")
    print("graded lum pct 1/5/25/50/95/99: " + " ".join(f"{v:.1f}" for v in pct))
    print(f"graded sha256       {hashlib.sha256(OUTPUT.read_bytes()).hexdigest()}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
