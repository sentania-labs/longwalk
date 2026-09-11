extends RefCounted

# Baked from bridge.glb centerline triangles by reference/bake-bridge-profile.py.
# Heights use a 24m span with its bottom at zero, before placement offset.
# Source SHA256: 181f917f13db775c773db90cecd090fc4a54c6c58591fb168c94117ebfe49f2f
const MAIN_OFFSET := -1.2
const SMALL_OFFSET := -0.6
const STEP := 0.25
const HEIGHTS := [0.000000, 0.390421, 0.441523, 0.495736, 0.573728, 0.618049, 0.659150, 0.708293, 0.787529, 0.832468, 0.899394, 0.961289, 1.018191, 1.146615, 1.200825, 1.158025, 1.234947, 1.293943, 1.383286, 1.429059, 1.471901, 1.517416, 1.542856, 1.618973, 1.669010, 1.771821, 1.805592, 1.789779, 1.863369, 1.884970, 1.960953, 2.001559, 2.125994, 2.171594, 2.167028, 2.221883, 2.300563, 2.389764, 2.434508, 2.516110, 2.562195, 2.587997, 2.605648, 2.594745, 2.624161, 2.649254, 2.673994, 2.740634, 2.726713, 2.787521, 2.775986, 2.666040, 2.669323, 2.671403, 2.635099, 2.610783, 2.554013, 2.529629, 2.463379, 2.435683, 2.384317, 2.354070, 2.382062, 2.358295, 2.324814, 2.268133, 2.227612, 2.216182, 2.167858, 2.121348, 2.019806, 1.972996, 1.880001, 1.858680, 1.794323, 1.780043, 1.733187, 1.662032, 1.637223, 1.600860, 1.534489, 1.461900, 1.457817, 1.409494, 1.343935, 1.278516, 1.225081, 1.104351, 1.047143, 0.988973, 0.926331, 0.873512, 0.866285, 0.777831, 0.763087, 0.737876, 0.000000]

static func deck_height(distance: float, small: bool) -> float:
 var scale_factor := 0.5 if small else 1.0
 # The short bridge's 90 degree yaw maps local +X to world -Z.
 var local_distance := -distance / scale_factor if small else distance
 if absf(local_distance) >= 12.0:
  return 0.0
 var index := (local_distance + 12.0) / STEP
 var lower := int(floor(index))
 var sampled := lerpf(HEIGHTS[lower], HEIGHTS[lower + 1], index - lower)
 return maxf(0.0, sampled * scale_factor + (SMALL_OFFSET if small else MAIN_OFFSET))
