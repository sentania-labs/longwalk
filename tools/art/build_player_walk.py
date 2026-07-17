#!/usr/bin/env python3
"""Build the colored source and shipping player walk atlases.

The generated revision-3 side row is retained byte-for-byte inside its source
cells. Down and up are hand-authored as symmetric four-frame cycles: generated
poses 0 and 1 provide contact and passing poses, and poses 2 and 3 are their
full-body horizontal mirrors. After mirroring, the marker hues are exchanged so
magenta and cyan stay bound to the same anatomical boots rather than becoming
screen-space labels.

Every operation is a pure function of the committed revision-3 PNG. There is no
RNG, filesystem-order dependency, or unrecorded editor state.
"""

from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_INPUT = ROOT / "tools/art/out/player_walk_sheet_colored_revision_3.png"
DEFAULT_COLORED = ROOT / "tools/art/out/player_walk_sheet_option_c_colored.png"
DEFAULT_ATLAS = ROOT / "tools/art/out/processed/player_walk_moss.png"

ROWS = 3
COLS = 4
CELL = 160
BG_TOLERANCE = 24

MAGENTA_HUE_RANGE = (280.0, 340.0)
CYAN_HUE_RANGE = (160.0, 200.0)
MARKER_MIN_SATURATION = 0.35
MARKER_MIN_VALUE = 0.20
LEATHER_HUE = 27.0
LEATHER_SATURATION = 0.62
LEATHER_VALUE_SCALE = 0.62

TUNIC_HUE_RANGE = (40.0, 80.0)
TUNIC_MIN_SATURATION = 0.4
APPEARANCE_HUES = {
    "moss": None,
    "slate_blue": 210.0,
    "burgundy": 350.0,
}


def _hue_mask(image: Image.Image, hue_range: tuple[float, float]) -> np.ndarray:
    rgba = image.convert("RGBA")
    rgb = np.asarray(rgba.convert("RGB"))
    hsv = np.asarray(Image.fromarray(rgb).convert("HSV"), dtype=np.float64)
    alpha = np.asarray(rgba)[:, :, 3]
    # Raw source sheets use a saturated magenta background, the same hue as
    # the left boot. Limit marker edits to foreground pixels before testing
    # hue. Transparent shipping atlases naturally pass this through alpha.
    if alpha[0, 0] > 0:
        foreground = np.abs(rgb.astype(np.int16) - rgb[0, 0].astype(np.int16)).max(axis=2) > BG_TOLERANCE
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


def marker_residue_mask(image: Image.Image) -> np.ndarray:
    """Return opaque pixels that retain either generation-marker hue."""
    rgba = image.convert("RGBA")
    hsv = np.asarray(rgba.convert("RGB").convert("HSV"), dtype=np.float64)
    hue = hsv[:, :, 0] * (360.0 / 255.0)
    value = hsv[:, :, 2] / 255.0
    alpha = np.asarray(rgba)[:, :, 3]
    marker_hue = (
        ((hue >= MAGENTA_HUE_RANGE[0]) & (hue <= MAGENTA_HUE_RANGE[1]))
        | ((hue >= CYAN_HUE_RANGE[0]) & (hue <= CYAN_HUE_RANGE[1]))
    )
    return marker_hue & (value >= MARKER_MIN_VALUE) & (alpha > 0)


def marker_blend_residue_mask(image: Image.Image) -> np.ndarray:
    """Return visible blue pixels produced by blended boot markers."""
    rgba = image.convert("RGBA")
    rgb = np.asarray(rgba)[:, :, :3].astype(np.int16)
    hsv = np.asarray(rgba.convert("RGB").convert("HSV"), dtype=np.float64)
    hue = hsv[:, :, 0] * (360.0 / 255.0)
    saturation = hsv[:, :, 1] / 255.0
    value = hsv[:, :, 2] / 255.0
    alpha = np.asarray(rgba)[:, :, 3]
    red_green_balance = np.abs(rgb[:, :, 0] - rgb[:, :, 1]) <= 55
    blue_dominant = rgb[:, :, 2] > np.maximum(rgb[:, :, 0], rgb[:, :, 1])
    return (
        (hue >= 220.0)
        & (hue <= 260.0)
        & (saturation >= MARKER_MIN_SATURATION)
        & (value >= MARKER_MIN_VALUE)
        & red_green_balance
        & blue_dominant
        & (alpha >= 128)
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


def build_colored_source(source: Image.Image) -> Image.Image:
    if source.width % COLS or source.height % ROWS:
        raise ValueError(f"source size {source.size} is not divisible by {COLS}x{ROWS}")
    cell_width = source.width // COLS
    cell_height = source.height // ROWS
    output = source.copy()

    # Down and up use generated poses 0 and 1 as the editable master half-cycle.
    # Mirroring the full figure creates genuinely opposed limb geometry. Hue
    # restoration keeps the chromatic markers attached to anatomical feet.
    for row in (0, 1):
        # A, B, mirrored-B, mirrored-A produces a continuous symmetric loop.
        # The generated B poses also carry the clearest planted-foot depth,
        # making columns 0 and 2 the two opposed contacts expected by the gate.
        for source_col, target_col in ((1, 2), (0, 3)):
            box = (
                source_col * cell_width,
                row * cell_height,
                (source_col + 1) * cell_width,
                (row + 1) * cell_height,
            )
            authored = source.crop(box).transpose(Image.Transpose.FLIP_LEFT_RIGHT)
            authored = _swap_boot_hues(authored)
            output.paste(authored.convert(source.mode), (target_col * cell_width, row * cell_height))
    return output


def _foreground_bbox(cell: Image.Image) -> tuple[int, int, int, int]:
    rgb = np.asarray(cell.convert("RGB"), dtype=np.int16)
    background = rgb[0, 0]
    foreground = np.abs(rgb - background).max(axis=2) > BG_TOLERANCE
    ys, xs = np.nonzero(foreground)
    if not len(xs):
        raise ValueError("empty source cell")
    return int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1


def _shipping_frame(cell: Image.Image) -> Image.Image:
    bbox = _foreground_bbox(cell)
    subject = cell.crop(bbox).convert("RGBA")
    rgb = np.asarray(subject)[:, :, :3].astype(np.int16)
    background = rgb[0, 0]
    alpha = (np.abs(rgb - background).max(axis=2) > BG_TOLERANCE).astype(np.uint8) * 255
    rgba = np.asarray(subject).copy()
    rgba[:, :, 3] = alpha
    subject = Image.fromarray(rgba, mode="RGBA")

    # Preserve aspect and place the opaque sole on the contract's row 159.
    scale = min(CELL / subject.width, CELL / subject.height)
    size = (max(1, round(subject.width * scale)), max(1, round(subject.height * scale)))
    subject = subject.resize(size, Image.Resampling.LANCZOS)
    frame = Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
    frame.alpha_composite(subject, ((CELL - size[0]) // 2, CELL - size[1]))
    # Lanczos can turn a fully opaque source sole into a subpixel-only final
    # row. The world contract requires real opaque contact pixels on row 159.
    pixels = np.asarray(frame).copy()
    contact = pixels[CELL - 1, :, 3] > 0
    pixels[CELL - 1, contact, 3] = 255
    frame = Image.fromarray(pixels, mode="RGBA")
    return frame


def build_colored_shipping_atlas(source: Image.Image) -> Image.Image:
    source_cell_width = source.width // COLS
    source_cell_height = source.height // ROWS
    atlas = Image.new("RGBA", (COLS * CELL, 4 * CELL), (0, 0, 0, 0))
    for row in range(ROWS):
        for col in range(COLS):
            box = (
                col * source_cell_width,
                row * source_cell_height,
                (col + 1) * source_cell_width,
                (row + 1) * source_cell_height,
            )
            frame = _shipping_frame(source.crop(box))
            atlas.alpha_composite(frame, (col * CELL, row * CELL))

    # The source side row faces right. Mirror each completed shipping frame to
    # create the fourth direction only after source-row validation.
    for col in range(COLS):
        box = (col * CELL, 2 * CELL, (col + 1) * CELL, 3 * CELL)
        left = atlas.crop(box).transpose(Image.Transpose.FLIP_LEFT_RIGHT)
        atlas.alpha_composite(left, (col * CELL, 3 * CELL))
    return atlas


def recolor_boots(image: Image.Image) -> Image.Image:
    # Use broader hue windows than the rejection gate so antialiased marker
    # fringes are recolored too. Keep that broad match saturation-gated to
    # protect unrelated muted colors, then include the exact marker windows
    # without a saturation floor so HSV round trips cannot strand boot edges.
    marker = (
        _hue_mask(image, (260.0, 359.9))
        | _hue_mask(image, (140.0, 220.0))
        | marker_residue_mask(image)
        | marker_blend_residue_mask(image)
    )
    rgba = image.convert("RGBA")
    hsv = np.asarray(rgba.convert("RGB").convert("HSV"), dtype=np.uint8).copy()
    hsv[marker, 0] = round(LEATHER_HUE * 255.0 / 360.0)
    hsv[marker, 1] = round(LEATHER_SATURATION * 255.0)
    values = hsv[:, :, 2].astype(np.float64)
    hsv[marker, 2] = np.clip(values[marker] * LEATHER_VALUE_SCALE, 35, 155).astype(np.uint8)
    rgb = np.asarray(Image.fromarray(hsv, mode="HSV").convert("RGB"))
    result = np.asarray(rgba).copy()
    result[marker, :3] = rgb[marker]
    return Image.fromarray(result, mode="RGBA")


def recolor_tunic(image: Image.Image, target_hue: float | None) -> Image.Image:
    if target_hue is None:
        return image.copy()
    rgba = image.convert("RGBA")
    hsv = np.asarray(rgba.convert("RGB").convert("HSV"), dtype=np.float64)
    alpha = np.asarray(rgba)[:, :, 3]
    hue = hsv[:, :, 0] * (360.0 / 255.0)
    saturation = hsv[:, :, 1] / 255.0
    mask = (
        (hue >= TUNIC_HUE_RANGE[0])
        & (hue <= TUNIC_HUE_RANGE[1])
        & (saturation >= TUNIC_MIN_SATURATION)
        & (alpha > 0)
    )
    return _set_hue(rgba, mask, target_hue)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, default=DEFAULT_INPUT)
    parser.add_argument("--colored-source", type=Path, default=DEFAULT_COLORED)
    parser.add_argument("--atlas", type=Path, default=DEFAULT_ATLAS)
    args = parser.parse_args()

    source = Image.open(args.input).convert("RGB")
    colored_source = build_colored_source(source)
    args.colored_source.parent.mkdir(parents=True, exist_ok=True)
    colored_source.save(args.colored_source)

    colored_atlas = build_colored_shipping_atlas(colored_source)
    brown_atlas = recolor_boots(colored_atlas)
    args.atlas.parent.mkdir(parents=True, exist_ok=True)
    for name, hue in APPEARANCE_HUES.items():
        destination = args.atlas.with_name(f"player_walk_{name}.png")
        recolor_tunic(brown_atlas, hue).save(destination)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
