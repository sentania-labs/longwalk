#!/usr/bin/env python3
import json
import pathlib
import sys
import tempfile

from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools/art"))

from build_player_walk import FACING_IDS, build


def main() -> int:
    with tempfile.TemporaryDirectory() as temp:
        root = pathlib.Path(temp)
        frames = {}
        for row, facing in enumerate(FACING_IDS):
            for col in range(6):
                frame_id = f"{facing}_{col}"
                path = root / f"{frame_id}.png"
                Image.new("RGBA", (16, 16), (row * 20, col * 20, 80, 255)).save(path)
                frames[frame_id] = {"source": path.name, "anchor": [8, 15]}
        manifest = root / "walk.json"
        manifest.write_text(json.dumps({
            "facing_order": list(FACING_IDS), "frames_per_facing": 6,
            "cell_size": 16, "mirroring": {"enabled": False, "declared_before_generation": True},
            "frames": frames,
        }), encoding="utf-8")
        atlas = build(manifest, root / "atlas.png")
        assert atlas.size == (96, 128)
        assert atlas.getpixel((8, 7 * 16 + 8))[0] == 140
        bad = json.loads(manifest.read_text())
        bad["facing_order"][0] = "W"
        manifest.write_text(json.dumps(bad), encoding="utf-8")
        try:
            build(manifest, root / "bad.png")
            raise AssertionError("wrong facing order was accepted")
        except ValueError:
            pass
    print("build_player_walk tests passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
