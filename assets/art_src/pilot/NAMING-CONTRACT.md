# Rendered Sprite Naming Contract

This document defines the strict naming contract for isometric sprite renders produced by the `tools/art/blender_pose_rig.py` module. 

## Contract
Each rendered pass for a character pose MUST follow this exact filename format:
`{facing}_{pose_idx}_{pass_name}.png`

- **`facing`**: The isometric facing label. Must be one of `["E", "SE", "S", "SW", "W", "NW", "N", "NE"]`.
- **`pose_idx`**: The 0-indexed integer representing the pose keyframe. For a 6-pose walk cycle, this is `0` through `5`.
- **`pass_name`**: The rendering pass identifier. Valid passes include `color`, `z`, `normal`, `position`, `uv`, and `shadow`.

## Examples
- `E_0_color.png` (East facing, pose 0, RGBA color pass)
- `SE_3_z.png` (South-East facing, pose 3, depth pass)
- `NW_5_normal.png` (North-West facing, pose 5, normal pass)

## Producer/Consumer Agreement
The Blender `blender_pose_rig.py` (producer) explicitly enforces this by stripping Blender's default frame-number suffixes from `CompositorNodeOutputFile` outputs. The downstream atlas builder (consumer, e.g., `build_player_walk.py`) is guaranteed to find files precisely matching this format without needing to parse unpredictable suffixes.
