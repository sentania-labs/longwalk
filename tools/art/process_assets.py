#!/usr/bin/env python3
"""Manifest-driven normalization and deterministic ground-shadow derivation."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter


LIGHT_VECTOR = (18, 9)
FOOTPRINT_SLICE = 10


def normalize_to_anchor(image: Image.Image, size: tuple[int, int], source_anchor: tuple[int, int], target_anchor: tuple[int, int], scale: float = 1.0) -> Image.Image:
    if scale <= 0:
        raise ValueError("scale must be positive")
    if scale != 1.0:
        image = image.resize((max(1, round(image.width * scale)), max(1, round(image.height * scale))), Image.Resampling.LANCZOS)
        source_anchor = (round(source_anchor[0] * scale), round(source_anchor[1] * scale))
    output = Image.new("RGBA", size, (0, 0, 0, 0))
    output.alpha_composite(image.convert("RGBA"), (target_anchor[0] - source_anchor[0], target_anchor[1] - source_anchor[1]))
    return output


def derive_shadows(image: Image.Image, contact_y: int, light_vector: tuple[int, int] = LIGHT_VECTOR, footprint_slice: int = FOOTPRINT_SLICE) -> tuple[Image.Image, Image.Image]:
    """Derive cast and contact masks from only the bottom contact silhouette.

    Roof and wall alpha above the footprint slice never enters either mask.
    """
    alpha = np.asarray(image.convert("RGBA"))[:, :, 3]
    height, width = alpha.shape
    start = max(0, min(height - 1, contact_y - footprint_slice + 1))
    stop = max(start + 1, min(height, contact_y + 1))
    footprint = np.zeros_like(alpha)
    footprint[start:stop] = alpha[start:stop]
    cast = np.zeros_like(alpha)
    dx, dy = light_vector
    steps = max(abs(dx), abs(dy), 1)
    for step in range(steps + 1):
        ox = round(dx * step / steps)
        oy = round(dy * step / steps)
        src_y0, src_y1 = max(0, -oy), min(height, height - oy)
        src_x0, src_x1 = max(0, -ox), min(width, width - ox)
        cast[src_y0 + oy : src_y1 + oy, src_x0 + ox : src_x1 + ox] = np.maximum(
            cast[src_y0 + oy : src_y1 + oy, src_x0 + ox : src_x1 + ox],
            footprint[src_y0:src_y1, src_x0:src_x1],
        )
    cast_image = Image.fromarray(cast, "L").filter(ImageFilter.GaussianBlur(2.0))
    contact = Image.fromarray(footprint, "L").filter(ImageFilter.MaxFilter(5)).filter(ImageFilter.GaussianBlur(1.2))
    return cast_image, contact


def process_manifest(path: Path) -> list[Path]:
    data = json.loads(path.read_text(encoding="utf-8"))
    written: list[Path] = []
    for asset in data["assets"]:
        source = (path.parent / asset["source"]).resolve()
        destination = (path.parent / asset["output"]).resolve()
        image = Image.open(source).convert("RGBA")
        size = tuple(asset["output_size"])
        image = normalize_to_anchor(image, size, tuple(asset["source_anchor"]), tuple(asset["target_anchor"]), float(asset.get("scale", 1.0)))
        destination.parent.mkdir(parents=True, exist_ok=True)
        image.save(destination)
        written.append(destination)
        if asset.get("shadows"):
            cast, contact = derive_shadows(image, int(asset["target_anchor"][1]), tuple(data["shadow_policy"]["light_vector"]), int(data["shadow_policy"]["footprint_slice"]))
            for suffix, mask in (("cast", cast), ("contact", contact)):
                target = destination.with_name(f"{destination.stem}_{suffix}_shadow_rgba.png")
                alpha = np.asarray(mask)
                rgba = np.zeros((mask.height, mask.width, 4), dtype=np.uint8)
                rgba[:, :, 3] = alpha
                Image.fromarray(rgba, "RGBA").save(target)
                written.append(target)
    return written


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("manifest", type=Path)
    args = parser.parse_args(argv)
    process_manifest(args.manifest)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
