#!/usr/bin/env python3
"""Rebuild the historical option C colored walk sheet from revision 3."""

from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_INPUT = ROOT / "tools/art/out/player_walk_sheet_colored_revision_3.png"
DEFAULT_OUTPUT = ROOT / "tools/art/out/player_walk_sheet_option_c_colored.png"

ROWS = 3
COLS = 4
BG_TOLERANCE = 24
MAGENTA_HUE_RANGE = (280.0, 340.0)
CYAN_HUE_RANGE = (160.0, 200.0)
MARKER_MIN_SATURATION = 0.35
MARKER_MIN_VALUE = 0.20


def _hue_mask(image: Image.Image, hue_range: tuple[float, float]) -> np.ndarray:
    rgba = image.convert("RGBA")
    rgb = np.asarray(rgba.convert("RGB"))
    hsv = np.asarray(Image.fromarray(rgb).convert("HSV"), dtype=np.float64)
    alpha = np.asarray(rgba)[:, :, 3]
    if alpha[0, 0] > 0:
        foreground = (
            np.abs(rgb.astype(np.int16) - rgb[0, 0].astype(np.int16)).max(axis=2)
            > BG_TOLERANCE
        )
    else:
        foreground = alpha > 0
    hue = hsv[:, :, 0] * (360.0 / 255.0)
    saturation = hsv[:, :, 1] / 255.0
    value = hsv[:, :, 2] / 255.0
    return (
        (hue >= hue_range[0])
        & (hue <= hue_range[1])
        & (saturation >= MARKER_MIN_SATURATION)
        & (value >= MARKER_MIN_VALUE)
        & foreground
    )


def _set_hue(image: Image.Image, mask: np.ndarray, hue_degrees: float) -> Image.Image:
    rgba = image.convert("RGBA")
    hsv = np.asarray(rgba.convert("RGB").convert("HSV"), dtype=np.uint8).copy()
    hsv[mask, 0] = round(hue_degrees * 255.0 / 360.0)
    rgb = np.asarray(Image.fromarray(hsv, mode="HSV").convert("RGB"))
    result = np.asarray(rgba).copy()
    result[mask, :3] = rgb[mask]
    return Image.fromarray(result, mode="RGBA")


def _swap_boot_hues(image: Image.Image) -> Image.Image:
    magenta = _hue_mask(image, MAGENTA_HUE_RANGE)
    cyan = _hue_mask(image, CYAN_HUE_RANGE)
    result = _set_hue(image, magenta, 180.0)
    return _set_hue(result, cyan, 310.0)


def build(source: Image.Image) -> Image.Image:
    if source.width % COLS or source.height % ROWS:
        raise ValueError(f"source size {source.size} is not divisible by {COLS}x{ROWS}")
    cell_width = source.width // COLS
    cell_height = source.height // ROWS
    output = source.copy()

    # Preserve the generated side row. Complete the down and up rows as
    # A, B, mirrored-B, mirrored-A symmetric cycles.
    for row in (0, 1):
        for source_col, target_col in ((1, 2), (0, 3)):
            box = (
                source_col * cell_width,
                row * cell_height,
                (source_col + 1) * cell_width,
                (row + 1) * cell_height,
            )
            authored = source.crop(box).transpose(Image.Transpose.FLIP_LEFT_RIGHT)
            authored = _swap_boot_hues(authored)
            output.paste(
                authored.convert(source.mode),
                (target_col * cell_width, row * cell_height),
            )
    return output


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, default=DEFAULT_INPUT)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args(argv)

    source = Image.open(args.input).convert("RGB")
    output = build(source)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    output.save(args.output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
