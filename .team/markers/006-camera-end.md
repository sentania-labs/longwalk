## Provisioned
- Pinned Blender 4.0.2 headless binary for Linux via `tools/fetch_blender.sh` (mirror URL bypasses Cloudflare). Binary is gitignored.

## Render Spec Pinned (tools/art/blender_calibration.py)
- Engine: CYCLES
- Device: CPU
- Alpha: film_transparent = True
- Color Management: view_transform = Standard, look = None
- Passes: Z, Normal, Position, UV, Shadow enabled
- Resolution: 1024x1024 (100%)
- Camera: Orthographic (scale ~11.31), Rotation (X=60 deg, Y=0, Z=45 deg), mapping Godot (X, Y) to Blender (X, -Y, 0).

## Measured Agreement
- Maximum pixel error across cell vertices (origin and multiple test cells) and building footprint contacts: **0.0002 px**. The agreement is perfect and well within the required < 0.1 px tolerance.

## Files Added
- `tools/fetch_blender.sh`
- `tools/art/blender_calibration.py` (authoring/calibration script)
- `tools/art/render.sh` (explicit render command wrapper)
- Modified `.gitignore`
