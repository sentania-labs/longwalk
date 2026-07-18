#!/usr/bin/env python3
import json
import pathlib
import sys
import tempfile

import numpy as np
from PIL import Image, ImageDraw

ROOT = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools/art"))

from ingest_generated_sheet import ManifestError, ingest, validate_sheet
from process_assets import autocrop_and_fit, derive_shadows, remove_border_background

VILLAGE_ASSETS = ROOT / "assets/village"
VILLAGE_GROUND_IDS = {
    "ground_grass_plate": ("ground_plate", (1024, 1024), "generated"),
    "ground_dirt_plate": ("ground_plate", (1024, 1024), "generated"),
    "ground_warp": ("ground_warp", (256, 256), "generated"),
    "shadow_decal": ("shadow", (256, 128), "generated"),
}


def manifest(root: pathlib.Path) -> pathlib.Path:
    path = root / "manifest.json"
    path.write_text(json.dumps({
        "version": "longwalk.generated-sheet.v1",
        "provenance": {"prompt": "prompt.txt", "style_board": "board.png", "generator": "image_gen"},
        "sheet": {"source": "sheet.png", "rows": 1, "cols": 1, "cell_width": 32, "cell_height": 32,
                  "expected_width": 32, "expected_height": 32, "magenta_key": "#FF00FF", "key_tolerance": 8},
        "runtime_assets": ["tree"],
        "cells": [{"id": "tree", "row": 0, "col": 0, "role": "flora", "anchor": [16, 27],
                   "output": "tree.png", "runtime": True}],
    }), encoding="utf-8")
    return path


def main() -> int:
    village_manifest = json.loads((VILLAGE_ASSETS / "manifest.json").read_text(encoding="utf-8"))
    village_records = {record["id"]: record for record in village_manifest["objects"]}
    for asset_id, (kind, dimensions, provenance) in VILLAGE_GROUND_IDS.items():
        record = village_records[asset_id]
        assert record["kind"] == kind
        assert tuple(record["native_px"]) == dimensions
        assert record["provenance"] == provenance
        asset_path = VILLAGE_ASSETS / record["png"]
        assert asset_path.exists(), f"missing village asset: {asset_path}"
        with Image.open(asset_path) as village_image:
            assert village_image.size == dimensions, f"native_px mismatch for {asset_id}"

    with tempfile.TemporaryDirectory() as temp:
        root = pathlib.Path(temp)
        image = Image.new("RGB", (32, 32), "#FF00FF")
        ImageDraw.Draw(image).rectangle((10, 8, 21, 27), fill=(20, 90, 30))
        image.save(root / "sheet.png")
        path = manifest(root)
        validate_sheet(path)
        outputs = ingest(path, root / "out")
        assert outputs[0].exists() and Image.open(outputs[0]).getpixel((0, 0))[3] == 0
        edge = Image.open(root / "sheet.png")
        ImageDraw.Draw(edge).point((0, 0), fill=(0, 0, 0))
        edge.save(root / "sheet.png")
        try:
            validate_sheet(path)
            raise AssertionError("edge touch accepted")
        except ManifestError:
            pass

        sprite = Image.new("RGBA", (40, 40), (0, 0, 0, 0))
        draw = ImageDraw.Draw(sprite)
        draw.rectangle((5, 2, 34, 20), fill=(255, 255, 255, 255))
        draw.rectangle((14, 28, 25, 31), fill=(255, 255, 255, 255))
        cast, contact = derive_shadows(sprite, 31, (6, 3), 4)
        cast_alpha = np.asarray(cast)
        contact_alpha = np.asarray(contact)
        assert cast_alpha[2:21].max() == 0, "roof pixels leaked into cast source"
        assert cast_alpha[28:].max() > 0 and contact_alpha[28:].max() > 0

        generated = Image.new("RGB", (64, 64), (140, 141, 140))
        generated_draw = ImageDraw.Draw(generated)
        generated_draw.rectangle((16, 12, 47, 55), fill=(90, 70, 45))
        generated_draw.rectangle((20, 16, 43, 51), fill=(138, 139, 138))
        cleaned = remove_border_background(generated, tolerance=12, max_chroma=18, feather_radius=1.0)
        assert cleaned.getpixel((0, 0))[3] == 0
        assert cleaned.getpixel((24, 20))[3] == 255, "border fill punched through enclosed gray stone"
        fitted = autocrop_and_fit(cleaned, (20, 30))
        assert fitted.width <= 20 and fitted.height <= 30
    print("art manifest tests passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
