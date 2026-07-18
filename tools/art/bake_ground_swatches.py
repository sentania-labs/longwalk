#!/usr/bin/env python3
"""Bake deterministic offset-and-heal village ground swatches.

The source rectangles come from docs/art/iso-five-asset-spike.png. The crop is
half-offset so its original edges meet in a central seam cross. Fixed donor
patches from the same crop are then feathered over only that cross. Pixels
outside the two seam bands remain the untouched, half-offset source crop.
"""

from __future__ import annotations

import pathlib

import numpy as np
from PIL import Image, ImageDraw, ImageFont


ROOT = pathlib.Path(__file__).resolve().parents[2]
SOURCE = ROOT / "docs/art/iso-five-asset-spike.png"
ASSETS = ROOT / "assets/village"
CONTACT = ROOT / "docs/art/village/ground-swatch-contactsheet.png"
SIZE = 512
SEAM_HALF_WIDTH = 48


def _smoothstep(value: np.ndarray) -> np.ndarray:
    value = np.clip(value, 0.0, 1.0)
    return value * value * (3.0 - 2.0 * value)


def _seam_mask(axis: int) -> np.ndarray:
    """Return a feathered mask confined to one central seam band."""
    coordinate = np.arange(SIZE, dtype=np.float64)
    distance = np.abs(coordinate - SIZE / 2 + 0.5)
    mask = _smoothstep((SEAM_HALF_WIDTH - distance) / (SEAM_HALF_WIDTH * 0.45))
    if axis == 0:
        return np.broadcast_to(mask[:, None, None], (SIZE, SIZE, 1))
    return np.broadcast_to(mask[None, :, None], (SIZE, SIZE, 1))


def _offset_and_heal(crop: Image.Image, donor_offset: tuple[int, int]) -> Image.Image:
    """Half-offset a crop, then clone fixed organic donors over the seam cross."""
    sample = np.asarray(crop.resize((SIZE, SIZE), Image.Resampling.LANCZOS), dtype=np.float64)
    offset = np.roll(sample, (SIZE // 2, SIZE // 2), axis=(0, 1))

    # Each donor is another deterministic translation of the same organic crop.
    # Applying one axis at a time also heals the central cross intersection.
    healed = offset
    vertical_donor = np.roll(offset, donor_offset[1], axis=1)
    mask = _seam_mask(1)
    healed = healed * (1.0 - mask) + vertical_donor * mask
    horizontal_donor = np.roll(healed, donor_offset[0], axis=0)
    mask = _seam_mask(0)
    healed = healed * (1.0 - mask) + horizontal_donor * mask
    return Image.fromarray(np.uint8(np.clip(np.rint(healed), 0, 255)), "RGB")


def _tile_panel(tile: Image.Image, zoom: float) -> Image.Image:
    period = round(128 * zoom)
    shown = tile.resize((period, period), Image.Resampling.LANCZOS)
    panel = Image.new("RGB", (period * 8, period * 8))
    for y in range(8):
        for x in range(8):
            panel.paste(shown, (x * period, y * period))
    return panel


def _contact_sheet(tiles: list[tuple[str, Image.Image]]) -> None:
    zooms = (0.5, 1.0, 2.0)
    panels = {(name, zoom): _tile_panel(tile, zoom) for name, tile in tiles for zoom in zooms}
    widths = [panels[(tiles[0][0], zoom)].width for zoom in zooms]
    row_height = max(panels[(tiles[0][0], zoom)].height for zoom in zooms)
    header = 48
    sheet = Image.new("RGB", (sum(widths), (row_height + header) * len(tiles)), (38, 38, 38))
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.load_default(size=18)
    for row, (name, _) in enumerate(tiles):
        x = 0
        top = row * (row_height + header)
        for zoom, width in zip(zooms, widths):
            panel = panels[(name, zoom)]
            sheet.paste(panel, (x, top + header))
            draw.text((x + 12, top + 12), f"{name}: 8x8 repeats at {zoom:g}x", fill="white", font=font)
            x += width
    CONTACT.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(CONTACT, optimize=True)


def main() -> int:
    source = Image.open(SOURCE).convert("RGB")
    # Largest useful unobstructed rectangles: upper-right meadow and broad lane.
    grass_crop = source.crop((800, 36, 1152, 230))
    dirt_crop = source.crop((278, 365, 354, 455))
    grass = _offset_and_heal(grass_crop, (137, 173))
    dirt = _offset_and_heal(dirt_crop, (151, 181))
    ASSETS.mkdir(parents=True, exist_ok=True)
    grass.save(ASSETS / "ground_grass_tile.png", optimize=True)
    dirt.save(ASSETS / "ground_dirt_tile.png", optimize=True)
    _contact_sheet([("grass", grass), ("dirt", dirt)])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
