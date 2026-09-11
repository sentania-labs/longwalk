# Two Rivers terrain study

Flat 1024 by 1024 meter authored terrain, matching the simulation map exactly. Instantiate `terrain.gd` as a Node3D at world origin. It creates ground at y=0 and water at y=-0.18. It does not create collisions, navigation, buildings, or bridges.

Ground uses the existing generated grass, dirt and soil materials. A 2048px control map stores road and three farm surface weights. `bake-terrain-mask.py` reads the frozen landscape constants and samples coordinates independently, with no stateful random placement. Re-run it after authored road or farm coordinates change. Field edges blend over 1.6 meters; roads have soft shoulders. Forest soil increases outside the settlement, while the center has a small cobbled square. Grain and crop colors are surface underlays for any later crop meshes, not actual modeled plants.

River cutouts and bank shading mirror `river_x` and `tributary_z` in the simulation. Animated water is opaque and shallow-looking, intentionally inexpensive for this layout and camera prototype. Terrain is flat, so steep banks, terrain sculpting and waterfalls remain future art work. The two reference images guide muted meadow colors, irregular worn surfaces, dark soil and warm grain.

Integration pass: road shoulders now span about 4.1 meters. A second baked RGB wear map adds narrow footpaths from each of the 19 static building entries to the nearest lane or square, plus tight oriented foundation wear. Building positions, rotation and height are read from the scene, so rerun the baker after they change. Water uses gently moving stretched positional noise rather than periodic ripple products. Main-scene screenshots were checked at the village square and stone bridge after this pass.
