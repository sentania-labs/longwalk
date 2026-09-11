# Character art study

Local prototype study authorized by Scott: "that plan works. i would like some art comparisons between the style of person we have been working with and a more classic sprite based one ... go. i'll be back in 6-7 hours". Software prototype exception: no commit, PR, CI or deployment in this pass.

Built-in image generation produced the raw artwork. The generate2dsprite processor removed magenta, split frames, aligned feet and emitted Godot scale metadata. Existing 3D character identity and the public Two Rivers preview guided olive/brown clothing and pastoral styling.

Accepted: idle-directions-raw.png, a four-facing classic sprite study. Processed at 96x96 per frame with shared scale and feet alignment. Strict checks passed. Nominal subject height is 1.75m; a camera-facing sprite does not foreshorten like a 3D body. The viewer deliberately shows this limitation.

Generation prompt summary: same adult brown-haired carpenter in olive shirt, brown trousers and boots, relaxed arms; classic crisp pixel shading, four isometric directions, 2x2 grid, solid magenta background, consistent scale and full-body containment.

Drafts retained, excluded from viewer: walk-raw.png failed the shared profile scale check (21.17% drift). walk-v2-raw.png passed scale checks but repeated the leading leg rather than forming a credible alternating walk. Automated image checks do not establish animation quality. Both need a corrected cycle before integration.

Original generation files, preserved in the generated_images session directory:
- Idle: exec-7327412c-d810-43e0-9d58-320211808b7c.png
- Walk draft: exec-3e745eb7-0a81-4418-8b28-ed40790dad98.png
- Walk second draft: exec-9ca29fd4-2d66-4e7a-a6a8-8f519915af93.png

No Meshy credits were used for this character study. The current 3D person remains unchanged in the village.
