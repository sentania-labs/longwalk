# claude-worker, round 005 phase-2 critique

Adversarial critique of both peer proposals for the isometric visual-identity
round. My proposal is `claude/005-proposal` at `adb79ab`. Peers:

- codex-worker: `codex/005-proposal` at `b42081c`
- agy-worker: `agy/005-proposal` at `35d7d34`

I verified claims against the integration base rather than trusting any of our
memories of it. Two facts up front, because all three of us tripped on them:

- **`ingest_kenney_roguelike.py` does not exist on the base.** It was dropped
  with the round-004 art slice when decision 007 rescinded the pack. `git
  ls-files tools/art/` returns nothing matching `ingest`.
- **`build_walk_comparison.py` and `capture_art_acceptance.gd` do not exist
  either.** The real files are `tools/art/check_walk_sheet.py` and
  `tools/art/capture_player_walk.gd`. My own proposal names both phantom files;
  so does codex; so does agy. I am not exempt from this finding, I am reporting
  it against everyone including me.

---

## codex-worker

### Steelman

The strongest version of codex's proposal is the one it actually wrote: the vibe
gap is a *shared-render-context* problem, and the fix is a generated coherence
master (a dressed in-world style board) that is then held visibly in frame for a
small number of category sheets, so palette, light vector, edge treatment, and
scale propagate from one authored anchor instead of being re-rolled per prompt.
Its implicit-but-correct premise, which makes it better than a bare "full sheet"
answer, is that the coherence lives in the *reference handoff*, not in the sheet
count: one giant atlas starves buildings and animation frames of pixels and
correlates extraction failure, so the board-plus-category-sheets structure is
the coherence mechanism minus the atlas's costs. On rigor it is the deepest of
the three: it is the only proposal that catches the camera-bounds defect (below),
the only one with a Y-sort tie-breaker, and the only one whose estimate is
honest about the day count.

### Where codex is right and I was not (concede)

1. **Camera bounds must come from the projected diamond corners, not
   `_layout.pixel_size()`.** codex is correct and this is the best single catch
   of the round. `camera_rig_2d.gd:19-24` and `:36-38` set `limit_*` and compute
   `min_zoom` from `_layout.pixel_size()` as an axis-aligned rectangle. Under iso
   projection the walkable diamond does not inscribe that rectangle, so those
   limits will either clip the map or expose void. My proposal said "clamped to
   the existing `limit_*` extents," which is simply wrong for iso. agy inherits
   the same bug and also does not address it. Concede to codex.

2. **Y-sort needs a stable secondary key for ties.** codex sorts on projected
   contact Y with "a stable secondary key derived from authored placement id for
   ties." Two objects on the same iso row have equal `x+y` and therefore equal
   projected Y; Godot's `y_sort_enabled` leaves that tie to tree order, which is
   not stable across a rebuild of the render tree. My proposal leaned on bare
   `y_sort_enabled` and never mentioned ties. codex thought about it; I did not.

3. **codex hedged the ingest file correctly.** "If `ingest_kenney_roguelike.py`
   exists on the integration base, replace it; if it was dropped, create only
   the generic entrypoint." That conditional is exactly right and my flat
   "delete and replace" is not. Concede.

### Attacks

1. **Two of codex's four "surviving pipeline" files do not exist.** Having
   hedged the ingest file, codex then asserts unconditionally that
   `build_walk_comparison.py` is "renamed `build_isometric_walk_preview.py`" and
   that `capture_art_acceptance.gd` "survives as a real-engine capture harness."
   Neither file is on the base (`git ls-files tools/art/`). There is nothing to
   rename and nothing to retarget; the real targets are `check_walk_sheet.py`
   and `capture_player_walk.gd`. The plan needs to name the files that exist or
   state it is authoring the preview/capture harnesses fresh.

2. **codex's own best catch undercuts its own division of labor.** codex argues
   camera bounds must be computed from the projected map corners, which requires
   the projection module, then assigns drag-pan/zoom/bounds to "the resident who
   owns the current camera rig" and projection integration to a *different*
   resident. That splits the bounds computation from the projection it depends on
   across two seats, which is precisely the cross-slice contract risk codex warns
   about for the art handoff. The bounds function is projection-side; the rig
   owner should consume it, not re-derive it. Either the projection owner hands a
   `projected_bounds()` function across a frozen contract (workable, but say so),
   or camera bounds live with the projection spine. codex leaves this coupling
   unowned.

3. **The 8-facing fallback is a mid-round method flip its estimate does not
   bound.** codex commits to "eight authored facings, no runtime mirroring" and
   "mirroring may be used only if declared in the manifest before generation,"
   then in Risks says if the one-facing spike fails it "would test a coherent
   four-facing sheet plus deterministic mirrored companions." That is a switch
   from 8-authored to 4-plus-mirror after generation has started, which is a
   different manifest and a different assembler contract, and it contradicts the
   "declared before generation" rule it just set. The estimate's "possible
   regeneration" line does not price a topology change; it prices re-rolls of the
   same topology.

4. **`generate2dmap ... y_sorted_props` plus a separate hand-built Y-sorted
   layer is double-sorting.** codex asks the map generator for `y_sorted_props`
   and *also* specifies "one Y-sorted world-object layer containing the player,
   flora, and buildings." If props are baked into the tilemap's own y-sort and
   buildings/player are nodes in a separate y-sorted layer, the two orderings do
   not interleave: a prop in the tilemap layer cannot sort between a player and a
   building in the node layer. Pick one Y-sort domain for everything that must
   depth-interleave with the actor.

---

## agy-worker

### Steelman

The strongest version of agy's proposal is that full-sheet coherent generation
is the *tightest* single coherence mechanism available (one physical render is
one palette, one light, one proportion system, with zero cross-invocation
drift), and that strict blind slicing (`row i -> facing i`, `col j -> frame j`,
regenerate-never-relaunder) is the cleanest possible answer to decision 006
ground 7's no-laundering rule, because it removes human frame selection from the
loop entirely. And its camera claim has a real basis I confirmed: agy authored
`camera_rig_2d.gd` (sole `Co-authored-by: Antigravity` on that file), so the
round-004 state-machine and input context genuinely lives in its head.

### Where agy is right and I was not (concede)

**8 facings, not my 4.** This is the tension I was told to test on the side I did
not pick, and testing it honestly turns up my own weak premise. I argued "the
diamond's four screen diagonals are the natural iso travel directions." But town
movement is dominated by walking along roads, and roads are grid-axis-aligned.
A pure grid `+x` step projects to a screen-space angle of `atan2(TILE_H/2,
TILE_W/2) = atan2(32, 64) ~= 27deg`, and my nearest diagonal facing is 45deg
(SE), so the character walks the most common path in the game permanently
~18deg off its facing, a constant low-grade skate. 8 facings put a pose within
22.5deg of every direction and land axis-aligned road movement much closer.
agy and codex are right that believability wants 8; my 4 optimizes the walk-sheet
cost at the expense of the exact motion the town spends most of its time doing.
Concede the target is 8.

### Attacks

1. **agy names three phantom files and hedges none of them.** "We will rename
   `ingest_kenney_roguelike.py`" (does not exist) and "the generic pipeline
   (`process_assets.py`, `build_player_walk.py`, `build_walk_comparison.py`,
   `capture_art_acceptance.gd`) survives untouched" (the last two do not exist).
   Of the three of us this is the least accurate reading of the base: unlike
   codex it does not hedge the ingest file, and it asserts two nonexistent files
   "survive untouched," which cannot be true of a file that is not there. The
   real files are `check_walk_sheet.py` and `capture_player_walk.gd`.

2. **The drag-pan has a concrete zoom bug and a concrete state bug.** agy: "when
   `pan_drag` is held, `_input(event: InputEventMouseMotion)` will subtract
   `event.relative` from the camera's screen-space `global_position`."
   - **No `/zoom` divide.** `event.relative` is in screen pixels;
     `global_position` is world units. The rig runs six zoom levels (0.5 to 2.0,
     `camera_rig_2d.gd:10`). At zoom 2.0 a one-screen-pixel drag must move the
     camera 0.5 world units, not 1.0. Without dividing by `zoom` the pan is
     wrong at every level except 1.0. codex and I both divide by zoom; agy does
     not.
   - **FOLLOW stomps the pan.** agy says dragging "will immediately break any
     active FOLLOW focus" but never changes state. `_process` runs `if _state ==
     State.FOLLOW and _player != null: position = _player.position`
     (`camera_rig_2d.gd:135-136`) every frame. Subtracting from `global_position`
     in `_input` while the state stays FOLLOW is overwritten on the next
     `_process` tick, so the drag does nothing. agy needs an explicit state
     transition (a DRAG state, or entering FOCUSED as codex does); asserting the
     break without implementing it is the whole bug.

3. **agy adds `pan_drag` on RMB without removing `focus_view`, which is already
   RMB.** `focus_view` is bound to `button_index:2` (right mouse) in
   `project.godot:70-74`. Binding a new `pan_drag` action to RMB leaves two
   actions firing on the same button. codex avoids this by reusing `focus_view`
   itself. agy's redundant action needs `focus_view` retired or it double-fires.

4. **The Isometric-TileMap-vs-hand-rolled-projection inconsistency is
   unresolved.** agy assigns claude to "wire up the Isometric TileMap" and refers
   to "the visual tilemap," while simultaneously hand-writing an inverse
   projection (`world_x = (screen_x/half_width + screen_y/half_height)/2`, which
   is algebraically correct, I checked). If the ground is a Godot `TileMapLayer`
   in engine iso mode, its projection is engine-defined and must match agy's
   hand-rolled inverse *exactly* or picking desyncs from what is drawn. agy lists
   this as its own risk #3 ("the isometric math to be perfectly aligned with the
   visual tilemap") but never says which projection is authoritative. codex and I
   both avoid this by projecting per-node with our own function and using no
   engine TileMap, so there is one source of truth. agy has two and does not
   reconcile them.

5. **Shadow grounding is delegated to the generator and is non-deterministic.**
   agy: "a secondary generated sheet for shadow masks (or extract a pure
   black/alpha layer if the generator provides it)." Decision 006 ground 6
   (STANDS per 007) is *preprocessed* masks under one shared light vector, i.e. a
   deterministic processor pass. "If the generator provides it" makes grounding a
   property of whatever the AI happened to emit, which will vary sheet to sheet
   and reintroduce the float defect this round exists to kill. codex bakes
   shadows in `process_assets.py` under one shared vector; I bake a silhouette
   mask offline. agy should too, not hope the generator supplies one.

6. **1 to 2 days for the whole round is not credible.** agy prices the entire
   round (8-facing generation, projection integration, shadows, drag-pan camera,
   iso picking, acceptance artifacts) at 1 to 2 calendar days, against codex's 6
   to 10 worker-days and my 3 to 5 engineer-days for the render spine *alone*.
   The gap is the Scott taste gate: generation is an iterate-until-accepted loop
   with no fixed day count, and agy's estimate does not contain it. agy's own
   blow-up line ("3 to 4 days" if full-sheet generation fails) already exceeds
   its own headline number, which tells you the headline is the best case priced
   as the expected case.

---

## Camera ownership: the technical argument (not a fairness claim)

The task asks for the technical case, so here it is stripped of who-deserves-it.
Drag-pan decomposes into two parts with different natural owners:

- **The input/state half** (RMB press-drag-release, threshold to distinguish
  click from drag, returning to FOLLOW) is tightly coupled to the round-004
  state machine in `camera_rig_2d.gd`, which agy authored. That half is small and
  agy has the context.
- **The bounds half** (clamping the pan to the map) *requires* the projected
  diamond corners, which only exist inside the projection module, as codex
  correctly established. That half cannot be written correctly without the
  projection spine.

So the honest answer is neither "I fold the whole camera into my render spine"
(my proposal overreached: the state machine is agy's and I gave no reason to
rewrite it) nor "agy owns the camera outright" (agy cannot compute correct iso
bounds without depending on the projection owner). The clean split is: the
projection owner exposes `projected_bounds()` and `screen_to_cell()` as a frozen
render-side contract, and the rig owner consumes them to implement drag and
clamp. That keeps one source of projection truth and lets agy keep the state
machine it wrote. I withdraw the part of my division-of-labor claim that swallows
the camera; I keep the projection module, the picking inverse, and the bounds
function, and agy keeps the rig that calls them.

---

## Constitution conformance

I checked all three against the load-bearing rules and found **no violation to
escalate**, so I am not phrasing any of the above as a VIOLATES claim:

- **Determinism / no stateful RNG in placement.** None of the three introduces
  `randf()`, `randi()`, or an order-dependent accumulator in placement. codex is
  explicit ("no `randf()`, no time seed," flora phase "a stable function of
  authored placement id"). agy introduces no RNG. Mine uses hash-of-cell. Clean.
- **Sim/render separation.** All three keep the projection and all screen
  coordinates render-side and state so explicitly (codex: "No projection symbol
  or screen coordinate enters `src/sim/`"; agy's picking is render-side; mine is
  `src/render/iso/`). None routes iso math through `src/sim/`. Clean. Note
  `TILE_SIZE` already sits in `src/sim/town_layout.gd:18` as a pre-existing
  pixel-space wart, but no proposal proposes touching it, so it is not a new
  violation by anyone.
- **Cross-platform / no em-dashes.** No proposal introduces platform paths or
  em-dashes.

The disagreements this round are engineering and division-of-labor calls for the
orchestrator to synthesize, not authority questions for Scott.

---

## Summary of the synthesis I would build toward

- **Generation:** codex's style-board-led category sheets, not agy's single
  full-sheet (starves buildings/frames, correlates extraction failure) and not
  bare per-family plates without a shared visible anchor. This is the strongest
  single idea in the round and it is codex's.
- **Facings:** 8, conceded, with the drift/identity cost both peers admit
  budgeted honestly, and the frame-selector committed as blind code before
  generation (all three agree here).
- **Camera:** split as above, projection owner exposes bounds + picking, rig
  owner (agy) implements drag against them; adopt codex's projected-corner
  bounds; fix agy's `/zoom` and state-transition bugs.
- **Y-sort:** adopt codex's placement-id secondary key over my bare
  `y_sort_enabled`.
- **Pipeline files:** name the files that exist (`check_walk_sheet.py`,
  `capture_player_walk.gd`, a new generic `ingest_*.py`), which none of the three
  proposals currently does.
