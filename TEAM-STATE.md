# TEAM-STATE

<!--
MACHINERY, NOT A CHANGELOG.

The orchestrator is ephemeral: spawned with an assignment, runs the protocol,
dies. Nothing it holds in memory survives. It reads this file first on every
run and rewrites it before exiting. That read/write cycle is the team's only
continuity between runs.

  - It is OVERWRITTEN. The durable record of a decision is
    docs/decisions/NNN-topic.md (append-only), not this file.
  - It describes the PRESENT, not the past. When an assignment finishes its
    state is REPLACED, not appended. History lives in git + decision records +
    refs/archive/NNN/*.
  - Humans read it, but it is a state dump the next run can act on, not a
    changelog.

Keep the heading structure stable (orchestrator + Dashboard parse by heading).
-->

## Current assignment

**ROUND 007: Two Rivers village at spike fidelity, free-cam, no PC/no NPC.
FULL PROTOCOL, four-ballot resolved 4-0 (Option H, decision 009).
EXECUTION: first district built + QA'd NOT-CONFUSABLE (ground/lane tile-grid is
the tell). NESTED FULL-PROTOCOL SUB-ROUND on the GROUND/LANE method:
DECISION 010 RESOLVED 4-0 + SIGNED + GATE-VALIDATED. NOW: IMPLEMENTATION.**

=== GROUND/LANE SUB-ROUND (this run) ==================================
Scope: `.pka/round007/ground-treatment/assignment.md`. Full protocol (agy ruled
ground a METHOD failure per decision 009 item 9; touches protected `src/sim/
town_layout.gd`; genuine 3-way method fork). Decision record = **010**.

**SYNTHESIS DONE THIS RUN. Decision 010 WRITTEN + SIGNED 4-0 + PUSHED + GATE-PASS.**
- Phase-2 critiques verified from end markers + tree (stamp `20260718-063941`, NOT
  the `070000` an earlier run planned): claude `39dbe3e`, codex `58a45dd`, agy
  `bd9182c` (all branch_changed=yes, exit0, no cap, no uncommitted; genuinely
  adversarial). Collected onto round branch (cherry-picks `838a577`/`f2d455f`/
  `1d09d08`).
- THE CRITIQUE ROUND CONVERGED, it did not split. codex (the phase-1 dissenter)
  CONCEDED its plate to fallback-only in its OWN critique doc; agy called claude's
  method "structurally superior to my own". So this was NOT a 2-2 contest.
- Decision 010 (`docs/decisions/010-ground-and-lane-treatment.md`) synthesized +
  committed `5b7b862`. Four-ballot on the contested method (shader-quad vs plate):
  orchestrator=shader-quad; doer ballots collected via ballot+sign dispatch (stamp
  `20260718-064830`, verified from markers+tree): claude `c9e0737` accept, codex
  `8b5c1c0` accept (residual plate preference recorded, non-constitutional), agy
  `ac559fe` accept. **TALLY 4-0. Critic NOT invoked (not 2-2). No constitution
  claim.** Signatures integrated `053906a` (real ts 06:48:34/46/54Z), PUSHED.
  `check_consensus.py` PASSES 010 (all 3 sigs, covers src/sim/).
- **THE DECISION (010):** primary = ONE continuous cell-space SHADER-QUAD ground
  plane. UV=cell-corners (affine, no screen->iso inversion); rectangular
  PROVEN-PERIODIC grass+dirt swatches (HARD prerequisite, >=8x8 contact-sheet
  gate at 0.5/1/2x); render-derived R8 lane mask from sim `ground` grid at K>1
  texels/cell; CPU-baked fixed-seed FastNoiseLite warp texture (NOT in-shader
  hash -- determinism); protected semantic lane core (central 0.5-cell unwarped,
  edge warp <=0.2 cell); textureGrad/textureLod for mip; separate contact-shadow
  layer (soft ellipses, agy defect #3). Grafts: codex semantic fingerprint as a
  test guard, codex offline guide may bake the warp texture. PLATE = explicit
  bounded fallback only if swatches fail the zoom gate. town_layout.gd stays
  texture-ignorant + viewport-free (read-only mask).
- **DoL (decision 010):** codex=asset production (swatches + CPU warp/mask baker
  + shadow_decal); claude=render integration (shader-quad in village_render.gd +
  .gdshader + runtime mask + lane core + contact-shadow layer + export-gate
  assertions + coordinate spike); agy=multimodal QA vs spike at 0.5/1/2x.

**SHARED INTERFACE CONTRACT (specified identically in both impl prompts):**
- codex assets under res://assets/village/: `ground_grass_tile.png`,
  `ground_dirt_tile.png` (rectangular, seamlessly tileable, POT e.g. 512x512),
  `ground_warp.png` (R8/RG8, e.g. 256x256, CPU-baked deterministic), `shadow_
  decal.png` (RGBA soft ellipse). Manifest entries: kind `ground_tile`/`ground_
  warp`/`shadow`, native_px==real dims, provenance slice|generated.
- claude .gdshader uniforms: `grass_tex`,`dirt_tex`,`warp_tex` (codex assets) +
  runtime `lane_mask` (claude-built ImageTexture from sim grid) + floats
  `tiles_per_cell`,`warp_amp`(<=0.2),`core_frac`(0.5). Both build blind in
  parallel against this contract; integration swaps codex real assets into
  claude's tree + re-runs gate (established pattern).

**IMPLEMENTATION DISPATCH state recorded under "Phase" below. Balance 2952
(zero-credit swatch synthesis attempted first; paid Meshy only if codex surfaces
a swatch-gate failure, orchestrator-supervised, NOT doer-spent).**

Root defect: `village_render.gd::_build_ground()` draws flat-color Polygon2D
diamonds per cell (GROUND_COLORS grass/tan + 3% jitter) = the checkerboard.
Contact shadows (agy defect #3) folded in; halo re-cut (agy defect #2) is a
SEPARATE fast-lane to codex, sequenced after.

**PHASE 1 (blind proposal) COMPLETE + VERIFIED from end markers + tree** (all off
5f1c5cc, branch_changed=yes, exit0, no cap, no uncommitted). Decision 010 cites
these SHAs:
- claude `9c841b57a69202277f38c0066467a89085ed7351` (`claude/007-ground-proposal`)
  -- ONE continuous shader-painted quad, UV=CELL coords (tiling grass/dirt swatches
  in ground space), render-derived R8 lane mask from sim grid, domain-warp + noisy
  threshold so lane edge wanders, separate contact-shadow layer. Sim untouched.
  Needs codex rectangular tileable swatches.
- codex `fec8b92fe51fdc00dfca25e0a9889d0310be2d88` (`codex/007-ground-proposal`)
  -- ONE frozen authored ~2048x1152 painterly PLATE. Offline lane-guide generator
  (projects PATH cells, hash wander), generated+hand-composited paint, SEMANTIC
  FINGERPRINT rejects stale paint. One Sprite2D. Render-side shadows.
- agy `4e51ff67033cbaf09272c5f7f34a67cb5b7dbb5c` (`agy/007-ground-proposal`)
  -- splat-mapped single ground plane, CanvasItem shader, per-cell blend-mask
  ImageTexture from sim grid, domain-warp wander, tile uniforms, shadow_decal
  layer. Flags screen->iso in-shader UV over the diamond PNGs as the brittle part.

THE SPREAD: claude + agy CONVERGED INDEPENDENTLY on the same method family
(continuous shader-quad + render-derived warped blend mask from the sim grid +
separate contact-shadow layer). codex DISSENTS with the frozen authored plate --
which carries the SAME 2x-zoom-blur + per-district-reauthor + 9MiB-scaling weakness
that sank its own Option G in decision 009. claude's UV=cell-corners trick also
directly answers agy's own flagged brittleness (screen->iso in-shader tiling). The
contested synthesis question: shader-quad (claude/agy) vs authored plate (codex),
and within the shader camp claude's UV=cell vs agy's screen->iso sampling.

**PHASE 2 (adversarial critique) SETUP DONE + DISPATCHED.** Proposals collected
onto round branch @ `b7acadf` (integration commit, PUSHED to origin). Each doer
worktree switched to `<prefix>/007-ground-critique` off b7acadf (all 3 proposals
present). Prompt: `.pka/round007/ground-treatment/critique-prompt.md` (each
critiques the OTHER TWO; "looks good" = failed round, send back). Dispatch detail
+ end markers recorded under "Phase" below. VERIFY from markers + tree, not
narration. NEXT after all 3 critiques land: collect onto round branch, four-ballot
synthesis, write decision 010, then implementation. Balance **2952** (no paid work
in a deliberation round).
======================================================================

Scott redefined the milestone (2026-07-18T03:30Z, via dalinar relaying req
c3ffe894; inbox `2026-07-18-0330-dalinar-vision-bar-answer-and-village-
milestone.md`). Goal, verbatim:

> "Build me Two Rivers in that style. No NPCs, no PC, just a disincorporated
> move around the map. Just show me you can build a full-on village in that
> style."

- The style/bar IS the spike itself: `docs/art/iso-five-asset-spike.png` (Scott:
  "the art style for the game is subject-2/town.png"; subject-2 == spike per the
  round-006 acceptance `_key.json`). Not a candidate, not a distance score.
  Produce the spike at village scale in the running game.
- Deliverable: a PLAYABLE Windows build, a FULL Two Rivers village at spike
  fidelity (cottages, inn/anchor building, dirt lanes, hedges, gardens, trees,
  flora, props, painterly ground; a real village, not five assets), NO PC and NO
  NPCs, navigated by a FREE ("disincorporated") camera (drag-pan/zoom, no follow
  target). Style test: screenshots confusable with the spike.
- Method UNMANDATED (Meshy available; use it, don't, or mix with NPR/hand-
  authoring; judged only on spike-indistinguishability).
- WALK CYCLE / ANIMATION IS OUT OF SCOPE this round (Scott dropped it; pure
  environment-art + free-cam proof).

Full scope + the five contested design questions: `.pka/round007/assignment.md`.
Phase-1 prompt (shared, all three doers): `.pka/round007/proposal-prompt.md`.

**MANDATORY carry-forward finding (solve this round, not one-off patched):**
authored art in a `.gdignore`'d tree loaded via raw `Image.load`/`FileAccess`
off `res://` is EXCLUDED by a stock Godot export, so a packaged `.exe` silently
ships default/placeholder art. Never caught because loaders only ran from source.
The village art WILL hit this. The build must be PROVEN from a packaged export
(or a standalone `.pck` in an isolated project), not just from source.

**Protected paths (forecast): YES** -- `src/sim/` (village layout data in
`town_layout.gd`), `export_presets.cfg` (export-safe inclusion), possibly
`project.godot`. Consequences automatic: full protocol; four-ballot on contested
synthesis, critic only on a 2-2 split; any PR touching these needs a signed
`docs/decisions/NNN-*.md`.

**Decision numbering:** on MAIN the ledger ends at 008, so round-007 decisions
start at **009**. Round 006's own 009/010 live ONLY in `refs/archive/006/*`
separate history and never merged to main -- no collision on main's canonical
ledger. Decision-010's render-scale math (32*sqrt(6) px/m upright) is reusable
reference if a proposal re-adopts it.

**Standing posture (directive 1500, reaffirmed by Scott's Q2 GO):** autonomous
multi-round iteration. "Burn the tokens, run rounds back to back, do NOT
stop-and-wait after every slice." Surface a playable build to Scott ONLY when
the team believes screenshots genuinely pass his "confusable with the spike"
bar, or on a real decision (constitution question, deadlock the critic can't
settle). Check `.pka/inbound/orchestrator/` at EVERY phase boundary.

## Phase

**GROUND/LANE SUB-ROUND: SYNTHESIS DONE (decision 010 signed 4-0, gate-pass).
NOW IMPLEMENTATION -- BOTH SLICES DISPATCHED + IN FLIGHT (detached).**

Phase 1 + phase 2 complete + verified (SHAs in the sub-round box above). Decision
010 written, four-ballot 4-0, signed, integrated `053906a`, pushed,
check_consensus PASS. Full synthesis detail in the "GROUND/LANE SUB-ROUND" box.

**IMPLEMENTATION (stamp `20260718-065409`) -- BOTH SLICES LANDED + VERIFIED from
end markers + tree. Off signed round head `053906a`:**

- **claude RENDER slice DONE + VERIFIED + SUITE GREEN (orchestrator ran it).**
  `claude/007-ground-impl` @ **`54a7ce2`** (end marker: exit0, branch_changed=yes,
  no cap, no uncommitted, 623s). Delivered: `src/render/town/ground.gdshader` (90
  lines), `village_render.gd` shader-quad rewrite (+187: continuous quad,
  UV=cell-corners, runtime R8 lane mask from sim grid, domain warp, protected lane
  core, contact-shadow layer), `test/active_path/test_ground_uv_spike.gd` (143-line
  coordinate spike), export-gate shader/decal assertions, `village.tscn`,
  provisional PLACEHOLDER swatches/warp/decal. **Suite GREEN on its tree**: UV
  spike PROVEN (max err ~0, both triangles agree across shared diagonal) + all 19
  village-render checks. Render code is sound. Placeholders are flat; the REAL
  look needs codex's periodic swatches (below), so QA waits on the swatch.

- **codex ASSET slice DONE + VERIFIED, but SWATCHES FAILED THE GATE (honest).**
  `codex/007-ground-impl` @ **`d3ba799`** (end marker: exit0, branch_changed=yes,
  no cap, no uncommitted, 280s). Delivered the deterministic FastNoiseLite warp
  baker + `ground_warp.png` (GOOD), `shadow_decal.png` (GOOD), manifest entries,
  tests, contact sheet + acceptance doc. BUT both `ground_grass_tile.png` /
  `ground_dirt_tile.png` FAILED codex's own 8x8 contact-sheet gate: a recurring
  DIAGONAL weave, reads as fabric not painterly ground. **Orchestrator verified
  the contact sheet directly -- the FAIL is correct.** codex filed
  `.team/blocked/codex-worker-20260718T065655Z.md` requesting resolution. Root
  cause: frequency-domain phase synthesis randomizes phase over the crop's
  directional frequencies => manufactures a regular weave + kills painterliness.

- **SWATCH RE-DISPATCH (orchestrator decision, ZERO-CREDIT, NOT paid):** balance
  re-verified **2952** (meshy_check_balance) -- I did NOT spend; paid Meshy at the
  tail of a long run is against the durable lesson, and a naive paid img2img won't
  produce a SEAMLESS tile anyway. The right fix is OFFSET-AND-HEAL seamless
  synthesis (preserves organic painterliness, heals only the seam cross, no global
  regular structure). Re-dispatched codex on its SAME branch `codex/007-ground-
  impl`: stamp **`20260718-070615`**, DETACHED, cap 2400s, label
  `codex-ground-swatch-v2`. Prompt: `.pka/round007/ground-treatment/impl-codex-
  swatch-v2-prompt.md`. End marker: `lw-007-codex/.team/markers/codex-ground-
  swatch-v2-20260718-070615-end.md`. Start marker + proc confirmed alive.
  If offset-and-heal ALSO fails (spike crops too small/low-detail), codex updates
  the blocked marker asking for a HIGHER-RES painterly SOURCE; THEN (and only then)
  orchestrator runs ONE supervised paid image gen (verify billing first) and hands
  it back for codex to offset-and-heal. Doer never spends.

**NEXT (poll swatch-v2 end marker; verify from marker+tree+the NEW contact sheet,
not narration):**
1. If swatch-v2 PASSES (organic, no repeat axis, crisp at 2x) + blocked marker
   deleted: cross peer sign-off (claude, non-author) of codex's final asset
   commit AND agy or claude sign-off of claude's render `54a7ce2` (non-author each).
2. Integrate BOTH slices onto `round/007-village` (--no-ff, reviewed SHAs
   preserved). Both touch the SAME asset paths (swatch/warp/decal) + claude's
   placeholders -- codex's REAL swatches must WIN over claude's placeholders in the
   integrated tree (drop claude's `village_placeholder_assets.py` outputs for the 4
   ground assets; keep claude's shader/render/test). Decision 010 covers the
   protected `src/sim/` read coupling (village_render reads `ground`).
3. RE-RUN the honest export gate on the integrated tree (now asserts shader +
   shadow_decal + swatches + warp resolve from the isolated PCK) + full suite.
4. agy multimodal QA at 0.5/1/2x vs spike -- SPECIFICALLY re-adjudicate the ground
   tell. If NOT-CONFUSABLE again, iterate (decision 010 step 10). If CONFUSABLE,
   THEN expand toward the full ~12-16-structure village + open the ONE round PR +
   external Codex review. Do NOT surface to Scott until the team believes a
   screenshot passes the confusable bar.

**Peer sign-off still owed on decision-010 impl commits before the round PR:**
claude render `54a7ce2` (needs non-author sign-off), codex final assets (needs
claude non-author sign-off). Neither signed yet.

Prior execution state (below) is still true: first real-art district COMPLETE +
QA'd NOT-CONFUSABLE, round branch history preserved. The ground/lane tile-grid is
the confirmed dominant tell; this sub-round picks the method to fix it (010).**

The whole processing->integration->gate->QA loop closed this run, all verified
from end markers + tree + real gate runs. The buildings ARE spike-fidelity; the
scene FAILS the confusable bar on GROUND rendering, not on the objects. This is
exactly decision 009 item 9's "method failure at the gate changes the METHOD,
not the count."

**agy QA VERDICT (`docs/art/village/qa-agy-inn-green-001.md`, on round branch),
3 ranked defects for the next iteration:**
1. **Ground/paths (DOMINANT):** hard checkerboard of flat green diamond tiles +
   solid tan diagonal path bands, vs the spike's continuous organic painterly
   grass + soft worn dirt trails. No blending/transition. This is THE tell.
2. **Halo cutouts on sliced props:** bushes/flowers/signpost (sliced from the
   spike) retain harsh polygonal chunks of the spike's terrain background around
   them, clashing with the flat tiles. (Asset-quality bug; re-cut with the border-
   flood-fill that already worked on the buildings. Near fast-lane.)
3. **Missing contact shadows + sparse gridded composition:** objects float; the
   spike's tight organic cluster is replaced by grid-aligned placement.

**NEXT-ITERATION TRIAGE (for the next run):** defect 1 (ground) is a real design
fork -- continuous painterly ground plate vs blended/painterly overlapping tiles
vs hybrid -- so it is FULL PROTOCOL (blind proposal / critique / synthesis), and
touching the ground renderer likely re-touches `src/sim/town_layout.gd` +
render, so a decision record (010) is in play. Defects 2 (re-cut halos) and 3
(contact-shadow render pass) can ride as scoped slices once the ground method is
chosen, or 2 can be fast-laned to codex independently. Do NOT expand to the full
~12-16-structure village until a district passes the confusable bar. Do NOT
surface to Scott until the team believes a screenshot genuinely passes it.

=== THIS RUN (post-paid-pass) -- all verified from markers + tree + real gate runs ===

- **Balance re-verified 2952** (meshy_check_balance), exact match. NO paid work
  this run (processing/review/gate/QA all zero-credit).
- **codex processing slice `5a70f178...` VERIFIED** (end marker codex-process-gen-
  20260718-060035: exit0, branch_changed=yes, uncommitted=no, 547s). Replaced 6
  magenta placeholders with real RGBA sprites from the paid Meshy raws (staged
  `tools/art/generated_src/*.src.png` + provenance.json), added `process_assets.py`
  (border-flood-fill bg removal + autocrop), updated test_art_manifest.py. Manifest
  honest: 6 flipped to `generated`, native_px == real dims exactly.
- **PEER SIGN-OFF DONE (claude, non-author):** claude review `6311c4c` on
  `claude/007-village-render`, marker `.team/signoffs/codex-007-village-assets-
  5a70f178e88f.md`, result **signed-off**. Genuine review: decoded all 6 PNGs,
  confirmed NO punched-through alpha in grey-stone buildings, border flood-fill in
  code (not global key), dims match, anchors bottom-centre, provenance honest,
  export hygiene clean, tools/run_tests.sh green.
- **INTEGRATED onto `round/007-village`:** merge `69d3ac9` (--no-ff of 5a70f17,
  reviewed SHA preserved) + cherry-pick `af34077` (signoff marker) + captures
  `30b75c5`. 5a70f17 touches NO protected paths. **Round head `30b75c5` PUSHED.**
- **HONEST EXPORT GATE RE-RAN + PASSED on all 16 real assets** (orchestrator ran it
  as integration verification; script+audit already committed/reviewed):
  `VILLAGE_GATE_PASS` + `VILLAGE EXPORT GATE PASSED`. 16/16 resolve through
  ResourceLoader from an isolated `.pck` (non-repo cwd), 4 landmarks project at
  0.5x (all IN), 1x (all IN), 2x (2 IN / 2 scroll off-viewport -- expected for a
  zoomed-in free-cam; gate still PASS), non-mutation guard clean. Fresh captures
  `docs/art/village/village-inn-green-{0.5x,1x,2x}.png` committed @ 30b75c5.
- **FULL SUITE GREEN on integrated tree** (19 village-render checks + all
  active-path suites): manifest join 16/16, crown sorts above, no CharacterBody2D,
  camera starts FREE with no follow target.
- **ORCHESTRATOR VISUAL READ (1x capture vs spike):** buildings (half-timbered
  cottages, mossy slate roofs, stone foundations, 2-story inn + hanging sign,
  smithy w/ anvil+grindstone+forge, painterly oak, bush/flower/rock clusters) are
  genuinely spike-idiom -- a real achievement. DECISIVE GAP: the GROUND is a hard
  isometric diamond TILE GRID (alternating light/dark checkerboard) and the lanes
  are straight diamond-band tiles, vs the spike's CONTINUOUS painterly grass +
  organically-worn soft dirt trails. Also: objects may lack the spike's soft
  contact shadows (float risk), grass more saturated/flat, composition sparser
  than the spike's tight cluster. => NOT yet confusable. Below the bar.
- **agy QA DONE + VERIFIED (agy's FIRST execution dispatch, `b438beb` on
  `agy/007-qa`, end marker agy-qa-district-20260718-062218: exit0, branch_changed,
  uncommitted=no, 63s).** Genuine multimodal work (defects are specific to the real
  captures, not a no-op): **VERDICT NOT-CONFUSABLE** + 3 ranked defects (above) +
  method-update section, and signed decision 009 @ 2026-07-18T06:22:51Z.
- **agy QA + 009 sig INTEGRATED onto round branch** (merge, --no-ff). **All 3
  decision-009 sigs now present** (claude 05:25:08Z, codex 05:03:08Z, agy
  06:22:51Z) -> consensus gate satisfiable for the eventual round PR. **Round head
  `5f1c5cc` PUSHED.**
- **HYGIENE:** leak guard OK (no doer branches on origin; only round/007-village),
  zero open PRs (correct -- round PR opens only when a district passes the bar).

=== PRIOR (paid pass, still true) ===

**FIRST PAID PASS DONE (6/6 objects generated, 18 credits, ACCEPTED).**

=== SUPERVISED FIRST PAID PASS: COMPLETE (this run) ===

Generated all 6 `generated-pending` objects via Meshy image-to-image (Option H,
decision 009), each conditioned on a spike-derived style crop. Method validated
by a single 3-credit probe (cottage_front) BEFORE batch spend; probe passed
(clean isolated spike-fidelity cottage on flat grey), so batched the other 5.

- Model **nano-banana** (3 cr/call). **18 credits total.** Balance **2970 -> 2952**
  (verified via meshy_check_balance both before and after; exact match, no leak).
- NO PENDING/IN_PROGRESS tasks before spend (verified meshy_list_tasks: all prior
  SUCCEEDED); no stray dispatch proc. No double-spend.
- All 6 ACCEPTED on my visual judgment vs the spike (I Read each PNG): inn
  (two-story, hanging sign, tall chimney), smithy_cluster (anvil+grindstone+open
  forge bay), cottage_front, cottage_rear (plain gable back, no door),
  crown_foliage (dappled oak canopy, no trunk), fence_section (mossy post-and-rail).
  Every one is genuinely confusable with the spike's painterly idiom.
- **Durable artifacts (raw Meshy URLs EXPIRE ~20min, these downloads are the ONLY
  copies -- do NOT regenerate, that double-spends):**
  - `.pka/round007/generated/*.png` (6 raw RGB 1024x1024 on flat grey) +
    `provenance.json` (task ids, credits, ref crops, spike boxes, balances).
  - `.pka/round007/generated-backup/` (identical backup copy, insurance).
  - `.pka/round007/style-crops/*.png` (5 spike crops used as img2img references).
- Task IDs: cottage_front 019f73c9-0b57-7ae2-b7e7-aaf2f4b0e1b1; inn
  019f73ca-9820-7b39-b712-cee433e2af4b; cottage_rear 019f73ca-2d9e-7495-a687-c3d12bf13934;
  smithy_cluster 019f73ca-3954-70a6-a8f0-da818a14ea26; crown_foliage
  019f73ca-4513-749b-94a0-b7b75a9062a5; fence_section 019f73ca-4d61-749c-b0ff-4049d57bd9d1.

DIVISION note: I (orchestrator) ran the paid generation DIRECTLY as the supervised
first spend (my explicit mandate: per-object cost-confirm, watch balance,
double-spend guard). This is art generation, not code authoring. codex retains
asset-production authority: it JUDGES/processes each candidate into a game-ready
RGBA sprite and authors the manifest/asset repo change (below).

=== NEXT (dispatched / to dispatch this run) ===

**IN FLIGHT (this run):** codex dispatched DETACHED to process the candidates
(label `codex-process-gen`, stamp `20260718-060035`, cap 1800s, worktree
`lw-007-codex`). Prompt: `.pka/round007/codex-process-generated-prompt.md`. Raws
staged at `lw-007-codex/tools/art/generated_src/<id>.src.png`. Poll end marker
`lw-007-codex/.team/markers/codex-process-gen-20260718-060035-end.md`; verify
branch_changed + tree, not narration. If dead, re-dispatch is SAFE (no spend;
reproducible). Do NOT re-run Meshy.

1. **codex (asset seat):** process the 6 staged RGB candidates in
   `.pka/round007/generated/` into game-ready RGBA sprites -- BORDER FLOOD-FILL bg
   removal (NOT global grey key: buildings contain grey stone; a global key punches
   holes), autocrop to content bbox, size sensibly for the iso grid; set manifest
   `native_px` == the ACTUAL final PNG dims (claude's gate asserts equality) and a
   correct `anchor_px` (ground-contact: bottom-centre for buildings, attach point
   for crown); overwrite `assets/village/<id>.png`; flip `provenance` to
   `generated` with source metadata. Commit on `codex/007-village-assets`.
2. Peer sign-off (claude or agy, non-author) of codex's asset commit.
3. Integrate onto `round/007-village`; claude RE-RUNS the honest export gate on the
   real generated assets; agy multimodal QA the 0.5/1/2x capture vs the spike.
4. Only if the district capture passes the confusable-with-spike bar do we expand
   to the full ~12-16-structure village.

=== EARLIER (zero-credit rig, still true) ===

=== WHAT IS DONE (this run, all verified from end markers + tree + a real gate run) ===

The first inn-green district's whole PIPELINE is built, peer-reviewed, integrated
onto `round/007-village`, and PROVEN from an isolated packaged export against REAL
sliced assets, at ZERO credits. Round branch head **`5a42736`** (pushed to origin).

- **Integration commit chain on `round/007-village`:** bc80b4d (decision 009) ->
  15803d2 (merge claude render c164ef7) -> 200af94 (merge codex assets 019bbd9,
  real assets win over claude's provisional, 009 sigs resolved) -> 5a42736 (honest
  real-asset gate proof captures).
- **Suite GREEN** on the integrated tree: all active-path suites + 19 village-render
  checks (16 placements join manifest, crown sorts above, no CharacterBody2D,
  camera starts FREE with no follow target).
- **HONEST export gate PASSED on codex's REAL assets:** `tools/art/
  village_export_gate.sh` exported a `.pck` (stock Windows preset, all_resources),
  ran it headless from a non-repo temp dir with NO source tree, and 16/16 manifest
  assets resolved through ResourceLoader with declared dims; 4 landmarks project at
  0.5/1/2x; non-mutation guard confirms `assets/village/` unchanged by the run. The
  round-006 carry-forward finding (packaged builds silently shipping default art)
  is CLOSED with a non-self-defeating gate. Captures: `docs/art/village/village-
  inn-green-{0.5x,1x,2x}.png` show real sliced art (painterly tree, flower/bush
  clusters, rocks, sign_post) on the iso grid with the lane junction, plus 6 MAGENTA
  placeholder triangles marking the generated-pending objects.
- **Signatures on decision 009:** claude 2026-07-18T05:25:08Z, codex
  2026-07-18T05:03:08Z (both real, on the round branch). agy STILL PLACEHOLDER
  (signs at QA time; consensus gate needs it before the round PR merges to main).

Balance still **2970**, zero PENDING/IN_PROGRESS Meshy tasks. NO paid Meshy spent
this run (the whole rig was proven at zero credit, decision 009's judge-then-spend
inversion). This is a clean milestone: I deliberately did NOT start the first paid
spend at the tail of a long run (mid-spend is the worst place to die; the paid pass
needs a full turn for proper supervision).

**BOTH EXECUTION SLICES COMPLETE + VERIFIED from end markers + tree (not
narration). Cross peer sign-offs IN FLIGHT.**

- codex asset slice: `codex/007-village-assets` @ **`019bbd9d6f89c2ea2db6bc03b17527713d5f446c`**
  (worktree `lw-007-codex`). exit0, branch_changed=yes, uncommitted=no, cap ok.
  17 PNGs + `assets/village/manifest.json` + `process_assets.py` extension +
  codex's real 009 signature (2026-07-18T05:03:08Z). Principled bucketing (applied
  its own phase-2 occlusion critique): SLICED 10 (ground_grass, ground_lane,
  tree_large, bush_a/b, sign_post, rock_a/b, flower_cluster_a/b); deferred 6 to
  `generated-pending` placeholders (cottage_front, fence_section, inn,
  cottage_rear, smithy_cluster, crown_foliage). VERIFIED all 16 PNG pixel dims ==
  manifest native_px (0 mismatches), so codex assets will pass claude's gate.
- claude render slice: `claude/007-village-render` @ **`17611ace779a2a9fce1e99744d5b89e7c4d72390`**
  (worktree `lw-007-claude`). exit0, branch_changed=yes, uncommitted=no, cap ok.
  `build_inn_green_district()` (texture-ignorant DistrictPlacement) + `scenes/
  village.tscn` + `village_render.gd` (manifest-join, anchor_px, depth_key, crown
  band) + `setup_free()` no-PC free-cam (FOLLOW path untouched) + projection
  4-landmark reg + `tools/art/village_export_gate.sh`/`village_export_audit.gd` +
  Image.load ban + claude's real 009 signature. **EXPORT GATE RAN TO COMPLETION +
  PASSED: 16/16 assets resolved from an isolated packaged .pck (non-repo cwd),
  landmarks project at 0.5/1/2x, captures non-blank** in `docs/art/village/
  village-inn-green-{0.5x,1x,2x}.png`. tools/run_tests.sh PASSES. Gate runs capture
  under `xvfb-run` (dummy --headless never fires frame_post_draw); isolation is the
  packed bundle + non-repo cwd, not the flag. NOTE: claude committed PROVISIONAL
  placeholder assets (`village_placeholder_assets.py`) since codex's manifest was
  not on its branch; INTEGRATION overwrites `assets/village/` with codex's REAL
  assets + manifest and RE-RUNS the gate.

Shared kit-id contract + runtime manifest schema were specified identically in
both prompts and lined up. Env: Godot 4.3 `tools/godot/godot`, 4.3.stable templates
installed, `export_presets.cfg` uses `all_resources` (no glob edit).

**Sign-offs dispatched (parallel, detached, cap 1200s, stamp 20260718-053416):**
codex reviews claude's `17611ac` (marker on `codex/007-village-assets`); claude
reviews codex's `019bbd9` (marker on `claude/007-village-render`). Markers ride
each reviewer's branch into integration. Prompts:
`.pka/round007/signoff-{codex-reviews-claude,claude-reviews-codex}-prompt.md`.

**SIGN-OFF OUTCOME (peer review did its job, caught a real defect):**
- claude reviewed codex `019bbd9`: **signed-off** (marker on `claude/007-village-
  render` @ `9ed400a`; verified pixel dims 16/16, provenance honesty by decoding
  PNGs, export hygiene). codex assets are integration-ready.
- codex reviewed claude `17611ac`: **CHANGES-REQUESTED** (marker on `codex/007-
  village-assets` @ `bcf02d9`). Genuine defect: `village_export_gate.sh` line ~47
  runs `village_placeholder_assets.py` before every export, which REWRITES all of
  `assets/village/` incl `manifest.json`. So post-integration the gate would
  overwrite codex's REAL assets with placeholders and audit the placeholders,
  defeating decision 009 item 2. claude's "16/16 pass" only held vs its own
  regenerated placeholders. Confirmed against the script directly.
- **FIX LANDED:** claude `c164ef7` "export gate audits committed assets, never
  regenerates them" (dropped the regen, fail-loud on missing manifest, non-mutation
  guard). Gate re-ran green + guard confirmed unchanged.
- **RE-REVIEW LANDED:** codex re-reviewed `c164ef7`, **signed-off** (marker
  `.team/signoffs/claude-007-village-render-c164ef720322.md` on `codex/007-village-
  assets` @ `54e3811`; deleted the stale changes-requested marker for 17611ac).
- **INTEGRATED + PROVEN** (see "WHAT IS DONE" above): round branch @ `5a42736`.

=== NEXT: SUPERVISED FIRST PAID PASS (the first real Meshy spend -- SUPERVISE) ===

Generate the 6 `generated-pending` objects and replace their magenta placeholders:
**`inn`, `cottage_front`, `cottage_rear`, `smithy_cluster`, `crown_foliage`,
`fence_section`** (per manifest; note codex deferred cottage_front + fence_section
as not honestly sliceable). Method per decision 009 Option H: **image-to-image
conditioned on an ACCEPTED spike-derived style crop** (the `meshy` MCP is live;
`meshy_image_to_image`, nano-banana 3 / nano-banana-2 6 / nano-banana-pro 9 /
gpt-image 9-12 credits per call -> ~18-72 credits total, cheap). This is codex's
asset-production seat.

SUPERVISION discipline (paid, first spend, balance 2970):
- Before ANY relaunch, `meshy_list_tasks` to confirm no PENDING/IN_PROGRESS task
  (a second launch into the same work = double-spend). Cost-confirm every paid
  call. NEVER pass `save_to` to `meshy_download_model`. Watch the balance delta.
- First establish an ACCEPTED spike style crop (from `docs/art/iso-five-asset-
  spike.png`) as the conditioning reference; each generated object gets a per-object
  provenance manifest entry (`provenance: generated`, the source crop + prompt).
- Each generated PNG must keep its manifest `native_px` == real dims (claude's gate
  asserts this) and a correct `anchor_px`. Overwrite `assets/village/<id>.png` +
  flip `provenance` to `generated` in `manifest.json`.
- Then: peer sign-off (non-author), integrate onto the round branch, RE-RUN the
  honest export gate, and **agy multimodal QA** the capture vs the spike at
  0.5/1/2x (agy's first dispatch; agy then signs decision 009 with a real ts).
- Method failure at this gate changes the METHOD, not the count (decision 009 item
  9). Only once the district capture passes the confusable-with-spike bar do we
  expand to the full ~12-16-structure village, then open the ONE round PR + external
  Codex review, address findings, merge, sweep.
- Surface a build to Scott ONLY when the team believes screenshots genuinely pass
  his "confusable with the spike" bar. NOT yet (6 magenta placeholders remain).

<!-- prior phase history retained below for the record -->

**PHASE 1 (blind proposal) COMPLETE + verified. PHASE 2 (adversarial critique)
DISPATCHED + IN FLIGHT.**

Phase-1 proposals, all committed clean (branch_changed=yes, uncommitted=no,
exit0, cap_expired=no), verified from markers + tree. Full SHAs (decision record
009 cites these):
- claude `cc83cb956d052880a65de9ea9254f7b8668e2606` (`claude/007-proposal`) --
  SLICE THE SPIKE: cut the spike's own pixels into anchored iso sprites on the
  grid (zero-credit, spike-fidelity by construction); optional image-to-image
  variants conditioned on the slices (<=45 credits, not load-bearing). Diagnoses
  round-006 failure as a MEDIUM MISMATCH (3D-render can't reconstruct
  painterliness). Composition = sprites-on-grid. Free-cam = `setup_free()` +
  sibling village scene. Export-safe = res://assets/village + .import + packaged
  verify.
- codex `17d30086bee1a34b9d0124753fcf96917c4491ef` (`codex/007-proposal`) --
  GENERATED PAINTERLY DISTRICTS: freeze an art brief + blockout from the spike,
  generate 6 overlapping 2048px painterly district PLATES via `tools/art` 2D
  generation, assemble a master mosaic, extract only occlusion-crossing objects
  as separate layers. Argues AGAINST independent sprites ("stickers"). Meshy/
  Blender = composition-guide fallback only. Free-cam + export-safe converge with
  claude.
- agy `87d4550800e23ab4feb12f941445ced740a7e8c0` (`agy/007-proposal`) -- 3D->2D:
  Meshy 3D base models (20-40 credits) through the round-006 Blender iso render
  pipeline to sprites on the grid, stylized/img2img for painterliness.
  Composition + free-cam converge with claude; export-safe lighter (standard
  load + a static Image.load ban).

THE SPREAD (why phase 2 matters): art METHOD is a genuine 3-way fork (slice /
generate-plates / 3D-render). Note agy's 3D-render is the SAME FAMILY that missed
the spike bar TWICE in round 006 (claude's central argument). Composition is 2-1
(claude+agy sprites-on-grid vs codex plates). Free-cam and export-safe SHAPE are
near-consensus. The contested synthesis question is method + composition.

**Phase-2 setup done:** collected all three proposals onto `round/007-village`
(orchestrator integration commit `1ed5b15`, pushed); switched each doer worktree
to a `<prefix>/007-critique` branch off that commit (all three proposals visible
in each). Critique prompt `.pka/round007/critique-prompt.md` (each doer
critiques the OTHER TWO; "looks good" = failed round, send back). Dispatched
DETACHED at run stamp `20260718-043522` (worktrees `/home/scott/claude/lw-007-
{claude,codex,agy}`, on `<d>/007-critique` branches).

**PHASE 2 COMPLETE + verified** (all clean from markers + tree; a genuinely
adversarial round, not "looks good"). Critique SHAs (decision 009 cites these):
- claude `e30bee2e44d91f024987a36fbb0553aeb8586fe4` (`claude/007-critique`)
- codex  `0c2914866d32f11bafb229da998097c12eeedbb6` (`codex/007-critique`)
- agy    `dcc696d5ffd36d08a65b30601b807fa33e4247d4` (`agy/007-critique`)
Proposals + critiques collected onto `round/007-village` @ `6ab2f4a` (pushed).

**PHASE 3 COMPLETE. Four-ballot resolved 4-0 for Option H (hybrid graft).
Decision record 009 WRITTEN + pushed to the round branch @ `bc80b4d`
(`docs/decisions/009-village-art-method.md`).** My full synthesis working doc:
`.pka/round007/synthesis-and-ballot.md`.

Ballot SHAs (all voted H, all accepted their DoL slice, NO constitution-violation
claim; critic NOT invoked since not 2-2):
- claude `e2ab0c3819e77dbe5d75dab1ac470f8c0f0fffb7` (voted AGAINST its own Option
  S: "codex's occlusion critique is correct, it is decisive")
- codex  `10e0d69ddc8ba2cea9df417799e94337929ea162`
- agy    `828296b88f810a66320408544618671da6b71ac9`

**Decision 009 (4-0 Option H):** ship cleanly-separable unoccluded spike objects
as sliced sprites (zero-drift, zero-credit floor); generate COMPLETE RGBA objects
via image-to-image conditioned on an accepted spike-derived style crop for
everything occluded/net-new; MANDATORY first-district gate at 0.5x/1x/2x + four-
landmark projection.gd registration BEFORE any batch spend. Plus the converged
rulings (sprites-on-grid, codex's isolated-packaged export audit, source PNGs
under res://assets/village, town_layout viewport-free, explicit setup_free(),
drop 3D-render-as-primary, agy Image.load ban + multimodal QA, micro-cluster
baking, first-buildable = one inn-green district). DoL: codex=asset production,
claude=render integration + town_layout + free-cam, agy=multimodal QA.
Protected paths the record authorizes: `src/sim/`, `export_presets.cfg`,
`project.godot`.

CONVERGED after critique (I rule directly, no ballot; captured in the synthesis
doc): (1) sprites-on-grid composition, NOT plates (codex conceded; agy's sim/
render-separation + ecology-roadmap critique decisive); (2) codex's isolated-
packaged-capture export audit adopted verbatim + claude's non-placeholder assert;
(3) commit SOURCE PNGs under res://assets/village (NOT .import sidecars -- repo
gitignores `*.import`/`.godot/`), engine `--headless --import` then export, do
NOT glob the protected export_presets.cfg (uses all_resources); (4) town_layout.gd
stays viewport-free + texture-ignorant, decision 009 for the edit; (5) explicit
setup_free() no-PC free-cam, FOLLOW path preserved; (6) DROP 3D-Meshy-render as
primary (twice-failed round-006 family; Meshy not wired for agy anyway), keep
Blender/scale-contract as optional guide; (7) agy Image.load static ban + agy on
multimodal QA; (8) micro-cluster baking; (9) first-buildable = ONE inn-green
district at final pixel density proven from isolated packaged export, landmark-
registered at 0.5x/1x/2x.

CONTESTED (the four-ballot): **primary pixel-production method** -- Option S
(slice-first, claude), Option G (generate-first, codex), Option H (hybrid graft,
ORCHESTRATOR BALLOT = H). Provisional DoL: codex=asset production, claude=render
integration + town_layout + free-cam, agy=multimodal QA.

**NEXT (execution phase kickoff):**

1. **Collect the 3 doer signatures on decision 009** (protected-path record; the
   consensus gate reads `Signed-off-by:` lines from claude/codex/agy-worker with
   REAL UTC timestamps, currently placeholders). Mechanism: dispatch each doer to
   read 009 and, if it accepts, replace ONLY its own placeholder line with a real
   timestamp + commit (each on a signoff branch off the round head, or sequential
   into `lw-007-round`; then orchestrator integrates/pushes the round branch).
   Their ballots already attest acceptance, so this is near-formality, but the
   gate needs the literal signed lines before the round PR can merge. Can also be
   folded into each slice's dispatch (a dispatched worker reads + signs 009 as it
   picks up its slice).
2. **Implementation slices** (per decision 009 DoL, off the round branch, peer
   sign-off by a non-author, local --no-ff integration, ONE round PR at the end):
   - START with the FIRST-DISTRICT GATE (decision 009 item 9 + the Option-H
     pre-spend gate): codex produces ONE inn-green district's worth of assets
     (slice the unoccluded spike objects; generate the few occluded/net-new ones
     via image-to-image conditioned on a spike style crop -- this is the FIRST
     PAID Meshy point, SUPERVISE it: verify prior attempt dead + no duplicate
     billable work before any relaunch, NEVER pass save_to to
     meshy_download_model, cost-confirm, balance 2970 -> watch); claude wires the
     village scene + setup_free() free-cam + expanded town_layout.gd (under 009) +
     res://assets/village export-safe loading + the isolated-packaged export
     audit; agy multimodal-QA the district capture against the spike at 0.5x/1x/2x.
   - The district must PROVE from an isolated packaged export (not source) and be
     landmark-registered to projection.gd BEFORE any batch spend on more
     districts. Method failure at this gate changes the method, not the count.
   - Only after the district passes the confusable-with-spike bar do we expand to
     the full ~12-16-structure village, then open the ONE round PR + external
     Codex review, address findings, merge, sweep.
3. Surface a build to Scott ONLY when the team believes screenshots genuinely
   pass his "confusable with the spike" bar (directive 1500 posture).

**Live worktrees + branches (all LOCAL; only `round/007-village` is on origin):**
- `lw-007-round` on `round/007-village` @ `5f1c5cc` (integration tree, pushed;
  all real art + gate captures + all 3 decision-009 sigs + agy QA).
- `lw-007-claude` on `claude/007-village-render` @ `6311c4c` (render + gate fix +
  its signoff of codex processing 5a70f17 + claude 009 sig). Reuse next.
- `lw-007-codex` on `codex/007-village-assets` @ `5a70f17` (real assets + manifest
  + process_assets + processed generated sprites + codex 009 sig). Reuse next.
- `lw-007-agy` on `agy/007-qa` @ `b438beb` (QA report + agy 009 sig; agy stashed
  its old 007-ballot marker cruft). Reuse for the next QA dispatch.
- Deliberation branches `<d>/007-{proposal,critique,ballot}` hold the decision-009
  cited artifact SHAs; archive under `refs/archive/007/*` at round close.
- Doer execution branches are LOCAL-ONLY (never push). The paid-pass integration
  will re-merge codex's regenerated assets onto the round branch the same way.

## Round 006 -- CLOSED (superseded by Scott's redefinition)

Scott picked NEITHER candidate (the spike IS the style), dissolving round-006's
whole deliverable (candidate A/B sprite comparison + walk cycle). Closed this
run: all worktrees pruned, all local 006 branches deleted, the
`origin/codex/006-acceptance` doer-branch leak deleted, `origin/round/006-two-
rivers` deleted, sweep guard PASSES (zero doer branches on origin), zero open
PRs. No round PR was ever opened (never passed its acceptance gate; Scott
overrode the gate). Everything recoverable under **`refs/archive/006/*` (pushed
to origin)**:
- `round-two-rivers` @ 5eee7bf (full integrated round: candidate A+B, scale
  contract, null fix, Blender pipeline, decisions 009/010, .mcp.json cherry-pick)
- `acceptance-harness` @ adaf9a0 (anonymized matched-composition capture harness
  + `tools/art/build_acceptance_artifacts.py`; DIRECTLY REUSABLE for the round-
  007 confusable-with-spike style test)
- `scale-contract` @ ce5cbe5, `nullfix` @ f880a6d, `camera-calibration` @
  7b419ab, `blender-cleanup` @ ee3a99d, `candidate-a` @ acf822f, `candidate-b` @
  60ceb9c, `integrate` @ affa249, `pilot-gen` @ 061b2a6
- proposal/critique/ballot artifacts: `{claude,codex,agy}-{proposal,critique,
  ballot}`
Round-007 reuse of any of these is a phase-1/synthesis decision, not an
orchestrator pre-decision. Inspect with `git show refs/archive/006/<name>:<path>`.

## Durable lessons (paid for repeatedly; honor them)

- **A dispatch is synchronous; nothing external re-invokes you when a detached
  proc finishes.** Only supervisor respawn re-invokes you. Own tool calls cap at
  600s. So EITHER block on a dispatch in one call (if it fits budget) OR detach
  (setsid) and poll the end marker across calls, capturing in-flight state in
  THIS file FIRST so a respawn can continue.
- **Working detach recipe:** `setsid bash -c "'$DISPATCH' <harness> <wt> <brief>
  <prompt> --cap-seconds N --label L >> LOG 2>&1 < /dev/null" & disown`, then
  poll `<wt>/.team/markers/<label>-<stamp>-end.md`.
- **Verify from the end marker + tree, NEVER the exit code or narration.**
  `branch_sha_before` vs `branch_sha_after` + `branch_changed` is load-bearing;
  also `uncommitted_work` + `cap_expired`. Then check `git -C <wt> log`/`git diff
  --stat`, not the worker's account.
- **agy adapter passes `--add-dir` internally** but still can no-op into a
  scratch project; markers catch it.
- **Detached `claude -p` buffers ALL output until completion and can run 15-20
  min silent (esp. Meshy).** "No output + no end marker" != dead. Verify liveness
  with `ps -o pid=,etimes= -p <pid>` + child MCP procs before ANY relaunch. A
  second launch into the SAME worktree is the corruption + double-spend hazard.
- **claude/agy doers whose job ends in a commit recurrently background work and
  end the turn on a "monitor will re-invoke me" intention, which never re-fires
  a `claude -p`.** Tell them explicitly NOT to background / wait on a Monitor; if
  they still fail, a tiny COMMIT-ONLY re-dispatch reliably lands it.
- **Doer seats NEVER push to origin** (fixed in briefs @ b14e39a; unenforceable
  at the credential layer, so prevention + the end-of-round sweep guard are the
  control). Only the orchestrator pushes, only the round branch.
- **Long render/verification proofs must run to completion in the FOREGROUND in
  the same turn**, not backgrounded behind a monitor.
- **Cross-workspace asks to Scott:** address `to: dalinar` (lands in Scott's
  queue), NOT `to: scott` (swept to riker/inbox/stuck, never reaches him).

## Meshy

Key live at `~/.claude/pka-secrets/longwalk/meshy.env`; MCP `meshy` in
`.mcp.json` (on main). Reachability CONFIRMED inside a claude doer. Balance
**2970** (verify with `meshy_check_balance` before/after any paid work). Cost-
confirm every paid call; NEVER pass `save_to` to `meshy_download_model`. Method
is Scott-unmandated now; if a proposal leans on Meshy 3D sources at village
scale, pair adoption with a git-lfs/artifact-store decision for the binary
footprint (~180 MB / 2 assets in the pilot).

## Active decision records (on main)

001-008 on main. `007` (iso + own-art override) and `008` (iso visual identity)
are binding for round 007. Round-006's 009/010 are archive-only (not on main).
Round-007's first decision record is **009**.

## Notes for the next run

- Dashboard POST target `https://dashboard.int.sentania.net/api/team` (full
  overwrite each POST; token in `pka-secrets/dashboard-config.md`, header
  `X-Bridge-Token`, `--cacert /etc/ssl/certs/sentania.root.pem`). No `critic`/
  `agy` in author enums: post their docs as `author: "orchestrator"` with a
  naming line in the body; carry an agy sign-off in `status_note`, not
  `signoffs[]`; never invent enum values (they vanish silently). A failed POST
  never blocks the protocol.
- `gh pr edit` is broken (GraphQL projectCards). Use REST `gh api -X PATCH
  repos/sentania-labs/longwalk/pulls/N ...`.
- Inbox processed through the 04:45Z dashboard steer. **Dashboard `/team` tab was
  KILLED by Scott (inbox `2026-07-18-0445-dalinar-disable-dashboard-team-sync.md`):
  stop the team-snapshot POST to `dashboard.int.sentania.net/api/team` (endpoint
  is being removed, will 404). There is no in-repo sync tool (the POST was always
  manual/orchestrator-side), so "disabled" == this and future runs simply DO NOT
  POST. The dashboard-narration duty in the orchestrator brief is suspended; do
  not treat a missing POST as a failure.** The three older stuck escalations
  (walk-cycle art spike, PR#18 gate) are moot under the village redefinition.

**Last updated:** 2026-07-18 (round 007 EXECUTION run: closed the whole
process->sign->integrate->gate->QA loop on the FIRST REAL-ART district. codex's
paid-Meshy processing slice [5a70f17] peer-signed by claude [genuine per-object
alpha review, border-flood-fill confirmed, no punched-through stone]; integrated
onto round/007-village [--no-ff, reviewed SHA preserved]; RE-RAN the honest export
gate on all 16 real assets [VILLAGE_GATE_PASS, 16/16 resolve from isolated .pck,
landmarks project 0.5/1/2x, non-mutation guard clean]; full suite green; agy's
FIRST dispatch delivered multimodal QA [VERDICT NOT-CONFUSABLE + 3 ranked defects]
and signed decision 009 [all 3 sigs now present]; pushed round branch @ 5f1c5cc.
Inbox: nothing newer than the already-processed 0445 steer. Balance re-verified
2952, ZERO paid Meshy this run. Every dispatch verified from end marker + tree,
not narration. Milestone honestly NOT reached [ground/lane tile grid is the tell]
-> deliberately NOT surfaced to Scott. Stopped at a clean milestone; NEXT run runs
the GROUND-treatment method iteration as FULL PROTOCOL blind proposals [decision
010 in play], per the Phase block.)
