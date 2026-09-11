# Character comparison

Local presentation prototype under Scott's prototype workflow exception. No village assets or gameplay are replaced.

Compare the current animated 3D character with a four-facing billboard sprite on the same cottage/path stage. Both use a nominal height of 1.75 metres. Q/E rotates; minus/equals or the wheel zooms. Game view, close-up and low-angle presets expose both strengths and limitations.

The sprite's perspective and lighting are painted into the art. It has a modest contact shadow, not a dynamically lit 3D body. Its four facings switch at quadrant boundaries. Low-angle viewing deliberately reveals the fixed elevated perspective. The current 3D figure plays its original animation without corrective bone poses.

This package is an idle and appearance comparison. Two sprite walk drafts failed visual review: one changed body scale, the other repeated the same leading leg. Their source references are preserved, but draft walk assets are excluded from export and the walk control remains disabled. A later reviewed walk study can compare motion.

The billboard's screen height does not foreshorten with camera elevation as the 3D figure does. Both retain their nominal 1.75 metre height; neither is secretly resized to make their screen silhouettes match.

Run `tools/godot/godot --path prototypes/character_comparison` from repository root. Use `-- --capture-dir=/tmp/character-study` for the automated view capture. Export presets produce standalone Windows and Linux executables with embedded data. Windows requires a Windows playtest.
