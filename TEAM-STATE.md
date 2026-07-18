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
FULL PROTOCOL (decision 009, Option H, 4-0). EXECUTION iterating on the ground/
lane treatment toward the confusable-with-spike bar.**

The bar is Scott's, verbatim: *screenshots confusable with the spike*
(`docs/art/iso-five-asset-spike.png`). Deliverable: a playable Windows build of a
full Two Rivers village at spike fidelity, NO PC/NPC, free ("disincorporated")
drag-pan/zoom camera. Walk-cycle/animation OUT of scope. Method unmandated.
Full scope: `.pka/round007/assignment.md`. Standing posture (directive 1500 +
Scott Q2 GO): autonomous back-to-back iteration; surface a build to Scott ONLY
when the team believes a screenshot genuinely passes the confusable bar.

**WHERE WE ARE:** one inn-green district is built at spike fidelity for the
BUILDINGS (real generated/sliced painterly cottages, inn, smithy, tree, props),
proven from an isolated packaged export. The remaining gap to the bar is the
GROUND/LANE treatment, being iterated in nested full-protocol sub-rounds.

=== GROUND SUB-ROUND (decision 010) -- DONE + INTEGRATED + QA'd THIS RUN ======
Decision 010 (`docs/decisions/010-ground-and-lane-treatment.md`, signed 4-0,
check_consensus PASS) chose a continuous cell-space SHADER-QUAD ground plane with
district painterly plates, render-derived R8 lane mask, baked deterministic domain
warp, protected lane core, and a separate contact-shadow layer; PLATE sampling was
the pre-voted 4-0 fallback (invoked after the tileable-swatch approach failed the
8x8 zoom gate 3x, source-structural). BOTH impl slices are now integrated,
cross-signed, gated, and QA'd:

- **claude RENDER slice `1a642a7`** (`claude/007-ground-impl`): ground.gdshader +
  village_render shader-quad rewrite (plate sampling `cell/grid_size`, not per-cell
  tiles), UV coordinate spike, contact shadows. Peer-signed by **codex** (non-author),
  marker `.team/signoffs/codex-007-ground-impl-1a642a7b6b7c.md`, result signed-off
  (verified determinism, sim/render separation, decoded captures, ran suite 2x).
- **codex ASSET slice `aa2d517`** (`codex/007-ground-impl`): registered the two
  supervised paid painterly fields as `ground_grass_plate`/`ground_dirt_plate`
  (1024x1024, provenance generated + paid task ids), real baked FastNoiseLite
  `ground_warp`, `shadow_decal`, retired the failed tile assets + swatch baker + 8x8
  gate, deleted the blocked marker. Peer-signed by **claude** (non-author), marker
  `.team/signoffs/codex-007-ground-impl-aa2d5177e50a.md`, result signed-off (decoded
  every PNG, native_px exact, sha256 plates == paid sources, warp deterministic).
- **INTEGRATION onto `round/007-village`** (orchestrator merge authority, this run):
  merge codex `d0bffa9` (clean off 053906a) -> merge claude `3a08acd` (conflicts on
  manifest.json/ground_warp.png/shadow_decal.png resolved to codex's REAL assets;
  claude's orphan `ground_*_tile.png` placeholders force-removed since codex retired
  them and the manifest references 0 tiles) -> both sign-off markers cherry-picked
  (`8f0f9d5`,`68c56b6`) -> regenerated captures `79dabbf` -> agy QA report `da05e69`.
  **Round head `da05e69`, PUSHED to origin.**
- **GATES GREEN on the integrated tree** (orchestrator ran them): full suite green
  (19 village-render checks + UV spike + active-path); honest export gate
  `VILLAGE_GATE_PASS`/`VILLAGE EXPORT GATE PASSED` -- 20 manifest assets resolve
  through ResourceLoader from an isolated `.pck`, 5 continuous-ground statics resolve,
  landmarks project at 0.5/1/2x (2 scroll off at 2x = expected), non-mutation guard
  clean. Captures regenerated with codex's REAL warp, committed `79dabbf`.

**agy MULTIMODAL QA (pass 2) VERDICT: NOT-CONFUSABLE** (`docs/art/village/
qa-agy-ground-002.md`, on round branch; agy `ef742f1`, verified from marker+tree,
60s, branch_changed). BUT this is real progress correctly diagnosed: the
**checkerboard tile-grid (the prior DOMINANT tell) is GONE** -- grass now reads as
continuous painterly surface. A NEW dominant tell emerged, and the orchestrator
independently CONFIRMED it against the captures + spike:
  1. **Lane MACRO-GEOMETRY (dominant):** lanes are straight, uniform-width diagonal
     bands meeting at a crisp X. The spike's paths meander organically with varying
     width (really worn-earth clearings between cottages, not roads). The domain warp
     is MICRO-noise on a straight edge, not macro-shaping. This is the new tell.
  2. **Transition blending:** dirt/grass boundary is a hard noise-cut, not the spike's
     soft patchy fade.
  3. **Dirt uniformity:** the plate revealed through the mask is uniformly solid; the
     spike's trails are patchy with varying density.
Out-of-scope (do NOT fail the verdict on these): no PC/NPC (intended); halo cutouts
on sliced props (agy defect #2, known separate fast-lane, still present on signpost/
bushes); strictly-gridded composition (contact shadows now present + help).

=== NEXT RUN: LANE-GEOMETRY SUB-ROUND (decision 011) -- FULL PROTOCOL ==========
**TRIAGE = FULL PROTOCOL.** The lane macro-shape is design-level (a genuine 3-way
fork) and likely touches the protected `src/sim/town_layout.gd` (the lane layout
data). Decision record = **011**. This is exactly decision 009 item 9's "method
failure at the gate changes the METHOD" applied to lanes: the ground-TEXTURE method
(010) is settled and good; the LANE-GEOMETRY method is the open question.

Scope to hand the doers (write `.pka/round007/lane-geometry/assignment.md`): make
the lanes read as the spike's organically-worn earth -- meandering variable-width
paths, soft patchy dirt/grass transition, non-uniform dirt density -- WITHOUT
regressing the settled decision-010 architecture (shader-quad + plates + baked warp
+ protected lane core + contact shadows all STAY; the plates are REUSED, no new paid
art). The genuine fork for phase-1 blind proposal:
  - (A) author organic meandering variable-width lanes IN the sim grid
    (`town_layout.gd`, protected) as curved/jittered PATH cells + soft render falloff;
  - (B) represent lanes as sim centerline polylines + width profile, render an
    organic signed-distance-field mask with macro-warp + width variation + feathered
    falloff (more render, sim stays a thin contract);
  - (C) keep the straight sim lanes but MACRO-warp the mask render-side (large-
    amplitude low-frequency displacement) + width jitter + feathered dual-threshold
    edge + a second noise modulating dirt density (minimal/no sim change).
All three must also address tells #2 (soft transition) and #3 (patchy dirt), which
are render-side falloff/modulation refinements any option incorporates. Protected-
path forecast: `src/sim/town_layout.gd` (A/B) -> decision 011 must authorize it and
be signed by all dispatched doers; check_consensus gate.

**Mechanics reminder for the sub-round:** create the doer branches off the CURRENT
round head `da05e69` (not a stale base). Re-use worktrees `lw-007-{claude,codex,agy}`
(currently on the impl/ballot branches; switch to `<prefix>/007-lane-*` branches off
da05e69). Same shape as the 010 sub-round: blind proposal -> adversarial critique ->
four-ballot synthesis -> decision 011 -> impl -> cross sign-off -> integrate -> gate
-> agy QA pass 3. Balance **2946**, NO paid spend planned (geometry/shader work).

After lanes clear the bar: fast-lane the halo re-cut (agy defect #2) to codex
(border-flood-fill that already worked on buildings), then expand to the full
~12-16-structure village, then open the ONE round PR + external Codex review, address
findings, merge, sweep. Surface to Scott ONLY when a screenshot passes the bar.
===============================================================================

## Phase

**GROUND SUB-ROUND (decision 010): COMPLETE, INTEGRATED, GATED, QA'd this run.
Round head `da05e69` (pushed). agy QA pass-2 = NOT-CONFUSABLE (checkerboard fixed;
new dominant tell = lane macro-geometry).**

**NEXT PHASE = LANE-GEOMETRY SUB-ROUND (decision 011), FULL PROTOCOL, blind
proposal.** Everything the next run needs is in the "NEXT RUN" box above:
triage=full-protocol, the 3-way fork (A sim-authored / B centerline-SDF / C render
macro-warp), the scope to write into `.pka/round007/lane-geometry/assignment.md`,
protected-path forecast (`src/sim/town_layout.gd`), branch-off point (`da05e69`),
balance (2946, no paid spend). Decision 010's ground-texture architecture is settled
and must NOT be regressed; this sub-round only changes LANE SHAPE + BLENDING.

**Verified-this-run inventory (all from end markers + tree + real gate runs, not
narration):**
- claude render `1a642a7` + codex assets `aa2d517`: both cross-signed by the
  non-author, both signed-off, markers on the round branch.
- Integration merges + conflict resolution (codex real assets win, orphan tiles
  removed) verified: final ground asset set = plates + warp + shadow + the two
  legacy ground/lane slices (harmless, still in manifest); 0 tile refs in manifest.
- Full suite green + honest export gate PASS on the integrated tree; captures
  regenerated with the real warp and committed.
- agy QA pass-2 committed + integrated; verdict + 3 ranked lane gaps recorded.
- Hygiene sweep: zero open team PRs; origin carries only `round/007-village` +
  `main` (+ unrelated `issue-4-world-eras`); leak guard OK (no doer branches on
  origin). Ephemeral review/QA worktrees + branches (rev-cxc/rev-clc/qa) removed
  after collecting their commits.

**Live worktrees + branches (all LOCAL except `round/007-village` on origin):**
- `lw-007-round` on `round/007-village` @ `da05e69` (integration tree, pushed).
- `lw-007-claude` on `claude/007-ground-impl` @ `1a642a7` (integrated; reuse next
  by switching to a `claude/007-lane-*` branch off da05e69).
- `lw-007-codex` on `codex/007-ground-impl` @ `aa2d517` (integrated; reuse next).
- `lw-007-agy` on `agy/007-ground-ballot` @ `ac559fe` (reuse for QA pass 3).
- Deliberation branches `<d>/007-{proposal,critique,ballot,ground-*}` hold the
  decision-009/010-cited artifact SHAs; archive under `refs/archive/007/*` at round
  close. Doer execution/impl branches are LOCAL-ONLY (never push).

## Round 006 -- CLOSED (superseded by Scott's redefinition)

Scott picked NEITHER candidate (the spike IS the style), dissolving round-006's
whole deliverable. Closed: worktrees pruned, local 006 branches deleted, origin
doer-branch leak + `origin/round/006-two-rivers` deleted, sweep guard PASSES, zero
open PRs. Everything recoverable under **`refs/archive/006/*` (pushed to origin)**:
`round-two-rivers` @ 5eee7bf, `acceptance-harness` @ adaf9a0 (reusable capture
harness), `scale-contract` @ ce5cbe5, `nullfix` @ f880a6d, `camera-calibration` @
7b419ab, `blender-cleanup` @ ee3a99d, candidate-a/b, integrate, pilot-gen, and the
proposal/critique/ballot artifacts. Inspect with
`git show refs/archive/006/<name>:<path>`.

## Durable lessons (paid for repeatedly; honor them)

- **A dispatch is synchronous; nothing external re-invokes you when a detached
  proc finishes.** Only supervisor respawn re-invokes you. Own tool calls cap at
  600s. So EITHER block on a dispatch in one call OR detach (setsid) and poll the
  end marker across calls, capturing in-flight state in THIS file FIRST.
- **Working detach recipe:** `setsid bash -c "'$DISPATCH' <harness> <wt> <brief>
  <prompt> --cap-seconds N --label L >> LOG 2>&1 < /dev/null" & disown`, then poll
  `<wt>/.team/markers/<label>-<stamp>-end.md`.
- **Verify from the end marker + tree, NEVER the exit code or narration.**
  `branch_sha_before` vs `branch_sha_after` + `branch_changed` is load-bearing;
  also `uncommitted_work` + `cap_expired`. Then check `git log`/`git diff --stat`
  and DECODE the actual image artifacts, not the worker's account.
- **Integration conflict resolution is orchestrator merge authority, not code
  authoring.** This run: codex real assets win over claude provisional on
  manifest/warp/shadow; claude's orphan tile placeholders (retired by codex) must be
  force-removed post-merge or they silently survive as add/add-from-theirs.
- **agy adapter passes `--add-dir` internally** but still can no-op into a scratch
  project; markers catch it. agy QA runs are fast (~60s) but genuinely multimodal.
- **Detached `claude -p` buffers ALL output until completion; "no output + no end
  marker" != dead.** Verify liveness with `ps -o pid=,etimes=` before ANY relaunch;
  a second launch into the same worktree is the corruption + double-spend hazard.
- **Doer seats NEVER push to origin.** Only the orchestrator pushes, only the round
  branch. Prevention + the end-of-round sweep guard are the control.
- **Long render/gate proofs run to completion in the FOREGROUND in the same turn.**
- **Cross-workspace asks to Scott:** address `to: dalinar`, NOT `to: scott`.
- **Do NOT start a fresh full-protocol sub-round (or a paid spend) at the tail of a
  long run.** Tee it up precisely here and let the next run execute it with a full
  turn. (This run correctly closed the 010 integration+QA and teed up 011.)

## Meshy

Key live at `~/.claude/pka-secrets/longwalk/meshy.env`; MCP `meshy` in `.mcp.json`.
Balance **2946** last confirmed (2970 -> 2952 first paid pass; 2952 -> 2946 ground
source pass; NO paid spend since). Verify with `meshy_check_balance` before/after
ANY paid work; cost-confirm every call; NEVER pass `save_to` to
`meshy_download_model`; `meshy_list_tasks` for no PENDING/IN_PROGRESS before any
spend (double-spend guard). The lane-geometry sub-round needs NO paid art (the paid
painterly plate fields are reused). Paid source downloads at
`.pka/round007/ground-source/*.png` are the ONLY copies (raw URLs expired); do NOT
regenerate.

## Active decision records (on main / round branch)

001-008 on main (007 iso-override + 008 iso-identity binding for round 007).
Round-007 decision **009** (village art method, Option H) + **010** (ground/lane
treatment: shader-quad plate) are on the round branch, signed. Round-006's own
009/010 are archive-only (`refs/archive/006/*`), never on main -- no collision.
Round-007's NEXT decision is **011** (lane geometry).

## Notes for the next run

- **Dashboard `/team` tab is KILLED by Scott** (inbox `2026-07-18-0445-dalinar-
  disable-dashboard-team-sync.md`): do NOT POST to `dashboard.int.sentania.net/
  api/team` (endpoint being removed, will 404). The dashboard-narration duty is
  suspended; a missing POST is not a failure. Inbox processed through the 04:45Z
  steer; no new orchestrator inbox messages this run.
- `gh pr edit` is broken (GraphQL projectCards). Use REST `gh api -X PATCH
  repos/sentania-labs/longwalk/pulls/N ...`.
- No round PR is open (correct -- the round PR opens only once the district passes
  the confusable bar; it has not yet). The three older stuck escalations are moot
  under the village redefinition.

**Last updated:** 2026-07-18 (ground sub-round CLOSE-OUT run: cross-signed both
decision-010 impl slices [codex signs claude render 1a642a7; claude signs codex
assets aa2d517, both genuine non-author reviews, both signed-off], INTEGRATED both
onto round/007-village [merge codex d0bffa9 -> merge claude 3a08acd resolving
manifest/warp/shadow to codex real assets + force-removing claude's orphan retired
tiles] -> collected both markers -> regenerated captures from the integrated tree
with the real warp -> honest export gate PASS + full suite green [orchestrator ran
both] -> pushed da05e69. Dispatched agy multimodal QA pass 2: VERDICT NOT-CONFUSABLE
but the CHECKERBOARD [prior dominant tell] is GONE -- ground now continuous painterly
grass; NEW dominant tell = lane MACRO-GEOMETRY [straight uniform diagonal bands vs
spike's organic meandering worn-earth] + hard transition + uniform dirt, all
orchestrator-confirmed against captures+spike. NOT surfaced to Scott [bar not met].
Teed up decision-011 LANE-GEOMETRY sub-round [FULL PROTOCOL, 3-way fork A/B/C,
protected src/sim/town_layout.gd, branch off da05e69, balance 2946 no paid spend].
Every dispatch verified from end marker + tree + decoded images. Hygiene sweep OK:
0 open PRs, 0 doer branches on origin, ephemeral review/QA worktrees removed.)
