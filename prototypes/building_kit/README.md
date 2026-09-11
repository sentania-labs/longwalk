# Building kit construction study

Standalone Godot 4.3 prototype. This tests compatible building pieces, not replacement art for the accepted village landmarks. It does not change the Two Rivers project.

Run the Windows EXE after extracting the ZIP, or the Linux binary. Defaults immediately show a cottage. The interface selects cottage, longhouse or courtyard, switches thatch/slate and hides the roof. Right drag orbits and tilts, Q/E rotates, mouse wheel zooms, Escape exits.

The same 2 m wide, 3 m high bays form all footprints. Plain walls, framed windows, recessed doors, structural posts, stone foundations, roof slopes and gable endcaps are separate geometry. Wall openings are actual gaps in the plaster mesh. Window panes and door leaves are separate inset geometry. Material UVs use face dimensions instead of projecting a whole building image onto a box.

Six 512 px material panels were cropped from one built-in imagegen atlas: plaster, fieldstone, timber, thatch, slate and earth. Source atlas and prompt are in reference/. No paid Meshy calls. Mipmaps are enabled. The generated panels show some repeat seams and require artist cleanup before production use.

First-cut limitations: rectangular buildings only, flat roof silhouettes, basic closed window panes, fixed door leaf, no collision/navigation/people, no editor for individual bay placement, no interior fittings, no joined L/T roof valleys. Endcap lighting uses a simplified normal. Posts share the bay edges and need a dedicated corner treatment before production. Texture joints, roof thickness variation, chipped edges, regional trim and weathering need an art pass. These models are deliberately simpler and more regular than the Meshy landmark buildings.

Verification: the packaged Linux executable ran from its build directory and rendered all three layouts with both roof finishes plus roof cutaway. Captures were visually inspected. Windows export succeeded but requires Windows playtest. No CI, PR, deployment or changes to the main game, under the local prototype exception.
