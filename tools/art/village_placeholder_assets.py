#!/usr/bin/env python3
"""Provisional inn-green district assets + manifest (decision 009).

This is a PROVISIONAL STAND-IN for codex-worker's asset-production deliverable
(clean-sliced spike objects + image-to-image generated occluded/net-new objects
+ the per-object provenance manifest). It exists so the render-integration slice
can PROVE the whole rig end-to-end this turn: export-safety, manifest-driven
loading, the free-cam, landmark registration, and the isolated-packaged capture
gate. The orchestrator overwrites res://assets/village/ with codex's real assets
and re-runs the same gate; nothing here is meant to ship.

Every object is a real RGBA PNG with nonzero dimensions written to
assets/village/<png>, plus assets/village/manifest.json in codex's runtime
schema. The four occluded/net-new kit-ids (inn, cottage_rear, smithy_cluster,
crown_foliage) are emitted as flat-magenta generated-pending placeholders; the
rest use distinct muted fills standing in for the sliced spike pixels. The
export gate's non-placeholder assertion targets the ENGINE default (a missing
asset resolving to null / a blank capture), NOT these committed magenta PNGs,
which are legitimate nonzero textures that draw.

No RNG, no time: fully deterministic (constitution). Run from the repo root:
    python3 tools/art/village_placeholder_assets.py
"""

import json
import os

from PIL import Image, ImageDraw

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT_DIR = os.path.join(REPO_ROOT, "assets", "village")

MAGENTA = (255, 0, 255, 255)

# id -> (native_w, native_h, anchor_x, anchor_y, kind, provenance, rgb)
OBJECTS = {
    "ground_grass": (128, 64, 64, 32, "ground", "slice", (92, 138, 74)),
    "ground_lane": (128, 64, 64, 32, "ground", "slice", (179, 158, 115)),
    "cottage_front": (256, 300, 128, 290, "cottage", "slice", (176, 141, 99)),
    "tree_large": (220, 360, 110, 350, "tree", "slice", (74, 112, 66)),
    "bush_a": (120, 100, 60, 95, "bush", "slice", (86, 120, 70)),
    "bush_b": (120, 100, 60, 95, "bush", "slice", (96, 132, 78)),
    "fence_section": (140, 90, 70, 85, "fence", "slice", (150, 116, 78)),
    "sign_post": (60, 120, 30, 115, "sign", "slice", (140, 104, 66)),
    "rock_a": (100, 70, 50, 65, "rock", "slice", (128, 128, 132)),
    "rock_b": (90, 60, 45, 55, "rock", "slice", (112, 112, 118)),
    "flower_cluster_a": (110, 70, 55, 65, "flower", "slice", (196, 154, 178)),
    "flower_cluster_b": (110, 70, 55, 65, "flower", "slice", (176, 176, 96)),
    # Occluded / net-new: flat-magenta generated-pending placeholders.
    "inn": (384, 420, 192, 410, "building_anchor", "generated-pending", None),
    "cottage_rear": (256, 300, 128, 290, "cottage", "generated-pending", None),
    "smithy_cluster": (320, 280, 160, 270, "building", "generated-pending", None),
    "crown_foliage": (300, 220, 150, 210, "crown", "generated-pending", None),
}


def _draw(kit_id, w, h, anchor_x, anchor_y, provenance, rgb):
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    if provenance == "generated-pending":
        # Flat magenta body: unmistakably a placeholder to the eye, a real
        # nonzero texture to ResourceLoader.
        draw.rectangle([2, 2, w - 3, h - 3], fill=MAGENTA)
    else:
        fill = (rgb[0], rgb[1], rgb[2], 255)
        draw.rectangle([2, 2, w - 3, h - 3], fill=fill)
        # A darker base band so the anchored ground-contact edge reads.
        draw.rectangle([2, h - max(6, h // 12), w - 3, h - 3],
                       fill=(rgb[0] // 2, rgb[1] // 2, rgb[2] // 2, 255))
    # Anchor crosshair (a visible dot at the ground-contact pixel).
    ax, ay = anchor_x, anchor_y
    draw.line([ax - 5, ay, ax + 5, ay], fill=(0, 0, 0, 255), width=2)
    draw.line([ax, ay - 5, ax, ay + 5], fill=(0, 0, 0, 255), width=2)
    return img


# Continuous-ground stand-ins (decision 010). These are NOT manifest placements;
# they are the ground paint the shader samples plus the contact-shadow decal.
# Provisional flat fills / a mid-grey (zero-displacement) warp / a soft ellipse,
# committed at the contract paths so the scene loads and the suite runs.
# Integration swaps in codex's real periodic swatches + fixed-seed FastNoiseLite
# warp bake and re-runs the export gate. Deterministic, no RNG, no time.
GROUND_TILE_PX = 512
GRASS_FILL = (92, 138, 74, 255)
DIRT_FILL = (150, 120, 86, 255)
# Flat mid-grey = (0.5, 0.5) in the shader's warp decode -> zero displacement, so
# the placeholder lane edges stay straight rather than wandering randomly.
WARP_FILL = (128, 128, 128, 255)
SHADOW_PX = (256, 128)


def _write_ground_assets():
    Image.new("RGBA", (GROUND_TILE_PX, GROUND_TILE_PX), GRASS_FILL).save(
        os.path.join(OUT_DIR, "ground_grass_tile.png"))
    Image.new("RGBA", (GROUND_TILE_PX, GROUND_TILE_PX), DIRT_FILL).save(
        os.path.join(OUT_DIR, "ground_dirt_tile.png"))
    Image.new("RGBA", (GROUND_TILE_PX, GROUND_TILE_PX), WARP_FILL).save(
        os.path.join(OUT_DIR, "ground_warp.png"))

    # Soft radial-falloff ellipse. White body (the render tints it black via
    # modulate); the ALPHA channel carries the soft edge, alpha 255 at center
    # fading to 0 at the rim.
    w, h = SHADOW_PX
    shadow = Image.new("RGBA", (w, h), (255, 255, 255, 0))
    px = shadow.load()
    cx, cy = (w - 1) / 2.0, (h - 1) / 2.0
    rx, ry = w / 2.0, h / 2.0
    for y in range(h):
        for x in range(w):
            nx = (x - cx) / rx
            ny = (y - cy) / ry
            d = (nx * nx + ny * ny) ** 0.5
            a = max(0.0, 1.0 - d)
            px[x, y] = (255, 255, 255, int(255 * (a ** 1.5)))
    shadow.save(os.path.join(OUT_DIR, "shadow_decal.png"))


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    _write_ground_assets()
    objects = []
    for kit_id, (w, h, ax, ay, kind, provenance, rgb) in OBJECTS.items():
        png = "%s.png" % kit_id
        img = _draw(kit_id, w, h, ax, ay, provenance, rgb)
        img.save(os.path.join(OUT_DIR, png))
        objects.append({
            "id": kit_id,
            "png": png,
            "kind": kind,
            "anchor_px": [ax, ay],
            "native_px": [w, h],
            "provenance": provenance,
        })
    manifest = {"district": "inn-green", "objects": objects}
    with open(os.path.join(OUT_DIR, "manifest.json"), "w") as f:
        json.dump(manifest, f, indent=2)
        f.write("\n")
    print("wrote %d assets + manifest.json to %s" % (len(objects), OUT_DIR))


if __name__ == "__main__":
    main()
