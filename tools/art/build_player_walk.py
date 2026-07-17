#!/usr/bin/env python3
"""Assemble a declared eight-facing, six-frame walk atlas without relaundering."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image


FACING_IDS = ("E", "SE", "S", "SW", "W", "NW", "N", "NE")
FRAMES_PER_FACING = 6


def build(manifest_path: Path, output: Path) -> Image.Image:
    data = json.loads(manifest_path.read_text(encoding="utf-8"))
    if tuple(data["facing_order"]) != FACING_IDS:
        raise ValueError(f"facing_order must be {FACING_IDS}")
    if data.get("frames_per_facing") != FRAMES_PER_FACING:
        raise ValueError("frames_per_facing must be 6")
    if data.get("mirroring", {}).get("enabled") and not data["mirroring"].get("declared_before_generation"):
        raise ValueError("mirroring must be declared before generation")
    cell = int(data["cell_size"])
    atlas = Image.new("RGBA", (cell * FRAMES_PER_FACING, cell * len(FACING_IDS)), (0, 0, 0, 0))
    frames = data["frames"]
    expected = [f"{facing}_{index}" for facing in FACING_IDS for index in range(FRAMES_PER_FACING)]
    if list(frames) != expected:
        raise ValueError("frames must declare all cells in immutable row-major order")
    for frame_id in expected:
        spec = frames[frame_id]
        image = Image.open(manifest_path.parent / spec["source"]).convert("RGBA")
        if image.size != (cell, cell):
            raise ValueError(f"wrong frame size for {frame_id}: {image.size}")
        row = FACING_IDS.index(frame_id.rsplit("_", 1)[0])
        col = int(frame_id.rsplit("_", 1)[1])
        atlas.alpha_composite(image, (col * cell, row * cell))
    output.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(output)
    return atlas


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("manifest", type=Path)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args(argv)
    build(args.manifest, args.output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
