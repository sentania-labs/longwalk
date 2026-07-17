#!/usr/bin/env python3
import json
import math
import pathlib
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools/art"))

from check_scale_contract import check_manifest


def write_fixture(path: pathlib.Path, **changes: object) -> None:
    fixture = {
        "asset_kind": "player",
        "scene_geometry": {
            "scene_units_per_meter": 1.0,
            "contact_plane_z_m": 0.0,
            "sole_to_crown_m": 1.75,
        },
        "output": {"resolution_px": [160, 160]},
        "projected_landmarks": {
            "contact_px": [80, 144],
            "top_px": [80, 144 - 1.75 * 32 * math.sqrt(6)],
        },
    }
    for dotted_key, value in changes.items():
        target = fixture
        parts = dotted_key.split("__")
        for part in parts[:-1]:
            target = target[part]  # type: ignore[index,assignment]
        target[parts[-1]] = value  # type: ignore[index]
    path.write_text(json.dumps(fixture), encoding="utf-8")


def assert_rejected(path: pathlib.Path, phrase: str) -> None:
    rejections, _ = check_manifest(path)
    assert any(phrase in rejection for rejection in rejections), rejections


def main() -> int:
    with tempfile.TemporaryDirectory() as temp:
        root = pathlib.Path(temp)
        good = root / "good.json"
        write_fixture(good)
        rejections, report = check_manifest(good)
        assert rejections == []
        assert report["expected_pixel_height"] == 1.75 * 32 * math.sqrt(6)

        cottage = root / "cottage.json"
        cottage.write_text(json.dumps({
            "asset_kind": "cottage_2x2",
            "scene_geometry": {
                "scene_units_per_meter": 1.0,
                "contact_plane_z_m": 0.0,
                "door_height_m": 2.0,
                "eaves_height_m": 2.4,
                "ridge_height_m": 5.0,
            },
            "output": {"resolution_px": [512, 512]},
            "projected_landmarks": {
                "contact_px": [256, 448],
                "top_px": [256, 448 - 5.0 * 32 * math.sqrt(6)],
            },
        }), encoding="utf-8")
        assert check_manifest(cottage)[0] == []

        wrong_scale = root / "wrong_scale.json"
        write_fixture(wrong_scale, scene_geometry__scene_units_per_meter=0.5)
        assert_rejected(wrong_scale, "declared scene scale")

        wrong_height = root / "wrong_height.json"
        write_fixture(wrong_height, scene_geometry__sole_to_crown_m=1.5)
        assert_rejected(wrong_height, "outside")

        wrong_plane = root / "wrong_plane.json"
        write_fixture(wrong_plane, scene_geometry__contact_plane_z_m=0.1)
        assert_rejected(wrong_plane, "contact plane")

        wrong_canvas = root / "wrong_canvas.json"
        write_fixture(wrong_canvas, output__resolution_px=[320, 320])
        assert_rejected(wrong_canvas, "output resolution")

        drifted_anchor = root / "drifted_anchor.json"
        write_fixture(drifted_anchor, projected_landmarks__contact_px=[83, 144])
        assert_rejected(drifted_anchor, "contact anchor drift")

        off_pixel_height = root / "off_pixel_height.json"
        write_fixture(off_pixel_height, projected_landmarks__top_px=[80, 3])
        assert_rejected(off_pixel_height, "projected pixel height drift")

        command = [sys.executable, str(ROOT / "tools/art/check_scale_contract.py"), str(drifted_anchor)]
        assert subprocess.run(command, check=False, capture_output=True).returncode == 1
        command[-1] = str(good)
        assert subprocess.run(command, check=False, capture_output=True).returncode == 0

    print("check_scale_contract tests passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
