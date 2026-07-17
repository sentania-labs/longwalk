#!/usr/bin/env python3
"""Validate pre-render meter scale and post-process sprite landmarks."""

from __future__ import annotations

import argparse
import json
import math
from pathlib import Path
from typing import Any


PIXELS_PER_METER = 32.0 * math.sqrt(6.0)
HEIGHT_TOLERANCE_PX = 2.0
ANCHOR_TOLERANCE_PX = 2.0
METER_TOLERANCE = 0.01

POLICIES = {
    "player": {
        "canvas": (160, 160),
        "anchor": (80.0, 144.0),
        "height_field": "sole_to_crown_m",
        "height_min": 1.75,
        "height_max": 1.75,
        "required_dimensions": {"sole_to_crown_m": (1.75, 1.75)},
    },
    "cottage_2x2": {
        "canvas": (512, 512),
        "anchor": (256.0, 448.0),
        "height_field": "ridge_height_m",
        "height_min": 4.8,
        "height_max": 5.6,
        "required_dimensions": {
            "door_height_m": (2.0, 2.0),
            "eaves_height_m": (2.35, 2.45),
            "ridge_height_m": (4.8, 5.6),
        },
    },
}


class ScaleContractError(ValueError):
    pass


def _pair(value: Any, label: str) -> tuple[float, float]:
    if not isinstance(value, list) or len(value) != 2:
        raise ScaleContractError(f"{label} must be a two-item array")
    try:
        return float(value[0]), float(value[1])
    except (TypeError, ValueError) as exc:
        raise ScaleContractError(f"{label} values must be numbers") from exc


def check_manifest(path: Path) -> tuple[list[str], dict[str, Any]]:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ScaleContractError(f"cannot read manifest: {exc}") from exc

    kind = data.get("asset_kind")
    if kind not in POLICIES:
        raise ScaleContractError(f"unsupported asset_kind {kind!r}")
    policy = POLICIES[kind]
    scene = data.get("scene_geometry", {})
    output = data.get("output", {})
    landmarks = data.get("projected_landmarks", {})
    rejections: list[str] = []

    units = scene.get("scene_units_per_meter")
    if not isinstance(units, (int, float)) or abs(float(units) - 1.0) > METER_TOLERANCE:
        rejections.append("declared scene scale must be 1.0 scene unit per meter")
    plane = scene.get("contact_plane_z_m")
    if not isinstance(plane, (int, float)) or abs(float(plane)) > METER_TOLERANCE:
        rejections.append("contact plane must be Z = 0 m")

    height_field = policy["height_field"]
    height_value = None
    for field, limits in policy["required_dimensions"].items():
        value = scene.get(field)
        if not isinstance(value, (int, float)):
            rejections.append(f"missing numeric scene geometry field {field}")
            continue
        numeric = float(value)
        if field == height_field:
            height_value = numeric
        if not (limits[0] - METER_TOLERANCE <= numeric <= limits[1] + METER_TOLERANCE):
            rejections.append(
                f"declared {field} {numeric:g} m is outside {limits[0]:g} to {limits[1]:g} m"
            )

    canvas = _pair(output.get("resolution_px"), "output.resolution_px")
    if canvas != policy["canvas"]:
        rejections.append(f"output resolution must be {policy['canvas'][0]}x{policy['canvas'][1]}")

    contact = _pair(landmarks.get("contact_px"), "projected_landmarks.contact_px")
    anchor_error = max(abs(contact[i] - policy["anchor"][i]) for i in range(2))
    if anchor_error > ANCHOR_TOLERANCE_PX:
        rejections.append(
            f"contact anchor drift {anchor_error:.2f}px exceeds {ANCHOR_TOLERANCE_PX:.0f}px"
        )

    top = _pair(landmarks.get("top_px"), "projected_landmarks.top_px")
    rendered_height = contact[1] - top[1]
    expected_height = height_value * PIXELS_PER_METER if height_value is not None else None
    height_error = abs(rendered_height - expected_height) if expected_height is not None else None
    if height_error is not None and height_error > HEIGHT_TOLERANCE_PX:
        rejections.append(
            f"projected pixel height drift {height_error:.2f}px exceeds {HEIGHT_TOLERANCE_PX:.0f}px"
        )

    return rejections, {
        "asset_kind": kind,
        "pixels_per_meter": PIXELS_PER_METER,
        "expected_pixel_height": expected_height,
        "rendered_pixel_height": rendered_height,
        "anchor_error_px": anchor_error,
        "height_error_px": height_error,
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("manifest", type=Path)
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args(argv)
    try:
        rejections, report = check_manifest(args.manifest)
    except ScaleContractError as exc:
        parser.error(str(exc))
    if args.json:
        print(json.dumps({"rejections": rejections, **report}, indent=2))
    else:
        print("scale contract rejected" if rejections else "scale contract passed")
        for rejection in rejections:
            print(f"- {rejection}")
    return 1 if rejections else 0


if __name__ == "__main__":
    raise SystemExit(main())
