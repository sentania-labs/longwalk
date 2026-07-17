#!/usr/bin/env python3
"""Build deterministic walk GIF and before/after acceptance artifacts."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageDraw


def build_walk_gif(frames: list[Path], output: Path, duration: int = 110) -> None:
    images = [Image.open(path).convert("RGBA") for path in frames]
    if not images or len({image.size for image in images}) != 1:
        raise ValueError("walk GIF requires same-sized frames")
    output.parent.mkdir(parents=True, exist_ok=True)
    images[0].save(output, save_all=True, append_images=images[1:], duration=duration, loop=0, disposal=2)


def build_comparison(before: Path, after: Path, output: Path) -> None:
    images = [Image.open(path).convert("RGB") for path in (before, after)]
    height = min(image.height for image in images)
    resized = [image.resize((round(image.width * height / image.height), height), Image.Resampling.LANCZOS) for image in images]
    canvas = Image.new("RGB", (sum(image.width for image in resized), height + 30), (28, 25, 20))
    draw = ImageDraw.Draw(canvas)
    x = 0
    for label, image in zip(("BEFORE", "AFTER"), resized):
        canvas.paste(image, (x, 30))
        draw.text((x + 8, 8), label, fill=(235, 225, 195))
        x += image.width
    output.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(output)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    gif = sub.add_parser("walk-gif")
    gif.add_argument("frames", nargs="+", type=Path)
    gif.add_argument("--output", required=True, type=Path)
    compare = sub.add_parser("comparison")
    compare.add_argument("--before", required=True, type=Path)
    compare.add_argument("--after", required=True, type=Path)
    compare.add_argument("--output", required=True, type=Path)
    args = parser.parse_args(argv)
    if args.command == "walk-gif":
        build_walk_gif(args.frames, args.output)
    else:
        build_comparison(args.before, args.after, args.output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
