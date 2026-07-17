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

For each of the 6 poses (index `0` through `5`), 5 pass files were created, yielding exactly 30 files in total.
Stale output is cleared at the start of `run_sanity()` to prevent false positives.

```bash
$ ls -1 assets/art_src/pilot/sanity_render/
SE_0_color.png
SE_0_normal.png
SE_0_position.png
SE_0_uv.png
SE_0_z.png
SE_1_color.png
SE_1_normal.png
SE_1_position.png
SE_1_uv.png
SE_1_z.png
SE_2_color.png
SE_2_normal.png
SE_2_position.png
SE_2_uv.png
SE_2_z.png
SE_3_color.png
SE_3_normal.png
SE_3_position.png
SE_3_uv.png
SE_3_z.png
SE_4_color.png
SE_4_normal.png
SE_4_position.png
SE_4_uv.png
SE_4_z.png
SE_5_color.png
SE_5_normal.png
SE_5_position.png
SE_5_uv.png
SE_5_z.png
```

## Pixel Dimensions
All rendered PNG files are `1024x1024` pixels, as inherited from the calibrated scene (`scene.render.resolution_x = 1024`, `scene.render.resolution_y = 1024`).

## Naming Contract Note
The naming contract is `{facing}_{pose_idx}_{pass}.png`. Note that Blender's `FileOutput` node automatically appends the frame number (e.g., `_0000.png`) to the path. The script includes a post-render rename step (using glob matching since Blender 4.0 removes `slot.name`) to strip the frame number suffix and adhere strictly to the contract.
