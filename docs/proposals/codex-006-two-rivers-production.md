# Round 006 proposal: a 3D-authored, 2D-delivered art pipeline

## 1. Approach

I recommend path 3, a small 3D pre-render pilot followed by a decision gate. The runtime product remains 2D. Meshy supplies draft geometry, a conventional 3D scene supplies scale, rigging, motion, camera, and lighting, and an offline renderer emits transparent painterly sprites for the existing Godot isometric spine. This is not approval to adopt Meshy for the town. Meshy is a new external dependency, so adoption beyond the pre-authorized pilot needs Scott's explicit approval and decision record 009 covering account, cost, license, provenance, retention, and reproducibility.

This path is preferable to live 3D because the approved target is an illustrated scene, not merely correct geometry. Live meshes would replace the render spine, expose every weak surface and silhouette in a generated model, and make the whole game depend on a coherent shader, material, LOD, and lighting stack that does not exist. It is preferable to pure-sprite production because round 005 already demonstrates both sides of that bet: `docs/art/iso-five-asset-spike.png` proves that image generation can hit the look in one composed image, while the running screenshot shows the look collapsing when independent legacy facades, flat ground polygons, a proxy walk atlas, scale guesses, and procedural shadow substitutes are assembled. More prompting alone does not establish shared geometry across 48 walk frames or shared physical scale across a town.

### Production data flow

The pilot asset flow would be:

1. Freeze an art bible from `tools/art/out/iso/style_board.png`, `docs/art/iso-five-asset-spike.png`, and `tools/art/style.md`. Add orthographic silhouette, material, palette, roof pitch, timber width, and weathering callouts. Outside images remain visual reference only.
2. Generate one humble half-timbered cottage draft and one clothed human draft in Meshy. Save the original service output, request parameters, service version, license note, and hashes in a pilot provenance manifest. No Meshy material is accepted merely because it arrived on a mesh.
3. Import the drafts into an offline Blender scene. Blender is the proposed local conversion and rendering tool, not a runtime or engine change. Clean topology and silhouette only as far as the fixed camera reveals, replace materials with our restrained hand-painted palette, set the player to 1.75 scene units, and size the cottage from the same meter grid. Rig the player to a standard armature and author or retarget one six-pose walk loop.
4. Lock one orthographic camera to decision 007's view and lock one sun/key vector to the manifest's existing screen-space shadow direction. Render RGBA color, cast-shadow, contact-shadow, and optional object-id passes. Render the cottage once at its canonical orientation and the player at eight facings by six frames. A light texture or compositing pass may soften gradients and edges, but must be deterministic and batchable. Do not use generative repaint independently on each animation frame, since that reintroduces temporal boiling.
5. Extend the existing manifest boundary rather than replace it. A new `tools/art/manifests/prerender-pilot.json` records camera transform, orthographic scale, scene-unit scale, frame order, anchors, render settings, source hashes, and output ids. A small Blender batch script emits raw PNGs. `tools/art/ingest_generated_sheet.py`, `tools/art/process_assets.py`, `tools/art/build_player_walk.py`, and `tools/art/check_walk_sheet.py` continue to validate anchors, sizes, facings, frames, and atlases. The final outputs remain ordinary PNG textures under `tools/art/out/iso/processed/`.
6. Wire only the pilot outputs into `src/render/town/starter_town.gd` and `src/render/town/player_controller_2d.gd`, with no change to `src/sim/`. Keep `src/render/iso/projection.gd`, square-grid collision, contact anchors, depth ranking, and click routing intact. Replace flat `Polygon2D` color diamonds in the pilot capture with seamless generated ground texture layers and edge/decal overlays so the comparison tests the real assembly problem.

The scale contract should be documented in the pilot manifest and an art-facing document. One world unit is one meter, the canonical player is 1.75 m sole-to-crown, a cottage door is 2.0 m, eaves are about 2.4 m, and ridge height is 4.8 to 5.6 m. Thus the cottage ridge reads about 2.75 to 3.2 player heights above its contact plane, while a door reads about 1.14 player heights. The fixed camera maps that shared scene scale to pixels. Asset scripts may normalize anchors and pad canvases, but may not apply per-asset aesthetic scale overrides. A validation script should fail when declared scene scale, rendered contact anchor, or expected pixel height falls outside tolerance.

### Exact pilot and acceptance gate

The pilot contains exactly one 2 by 2 cottage and one player with one six-pose walk cycle rendered in all eight facings. It also includes only enough textured grass, dirt lane, hedge, flowers, rocks, and tall-grass dressing to make one small in-engine comparison plot. It does not model the inn, produce the rest of the town, change `project.godot`, touch `src/sim/`, or commit longwalk to Meshy.

The capture tool should produce one fixed-camera, one-to-one shipping-scale board with the pilot cottage, player, path, and dressing, plus a running-build walk GIF. Put that board beside three references at matched crop and exposure: the approved five-asset spike, the current running build, and the same pilot composition made with the best current pure-sprite assets. Acceptance requires all of the following:

- Blind review identifies the pilot as closer to the spike than the current build on silhouette, material richness, painterly cohesion, grounding, and rural humility. It must not read as glossy generic 3D.
- The cottage satisfies the documented player-height and door-height ratios without a runtime scale tweak.
- All eight directions are distinct, feet stay within a two-pixel contact-anchor tolerance, limb phase alternates, there is no visible frame-to-frame texture boiling, and the running GIF reads as weight transfer rather than a sliding paper doll.
- Ground has no visible diamond seams at normal zoom, props share the light vector, and building/player occlusion still follows the current contact-depth contract.
- The complete rerender from the committed local scene and manifest is reproducible without a second Meshy call. Service regeneration is provenance-controlled but need not be byte-identical.

If it passes, decision 009 can authorize a bounded production tranche, beginning with the Winespring-Inn analog, two cottage families, and a flora kit. If it fails painterly cohesion or cleanup economics, retain the exported pilot sprites and return to pure 2D with better evidence about scale and gait. Do not switch to live 3D as the fallback.

### Four-defect plan

1. **Walk gait.** Use one rig and one six-pose loop, render the same motion at eight yaw angles, and drive frames by accumulated projected distance as already specified in `player-walk-policy.json`. Add automated foot-anchor, silhouette-area, phase-order, and facing-count checks. Keep `tools/art/capture_player_walk.gd` as the decisive running-build GIF source. Human acceptance remains whether hips transfer weight, planted feet hold, arms oppose legs, and the body does not skate.
2. **Building-to-player scale.** Author both subjects in one meter-based 3D scene, enforce the ratios above in the manifest, and forbid per-asset runtime scaling. The cottage footprint, contact point, door, eaves, and ridge become measured outputs rather than unrelated prompt results.
3. **Fidelity gap.** Move composition knowledge upstream into a shared camera, palette, light, material library, and physical scene. Preserve it downstream with color, contact-shadow, and cast-shadow passes, seamless terrain layers, fixed anchors, and an in-engine dressed-board gate for every asset family. An isolated transparent sprite is not accepted until it passes the shipping renderer capture.
4. **`Instance base is null`.** Treat this as an independent fast lane, not an art-pipeline symptom. Reproduce from a clean import with the same playtest path, capture the Godot stderr and debugger stack, locate the stale or failed script/resource instance, fix it narrowly, and add a boot-flow assertion that fails on engine errors and on that exact text. The screenshot proves the message is visible; source search alone does not establish its cause, so naming a speculative line now would be unsafe.

## 2. Risks

The largest risk is that 3D correctness produces visually coherent mediocrity. Meshy may yield swollen rooflines, over-detailed surfaces, poor hands, unusable topology, or textures that look glossy and generic. Orthographic rendering can expose bad proportions, while postprocessing strong enough to hide them can erase animation consistency. A single successful cottage may also hide an unfavorable cleanup curve across an inn, sheds, fences, carts, and flora.

The dependency risk is real. Meshy adds cost, account and API availability, terms and license questions, source retention concerns, and a service version outside the repository. Blender would add a local authoring tool to the production path even though it does not change Godot. Both need explicit pinning and documentation before scale-out. A batch scene can be reproducible after download, but initial generation cannot honestly promise byte identity.

Pre-rendering also freezes view and lighting. Eight facings multiply character output, tall sprites stress atlas size, and changing the projection or sun later means rerendering. Destructible or modular buildings would need planned layers. Shadows baked too strongly into color will double-darken against separate masks. Ground remains chiefly a 2D composition problem, so path 3 does not automatically solve seams or biome transitions.

Pure sprites remain the lower-disruption alternative and already hit the target in the spike. The pilot could show that disciplined category sheets, scale contracts, and dressed-board gates are enough, making 3D cleanup needless overhead. Conversely, if the generated 3D draft is clean but its render cannot match the spike without per-frame generative repaint, the recommended path fails its central claim.

In the first hour I would use primitive proxy geometry in a meter-scaled orthographic scene, render a cottage box, door, and rigged mannequin through the proposed camera, then push those PNGs through the current anchor and Godot capture path. That tests scale, camera agreement, canvas sizes, and whether the current runtime accepts pre-render outputs before spending a Meshy call.

My first question to Scott would be: is faithful painterly resemblance allowed to depend on a deterministic local NPR/compositing pass after the 3D render, or must the raw 3D material render itself meet the spike? The answer controls whether path 3 is plausible without temporal generative repaint.

## 3. Division-of-labor claim

The Codex seat is best suited to own the 2D delivery boundary: render-pass specifications, manifests, batch postprocessing, chroma or alpha cleanup, anchor and scale validation, eight-facing atlas assembly, shadow masks, and the running-build comparison/GIF artifacts. That directly matches the sprite-forge mandate and builds on `tools/art/` rather than discarding it. I can also own prompt and art-bible iteration for the generated surface references.

Detailed Blender topology cleanup, armature weighting, and hand-tuning a convincing gait are better suited to whichever resident has the strongest 3D and animation tooling. The runtime resident best positioned in Godot should own the independent null-instance diagnosis and the narrow texture swap. Those boundaries let Codex judge the 3D output by the same strict 2D runtime contract that all production assets must pass.

## 4. Rough estimate

The decision pilot is roughly 4 to 7 focused worker-days across the team: one day for proxy camera/scale proof and manifests, one to two days for Meshy generation and cottage/player cleanup, one to two days for rigging, walk, and eight-facing renders, and one to two days for runtime integration, textured comparison plot, captures, and review fixes. Meshy account, licensing, or provisioning delay is outside that estimate.

If accepted, a first production tranche containing the inn, two cottage families, player walk set, seamless grass/dirt, and a small flora/prop kit is on the order of 3 to 6 worker-weeks before review iteration. The full starter-town arc is more likely 6 to 10 worker-weeks than a single round, because visual direction, cleanup cost, terrain transitions, and dressed assembly need repeated gates. The null-instance fast lane should be hours to one day once reliably reproduced.
