#!/usr/bin/env python3
"""Pre-recolor rejection gate for the 3x4 player walk sheet.

This is a REJECTION GATE, NOT AN ACCEPTANCE TEST. Exit code 0 means "no
defect was detected", which is emphatically not "this sheet is good". Per
decision 003, the accept authority is the in-game capture at 160 px. This
tool exists only to kill sheets that are provably broken before anyone
spends a capture cycle on them.

Two orthogonal gates run per source row:

  boot alternation  -- do the feet actually swap which one leads?
  anchor drift      -- does the figure stay on the ground while they do?

They cover different failures and neither subsumes the other. A sheet can
alternate its feet perfectly while the whole body bobs off the baseline,
which is exactly the "reads as a shuffle at 160 px" failure. Boots verify
ALTERNATION. Anchor drift verifies GROUND CONTACT.

## Why colored boots

"Left leg" and "right leg" are semantically distinct but visually
identical, so an image generator has no image-space signal to bind the
constraint to. Round 1 asked for alternation semantically and the model
dropped it twice. Colored boots move the constraint from semantic to
chromatic: the left boot is magenta, the right boot is cyan, and the
binding becomes measurable in pixels. The sheet is generated with colored
boots, validated here, and only then recolored to leather brown.

## Why this runs pre-mirror and pre-recolor

The natural implementation order does exactly the wrong thing. The recolor
pass maps boots to brown unconditionally, so a sheet carrying the exact
round-1 defect passes straight through it and comes out the far side with
the defect intact and its only diagnostic signal deliberately destroyed.
This gate must see the colored intermediate.

Mirroring inverts the color/leg binding (a mirrored magenta left boot is
now on the right of the image), so a mirrored row cannot be validated
against the colored intermediate at all. Only the three SOURCE rows are
checked here: down, up, side.

## Usage

    tools/art/check_walk_sheet.py tools/art/out/walk_sheet.png
    tools/art/check_walk_sheet.py sheet.png --json

Exit codes:
    0  no defect detected (NOT an accept; capture at 160 px still decides)
    1  rejected, see the reported reasons
    2  the sheet could not be read or parsed into a 3x4 grid
"""

import argparse
import json
import pathlib
import sys

import numpy as np
from PIL import Image

# Source row order on the sheet, top to bottom. Diagonals are the first
# stretch beyond this; four-cardinal snapping is not authorized.
DEFAULT_ROW_NAMES = ("down", "up", "side")
EXPECTED_COLUMNS = 4

# Background flood tolerance, matched to process_assets.py's BG_TOLERANCE so
# both stages agree on what counts as background.
BG_TOLERANCE = 24

# Chromatic marker windows, in HSV degrees / unit saturation / unit value.
# Deliberately wide: the generator will not hit a pure hue, and this gate
# may only reject, so a marker we fail to find is a rejection we cannot
# justify. Round-1 art (browns, greens, skin) lives entirely in hues 0-90
# and cannot collide with either window.
MAGENTA_HUE_RANGE = (280.0, 340.0)  # left boot
CYAN_HUE_RANGE = (160.0, 200.0)  # right boot
MARKER_MIN_SATURATION = 0.35
MARKER_MIN_VALUE = 0.20

# A marker blob smaller than this fraction of the frame's figure area is
# noise (a stray recolor pixel, a JPEG-ish fringe), not a boot.
MIN_MARKER_AREA_FRACTION = 0.0008

# Stride magnitude floors, in figure-height units. A contact frame whose
# signed boot separation is under this has not committed to a stride.
#
# Calibrated against the round-1 side row (candidate 2, traced): real
# contact frames measured 0.531 and 0.535, real passing frames measured
# 0.084 and 0.094. 0.12 sits above every observed passing frame and far
# below every observed contact frame.
MIN_CONTACT_STRIDE_SIDE = 0.12

# The down/up rows have no colored-boot reference art to calibrate against
# yet, so this floor is deliberately conservative: it is set low enough to
# only catch a degenerate row (feet effectively welded together), not to
# adjudicate stride quality. Raise it once colored down/up art exists.
MIN_CONTACT_STRIDE_FRONTAL = 0.06

# Anchor drift ceiling: max standard deviation of the per-frame sole line,
# in cell-height units. 0.05 of a 160 px shipping cell is 8 px of bob.
MAX_ANCHOR_STDEV = 0.05

# Fraction of the figure's height, measured up from its lowest pixel, that
# counts as the boot band when locating soles.
BOOT_BAND_FRACTION = 0.12

# Contact frames in a 4-frame cycle: 0 and 2 are the two contacts, 1 and 3
# are the passing poses between them.
CONTACT_FRAMES = (0, 2)


class SheetError(Exception):
    """The sheet could not be read or parsed into a 3x4 grid."""


def _contiguous_bands(flags):
    """Return (start, end) inclusive index pairs for each run of True."""
    bands = []
    start = None
    for index, value in enumerate(flags):
        if value and start is None:
            start = index
        elif not value and start is not None:
            bands.append((start, index - 1))
            start = None
    if start is not None:
        bands.append((start, len(flags) - 1))
    return bands


def foreground_mask(rgb):
    """True where a pixel differs from the sampled corner background.

    The sheet prompts ask for one flat background color and margin around
    every figure, same as the rest of tools/art/, so the corner is always
    background.
    """
    background = rgb[0, 0]
    return np.abs(rgb - background).max(axis=2) > BG_TOLERANCE


def split_grid(mask, row_names):
    """Split a sheet mask into frames by background gutters.

    Deliberately NOT a naive height/3 by width/4 split. The generator does
    not center figures in exact thirds: on the round-1 candidates an even
    split sliced through the figures and pulled the side row's heads up
    into the up row's cell, which silently corrupts every sole measurement
    taken from it. Detecting the empty gutters between bands finds the real
    rows and columns instead of assuming them.
    """
    row_bands = _contiguous_bands(mask.any(axis=1))
    if len(row_bands) != len(row_names):
        raise SheetError(
            f"expected {len(row_names)} content rows separated by background "
            f"gutters, found {len(row_bands)}; this is not a "
            f"{len(row_names)}x{EXPECTED_COLUMNS} sheet"
        )

    grid = []
    for name, (top, bottom) in zip(row_names, row_bands):
        strip = mask[top : bottom + 1]
        column_bands = _contiguous_bands(strip.any(axis=0))
        if len(column_bands) != EXPECTED_COLUMNS:
            raise SheetError(
                f"row '{name}': expected {EXPECTED_COLUMNS} frames separated "
                f"by background gutters, found {len(column_bands)}"
            )
        grid.append((name, (top, bottom), column_bands))
    return grid


def marker_masks(hsv, foreground):
    """Return (magenta, cyan) boolean masks for the two boot markers."""
    hue = hsv[:, :, 0] * (360.0 / 255.0)
    saturation = hsv[:, :, 1] / 255.0
    value = hsv[:, :, 2] / 255.0
    usable = foreground & (saturation >= MARKER_MIN_SATURATION) & (value >= MARKER_MIN_VALUE)

    def window(hue_range):
        low, high = hue_range
        return usable & (hue >= low) & (hue <= high)

    return window(MAGENTA_HUE_RANGE), window(CYAN_HUE_RANGE)


def _centroid(mask):
    ys, xs = np.nonzero(mask)
    if len(ys) == 0:
        return None
    return float(xs.mean()), float(ys.mean()), int(len(ys))


def measure_frame(frame_fg, frame_magenta, frame_cyan):
    """Measure one source frame's boot centroids and sole line.

    All positions are normalized by the figure's own pixel height, so the
    numbers are comparable across frames whose figures are drawn at
    slightly different scales and across raw sheets of any resolution.
    """
    ys, xs = np.nonzero(frame_fg)
    if len(ys) == 0:
        return None

    top, bottom = int(ys.min()), int(ys.max())
    figure_height = bottom - top + 1
    figure_area = int(frame_fg.sum())
    min_area = max(1, int(MIN_MARKER_AREA_FRACTION * figure_area))

    measurement = {
        "figure_height_px": figure_height,
        "sole_y_px": bottom,
        "magenta": None,
        "cyan": None,
    }

    for key, mask in (("magenta", frame_magenta), ("cyan", frame_cyan)):
        centroid = _centroid(mask)
        if centroid is None or centroid[2] < min_area:
            continue
        cx, cy, area = centroid
        measurement[key] = {
            "x": (cx - xs.mean()) / figure_height,
            "y": (cy - top) / figure_height,
            "area_px": area,
        }

    return measurement


def stride_axis(row_name):
    """Which image axis a leading leg moves along, for this facing.

    Side rows are profile views: the stride runs along screen x, so the
    leading boot is the one further along x.

    Down and up rows are frontal/rear views: left and right boots are
    always separated in x regardless of pose, so x carries no stride
    signal at all. The stride shows in y, because the leading foot is
    nearer the camera (down) or further from it (up) and lands lower or
    higher on screen accordingly.
    """
    return "x" if row_name == "side" else "y"


def signed_separations(frames, axis):
    """Signed magenta-minus-cyan separation per frame, in figure heights.

    The sign encodes which boot leads. Its absolute convention does not
    matter: the gate tests whether the sign REVERSES between the two
    contact frames, which is invariant to the convention chosen here.
    """
    separations = []
    for frame in frames:
        if frame is None or frame["magenta"] is None or frame["cyan"] is None:
            separations.append(None)
            continue
        separations.append(frame["magenta"][axis] - frame["cyan"][axis])
    return separations


def check_boot_alternation(row_name, frames, rejections):
    """Signed leading-leg reversal via the magenta and cyan boot centroids."""
    missing = []
    for index, frame in enumerate(frames):
        if frame is None:
            missing.append(f"frame {index}: no figure found")
            continue
        for marker in ("magenta", "cyan"):
            if frame[marker] is None:
                missing.append(f"frame {index}: no {marker} boot found")

    if missing:
        # Cannot measure the binding, therefore cannot clear the sheet.
        # This gate may only reject, so an unmeasurable sheet is a
        # rejection, never a pass.
        rejections.append(
            f"row '{row_name}': boot markers missing, cannot validate leading-leg "
            f"reversal ({'; '.join(missing)}). The sheet must be generated with a "
            f"magenta left boot and a cyan right boot, and validated BEFORE the "
            f"recolor pass."
        )
        return {"axis": None, "separations": [], "verdict": "unmeasurable"}

    axis = stride_axis(row_name)
    separations = signed_separations(frames, axis)
    floor = MIN_CONTACT_STRIDE_SIDE if row_name == "side" else MIN_CONTACT_STRIDE_FRONTAL

    first, second = (separations[i] for i in CONTACT_FRAMES)

    if np.sign(first) == np.sign(second):
        rejections.append(
            f"row '{row_name}': contact frames {CONTACT_FRAMES[0]} and "
            f"{CONTACT_FRAMES[1]} do not reverse the leading leg (signed "
            f"{axis} separation {first:+.3f} and {second:+.3f}, same sign). "
            f"The same boot leads in both contacts, so this reads as one pose "
            f"repeated, not an alternating walk."
        )

    for index in CONTACT_FRAMES:
        magnitude = abs(separations[index])
        if magnitude < floor:
            rejections.append(
                f"row '{row_name}': contact frame {index} has no committed "
                f"stride (|{axis} separation| {magnitude:.3f} < {floor:.3f} "
                f"figure heights)."
            )

    signs = {np.sign(s) for s in separations if abs(s) >= floor}
    if len(signs) == 1:
        rejections.append(
            f"row '{row_name}': the same boot leads in every frame with a "
            f"measurable stride (signed {axis} separations "
            f"{[round(s, 3) for s in separations]}). The feet never alternate."
        )

    return {
        "axis": axis,
        "separations": [round(s, 4) for s in separations],
        "contact_reversed": bool(np.sign(first) != np.sign(second)),
        "verdict": "measured",
    }


def check_anchor_drift(row_name, frames, row_span, column_bands, image_shape, rejections):
    """Ground-contact gate: the sole line must hold still across frames.

    Orthogonal to the boot check. Feet can alternate correctly while the
    whole figure bobs off the baseline, and that bob is what reads as a
    shuffle at 160 px.

    Measured per source frame, pre-mirror and pre-recolor, per the player
    and world contract. This runs on the RAW sheet, where figures float
    inside oversized cells with margin, so the meaningful quantity is the
    VARIATION of the sole line across a row, not its absolute position.
    Absolute alignment to row 159 is established later, by the
    crop-to-content step in process_assets.py; a row that drifts here will
    drift there too, because the crop is driven by the figure's own bbox.

    The drift is normalized by the row's content-band height, which is the
    correct proxy for the shipping cell: process_assets.py crops to content
    and resizes, so that band height is exactly what becomes the 160 px
    cell. That makes the ratio resolution-independent and comparable to the
    contract's 0.05 ceiling.
    """
    present = [f for f in frames if f is not None]
    if len(present) != len(frames):
        return {"verdict": "unmeasurable"}

    row_top, row_bottom = row_span
    band_height = row_bottom - row_top + 1
    soles = np.array([f["sole_y_px"] for f in present], dtype=float)
    stdev_px = float(soles.std())
    stdev_cells = stdev_px / band_height

    if stdev_cells > MAX_ANCHOR_STDEV:
        rejections.append(
            f"row '{row_name}': anchor drift {stdev_cells:.4f} cell heights "
            f"({stdev_px:.2f} px raw, {stdev_cells * 160:.2f} px at the 160 px "
            f"shipping cell) exceeds the {MAX_ANCHOR_STDEV} ceiling. The figure "
            f"bobs off the ground line instead of walking along it."
        )

    # Clipping means the figure runs off the sheet, so its content is cut
    # rather than resting on a ground line. Note this cannot be tested
    # against the row band: the band is derived FROM the content, so the
    # lowest figure pixel always sits at its bottom edge by construction.
    # The image edge is the real boundary. A figure clipped by an interior
    # cell boundary instead shows up as a missing gutter, which split_grid
    # already rejects.
    image_height, image_width = image_shape
    edges = []
    if row_top == 0:
        edges.append("top of the sheet")
    if row_bottom == image_height - 1:
        edges.append("bottom of the sheet")
    for index, (left, right) in enumerate(column_bands):
        if left == 0:
            edges.append(f"left of the sheet (frame {index})")
        if right == image_width - 1:
            edges.append(f"right of the sheet (frame {index})")

    if edges:
        rejections.append(
            f"row '{row_name}': figure content touches the {', '.join(edges)}, so "
            f"it is clipped or clamped rather than resting on the ground line. "
            f"Clipped frames are a regeneration trigger, not accepted variance."
        )

    return {
        "verdict": "measured",
        "sole_y_px": [int(s) for s in soles],
        "stdev_cell_heights": round(stdev_cells, 4),
        "stdev_px_at_160": round(stdev_cells * 160, 2),
        "clipped_edges": edges,
    }


def check_sheet(path, row_names=DEFAULT_ROW_NAMES):
    """Run every gate against one pre-recolor sheet.

    Returns (rejections, report). An empty rejections list means no defect
    was detected. It does not mean the sheet is good.
    """
    try:
        image = Image.open(path)
    except (OSError, ValueError) as exc:
        raise SheetError(f"could not read {path}: {exc}") from exc

    rgb_image = image.convert("RGB")
    rgb = np.asarray(rgb_image).astype(np.int16)
    hsv = np.asarray(rgb_image.convert("HSV")).astype(np.float64)

    foreground = foreground_mask(rgb)
    magenta, cyan = marker_masks(hsv, foreground)
    grid = split_grid(foreground, row_names)

    rejections = []
    report = {"sheet": str(path), "size": list(rgb_image.size), "rows": {}}

    for name, (top, bottom), column_bands in grid:
        frames = []
        for left, right in column_bands:
            frames.append(
                measure_frame(
                    foreground[top : bottom + 1, left : right + 1],
                    magenta[top : bottom + 1, left : right + 1],
                    cyan[top : bottom + 1, left : right + 1],
                )
            )
        report["rows"][name] = {
            "band": [top, bottom],
            "boot_alternation": check_boot_alternation(name, frames, rejections),
            "anchor_drift": check_anchor_drift(
                name, frames, (top, bottom), column_bands, foreground.shape, rejections
            ),
        }

    report["rejections"] = rejections
    report["rejected"] = bool(rejections)
    return rejections, report


def main(argv=None):
    parser = argparse.ArgumentParser(
        description=(
            "Reject a pre-recolor 3x4 walk sheet that fails leading-leg "
            "reversal or anchor drift. This gate can only reject; it never "
            "accepts. The in-game capture at 160 px is the accept authority."
        )
    )
    parser.add_argument("sheet", type=pathlib.Path, help="pre-recolor sheet PNG")
    parser.add_argument(
        "--rows",
        default=",".join(DEFAULT_ROW_NAMES),
        help="comma-separated source row names, top to bottom "
        f"(default: {','.join(DEFAULT_ROW_NAMES)})",
    )
    parser.add_argument("--json", action="store_true", help="emit the full report as JSON")
    args = parser.parse_args(argv)

    row_names = tuple(name.strip() for name in args.rows.split(",") if name.strip())

    try:
        rejections, report = check_sheet(args.sheet, row_names)
    except SheetError as exc:
        if args.json:
            print(json.dumps({"error": str(exc), "rejected": True}, indent=2))
        else:
            print(f"REJECT {args.sheet}\n  unreadable: {exc}", file=sys.stderr)
        return 2

    if args.json:
        print(json.dumps(report, indent=2))
    elif rejections:
        print(f"REJECT {args.sheet}")
        for reason in rejections:
            print(f"  - {reason}")
        print("\nRegenerate the sheet. Do not recolor it.")
    else:
        print(f"NO DEFECT DETECTED {args.sheet}")
        print(
            "This is NOT an acceptance. It means this gate found nothing "
            "provably broken.\nCapture the sheet in game at 160 px; that is "
            "what decides whether it ships."
        )

    return 1 if rejections else 0


if __name__ == "__main__":
    sys.exit(main())
