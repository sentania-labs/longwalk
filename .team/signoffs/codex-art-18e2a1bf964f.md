---
reviewed_branch: codex/art
reviewed_sha: 18e2a1bf964f5207d469339abe6133ea839f4e1a
reviewed_by: claude-worker
authored_by: codex-worker
timestamp: 2026-07-17T06:45:00Z
tests_run: tools/run_tests.sh
result: signed-off
---

This clears the finding I refused `1ca9a0e` over. The speckle is gone and the
costumes survive.

## The defect I named is closed, measured my own way

I re-ran my own metric (hue 220-260, sat >= 0.35, alpha >= 128), not
`marker_blend_residue_mask`, which would have been circular. Raw counts on the
three shipped atlases came back 3 / 3 / 5, not zero. I chased every surviving
pixel individually rather than accept the number: they are rgb (2,2,6),
(0,0,1), and (33,27,46), all at value <= 0.18, sitting in the outline. They are
below `MARKER_MIN_VALUE` (0.20) and invisible. My metric was simply missing the
value filter the marker system has always used. Adding it, the count is 0 / 0 / 0
across burgundy, moss, and slate_blue. Explained, not hand-waved.

Old versus new differs by exactly 466 pixels, and a full-hue census confirms the
edit is surgical: the 220-260 band goes 466 -> 0 while every other band is
untouched (green 2089 -> 2089, cyan/teal 21835 -> 21835, red 1040 -> 1040,
magenta 0 -> 0). Nothing was widened into by accident.

## Green and red speckle remains, and is not this slice's defect

The 10x crops still show green and red dots on the boots in both versions. I
checked rather than assumed: markers are only magenta (280-340) and cyan
(160-200), so those hues are outside the marker system entirely, and the
authored revision-3 source sheet already carries them in larger quantity (green
7378, red 2829) before any recoloring runs. They are generation artifacts of the
source art, unchanged by this commit and out of scope here. Worth a future look,
not a blocker on this gate.

## The slate_blue tunic survives

This is what killed the naive widen at 22064 pixels, so I checked it directly
rather than through the author's test. Computing the tunic region independently
(pixels `recolor_tunic` actually paints), the boot pass changes 0 of 23860 tunic
pixels for slate_blue at hue 210, and 0 of 23860 for burgundy at hue 350. Moss is
the `None` base and takes no tunic recolor. The `blue_dominant` and
`red_green_balance` predicates are what keep hue 210 out of the widened band. I
cleared my `tools/art/__pycache__` first, which is what gave me the false 22064
slate_blue failure last time.

## The visual check that actually decides it

Both prior metrics were blind to the shipping defect, so this is the one that
matters. I rendered the densest 40x40 defect window at 16x, old beside new. Left
(1ca9a0e) is heavily blue-speckled across the leather; right (18e2a1b) is clean
brown. Unambiguous, not a judgement call. I also compared the mirrored row (row
3, derived by flip) against the source side row at 6x: the mirrored row is clean
by the same margin, as expected since a per-pixel recolor commutes with a
horizontal flip. One saturated blue pixel remains at (394,275) in the slate_blue
crop; it is hue 210 sat 0.76 and absent from moss, so it is tunic costume color,
not residue.

## The new metric bites

I did not take this on report. I removed `| marker_blend_residue_mask(image)`
from `recolor_boots` to reintroduce the defect: the suite went red at 466 pixels
on all three atlases, exit 1. Restoring the file to the branch content
(sha256 verified byte-identical to `codex/art`) returns it to green, exit 0.
Codex reported 469/471/469 where I measure 466; the small delta is threshold
detail, and the direction and magnitude reproduce. A metric that goes red on the
real defect and green on the fix is a real metric.

## Nothing I cleared has regressed

- Determinism: regenerating from the committed source reproduces all three
  atlases byte-identically (sha256 matched against the committed PNGs).
- Gate untouched: no change to `tools/run_tests.sh` or `.github/`.
- No laundering: the revision-3 source sheet is not modified. Source rows only,
  mirrored row still derived after source-row validation.
- The masked-write improvement to `_set_hue` / `recolor_boots` stays.
- Suite green in-worktree (`tools/run_tests.sh`, exit 0). No em-dashes in the
  diff or the commit message. `Co-authored-by: Codex` trailer present. Scope is
  five files, all belonging to this slice.

No protected paths touched, so no decision record is required.

Co-authored-by: Claude <claude@sentania.net>
