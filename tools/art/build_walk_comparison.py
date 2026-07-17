#!/usr/bin/env python3
"""Build Scott's side-by-side walk-cycle acceptance GIF deterministically."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageSequence


ROOT = Path(__file__).resolve().parents[2]
ATLAS = ROOT / "tools/art/out/processed/player_walk_moss.png"
REFERENCE = ROOT / "docs/art/reference/human_walk_downx3.gif"
OUTPUT = ROOT / "docs/art/round-004-walk-comparison.gif"
CELL = 160


def main() -> int:
    atlas = Image.open(ATLAS).convert("RGBA")
    ours = [atlas.crop((column * CELL, 0, (column + 1) * CELL, CELL)) for column in range(4)]
    reference = [frame.convert("RGBA") for frame in ImageSequence.Iterator(Image.open(REFERENCE))]

    frames = []
    for index in range(12):
        canvas = Image.new("RGBA", (400, 220), (35, 39, 43, 255))
        draw = ImageDraw.Draw(canvas)
        draw.text((82, 12), "longwalk, 4 frames", fill="white")
        draw.text((242, 12), "CC0 reference, 3 frames", fill="white")
        left = ours[index % len(ours)]
        right = reference[index % len(reference)].resize((160, 160), Image.Resampling.NEAREST)
        canvas.alpha_composite(left, (20, 42))
        canvas.alpha_composite(right, (220, 42))
        draw.line((12, 202, 388, 202), fill=(220, 170, 90, 255), width=2)
        frames.append(canvas.convert("P", palette=Image.Palette.ADAPTIVE))

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    frames[0].save(OUTPUT, save_all=True, append_images=frames[1:], duration=140, loop=0, disposal=2)
    print(f"wrote {OUTPUT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
