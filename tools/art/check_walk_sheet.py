#!/usr/bin/env python3
"""Reject malformed 8-facing x 6-frame isometric walk atlases."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image

from build_player_walk import FACING_IDS, FRAMES_PER_FACING


class SheetError(ValueError):
    pass


def check_sheet(path: Path, cell_size: int = 160) -> tuple[list[str], dict]:
    image = Image.open(path).convert("RGBA")
    expected = (cell_size * FRAMES_PER_FACING, cell_size * len(FACING_IDS))
    if image.size != expected:
        raise SheetError(f"expected {expected[0]}x{expected[1]} 8-facing sheet, got {image.size}")
    alpha = np.asarray(image)[:, :, 3]
    rejections: list[str] = []
    rows = {}
    for row, facing in enumerate(FACING_IDS):
        anchors = []
        for col in range(FRAMES_PER_FACING):
            mask = alpha[row * cell_size : (row + 1) * cell_size, col * cell_size : (col + 1) * cell_size] > 0
            ys, xs = np.nonzero(mask)
            if not len(xs):
                rejections.append(f"{facing} frame {col} is empty")
                continue
            if mask[0].any() or mask[:, 0].any() or mask[:, -1].any():
                rejections.append(f"{facing} frame {col} touches a non-contact edge")
            anchors.append(int(ys.max()))
        drift = float(np.std(anchors)) if anchors else float("inf")
        if drift > cell_size * 0.05:
            rejections.append(f"{facing} ground-contact anchor drift {drift:.2f}px exceeds 5%")
        rows[facing] = {"contact_rows": anchors, "anchor_stddev": drift}
    return rejections, {"facing_order": list(FACING_IDS), "frames_per_facing": FRAMES_PER_FACING, "rows": rows}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("sheet", type=Path)
    parser.add_argument("--cell-size", type=int, default=160)
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args(argv)
    try:
        rejections, report = check_sheet(args.sheet, args.cell_size)
    except SheetError as exc:
        parser.error(str(exc))
    if args.json:
        print(json.dumps({"rejections": rejections, **report}, indent=2))
    else:
        print("walk sheet rejected" if rejections else "walk sheet passed rejection gates")
        for rejection in rejections:
            print(f"- {rejection}")
    return 1 if rejections else 0


if __name__ == "__main__":
    raise SystemExit(main())
