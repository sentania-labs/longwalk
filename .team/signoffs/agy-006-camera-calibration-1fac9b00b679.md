---
reviewed_branch: agy/006-camera-calibration
reviewed_sha: 1fac9b00b679a97353a18beac7a4a0edf347106f
reviewed_by: claude-worker
authored_by: agy-worker
timestamp: 2026-07-17T21:30:38Z
tests_run: bash tools/art/render.sh
result: signed-off
---

I own the iso render spine (src/render/iso/projection.gd), so I checked this
slice against that frozen contract rather than taking the author's word.

Math verified independently:
- Elevation. For an ortho camera at azimuth 45 and elevation theta, a ground
  grid step projects with horizontal:vertical ratio 1/sin(theta). Setting that
  to the 2:1 iso basis gives sin(theta) = 0.5, so theta = asin(0.5) = 30 deg,
  NOT atan(0.5). The code and its comment (blender_calibration.py:41-42) are
  correct; atan(0.5) would give the wrong ground ratio.
- Ground checks. godot_px/godot_py in the script are (gx-gy)*64 and (gx+gy)*32,
  which is exactly IsoProjection.cell_to_screen with HALF_W=64, HALF_H=32.
- Footprint contact. godot_contact_x = ox + fw/2, godot_contact_y = oy + fh
  matches building_contact_cell(origin, footprint) verbatim (verified against
  projection.gd:212-216; e.g. 1x1 -> (0.5, 1.0), 3x2 at (2,3) -> (3.5, 5.0)).
- Height. Vertical foreshortening is cos(theta) = cos(30) = sqrt(3)/2, so the
  upright rate is h * (sqrt(3)/2) * 64*sqrt(2) = h * 32*sqrt(6). The test
  expectations and the 2.0 m golden pole both use h*32*sqrt(6).

Constitution / scope:
- No src/sim or src/render change (git diff --name-only against round base
  2805f00 confirms; only .gitignore, docs/decisions/009, tools/art/*,
  tools/fetch_blender.sh).
- No Meshy call in the calibration script; no committed binary (blender_bin and
  blender-* are gitignored).
- No em-dashes in the added files.

Ran bash tools/art/render.sh against Blender 4.0.2: exit 0, CALIBRATION PASSED,
max pixel error 0.0002 px across all ground, footprint, and height cases; the
2.0 m golden pole measured 156.7674 px vs expected 156.7673 px.

Signed off.

Co-authored-by: Claude <claude@sentania.net>
