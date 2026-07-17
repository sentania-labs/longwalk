#!/usr/bin/env python3
"""Regression tests for the shipping player walk atlas build."""

import pathlib
import sys

import numpy as np
from PIL import Image


REPO_ROOT = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "tools" / "art"))

from build_player_walk import (  # noqa: E402
    APPEARANCE_HUES,
    DEFAULT_INPUT,
    build_colored_shipping_atlas,
    build_colored_source,
    marker_blend_residue_mask,
    marker_residue_mask,
    recolor_boots,
    recolor_tunic,
)


def main() -> int:
    source = Image.open(DEFAULT_INPUT).convert("RGB")
    colored = build_colored_source(source)
    colored_atlas = build_colored_shipping_atlas(colored)
    leather = recolor_boots(colored_atlas)

    failures = []
    before = np.asarray(colored_atlas.convert("RGBA"))
    after = np.asarray(leather.convert("RGBA"))
    hsv = np.asarray(colored_atlas.convert("RGB").convert("HSV"), dtype=np.float64)
    hue = hsv[:, :, 0] * (360.0 / 255.0)
    saturation = hsv[:, :, 1] / 255.0
    tunic = (
        (hue >= 40.0)
        & (hue <= 80.0)
        & (saturation >= 0.4)
        & (before[:, :, 3] > 0)
    )
    changed_tunic = int(np.count_nonzero(np.any(before[tunic] != after[tunic], axis=1)))
    if changed_tunic:
        failures.append(f"boot recolor changed {changed_tunic} tunic pixels")
    else:
        print("  ok    boot recolor leaves tunic pixels byte-identical")

    for name, hue in APPEARANCE_HUES.items():
        atlas = recolor_tunic(leather, hue)
        count = int(np.count_nonzero(marker_residue_mask(atlas)))
        blend_count = int(np.count_nonzero(marker_blend_residue_mask(atlas)))
        if count or blend_count:
            failures.append(
                f"{name}: {count} marker-hue pixels, {blend_count} blue marker-blend pixels"
            )
        else:
            print(f"  ok    {name} atlas has no visible marker or marker-blend pixels")

    if failures:
        for failure in failures:
            print(f"  FAIL  {failure}")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
