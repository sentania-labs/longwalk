#!/usr/bin/env python3
"""Synthesize colored-boot walk sheets for check_walk_sheet.py's tests.

The geometry here is TRACED FROM REAL DEFECTIVE ART, not invented. The
side-row boot centroids below were measured off
tools/art/out/player_walk_sheet_candidate_2.png, the round-1 spike sheet
that codex-worker rejected by eye and documented in
docs/proposals/codex-spike-walk-sheet.md.

Round-1 art predates the colored-boot ruling and has plain brown boots, so
it cannot exercise the chromatic reversal check directly (see
docs/art/walk-sheet-validation.md). Tracing its measured geometry into
colored-boot fixtures is how that check gets calibrated against the real
defect instead of against a guess.

Measured from candidate 2's side row, in figure-height units, as
(near_boot_centroid, far_boot_centroid):

    frame 0  contact  0.090, 0.621   separation 0.531
    frame 1  passing  0.069, 0.153   separation 0.084
    frame 2  contact  0.092, 0.627   separation 0.535
    frame 3  passing  0.065, 0.159   separation 0.094

Frames 0 and 2 are the defect: near-identical contact poses where the same
leg leads both times. A correct cycle keeps that geometry but swaps which
boot color sits at which end on frame 2.
"""

import numpy as np
from PIL import Image

BACKGROUND = (247, 243, 233)  # the cream the art pipeline generates on
BODY = (92, 110, 72)  # tunic green, well outside both marker hue windows
MAGENTA_BOOT = (222, 30, 190)
CYAN_BOOT = (30, 200, 214)

# Traced from candidate 2's side row, in figure-height units.
TRACED_SIDE_CONTACT = (0.090, 0.621)
TRACED_SIDE_PASSING = (0.069, 0.153)

FIGURE_HEIGHT = 300
BOOT_SIZE = 26
CELL = 362
GUTTER = 40


def _blank_sheet(rows=3, columns=4):
    width = columns * CELL
    height = rows * CELL
    return np.full((height, width, 3), BACKGROUND, dtype=np.uint8)


def _draw_frame(sheet, row, column, boots, sole_offset=0):
    """Draw one figure: a torso block plus two colored boots.

    boots is a sequence of (color, along_axis_position, axis) where
    along_axis_position is in figure-height units and axis is 'x' or 'y'.
    """
    cell_top = row * CELL
    cell_left = column * CELL
    # Ground the figure so its lowest pixel sits sole_offset px above the
    # nominal sole line, leaving margin below so bands stay separable.
    sole_y = cell_top + CELL - GUTTER - sole_offset
    center_x = cell_left + CELL // 2
    top_y = sole_y - FIGURE_HEIGHT

    # Torso: a plain block. Its only job is to give the frame a figure
    # bbox and a foreground area for the marker-noise threshold.
    torso_half = 34
    hip_y = sole_y - BOOT_SIZE - 60
    sheet[top_y:hip_y, center_x - torso_half : center_x + torso_half] = BODY

    for color, position, axis in boots:
        if axis == "x":
            bx = int(center_x + (position - 0.35) * FIGURE_HEIGHT)
            by = sole_y - BOOT_SIZE
        else:
            bx = center_x - BOOT_SIZE // 2
            by = int(sole_y - BOOT_SIZE - position * FIGURE_HEIGHT)
        # A leg joining the hip to this boot. Without it the boot is a
        # disconnected blob and the sheet reads as more than four columns
        # per row, which is not what real art looks like.
        leg_left, leg_right = sorted((center_x, bx + BOOT_SIZE // 2))
        sheet[hip_y:by, leg_left - 8 : leg_right + 8] = BODY
        sheet[by : by + BOOT_SIZE, bx : bx + BOOT_SIZE] = color


def _side_row_boots(near, far, reversed_lead):
    """Bind boot colors to the two traced positions.

    reversed_lead swaps which color takes the leading (far) position, which
    is exactly the difference between a correct cycle and the round-1
    defect.
    """
    if reversed_lead:
        return [(CYAN_BOOT, near, "x"), (MAGENTA_BOOT, far, "x")]
    return [(MAGENTA_BOOT, near, "x"), (CYAN_BOOT, far, "x")]


def build_sheet(side_defect=False, frontal_defect=False, anchor_drift_px=0, clip_row=None):
    """Build a colored-boot sheet.

    side_defect     reproduce the traced round-1 defect on the side row
                    (the same boot leads both contact frames)
    frontal_defect  same failure on the down and up rows
    anchor_drift_px bob the side row's sole line by this many pixels
    clip_row        row index whose frames run off the bottom of the sheet
    """
    sheet = _blank_sheet()
    near_contact, far_contact = TRACED_SIDE_CONTACT
    near_pass, far_pass = TRACED_SIDE_PASSING

    for row, name in enumerate(("down", "up", "side")):
        for column in range(4):
            is_second_contact = column == 2
            is_passing = column % 2 == 1
            if name == "side":
                near, far = (
                    (near_pass, far_pass) if is_passing else (near_contact, far_contact)
                )
                # On a correct cycle the second contact reverses the lead.
                reversed_lead = is_second_contact and not side_defect
                if is_passing:
                    reversed_lead = column == 3 and not side_defect
                boots = _side_row_boots(near, far, reversed_lead)
            else:
                # Frontal rows: the stride reads along y. Lead magnitudes
                # are modest compared to a profile stride.
                lead = 0.10 if not is_passing else 0.02
                sign = 1 if (not is_second_contact or frontal_defect) else -1
                boots = [
                    (MAGENTA_BOOT, 0.12 + sign * lead, "y"),
                    (CYAN_BOOT, 0.12 - sign * lead, "y"),
                ]

            offset = 0
            if name == "side" and anchor_drift_px:
                offset = anchor_drift_px if column % 2 else 0
            if clip_row == row:
                offset = -(GUTTER + 4)
            _draw_frame(sheet, row, column, boots, sole_offset=offset)

    return Image.fromarray(sheet, mode="RGB")


def build_brown_boot_sheet():
    """A sheet with no chromatic markers at all, like the round-1 art."""
    sheet = _blank_sheet()
    brown = (94, 64, 42)
    for row in range(3):
        for column in range(4):
            _draw_frame(
                sheet,
                row,
                column,
                [(brown, 0.090, "x"), (brown, 0.621, "x")],
            )
    return Image.fromarray(sheet, mode="RGB")


def write_fixture(image, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path)
    return path
