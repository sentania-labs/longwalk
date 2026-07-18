# claude-007 critique: codex and agy village-production proposals

Author: claude-worker. Phase-2 adversarial critique. I read both peer proposals
read-only from `round/007-village`. I do not critique my own
(`claude-007-village-production.md`); it is listed only so I know which two to
attack.

One scope note up front, so I do not waste a bullet on a weak objection: the
constitution determinism rule governs *map/placement generation as a pure
function of (seed, position)*, not offline art-asset creation. Codex's plate
generation and agy's Meshy/img2img are both offline authoring steps whose output
is frozen PNGs, and both keep `src/sim/town_layout.gd` as authored, viewport-free
data. So I am explicitly NOT claiming a determinism violation against either
peer. Attacking there would be a losing objection.

---

## Codex: painterly district plates + master mosaic + extracted occlusion layers

### Steelman

The one thing independent per-object sprites cannot reproduce is the spike's
*inter-object* integration: buildings, lanes, vegetation, cast shadows, and
negative space were painted together under one light, so edges bleed, shadows
land across objects, and there is no repeated-tile rhythm. Codex is right that a
kit of transparent stickers drifts in palette, light, and edge treatment and
reads as pasted even when each asset is pretty alone. A baked painterly mosaic is
the only one of the three methods that keeps that integration *by construction*.
And codex's export gate is the most rigorous of the three: export an isolated
PCK, copy it to a temp dir with no source tree, run it headless, assert every
declared asset loads through `ResourceLoader` with nonzero dims, and fail if the
capture matches the placeholder fixture. That is a genuinely stronger "cannot
silently ship default art" proof than either agy's or my own gate, and I concede
it outright: that audit should be adopted whichever composition method wins.

### Attack

1. **The plates blur when the free-cam zooms IN, and the round demands zoom.**
   `_zoom_levels` in `camera_rig_2d.gd` tops out at `2.0`. Codex's 40x32 map
   projects (per `projection.gd`, `(w+h)*HALF_W` by `(w+h)*HALF_H`) to roughly
   4608 by 2304 screen px at zoom 1.0, so six 2048 px plates are near-native
   there. At zoom 2.0 that same ground covers ~9200 screen px while the plate is
   still 2048 native: a ~2.2x upscale, visibly soft slate and timber. The
   acceptance bar is "comparable roof and timber detail ... confusable with the
   spike," and codex only ever addresses zoom-*out* ("free camera may reveal the
   finite edge only at the maximum fit zoom"). It never addresses zoom-in blur,
   which is precisely where a painting loses to sprites-on-a-grid that stay
   crisp at every zoom. This is the same medium-fidelity trap round 006 fell
   into, just from a different direction.

2. **Baking "most trees, fences, props, shadows" into plates breaks the moment
   the walkable village returns, which is the explicit roadmap direction.** The
   frozen depth contract (`projection.gd` `building_contact_cell` / `depth_key`)
   sorts by each object's *per-object contact cell*. A baked mosaic has no
   per-object contact cells: everything in the plate is depth-frozen at bake
   time. Codex extracts only 14 crowns + bridge rails + ~20 clusters as sortable
   layers and admits it does this "even though there is no actor this round." So
   codex pays for the occlusion-layer machinery NOW, when nothing moves and
   nothing needs it, and yet that machinery still cannot cover the props it bakes
   flat: when the PC comes back (next milestone, walkable Two Rivers), the player
   can occlude correctly against the 14 crowns but will draw wrongly over or
   under every baked tree, fence, and prop that has no contact cell. Sprites-on-
   grid gives every one of those a contact cell for free. Codex's model is
   optimized for a still image this round and structurally hostile to the
   walkable village the roadmap says is next.

3. **Highest floor and a fallback that is the method that already failed.** Six
   2048 plates + a hand-masked master mosaic checked at 100% + four-landmark
   registration per plate + ~34 extracted-and-alpha-cleaned layers + GPU-safe
   chunking for texture limits is the heaviest pipeline of the three before a
   single asset ships. And codex's own risk section says if district coherence
   fails, the fallback is Meshy + Blender guide renders, i.e. the round-006
   render family that missed this exact bar twice, at a stated 3-to-5-week
   blow-up. So the primary path is expensive and the safety net is the known
   failure.

4. **Minor, and I share the error.** Codex cites "decision-010 math." The
   decisions directory stops at `008-isometric-visual-identity.md`; there is no
   009 or 010. Codex's separate claim that new records "begin at 009" is
   therefore the correct next number, but the "decision-010" reference is a
   phantom. My own proposal makes the same mis-citation, so I flag it as a shared
   fact-check for synthesis, not as a codex-specific defect.

### What should happen instead

Keep sprites-on-grid as the composition (extensible, crisp at zoom, one contact
cell per object), but *steal codex's integration insight rather than discard it*:
bake small multi-object micro-clusters (a tree + bush + fence-corner, or the
smithy-with-anvil-and-grindstone as the spike already paints it) as single
sprites wherever nothing will ever need to occlude *between* those members. That
recovers the shared-light, shared-shadow integration codex is right about,
without freezing the whole village into a mosaic that blurs at zoom and cannot
depth-sort a future PC. And adopt codex's isolated-packaged-capture audit
verbatim as the export gate for whichever method wins.

---

## Agy: Meshy 3D base -> round-006 Blender iso render -> stylized/img2img sprites

### Steelman

A Meshy 3D base rendered through the round-006 Blender pipeline guarantees three
things pure 2D generation cannot: exact iso projection onto the frozen spine
(`decision 008`), uniform lighting across every asset, and scale-contract
correctness (`32*sqrt(6)` px/m) so the inn is not accidentally cottage-height.
If an img2img pass then adds the painterly surface on top of that geometrically
perfect base, agy gets both correctness AND painterliness, which is a genuinely
attractive combination that neither a pure-slice kit nor a pure-plate mosaic
gets in one shot.

### Attack

1. **This is round 006's method, and round 006 missed this exact bar twice.**
   TEAM-STATE `07078d1` records both 3D-render candidates failing: A was
   under-tuned NPR, B was texture-space photoreal clash. Agy's two proposed
   fidelity rescues are the same two: "stylized Blender shader" (re-invites B's
   clash) or "lightweight img2img pass" (the thing that, if it actually works,
   makes the whole 3D step an unnecessary detour). The proposal treats the
   twice-failed pipeline as the baseline and bolts on the rescues that did not
   save it.

2. **The img2img vise.** Weak img2img leaves the render reading as a clean 3D
   miniature: fails the bar exactly as round 006 did. Img2img strong enough to
   read as hand-painted does two damaging things at once: it warps the geometry
   the Blender step just guaranteed (so the iso projection and scale-contract
   correctness that were agy's whole reason for going 3D are degraded), and,
   applied per-sprite, it stylizes each asset under an independent diffusion draw
   so palette and light drift between sprites, which is the sticker-look failure
   mode. Agy cannot turn the img2img strength up for fidelity and down for
   projection/consistency at the same time.

3. **Unbudgeted blocking gate: `src/sim/` is protected.** Agy proposes to
   "extend `TownLayout` to support a `PropPlacement`." `town_layout.gd` lives
   under `src/sim/`, which is enumerated in `.github/protected-paths.txt`, so any
   PR touching it needs a signed `docs/decisions/NNN-*.md` record before it can
   merge (`consensus.yml`). Agy's proposal never mentions protected paths or a
   decision record anywhere, so it has not budgeted for the gate it will hit.
   This is not a constitution *violation* (the edit is permitted with a record),
   but codex and I both flag the record and agy does not, and a plan that walks
   into a blocking gate blind is a real cost the estimate omits.

4. **The CI export test is heavier than the one sentence admits.** Agy wants "an
   integration test that runs during CI to verify that a packaged PCK export
   successfully resolves these `.import` files." Two problems. First, the
   `.import`/`.ctex` sidecars only exist after a `--headless --import` editor
   pass; agy names the verify step but not the import step that produces the
   artifact it verifies, and there is no `.gdignore` in the repo today so the
   whole premise of "strictly outside any `.gdignore` tree" is guarding against a
   tree that does not currently exist. Second, `export_presets.cfg` already sets
   `application/modify_resources=false` specifically because the CI runner has no
   rcedit/wine; a full PCK-export-and-resolve inside the fork-gated CI is more
   fragile than "runs during CI" implies. Codex and I both push this verification
   to an isolated packaged artifact rather than leaning on CI, which is the safer
   framing.

### What I concede to agy

Agy is right that a static-analysis ban on `Image.load` /
`FileAccess.get_file_as_image()` for game assets in `tools/run_tests.sh` is a
cheap, correct guard (I proposed the same, so this is convergence, not a loss).
And agy's division-of-labor claim is legitimately its strongest card: it can
*visually* evaluate a generated asset against the spike in a way codex and I
cannot do as directly. That multimodal-QA role is real and should be kept
regardless of which art method wins.

### What should happen instead

Drop the 3D base. If img2img is the actual fidelity engine (agy's own risk
section concedes the Blender shader probably is not enough), then condition it
directly on the spike's own painterly pixels rather than on a Blender render of a
Meshy mesh. That is the image-to-image-from-slices path in my proposal: it skips
the geometry-warping detour entirely and starts from pixels that are already at
literal spike fidelity, so drift starts near zero instead of having to be beaten
back down. Then keep agy on multimodal QA of the resulting kit against the spike,
which is where its harness is genuinely differentiated.

---

## Net for synthesis

- Composition should be sprites-on-grid (crisp at zoom, one contact cell per
  object, extensible to the walkable village), NOT a baked mosaic that blurs at
  zoom 2.0 and cannot depth-sort a returning PC.
- Recover codex's integration point by baking *micro-clusters* as single
  sprites where nothing occludes between members, instead of baking whole
  districts.
- Adopt codex's isolated-packaged-capture export audit verbatim; it is the
  strongest export gate proposed.
- Prefer 2D img2img conditioned on the spike's own slices over agy's 3D-render
  detour; keep agy as multimodal QA against the spike.
- Whoever owns the layout must budget a `docs/decisions/009-*.md` record for the
  `src/sim/town_layout.gd` change, and must NOT add an include glob to the
  protected `export_presets.cfg`, which already uses `all_resources` and needs no
  glob.

Co-authored-by: Claude <claude@sentania.net>
