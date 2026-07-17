#!/usr/bin/env python3
"""Tests for tools/art/check_walk_sheet.py, the pre-recolor rejection gate.

Run directly (no pytest dependency, matching the repo's zero-extra-deps
posture for tools/art/):

    python3 test/art/test_check_walk_sheet.py

The load-bearing tests are the ones that PROVE THE GATE CAN FAIL. A gate
only ever observed passing is a gate that has not been tested: it is
indistinguishable from `return 0`. Every rejection path below is asserted
against a fixture built to trip exactly that path, and the corrected
control asserts the gate is not simply rejecting everything.
"""

import pathlib
import sys
import tempfile

REPO_ROOT = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "tools" / "art"))
sys.path.insert(0, str(REPO_ROOT / "test" / "art"))

import numpy as np  # noqa: E402
from PIL import Image  # noqa: E402

import walk_sheet_fixtures as fixtures  # noqa: E402
from check_walk_sheet import (  # noqa: E402
    SheetError,
    check_boot_alternation,
    check_sheet,
    foreground_mask,
    main as cli_main,
    marker_masks,
    measure_frame,
    split_grid,
)

FAILURES = []


def check(condition, label, detail=""):
    if condition:
        print(f"  ok    {label}")
    else:
        print(f"  FAIL  {label}  {detail}")
        FAILURES.append(label)


def _run(image, tmpdir, name):
    path = fixtures.write_fixture(image, pathlib.Path(tmpdir) / name)
    return check_sheet(path)


def test_corrected_sheet_is_not_rejected(tmpdir):
    print("\ncorrected sheet (traced geometry, lead reversed on contact 2)")
    rejections, report = _run(fixtures.build_sheet(), tmpdir, "good.png")
    check(
        not rejections,
        "a correct cycle is not rejected",
        f"got: {rejections}",
    )
    side = report["rows"]["side"]["boot_alternation"]
    check(
        side["contact_reversed"],
        "side row contact frames reverse the lead",
        f"separations={side['separations']}",
    )


def test_traced_round1_defect_is_rejected(tmpdir):
    print("\ntraced round-1 side-row defect (same boot leads both contacts)")
    rejections, report = _run(
        fixtures.build_sheet(side_defect=True), tmpdir, "side_defect.png"
    )
    side = report["rows"]["side"]["boot_alternation"]
    check(
        any("do not reverse the leading leg" in r for r in rejections),
        "the traced round-1 defect is rejected",
        f"got: {rejections}",
    )
    check(
        not side["contact_reversed"],
        "side contact frames are reported as non-reversing",
        f"separations={side['separations']}",
    )
    # The traced contacts must land near the real measured 0.531/0.535.
    first, second = side["separations"][0], side["separations"][2]
    check(
        abs(abs(first) - 0.531) < 0.06 and abs(abs(second) - 0.535) < 0.06,
        "traced separations reproduce the measured round-1 geometry",
        f"got {first:+.3f} and {second:+.3f}, expected magnitudes ~0.531/0.535",
    )


def test_degenerate_stride_is_rejected(tmpdir):
    print("\ndegenerate side stride (lead reverses, but the feet barely part)")
    rejections, report = _run(
        fixtures.build_sheet(degenerate_stride=True), tmpdir, "degenerate.png"
    )
    side = report["rows"]["side"]["boot_alternation"]
    check(
        any("no committed stride" in r for r in rejections),
        "a contact frame under the 0.12 stride floor is rejected",
        f"got: {rejections}",
    )
    # The lead DOES reverse here, so the reversal check cannot be what
    # rejects this. Asserting that pins the rejection on the floor alone.
    check(
        side["contact_reversed"],
        "the reversal check passes, so only the stride floor rejects this",
        f"separations={side['separations']}",
    )


def test_frontal_defect_is_rejected(tmpdir):
    print("\nfrontal (down/up) rows: same leg leads every frame")
    rejections, _ = _run(
        fixtures.build_sheet(frontal_defect=True), tmpdir, "frontal_defect.png"
    )
    check(
        any("row 'down'" in r for r in rejections),
        "the down row defect is rejected",
        f"got: {rejections}",
    )
    check(
        any("row 'up'" in r for r in rejections),
        "the up row defect is rejected",
        f"got: {rejections}",
    )


def test_missing_markers_are_rejected(tmpdir):
    print("\nbrown-boot sheet (no chromatic markers, like round-1 art)")
    rejections, _ = _run(fixtures.build_brown_boot_sheet(), tmpdir, "brown.png")
    check(
        any("boot markers missing" in r for r in rejections),
        "an unmeasurable sheet is rejected, never passed",
        f"got: {rejections}",
    )


def test_anchor_drift_is_rejected(tmpdir):
    print("\nanchor drift: feet alternate correctly but the figure bobs")
    # 0.05 of a 362 px band is ~18 px. A 44 px alternating bob gives a
    # stdev of 22 px = 0.061 cell heights, over the ceiling.
    rejections, report = _run(
        fixtures.build_sheet(anchor_drift_px=44), tmpdir, "drift.png"
    )
    drift = report["rows"]["side"]["anchor_drift"]
    check(
        any("anchor drift" in r for r in rejections),
        "a bobbing figure is rejected even though its feet alternate",
        f"got: {rejections}",
    )
    check(
        drift["stdev_cell_heights"] > 0.05,
        "measured drift exceeds the 0.05 ceiling",
        f"got {drift['stdev_cell_heights']}",
    )
    check(
        report["rows"]["side"]["boot_alternation"]["contact_reversed"],
        "the boot check still passes, proving the two gates are orthogonal",
    )


def test_anchor_drift_within_tolerance_is_not_rejected(tmpdir):
    print("\nanchor drift within tolerance")
    rejections, report = _run(fixtures.build_sheet(anchor_drift_px=8), tmpdir, "ok_drift.png")
    drift = report["rows"]["side"]["anchor_drift"]
    check(
        not any("anchor drift" in r for r in rejections),
        "a small bob is not rejected",
        f"got: {rejections} drift={drift}",
    )


def test_clipped_figure_is_rejected(tmpdir):
    print("\nclipped figure running off the sheet edge")
    rejections, _ = _run(fixtures.build_sheet(clip_row=2), tmpdir, "clipped.png")
    check(
        any("clipped or clamped" in r for r in rejections),
        "a figure clipped by the sheet edge is rejected",
        f"got: {rejections}",
    )


def test_malformed_grid_is_rejected(tmpdir):
    print("\nmalformed grid")
    image = fixtures.build_sheet().crop((0, 0, 362 * 4, 362 * 2))
    path = fixtures.write_fixture(image, pathlib.Path(tmpdir) / "two_rows.png")
    try:
        check_sheet(path)
        check(False, "a 2-row sheet raises SheetError")
    except SheetError as exc:
        check("found 2" in str(exc), "a 2-row sheet raises SheetError", str(exc))


def test_mirrored_row_cannot_earn_a_verdict(tmpdir):
    print("\nmirrored side row (decision 003: only source rows are checked)")
    image = fixtures.build_mirrored_side_row_sheet()
    path = fixtures.write_fixture(image, pathlib.Path(tmpdir) / "mirrored_side.png")

    # First prove the fixture is the dangerous case and not merely junk:
    # run the gate's own checks against it as a one-row 'side' sheet and
    # watch every one of them read clean. That is exactly why the layout
    # cannot be an option. If this row could be rejected on its merits,
    # the fixed layout would not be load-bearing.
    rgb_image = Image.open(path).convert("RGB")
    rgb = np.asarray(rgb_image).astype(np.int16)
    hsv = np.asarray(rgb_image.convert("HSV")).astype(np.float64)
    foreground = foreground_mask(rgb)
    magenta, cyan = marker_masks(hsv, foreground)
    (_, (top, bottom), column_bands), = split_grid(foreground, ("side",))
    frames = [
        measure_frame(
            foreground[top : bottom + 1, left : right + 1],
            magenta[top : bottom + 1, left : right + 1],
            cyan[top : bottom + 1, left : right + 1],
        )
        for left, right in column_bands
    ]
    leaked = []
    alternation = check_boot_alternation("side", frames, leaked)
    check(
        not leaked and alternation["contact_reversed"],
        "the mirrored row reads clean on merit, so only the layout can stop it",
        f"got: {leaked}",
    )

    # The actual gate must therefore refuse to parse it at all.
    try:
        check_sheet(path)
        check(False, "a mirrored single row raises SheetError instead of a verdict")
    except SheetError as exc:
        check(
            "found 1" in str(exc),
            "a mirrored single row raises SheetError instead of a verdict",
            str(exc),
        )

    # And no CLI override may reintroduce the hole.
    try:
        cli_main([str(path), "--rows", "side"])
        check(False, "the CLI has no --rows override to aim at a mirrored row")
    except SystemExit as exc:
        check(
            exc.code == 2,
            "the CLI has no --rows override to aim at a mirrored row",
            f"exit {exc.code}",
        )


def test_round1_candidates_are_rejected():
    print("\nreal round-1 candidate sheets")
    for n in (1, 2):
        path = REPO_ROOT / "tools" / "art" / "out" / f"player_walk_sheet_candidate_{n}.png"
        if not path.exists():
            print(f"  skip  candidate {n} not in tree")
            continue
        rejections, _ = check_sheet(path)
        check(
            bool(rejections),
            f"round-1 candidate {n} is rejected",
            f"got: {rejections}",
        )
        check(
            any("boot markers missing" in r for r in rejections),
            f"candidate {n} is rejected for missing markers, the honest reason",
            f"got: {rejections}",
        )


def main():
    with tempfile.TemporaryDirectory() as tmpdir:
        test_corrected_sheet_is_not_rejected(tmpdir)
        test_traced_round1_defect_is_rejected(tmpdir)
        test_degenerate_stride_is_rejected(tmpdir)
        test_frontal_defect_is_rejected(tmpdir)
        test_missing_markers_are_rejected(tmpdir)
        test_anchor_drift_is_rejected(tmpdir)
        test_anchor_drift_within_tolerance_is_not_rejected(tmpdir)
        test_clipped_figure_is_rejected(tmpdir)
        test_malformed_grid_is_rejected(tmpdir)
        test_mirrored_row_cannot_earn_a_verdict(tmpdir)
    test_round1_candidates_are_rejected()

    print()
    if FAILURES:
        print(f"FAILED: {len(FAILURES)} check(s): {FAILURES}")
        return 1
    print("check_walk_sheet tests passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
