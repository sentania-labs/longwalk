#!/usr/bin/env python3
"""Extract the ruled Kenney Roguelike/RPG subset at an integer art scale.

The source sheet is 16 px with a 1 px gutter. Shipping ground tiles are 128 px,
so every source pixel becomes an exact 8 by 8 block. Props retain transparent
padding and use the same scale. There is no interpolation or generated detail.
"""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


TILE = 16
GUTTER = 1
SCALE = 8


def tile(sheet: Image.Image, column: int, row: int) -> Image.Image:
    left = column * (TILE + GUTTER)
    top = row * (TILE + GUTTER)
    return sheet.crop((left, top, left + TILE, top + TILE))


def nearest(image: Image.Image) -> Image.Image:
    return image.resize((image.width * SCALE, image.height * SCALE), Image.Resampling.NEAREST)


def stacked_prop(sheet: Image.Image, column: int, rows: tuple[int, ...]) -> Image.Image:
    result = Image.new("RGBA", (TILE, TILE * len(rows)), (0, 0, 0, 0))
    for index, row in enumerate(rows):
        result.alpha_composite(tile(sheet, column, row), (0, index * TILE))
    return result


def building(sheet: Image.Image) -> Image.Image:
    """Assemble one pack-native cottage from roof, wall, window, and door tiles."""
    result = Image.new("RGBA", (TILE * 5, TILE * 5), (0, 0, 0, 0))

    # Beige roof pieces and wall surfaces are adjacent families in the source
    # sheet. The composition stays tile-native and is intentionally simple.
    roof = [tile(sheet, column, 21) for column in (13, 14, 15, 16, 16)]
    wall = tile(sheet, 17, 21)
    window = tile(sheet, 47, 2)
    door = tile(sheet, 44, 2)
    for column, piece in enumerate(roof):
        result.alpha_composite(piece, (column * TILE, 0))
    for row in range(1, 5):
        for column in range(5):
            result.alpha_composite(wall, (column * TILE, row * TILE))
    result.alpha_composite(window, (TILE, TILE * 2))
    result.alpha_composite(window, (TILE * 3, TILE * 2))
    result.alpha_composite(door, (TILE * 2, TILE * 3))
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("sheet", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()

    sheet = Image.open(args.sheet).convert("RGBA")
    args.output.mkdir(parents=True, exist_ok=True)

    assets = {
        "grass.png": tile(sheet, 5, 0),
        "path.png": tile(sheet, 6, 0),
        "tree.png": stacked_prop(sheet, 14, (9, 10, 11)),
        "bush.png": tile(sheet, 20, 9),
        "flowers.png": tile(sheet, 0, 6),
        "cottage.png": building(sheet),
    }
    for name, image in assets.items():
        destination = args.output / name
        nearest(image).save(destination)
        print(f"wrote {destination} ({image.width * SCALE}x{image.height * SCALE})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
