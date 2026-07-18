#!/usr/bin/env python3
"""Manifest-driven normalization and deterministic ground-shadow derivation."""

from __future__ import annotations

import argparse
from collections import deque
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter


LIGHT_VECTOR = (18, 9)
FOOTPRINT_SLICE = 10


def remove_border_background(
    image: Image.Image,
    tolerance: float = 12.0,
    max_chroma: int = 18,
    feather_radius: float = 1.0,
    decontaminate_rgb: bool = False,
) -> Image.Image:
    """Remove a smooth neutral background connected to the image border.

    Membership is grown from every border pixel. A candidate must be close to
    the neighboring background pixel and remain nearly neutral, which keeps
    similarly colored stone inside the isolated object opaque.
    """
    rgb = np.asarray(image.convert("RGB"), dtype=np.int16)
    height, width, _ = rgb.shape
    background = np.zeros((height, width), dtype=bool)
    queued = np.zeros((height, width), dtype=bool)
    pending: deque[tuple[int, int]] = deque()

    def seed(x: int, y: int) -> None:
        if not queued[y, x]:
            queued[y, x] = True
            background[y, x] = True
            pending.append((x, y))

    for x in range(width):
        seed(x, 0)
        seed(x, height - 1)
    for y in range(height):
        seed(0, y)
        seed(width - 1, y)

    tolerance_squared = tolerance * tolerance
    while pending:
        x, y = pending.popleft()
        current = rgb[y, x]
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if nx < 0 or nx >= width or ny < 0 or ny >= height or queued[ny, nx]:
                continue
            queued[ny, nx] = True
            candidate = rgb[ny, nx]
            delta = candidate - current
            chroma = int(candidate.max() - candidate.min())
            if chroma <= max_chroma and float(delta @ delta) <= tolerance_squared:
                background[ny, nx] = True
                pending.append((nx, ny))

    # A hard lighting seam can leave a narrow rejected strip even though both
    # sides were reached from the border. Remove every residual foreground
    # component that still touches the border. The isolated subject is fully
    # enclosed by background in the generated source contract.
    residual = ~background
    exterior = np.zeros((height, width), dtype=bool)
    pending.clear()

    def seed_residual(x: int, y: int) -> None:
        if residual[y, x] and not exterior[y, x]:
            exterior[y, x] = True
            pending.append((x, y))

    for x in range(width):
        seed_residual(x, 0)
        seed_residual(x, height - 1)
    for y in range(height):
        seed_residual(0, y)
        seed_residual(width - 1, y)
    while pending:
        x, y = pending.popleft()
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if 0 <= nx < width and 0 <= ny < height and residual[ny, nx] and not exterior[ny, nx]:
                exterior[ny, nx] = True
                pending.append((nx, ny))
    background |= exterior

    # The contract contains one isolated object. Keep its largest connected
    # foreground component so disconnected lighting seams and compression
    # flecks cannot survive as sprite content.
    residual = ~background
    visited = np.zeros((height, width), dtype=bool)
    largest_component: list[tuple[int, int]] = []
    for y in range(height):
        for x in range(width):
            if not residual[y, x] or visited[y, x]:
                continue
            component: list[tuple[int, int]] = []
            visited[y, x] = True
            pending.append((x, y))
            while pending:
                cx, cy = pending.popleft()
                component.append((cx, cy))
                for nx, ny in ((cx - 1, cy), (cx + 1, cy), (cx, cy - 1), (cx, cy + 1)):
                    if 0 <= nx < width and 0 <= ny < height and residual[ny, nx] and not visited[ny, nx]:
                        visited[ny, nx] = True
                        pending.append((nx, ny))
            if len(component) > len(largest_component):
                largest_component = component
    background[:] = True
    for x, y in largest_component:
        background[y, x] = False

    background_mask = Image.fromarray(background.astype(np.uint8) * 255, "L")
    if decontaminate_rgb:
        # Contract the matte by one source pixel before feathering. Generated
        # antialiasing blends neutral background RGB into this outermost ring.
        background_mask = background_mask.filter(ImageFilter.MaxFilter(3))
    if feather_radius > 0:
        background_mask = background_mask.filter(ImageFilter.GaussianBlur(feather_radius))
    alpha = 255 - np.asarray(background_mask, dtype=np.uint8)
    result = image.convert("RGBA")
    if decontaminate_rgb:
        pixels = np.asarray(result).copy()
        rgb = pixels[:, :, :3]
        known = alpha == 255
        edge = (alpha > 0) & ~known
        # Feather pixels are at most two pixels from the contracted opaque
        # matte. Propagate subject RGB outwards so filtering cannot reveal the
        # neutral source background as a halo.
        for _step in range(16):
            if not edge.any():
                break
            next_known = known.copy()
            for dy, dx in ((-1, -1), (-1, 0), (-1, 1), (0, -1), (0, 1), (1, -1), (1, 0), (1, 1)):
                source_known = np.roll(known, (dy, dx), axis=(0, 1))
                source_rgb = np.roll(rgb, (dy, dx), axis=(0, 1))
                take = edge & source_known & ~next_known
                rgb[take] = source_rgb[take]
                next_known[take] = True
            known = next_known
            edge &= ~known
        result = Image.fromarray(pixels, "RGBA")
    result.putalpha(Image.fromarray(alpha, "L"))
    return result


def autocrop_and_fit(image: Image.Image, target_size: tuple[int, int]) -> Image.Image:
    """Crop transparent margins and fit within target_size without distortion."""
    alpha = image.getchannel("A")
    bbox = alpha.getbbox()
    if bbox is None:
        raise ValueError("background removal produced an empty image")
    image = image.crop(bbox)
    scale = min(target_size[0] / image.width, target_size[1] / image.height)
    output_size = (
        max(1, round(image.width * scale)),
        max(1, round(image.height * scale)),
    )
    fitted = image.resize(output_size, Image.Resampling.LANCZOS)
    pixels = np.asarray(fitted).copy()
    nearly_transparent = pixels[:, :, 3] <= 1
    pixels[nearly_transparent] = 0
    return Image.fromarray(pixels, "RGBA")


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
        if asset.get("operation") == "derive_shadows":
            source = (path.parent / asset["source"]).resolve()
            output_dir = (path.parent / asset["output_dir"]).resolve()
            image = Image.open(source).convert("RGBA")
            cast, contact = derive_shadows(
                image,
                int(asset["contact_y"]),
                tuple(data["shadow_policy"]["light_vector"]),
                int(asset.get("footprint_slice", data["shadow_policy"]["footprint_slice"])),
            )
            output_dir.mkdir(parents=True, exist_ok=True)
            for kind, mask in (("cast", cast), ("contact", contact)):
                target = output_dir / f"{asset['id']}_{kind}.png"
                rgba = np.zeros((mask.height, mask.width, 4), dtype=np.uint8)
                rgba[:, :, 3] = np.asarray(mask)
                Image.fromarray(rgba, "RGBA").save(target)
                written.append(target)
            continue
        if asset.get("operation") == "remove_border_background":
            source = (path.parent / asset["source"]).resolve()
            destination = (path.parent / asset["output"]).resolve()
            image = remove_border_background(
                Image.open(source),
                float(asset.get("flood_tolerance", 12.0)),
                int(asset.get("max_chroma", 18)),
                float(asset.get("feather_radius", 1.0)),
                bool(asset.get("decontaminate_rgb", False)),
            )
            image = autocrop_and_fit(image, tuple(asset["target_size"]))
            destination.parent.mkdir(parents=True, exist_ok=True)
            image.save(destination)
            written.append(destination)
            continue
        if "crop" in asset:
            source = (path.parent / asset["source"]).resolve()
            destination = (path.parent / asset["output"]).resolve()
            crop = tuple(asset["crop"])
            image = Image.open(source).convert("RGBA").crop(crop)
            mask = Image.new("L", image.size, 0)
            points = asset.get("polygon", [[0, 0], [image.width, 0], [image.width, image.height], [0, image.height]])
            ImageDraw.Draw(mask).polygon([tuple(point) for point in points], fill=255)
            image.putalpha(mask)
            destination.parent.mkdir(parents=True, exist_ok=True)
            image.save(destination)
            written.append(destination)
            continue
        if "placeholder_size" in asset:
            destination = (path.parent / asset["output"]).resolve()
            size = tuple(asset["placeholder_size"])
            image = Image.new("RGBA", size, (0, 0, 0, 0))
            inset = max(4, min(size) // 16)
            ImageDraw.Draw(image).polygon(
                [(size[0] // 2, inset), (size[0] - inset, size[1] - inset), (inset, size[1] - inset)],
                fill=(255, 0, 255, 255),
            )
            destination.parent.mkdir(parents=True, exist_ok=True)
            image.save(destination)
            written.append(destination)
            continue
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
