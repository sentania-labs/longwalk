#!/usr/bin/env python3
"""Composite Candidate B (generative-albedo) renders into muted painterly sprites.

Candidate B differs from Candidate A in exactly ONE place: the surface treatment.
Both use the identical cleaned geometry, 30 degree ORTHO iso camera, warm-key +
cool-fill lighting, 160 px cells, contact anchor, and grounding shadow. Candidate
A recovers painterliness with a deterministic 16-colour palette quantisation plus
normal-derived NPR shading (tools/art/treat_candidate_a.py). Candidate B instead
takes the rendered colour pass as-is (the painterly look lives in the Meshy
restyled mesh albedo and the 3D render lighting) and only cleans the alpha edge,
so the pilot compares the two fidelity-recovery MECHANISMS, not two compositors.

No palette quantisation, no synthetic re-lighting, and no forced dark silhouette
edge are applied here; those are Candidate A's NPR choices. Placement, canvas, and
the fixed grounding shadow are copied verbatim from Candidate A for parity.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter


FACINGS = ("E", "SE", "S", "SW", "W", "NW", "N", "NE")


def prepare(color_path: Path) -> Image.Image:
    """Rendered colour pass, softened alpha edge only. No surface restyle here:
    the restyle is the Meshy albedo, baked into the render already."""
    color = Image.open(color_path).convert("RGBA")
    rgba = np.asarray(color).copy()
    alpha = rgba[:, :, 3]
    soft_alpha = Image.fromarray(alpha).filter(ImageFilter.GaussianBlur(0.45))
    result = np.dstack((rgba[:, :, :3], np.asarray(soft_alpha, dtype=np.uint8)))
    result[alpha == 0, :3] = 0
    return Image.fromarray(result, "RGBA")


def place(source: Image.Image, size: tuple[int, int], body_contact: tuple[int, int],
          source_contact=(512, 512), shadow=False) -> Image.Image:
    """Identical to Candidate A's placement, including the fixed grounding shadow."""
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


def alpha_bottom(image: Image.Image) -> int:
    """Bottom-most visible row, so placement grounds the subject's feet exactly
    where Candidate A grounds them. Same geometry and camera means the same
    contact row, which is what keeps the two candidates apples-to-apples."""
    alpha = np.asarray(image)[:, :, 3]
    rows = np.nonzero(alpha > 8)[0]
    if not len(rows):
        raise ValueError("rendered subject has no visible pixels")
    return int(rows.max())


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--render-dir", type=Path, default=Path("assets/art_src/pilot/candidate_b/render"))
    parser.add_argument("--output-dir", type=Path, default=Path("assets/art_src/pilot/candidate_b/finished"))
    args = parser.parse_args()
    player_out = args.output_dir / "player"
    cottage_out = args.output_dir / "cottage"
    player_out.mkdir(parents=True, exist_ok=True)
    cottage_out.mkdir(parents=True, exist_ok=True)

    frames = {}
    for facing in FACINGS:
        for pose in range(6):
            sprite = prepare(args.render_dir / "player" / f"{facing}_{pose}_color.png")
            cell = place(sprite, (160, 160), (80, 144), source_contact=(512, alpha_bottom(sprite)), shadow=True)
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

    cottage = prepare(args.render_dir / "cottage" / "W_0_color.png")
    place(cottage, (512, 512), (256, 448), source_contact=(512, alpha_bottom(cottage))).save(
        cottage_out / "cottage_w.png", optimize=False, compress_level=9
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
