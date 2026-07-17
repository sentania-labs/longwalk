#!/usr/bin/env python3
import pathlib
import sys
import tempfile

from PIL import Image, ImageDraw

ROOT = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools/art"))

from check_walk_sheet import SheetError, check_sheet


def fixture(path: pathlib.Path, drift: int = 0) -> None:
    image = Image.new("RGBA", (6 * 32, 8 * 32), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    for row in range(8):
        for col in range(6):
            bottom = row * 32 + 29 - (drift if col % 2 else 0)
            draw.rectangle((col * 32 + 10, bottom - 19, col * 32 + 21, bottom), fill=(80, 90, 60, 255))
    image.save(path)


def main() -> int:
    with tempfile.TemporaryDirectory() as temp:
        root = pathlib.Path(temp)
        good = root / "good.png"
        fixture(good)
        assert check_sheet(good, 32)[0] == []
        drift = root / "drift.png"
        fixture(drift, 8)
        assert any("anchor drift" in item for item in check_sheet(drift, 32)[0])
        wrong = root / "wrong.png"
        Image.new("RGBA", (32, 32)).save(wrong)
        try:
            check_sheet(wrong, 32)
            raise AssertionError("wrong grid accepted")
        except SheetError:
            pass
    print("check_walk_sheet tests passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
