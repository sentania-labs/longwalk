#!/usr/bin/env python3
"""Deterministic tone-grade for the round-007 dirt ground plate (decision 012
item 5, the pre-authorized paid regen path).

The accepted paid regen
(.pka/round007/ground-source/dirt-regen-nbpro-019f74b2.png, nano-banana-pro task
019f74b2-36fc-777a-880b-dbd814e2a725) carries the real earthy structure the old
flat source-dirt plate lacked (per-channel std ~24/20/15 vs the old ~4.5), but it
decodes lighter/warmer (lum 145.4) than the reference spike dirt (lum 84.9,
meanRGB 98.6/85.0/43.5). This step darkens + desaturates the regen toward the
spike mean with a per-channel AFFINE grade: it shifts each channel mean onto the
spike target while keeping the source's absolute per-channel std intact (contrast
factor 1.0). That is the operation the dominant flat-core tell needs: the core
samples this plate directly, so the richness has to come from the plate's tonal
variation, and a pure multiply toward a darker mean would scale that variation
down with the mean (19.8 -> 10.9 std) instead of preserving it. The affine grade
lands mean exactly on the spike target while holding std at ~19.8 (4.4x the old
flat 4.5). Shadow underflow is negligible (~0.2% of the B channel clips to 0,
which reads as dark earthy crevices, not banding).

This is a DEV tool under tools/art/ (never packed into the game asset path). It
is a pure function of the committed source bytes: no RNG, no time, no order
dependence. Re-running it on the same source yields byte-identical output.

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
# The grade target: darken + desaturate the warm/light regen toward this earthy
# mean while keeping its structure.
SPIKE_MEAN = np.array([98.6, 85.0, 43.5], dtype=np.float64)


def main() -> int:
    source = np.asarray(Image.open(SOURCE).convert("RGB"), dtype=np.float64)
    channel_mean = source.reshape(-1, 3).mean(axis=0)
    # Per-channel affine grade: recentre each channel mean onto the spike target
    # while keeping the source's absolute per-channel std (contrast factor 1.0).
    # This darkens + desaturates toward the earthy spike tone without shrinking
    # the std-carried tonal structure the protected core reads directly.
    graded = np.clip(np.rint(source - channel_mean + SPIKE_MEAN), 0.0, 255.0).astype(np.uint8)

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(graded, "RGB").save(OUTPUT)

    graded_f = graded.astype(np.float64)
    per_std = graded_f.reshape(-1, 3).std(axis=0)
    lum = graded_f[..., 0] * 0.2126 + graded_f[..., 1] * 0.7152 + graded_f[..., 2] * 0.0722
    print(f"source channel mean {channel_mean.round(2)}")
    print(f"grade shift         {(SPIKE_MEAN - channel_mean).round(2)}")
    print(f"graded channel mean {graded_f.reshape(-1, 3).mean(axis=0).round(2)}")
    print(f"graded per-chan std {per_std.round(2)}  (std_rgb {per_std.mean():.2f})")
    print(f"graded lum mean     {lum.mean():.2f}  (spike 84.9)")
    print(f"graded sha256       {hashlib.sha256(OUTPUT.read_bytes()).hexdigest()}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
