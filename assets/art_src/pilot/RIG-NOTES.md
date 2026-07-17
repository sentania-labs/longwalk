# Rig Notes

## Player Walk GLB Inspection
- **Armature Name:** `Armature`
- **Bone Names:** 'Hips', 'LeftUpLeg', 'LeftLeg', 'LeftFoot', 'LeftToeBase', 'RightUpLeg', 'RightLeg', 'RightFoot', 'RightToeBase', 'Spine02', 'Spine01', 'Spine', 'LeftShoulder', 'LeftArm', 'LeftForeArm', 'LeftHand', 'RightShoulder', 'RightArm', 'RightForeArm', 'RightHand', 'neck', 'Head', 'head_end', 'headfront'
- **Walk Action:** `Armature|walking_man|baselayer_Armature`
- **Frame Range:** 1 to 25 (approximate from `<Vector (0.8000, 25.6000)>`)

## 6-Pose Sampling Strategy
We linearly interpolate the frame index over the range 1 to 25 to generate 6 poses. Poses correspond to frames roughly at: 1, 5.8, 10.6, 15.4, 20.2, 25.

## Facing to World-Z Rotation Mapping
The camera is kept stationary at the calibrated iso pose (azimuth 45 degrees, elevation 30 degrees). We rotate the character around the world-Z axis to generate the 8 isometric facings.

| Facing Label | Screen Angle (Y-down) | Blender Z Rotation (degrees) |
|--------------|-----------------------|------------------------------|
| E            | 0                     | -45.0                        |
| SE           | 45                    | -90.0                        |
| S            | 90                    | -135.0                       |
| SW           | 135                   | -180.0                       |
| W            | 180                   | 135.0                        |
| NW           | 225                   | 90.0                         |
| N            | 270                   | 45.0                         |
| NE           | 315                   | 0.0                          |

*(Assuming the character faces +Y natively on import, which corresponds to NE in our calibrated iso projection).*
