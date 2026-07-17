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
    marker_residue_mask,
    recolor_boots,
    recolor_tunic,
)


def main() -> int:
    source = Image.open(DEFAULT_INPUT).convert("RGB")
    colored = build_colored_source(source)
    leather = recolor_boots(build_colored_shipping_atlas(colored))

    failures = []
    for name, hue in APPEARANCE_HUES.items():
        atlas = recolor_tunic(leather, hue)
        count = int(np.count_nonzero(marker_residue_mask(atlas)))
        if count:
            failures.append(f"{name}: {count} opaque marker-hue pixels")
        else:
            print(f"  ok    {name} atlas has no opaque marker-hue pixels")

    if failures:
        for failure in failures:
            print(f"  FAIL  {failure}")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
