# Sanity Render

## Command
```bash
tools/blender/blender_bin --background --python tools/art/blender_pose_rig.py -- --sanity
```

## Produced Output
The script ran successfully for facing `SE` and 6 poses (interpolated across the walk action frame range).

The following passes were produced per pose:
- `color` (RGBA)
- `z` (Depth)
- `normal`
- `position`
- `uv`

(The `shadow` pass was defined in the CompositorNodeOutputFile slots, but skipped linking because the `Shadow` output was missing from `Render Layers` in our headless environment setup.)

For each of the 6 poses (index `0` through `5`), 5 pass files were created, yielding 30 files in total.

## Pixel Dimensions
All rendered PNG files are `1024x1024` pixels, as inherited from the calibrated scene (`scene.render.resolution_x = 1024`, `scene.render.resolution_y = 1024`).

## Naming Contract Note
The naming contract is `{facing}_{pose_idx}_{pass}.png`. Note that Blender's `FileOutput` node automatically appends the frame number (e.g., `_0000.png`) to the path. The script includes a post-render rename step to strip the frame number suffix and adhere strictly to the contract.
