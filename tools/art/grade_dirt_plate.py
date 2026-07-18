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
    mid = b_mid_lo - b_macro
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

    print(f"reshape radii {RESHAPE_RADII}  band gains (fine,lomid,mid,macro) {BAND_GAINS}")
    print(f"graded channel mean {out.reshape(-1, 3).mean(axis=0).round(2)}  (spike {SPIKE_MEAN})")
    print(f"graded per-chan std {per_std.round(2)}  (std_rgb {per_std.mean():.2f})")
    print(f"graded lum mean     {lum.mean():.2f}  (spike 84.9)")
    print(f"graded lum std      {lum.std():.2f}")
    print(f"center-crop lum std {center.std():.2f}  (flat-core gate: >= 17.97)")
    print(f"graded mean_grad    {grad(lum):.2f}  (spike 12.14, grass ceiling ~10.28 native)")
    print("graded band RMS     " + "  ".join(f"{k}={v:.2f}" for k, v in bands.items()))
    print("graded lum pct 1/5/25/50/95/99: " + " ".join(f"{v:.1f}" for v in pct))
    print(f"graded sha256       {hashlib.sha256(OUTPUT.read_bytes()).hexdigest()}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
