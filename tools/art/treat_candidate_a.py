#!/usr/bin/env python3
"""Deterministically composite Candidate A into muted painterly sprites."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter


FACINGS = ("E", "SE", "S", "SW", "W", "NW", "N", "NE")
PALETTE = np.array(
    [
        (40, 44, 37), (65, 68, 52), (88, 82, 59), (109, 96, 67),
        (132, 113, 78), (155, 134, 96), (179, 158, 116), (204, 187, 147),
        (73, 61, 55), (99, 72, 59), (124, 83, 62), (146, 101, 72),
        (62, 76, 72), (79, 93, 84), (101, 111, 94), (130, 133, 105),
    ],
    dtype=np.int16,
)


def painterly(color_path: Path, normal_path: Path) -> Image.Image:
    color = Image.open(color_path).convert("RGBA")
    rgba = np.asarray(color).copy()
    alpha = rgba[:, :, 3]
    rgb = rgba[:, :, :3].astype(np.float32)
    normal = np.asarray(Image.open(normal_path).convert("RGB"), dtype=np.float32) / 255.0

    light = np.clip(0.78 + (normal[:, :, 2] - 0.5) * 0.38 + (normal[:, :, 1] - 0.5) * 0.12, 0.68, 1.08)
    rgb *= light[:, :, None]
    rgb = rgb * np.array([0.94, 0.91, 0.82]) + np.array([8.0, 7.0, 5.0])
    flat = rgb.reshape(-1, 1, 3)
    nearest = ((flat - PALETTE[None, :, :]) ** 2).sum(axis=2).argmin(axis=1)
    quantized = PALETTE[nearest].reshape(rgb.shape).astype(np.uint8)

    soft_alpha = Image.fromarray(alpha).filter(ImageFilter.GaussianBlur(0.45))
    edge = np.asarray(Image.fromarray(alpha).filter(ImageFilter.MaxFilter(3)), dtype=np.int16) - alpha.astype(np.int16)
    quantized[edge > 28] = (49, 50, 41)
    result = np.dstack((quantized, np.asarray(soft_alpha, dtype=np.uint8)))
    result[alpha == 0, :3] = 0
    return Image.fromarray(result, "RGBA")


def place(source: Image.Image, size: tuple[int, int], body_contact: tuple[int, int], source_contact=(512, 512), shadow=False) -> Image.Image:
    canvas = Image.new("RGBA", size, (0, 0, 0, 0))
    if shadow:
        shadow_layer = Image.new("RGBA", size, (0, 0, 0, 0))
        shadow_shape = Image.new("L", (54, 14), 0)
        yy, xx = np.ogrid[:14, :54]
        mask = np.clip(1.0 - ((xx - 26.5) / 27.0) ** 2 - ((yy - 6.5) / 7.0) ** 2, 0, 1)
        shadow_shape.putdata((mask * 82).astype(np.uint8).ravel())
        shadow_shape = shadow_shape.filter(ImageFilter.GaussianBlur(2.0))
        shadow_layer.paste((46, 50, 39, 82), (body_contact[0] - 27, 146), shadow_shape)
        canvas.alpha_composite(shadow_layer)
    canvas.alpha_composite(source, (body_contact[0] - source_contact[0], body_contact[1] - source_contact[1]))
    return canvas


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--render-dir", type=Path, default=Path("assets/art_src/pilot/candidate_a/render"))
    parser.add_argument("--output-dir", type=Path, default=Path("assets/art_src/pilot/candidate_a/finished"))
    args = parser.parse_args()
    player_out = args.output_dir / "player"
    cottage_out = args.output_dir / "cottage"
    player_out.mkdir(parents=True, exist_ok=True)
    cottage_out.mkdir(parents=True, exist_ok=True)

    frames = {}
    for facing in FACINGS:
        for pose in range(6):
            sprite = painterly(
                args.render_dir / "player" / f"{facing}_{pose}_color.png",
                args.render_dir / "player" / f"{facing}_{pose}_normal.png",
            )
            cell = place(sprite, (160, 160), (80, 144), shadow=True)
            name = f"{facing}_{pose}.png"
            cell.save(player_out / name, optimize=False, compress_level=9)
            frames[f"{facing}_{pose}"] = {"source": f"finished/player/{name}"}

    manifest = {
        "facing_order": list(FACINGS),
        "frames_per_facing": 6,
        "cell_size": 160,
        "contact_anchor": [80, 159],
        "mirroring": {"enabled": False},
        "frames": frames,
    }
    (args.output_dir.parent / "player_walk_manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")

    cottage = painterly(
        args.render_dir / "cottage" / "SW_0_color.png",
        args.render_dir / "cottage" / "SW_0_normal.png",
    )
    place(cottage, (512, 512), (256, 448)).save(cottage_out / "cottage_sw.png", optimize=False, compress_level=9)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
