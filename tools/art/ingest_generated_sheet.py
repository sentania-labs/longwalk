#!/usr/bin/env python3
"""Validate and extract a generated art sheet from a provenance manifest."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image


class ManifestError(ValueError):
    pass


def load_manifest(path: Path) -> dict:
    data = json.loads(path.read_text(encoding="utf-8"))
    required = ("version", "provenance", "sheet", "cells")
    missing = [key for key in required if key not in data]
    if missing:
        raise ManifestError(f"missing manifest fields: {', '.join(missing)}")
    provenance = data["provenance"]
    for key in ("prompt", "style_board", "generator"):
        if not isinstance(provenance.get(key), str) or not provenance[key].strip():
            raise ManifestError(f"missing provenance.{key}")
    return data


def _key_mask(cell: Image.Image, key: str, tolerance: int) -> np.ndarray:
    rgb = np.asarray(cell.convert("RGB"), dtype=np.int16)
    target = np.array([int(key[i : i + 2], 16) for i in (1, 3, 5)], dtype=np.int16)
    return np.max(np.abs(rgb - target), axis=2) <= tolerance


def validate_sheet(manifest_path: Path, source_override: Path | None = None) -> tuple[dict, Image.Image]:
    data = load_manifest(manifest_path)
    sheet = data["sheet"]
    for key in ("source", "rows", "cols", "cell_width", "cell_height", "expected_width", "expected_height"):
        if key not in sheet:
            raise ManifestError(f"missing sheet.{key}")
    source = source_override or manifest_path.parent / sheet["source"]
    image = Image.open(source).convert("RGBA")
    expected = (int(sheet["expected_width"]), int(sheet["expected_height"]))
    if image.size != expected:
        raise ManifestError(f"wrong sheet dimensions: expected {expected}, got {image.size}")
    rows, cols = int(sheet["rows"]), int(sheet["cols"])
    cw, ch = int(sheet["cell_width"]), int(sheet["cell_height"])
    if expected != (cols * cw, rows * ch):
        raise ManifestError("wrong grid: expected dimensions do not equal rows x cols x cell size")
    cells = data["cells"]
    if len(cells) != rows * cols:
        raise ManifestError(f"wrong grid: expected {rows * cols} cell declarations, got {len(cells)}")
    seen_slots: set[tuple[int, int]] = set()
    seen_ids: set[str] = set()
    declared_runtime = set(data.get("runtime_assets", []))
    actual_runtime: set[str] = set()
    key = sheet.get("magenta_key", "#FF00FF")
    tolerance = int(sheet.get("key_tolerance", 24))
    for cell in cells:
        for field in ("id", "row", "col", "role", "anchor", "output"):
            if field not in cell:
                raise ManifestError(f"cell missing {field}")
        slot = (int(cell["row"]), int(cell["col"]))
        if slot in seen_slots or not (0 <= slot[0] < rows and 0 <= slot[1] < cols):
            raise ManifestError(f"invalid or duplicate cell slot {slot}")
        if cell["id"] in seen_ids:
            raise ManifestError(f"duplicate cell id {cell['id']}")
        seen_slots.add(slot)
        seen_ids.add(cell["id"])
        anchor = cell["anchor"]
        if not (isinstance(anchor, list) and len(anchor) == 2 and 0 <= anchor[0] < cw and 0 <= anchor[1] < ch):
            raise ManifestError(f"invalid anchor for {cell['id']}")
        box = (slot[1] * cw, slot[0] * ch, (slot[1] + 1) * cw, (slot[0] + 1) * ch)
        keyed = _key_mask(image.crop(box), key, tolerance)
        foreground = ~keyed
        if not foreground.any():
            raise ManifestError(f"empty cell: {cell['id']}")
        if foreground[0].any() or foreground[-1].any() or foreground[:, 0].any() or foreground[:, -1].any():
            raise ManifestError(f"edge-touch cell: {cell['id']}")
        if cell.get("runtime", True):
            actual_runtime.add(cell["id"])
    if actual_runtime != declared_runtime:
        missing = sorted(actual_runtime - declared_runtime)
        extra = sorted(declared_runtime - actual_runtime)
        raise ManifestError(f"undeclared runtime assets: missing={missing}, extra={extra}")
    return data, image


def ingest(manifest_path: Path, output_dir: Path, source_override: Path | None = None) -> list[Path]:
    data, image = validate_sheet(manifest_path, source_override)
    sheet = data["sheet"]
    cw, ch = int(sheet["cell_width"]), int(sheet["cell_height"])
    key, tolerance = sheet.get("magenta_key", "#FF00FF"), int(sheet.get("key_tolerance", 24))
    output_dir.mkdir(parents=True, exist_ok=True)
    written = []
    for spec in data["cells"]:
        box = (spec["col"] * cw, spec["row"] * ch, (spec["col"] + 1) * cw, (spec["row"] + 1) * ch)
        cell = image.crop(box)
        rgba = np.asarray(cell).copy()
        rgba[_key_mask(cell, key, tolerance), 3] = 0
        destination = output_dir / spec["output"]
        destination.parent.mkdir(parents=True, exist_ok=True)
        Image.fromarray(rgba, "RGBA").save(destination)
        written.append(destination)
    return written


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("manifest", type=Path)
    parser.add_argument("--input", type=Path)
    parser.add_argument("--output-dir", type=Path, required=True)
    args = parser.parse_args(argv)
    try:
        ingest(args.manifest, args.output_dir, args.input)
    except (ManifestError, OSError, json.JSONDecodeError) as exc:
        parser.error(str(exc))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
