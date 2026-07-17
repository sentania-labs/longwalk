# Walk-sheet validation

`tools/art/check_walk_sheet.py` is the pre-recolor rejection gate for the 3x4
player walk sheet. This document records what it checks, why the pipeline is
ordered the way it is, and exactly what evidence stands behind it.

## The gate may only reject

Exit code 0 means "no defect detected". It does not mean the sheet is good, and
nothing in this tool should ever be quoted as an acceptance. Per decision 003
the accept authority is the in-game capture at 160 px. This gate exists to kill
sheets that are provably broken before anyone spends a capture cycle on them.

That asymmetry drives real design choices. A marker the gate cannot find is a
rejection, never a pass, because an unmeasurable sheet is one this gate cannot
clear. The stride magnitude floors are deliberately conservative for the same
reason: over-rejecting borderline art would usurp the capture's authority.

## Pipeline order is binding

    generate (colored boots) -> VALIDATE (here) -> mirror -> recolor to brown

The natural implementation order does exactly the wrong thing. The recolor pass
maps boots to brown unconditionally, so a sheet carrying the exact round-1
defect passes straight through it and emerges with the defect intact and its
only diagnostic signal deliberately destroyed. The gate must see the colored
intermediate.

Mirroring inverts the color/leg binding: a mirrored magenta left boot now sits
on the right of the image. So a mirrored row cannot be validated against the
colored intermediate at all, and only the three source rows (down, up, side) are
checked. The pre-recolor image is the artifact of record and is kept under
`tools/art/`.

## Why colored boots

"Left leg" and "right leg" are semantically distinct but visually identical, so
the generator has no image-space signal to bind the constraint to. Round 1 asked
for alternation semantically and the model dropped it twice. Colored boots move
the constraint from semantic to chromatic (magenta left, cyan right), where it
is measurable in pixels.

## The two gates are orthogonal

| Gate | Question | Failure it catches |
| --- | --- | --- |
| Boot alternation | Do the feet swap which one leads? | The round-1 defect: one pose repeated |
| Anchor drift | Does the figure stay on the ground? | Bobbing that reads as a shuffle at 160 px |

Neither subsumes the other. A sheet can alternate its feet perfectly while the
whole body bobs off the baseline. Boots verify ALTERNATION, anchor drift
verifies GROUND CONTACT. `test_anchor_drift_is_rejected` pins this: it builds a
sheet whose boot check passes and whose drift check rejects.

### Boot alternation

Per source row, the gate takes the hue centroids of the magenta and cyan boots
and computes a signed separation along the row's stride axis, normalized by the
figure's own pixel height.

The stride axis differs by facing. The side row is a profile view, so the stride
runs along screen x. The down and up rows are frontal and rear views, where left
and right boots are always separated in x regardless of pose, so x carries no
stride signal at all; the stride shows in y, because the leading foot is nearer
the camera (down) or further from it (up).

The gate then rejects when the two contact frames (0 and 2) fail to reverse the
sign, when a contact frame has no committed stride, or when the same boot leads
in every measurable frame. The sign convention itself does not matter: the test
is whether the sign REVERSES, which is invariant to the convention.

### Anchor drift

Per Scott's 0430 steer (recorded in decision 004): max anchor-y standard
deviation 0.05, and clamped or edge-touching frames are regeneration triggers,
not accepted variance.

The gate runs on the raw sheet, where figures float inside oversized cells with
margin, so the meaningful quantity is the VARIATION of the sole line across a
row, not its absolute position. Drift is normalized by the row's content-band
height, which is the correct proxy for the shipping cell: `process_assets.py`
crops to content and resizes, so that band height is exactly what becomes the
160 px cell. Absolute alignment to row 159 is established there, by the crop,
and a row that drifts here will drift there too because the crop is driven by
the figure's own bbox.

## Grid detection is not a naive split

The gate finds rows and columns by locating background gutters, not by slicing
the sheet into height/3 by width/4.

This is not defensive coding, it is a bug that actually fired. On the round-1
candidates the even split sliced through the figures: the real content bands are
at y 40-346, 383-684 and 719-1026, so an even split at y=362 and y=724 pulled
the side row's heads (starting at y=719) up into the up row's cell and reported
them as that row's soles. That produced a confident, entirely fictional reading
that every up-row frame was clipped at the cell edge.

## What the round-1 candidates prove, and what they do not

This is the most important limitation to understand before trusting this gate.

**Both round-1 candidates are rejected, but on the marker-absence path, not the
reversal path.** Measured over both sheets: **zero magenta pixels and zero cyan
pixels.** Their entire saturated palette lives in hues 0-90 (browns, greens,
skin). That is expected, since round-1 art predates the colored-boot ruling, but
it has a consequence worth stating plainly:

> The chromatic reversal check structurally cannot be evidenced against the
> round-1 sheets. There are no colored boots in them to measure. The gate
> rejects them for having no markers, which is correct pipeline behavior and
> honest, but it is NOT evidence that the reversal check catches the round-1
> defect.

Claiming otherwise would be fabrication. Instead the reversal check is
calibrated against the round-1 defect by **tracing its real geometry**. Measured
from candidate 2's side row, in figure-height units:

| Frame | Pose | Boot centroids | Separation |
| --- | --- | --- | --- |
| 0 | contact | +0.090, +0.621 | 0.531 |
| 1 | passing | +0.069, +0.153 | 0.084 |
| 2 | contact | +0.092, +0.627 | 0.535 |
| 3 | passing | +0.065, +0.159 | 0.094 |

Frames 0 and 2 are the defect in numbers: separations of 0.531 and 0.535 with
near-identical centroids. That is the same pose twice, exactly matching what
codex-worker rejected by eye in `docs/proposals/codex-spike-walk-sheet.md`
("frames one and three again repeated the same extended-stride silhouette
rather than reversing which leg led").

`test/art/walk_sheet_fixtures.py` rebuilds that measured geometry with colored
boots, in two variants: the defect (same color binding on both contacts) and the
correction (binding swapped on contact 2). The gate must reject the first and
must not reject the second. That is how a check that cannot be run against the
original art is still calibrated against the original defect.

These same measurements set the side-row stride floor: every observed passing
frame is at or below 0.094 and every observed contact frame is at or above
0.531, so the 0.12 floor separates them with wide margin. The down/up floor
(0.06) has no colored reference art to calibrate against and is deliberately set
only to catch a degenerate row.

**Anchor drift does not reject the round-1 candidates either**, and should not:
their measured drift, in cell-height units, is down 0.0065 / up 0.0292 / side
0.0100 for candidate 1 and down 0.0209 / up 0.0035 / side 0.0086 for candidate
2. All are inside the 0.05 ceiling. The round-1 failure was alternation, not
bobbing, and the gate reporting that faithfully is the gate working.

## The suite is mutation-tested

A gate only ever observed passing is indistinguishable from `return 0`. So each
check was disabled in turn and the suite re-run, confirming `git diff --stat`
was non-empty first, because a no-op mutation showing green proves nothing and
is the exact error this project has hit before.

| Mutation | Result |
| --- | --- |
| `if np.sign(first) == np.sign(second)` -> `if False` | caught |
| `MAX_ANCHOR_STDEV` 0.05 -> 99.0 | caught |
| `if missing:` -> `if False:` | caught |
| `if edges:` -> `if False:` | caught |
| `MIN_CONTACT_STRIDE_SIDE` 0.12 -> 0.0 | **SURVIVED, now caught** |

The stride floor survived: it was calibrated from traced geometry and documented
above, but nothing exercised it, so deleting it broke no test.
`test_degenerate_stride_is_rejected` closes that gap with a side row whose lead
genuinely reverses but whose contacts separate by only 0.10 figure heights. The
reversal check therefore passes on that fixture (the test asserts this), which
pins the rejection on the floor alone. That mutation now fails the suite.

Two caveats worth keeping honest:

- The `if missing:` mutant is caught only because removing the guard makes
  `np.sign(None)` raise a `TypeError`, not because an assertion fires on a
  clean rejection. The guard ships, so the shipped path is sound, but the test
  is weaker than it looks.
- The reversal mutant is caught by the redundant "same boot leads in every
  frame" check rather than by the contact-frame check the test names. The two
  overlap on this fixture.

## Running it

    tools/art/check_walk_sheet.py tools/art/out/walk_sheet.png
    tools/art/check_walk_sheet.py sheet.png --json    # machine-readable

Exit codes: 0 no defect detected (not an accept), 1 rejected, 2 unreadable or
not a 3x4 grid. Both 1 and 2 mean regenerate.

Tests: `python3 test/art/test_check_walk_sheet.py`, wired into
`tools/run_tests.sh`. Every rejection path has a fixture built to trip exactly
that path, plus a corrected control proving the gate is not simply rejecting
everything.
