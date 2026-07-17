# Offline sprite scale contract

This contract governs every 3D-authored sprite delivered to the isometric 2D
renderer. It is an acceptance boundary, not an art-direction suggestion. Assets
may not receive per-asset aesthetic scale overrides.

## World and subject scale

- One authoring scene unit is exactly one meter.
- The canonical player is 1.75 m from sole contact to crown.
- A cottage door opening is 2.0 m high.
- Cottage eaves are 2.4 m high, with a 0.05 m modeling tolerance.
- A cottage ridge is 4.8 m through 5.6 m high.
- The ground contact plane is scene `Z = 0`. The player sole contact and the
  building footprint contact edge lie on this plane. Geometry below it is an
  error.

The pre-render manifest records these dimensions in meters and declares
`scene_units_per_meter: 1.0`. Scaling an object, armature, camera, render layer,
or completed sprite to evade these dimensions is prohibited.

## Projection and pixel scale

`src/render/iso/projection.gd` freezes a 128 by 64 pixel, 2:1 dimetric diamond.
Its horizontal ground basis vectors remain `(64, 32)` and `(-64, 32)`. The
standard orthographic render camera is fixed at 30 degrees elevation to reproduce
that ground projection. Its world-unit scale is `P = 64*sqrt(2)` pixels, so the
upright basis is `(0, -32*sqrt(6))`, derived exactly as
`P*cos(30 degrees) = 32*sqrt(6)`. One upright meter therefore renders at
`32*sqrt(6)` pixels, approximately 78.3837 px/m. `TILE_H = 64` remains the
ground tile module and is not the upright pixels-per-meter rate.

For a landmark `h` meters above the contact plane, the expected raster height
is:

```text
expected_pixel_height = h * 32*sqrt(6)
expected_top_y = contact_y - expected_pixel_height
```

The validator permits at most 2 pixels of raster landmark error. The canonical
player therefore renders approximately 137.1714 pixels sole-to-crown. A 2.0 m
door renders 156.7673 pixels, 2.4 m eaves render 188.1208 pixels, and a 4.8 m
to 5.6 m ridge renders 376.2416 to 438.9485 pixels above contact. These values
are rounded only for display. Validation computes with the exact closed form.

## Canvas and anchor policy

All coordinates are PNG pixel coordinates with origin at the upper left. The
declared contact landmark is the pixel where the subject meets the ground plane.

| asset kind | RGBA output | contact anchor | padding policy |
| --- | --- | --- | --- |
| player frame | 160 by 160 | `(80, 144)` | 16 px below the soles; center the canonical figure horizontally |
| 2 by 2 cottage | 512 by 512 | `(256, 448)` | 64 px below the front-edge contact; center the frozen front-edge anchor horizontally |

The existing canvases accommodate the revised physical upright rate. For the
player, `144 - 1.75*32*sqrt(6)` leaves approximately 6.83 px above the crown,
with 16 px below contact. For the tallest permitted cottage,
`448 - 5.6*32*sqrt(6)` leaves approximately 9.05 px above the ridge, with 64 px
below contact. The canvas sizes and contact anchors therefore remain unchanged.

The cottage anchor represents `building_contact_cell(origin_cell, footprint)`
from `src/render/iso/projection.gd`: the center of the footprint's front,
maximum-screen-Y edge. Transparent padding may grow only through a future
contract revision applied to every asset of that kind. It may not move the
contact anchor.

Render directly at the specified output resolution. Cropping, atlas assembly,
color work, alpha cleanup, and deterministic compositing may preserve pixels,
but no downstream stage may resample, resize, stretch, shrink, or apply runtime
sprite scale. A changed target resolution requires a revised scale contract and
corresponding validation update.

## Validation boundary

`tools/art/check_scale_contract.py` checks both sides of the render boundary:

1. Pre-render, it checks the manifest's scene-unit declaration, ground plane,
   subject dimensions, asset kind, and output canvas.
2. Post-process, it checks the projected contact landmark and the pixel distance
   from contact to the declared top landmark.

Both checks are required. A correct model rendered onto a shifted canvas fails,
as does a correctly padded sprite produced from incorrectly declared geometry.
