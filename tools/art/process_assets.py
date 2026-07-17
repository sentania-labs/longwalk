#!/usr/bin/env python3
"""Post-process raw AI-generated art into game-ready assets.

Raw output from generate.sh (see README.md) is high-resolution, uncropped,
and (for sprites) sits on a plain cream background rather than true alpha
transparency. This script does the two manual post-processing steps the
README calls out: background removal (flood fill from the corners, since
every sprite prompt asks for a single flat background color) and cropping
to content, then a resize to a game-usable pixel size. Ground tiles are
already full-bleed (no background to remove) so they only get resized.

Run locally with plain Python/PIL, not inside the codex sandbox (see
README.md's sandbox caveat); this script has no codex/network dependency at
all, so that only matters for generate.sh.

Usage: tools/art/process_assets.py
Reads tools/art/out/<name>.png, writes tools/art/out/processed/<name>.png.
"""

import pathlib

import numpy as np
from PIL import Image

SCRIPT_DIR = pathlib.Path(__file__).resolve().parent
OUT_DIR = SCRIPT_DIR / "out"
PROCESSED_DIR = OUT_DIR / "processed"

# Background flood-fill tolerance: how far a pixel's color may be from the
# sampled corner color and still count as background.
BG_TOLERANCE = 24

# Sprites: raw art on a flat background, needs bg removal, crop-to-content,
# then a resize so the longest side matches the given pixel size.
SPRITES = {
    "building_facade.png": 320,
    "cottage_facade.png": 320,
    "player_character.png": 160,
}

# Ground tiles: already full-bleed, no background to remove. Resize (down)
# to a square tile size suitable for a TileMap.
TILES = {
    "ground_path_tile.png": 128,
    "grass_ground_tile.png": 128,
}

# Character creation appearance presets: recolor the player_character.png
# tunic (olive green, hue ~52-60 degrees per a manual sample, clearly
# separated from the skin/hair hue range of ~26-36 degrees) to a handful of
# alternate hues. This avoids needing a separate AI generation per outfit
# color, at the cost of only being able to vary tunic color, not silhouette.
TUNIC_HUE_RANGE = (40, 80)
TUNIC_MIN_SATURATION = 0.4
APPEARANCE_VARIANTS = {
    "moss": None,  # the original generated hue, no shift
    "slate_blue": 210,
    "burgundy": 350,
}


def remove_background(image):
    """Flood-fill transparent starting from the four corners.

    Every sprite prompt in tools/art/prompts/ asks for a single flat
    background color, so the corners are always background and the subject
    never touches the image edge (the prompts ask for margin around the
    subject). A corner-seeded flood fill is enough; it also tolerates the
    soft anti-aliased edge between the background and the subject, and it
    will not eat into subject pixels that merely happen to be a similar
    color (for example a cream shirt sleeve) since those are not connected
    to the corners through only background-colored pixels.

    Implemented as vectorized dilation (grow the background region into
    neighboring similar-colored pixels, repeat to a fixpoint) rather than a
    per-pixel Python flood fill, since these images are 1000+ pixels per
    side.
    """
    rgba = image.convert("RGBA")
    rgb = np.asarray(rgba)[:, :, :3].astype(np.int16)
    height, width = rgb.shape[:2]

    seed_color = rgb[0, 0]
    similar = np.all(np.abs(rgb - seed_color) <= BG_TOLERANCE, axis=2)

    background = np.zeros((height, width), dtype=bool)
    background[0, :] = similar[0, :]
    background[-1, :] = similar[-1, :]
    background[:, 0] = similar[:, 0]
    background[:, -1] = similar[:, -1]

    while True:
        grown = background.copy()
        grown[1:, :] |= background[:-1, :]
        grown[:-1, :] |= background[1:, :]
        grown[:, 1:] |= background[:, :-1]
        grown[:, :-1] |= background[:, 1:]
        grown &= similar
        if np.array_equal(grown, background):
            break
        background = grown

    result = np.asarray(rgba).copy()
    result[background, 3] = 0
    return Image.fromarray(result, mode="RGBA")


def crop_to_content(image):
    bbox = image.getbbox()
    if bbox is None:
        return image
    return image.crop(bbox)


def resize_to_longest_side(image, target_longest_side):
    width, height = image.size
    scale = target_longest_side / max(width, height)
    new_size = (max(1, round(width * scale)), max(1, round(height * scale)))
    return image.resize(new_size, Image.Resampling.NEAREST)


def process_sprite(name, target_longest_side):
    src = OUT_DIR / name
    image = Image.open(src)
    image = remove_background(image)
    image = crop_to_content(image)
    image = resize_to_longest_side(image, target_longest_side)
    dest = PROCESSED_DIR / name
    image.save(dest)
    print(f"wrote {dest} ({image.size[0]}x{image.size[1]}, alpha)")


def recolor_tunic(image, target_hue_degrees):
    """Return a copy of image with tunic-colored pixels hue-shifted.

    Operates in HSV, only on pixels whose hue falls in TUNIC_HUE_RANGE with
    at least TUNIC_MIN_SATURATION, so skin, hair, and outline pixels (a
    clearly different hue, see the module docstring sample) are untouched.
    Saturation and value are preserved so shading/highlights still read.
    """
    rgba = image.convert("RGBA")
    rgb = np.asarray(rgba.convert("RGB"))
    alpha = np.asarray(rgba)[:, :, 3]

    hsv = np.asarray(rgba.convert("RGB").convert("HSV")).astype(np.float64)
    hue_deg = hsv[:, :, 0] * (360.0 / 255.0)
    sat = hsv[:, :, 1] / 255.0

    mask = (
        (hue_deg >= TUNIC_HUE_RANGE[0])
        & (hue_deg <= TUNIC_HUE_RANGE[1])
        & (sat >= TUNIC_MIN_SATURATION)
        & (alpha > 0)
    )

    new_hsv = hsv.copy()
    new_hsv[mask, 0] = target_hue_degrees * (255.0 / 360.0)
    new_rgb = np.asarray(Image.fromarray(new_hsv.astype(np.uint8), mode="HSV").convert("RGB"))

    result_rgb = np.where(mask[:, :, None], new_rgb, rgb)
    result = np.dstack([result_rgb, alpha])
    return Image.fromarray(result, mode="RGBA")


def process_appearance_variants():
    src = PROCESSED_DIR / "player_character.png"
    base = Image.open(src)
    for variant_name, target_hue in APPEARANCE_VARIANTS.items():
        dest = PROCESSED_DIR / f"player_character_{variant_name}.png"
        image = base if target_hue is None else recolor_tunic(base, target_hue)
        image.save(dest)
        print(f"wrote {dest} ({image.size[0]}x{image.size[1]}, alpha)")


def process_tile(name, tile_size):
    src = OUT_DIR / name
    image = Image.open(src).convert("RGB")
    image = image.resize((tile_size, tile_size), Image.Resampling.NEAREST)
    dest = PROCESSED_DIR / name
    image.save(dest)
    print(f"wrote {dest} ({tile_size}x{tile_size}, opaque)")


def main():
    PROCESSED_DIR.mkdir(parents=True, exist_ok=True)
    for name, target in SPRITES.items():
        process_sprite(name, target)
    for name, tile_size in TILES.items():
        process_tile(name, tile_size)
    process_appearance_variants()


if __name__ == "__main__":
    main()
