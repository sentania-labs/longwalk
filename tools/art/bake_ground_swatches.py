#!/usr/bin/env python3
"""Bake periodic village ground swatches and their visual acceptance sheet.

The source rectangles are sampled from docs/art/iso-five-asset-spike.png. Each
crop is converted to a periodic texture by retaining its Fourier amplitudes and
assigning deterministic, coordinate-hashed phases. This removes composition
motifs and guarantees matching opposite boundaries without inventing a palette.
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


def _hash_phase(y: np.ndarray, x: np.ndarray, salt: int) -> np.ndarray:
    """Return a stateless phase determined only by frequency coordinates."""
    value = (x.astype(np.uint64) * np.uint64(0x9E3779B185EBCA87))
    value ^= y.astype(np.uint64) * np.uint64(0xC2B2AE3D27D4EB4F)
    value ^= np.uint64(salt)
    value ^= value >> np.uint64(30)
    value *= np.uint64(0xBF58476D1CE4E5B9)
    value ^= value >> np.uint64(27)
    return (value.astype(np.float64) / float(2**64)) * (2.0 * np.pi)


def _periodic_texture(crop: Image.Image, salt: int) -> Image.Image:
    sample = np.asarray(crop.resize((SIZE, SIZE), Image.Resampling.LANCZOS), dtype=np.float64)
    luminance = sample.mean(axis=2)
    spectrum = np.fft.rfft2(luminance - luminance.mean())
    fy, fx = np.indices(spectrum.shape)
    phase = _hash_phase(fy, fx, salt)
    phase[0, 0] = 0.0
    synthesized = np.fft.irfft2(np.abs(spectrum) * np.exp(1j * phase), s=(SIZE, SIZE))
    synthesized = (synthesized - synthesized.mean()) / max(synthesized.std(), 1e-6)

    # Reapply the crop's painterly color relationship as a smooth polynomial
    # mapping from luminance. This preserves the source palette and tonal range.
    source_luma = luminance.reshape(-1)
    output = np.empty((SIZE, SIZE, 3), dtype=np.float64)
    for channel in range(3):
        coeff = np.polyfit(source_luma, sample[:, :, channel].reshape(-1), 2)
        tonal = np.clip(128.0 + synthesized * source_luma.std(), 0.0, 255.0)
        output[:, :, channel] = np.polyval(coeff, tonal)
    lo = np.percentile(sample, 1, axis=(0, 1))
    hi = np.percentile(sample, 99, axis=(0, 1))
    return Image.fromarray(np.uint8(np.clip(output, lo, hi)), "RGB")


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


def _shadow() -> None:
    width, height = 256, 128
    y, x = np.indices((height, width), dtype=np.float64)
    radius = ((x - width / 2) / (width * 0.46)) ** 2 + ((y - height / 2) / (height * 0.38)) ** 2
    alpha = np.uint8(np.clip((1.0 - radius) ** 2 * 105.0, 0.0, 105.0))
    rgba = np.zeros((height, width, 4), dtype=np.uint8)
    rgba[:, :, 3] = alpha
    Image.fromarray(rgba, "RGBA").save(ASSETS / "shadow_decal.png", optimize=True)


def main() -> int:
    source = Image.open(SOURCE).convert("RGB")
    # Broad unobstructed spike areas: upper-right grass and central worn lane.
    grass_crop = source.crop((790, 36, 1138, 330))
    dirt_crop = source.crop((350, 330, 720, 590))
    grass = _periodic_texture(grass_crop, 0x4752415353)
    dirt = _periodic_texture(dirt_crop, 0x44495254)
    ASSETS.mkdir(parents=True, exist_ok=True)
    grass.save(ASSETS / "ground_grass_tile.png", optimize=True)
    dirt.save(ASSETS / "ground_dirt_tile.png", optimize=True)
    _shadow()
    _contact_sheet([("grass", grass), ("dirt", dirt)])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
