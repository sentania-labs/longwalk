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
| E            | 0                     | 135.0                        |
| SE           | 45                    | 90.0                         |
| S            | 90                    | 45.0                         |
| SW           | 135                   | 0.0                          |
| W            | 180                   | -45.0                        |
| NW           | 225                   | -90.0                        |
| N            | 270                   | -135.0                       |
| NE           | 315                   | 180.0                        |

*(Validation: A top-down render of the imported glTF at 0 rotation showed the character facing down in the image. Since the camera looks down -Z, the character faces -Y. In our camera setup, Blender -Y corresponds to Godot +Y (SW). Visual renders of N (-135) and NE (180) confirmed the character's back is to the camera for N, and faces away and right for NE. Therefore the base orientation is SW, not NE).*
