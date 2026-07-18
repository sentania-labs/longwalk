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
EXECUTION: first inn-green district ZERO-CREDIT rig PROVEN + INTEGRATED on
`round/007-village` @ `5a42736` (pushed). NEXT = supervised FIRST PAID pass.**

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

**EXECUTION: ZERO-CREDIT RIG PROVEN + INTEGRATED. NEXT = SUPERVISED FIRST PAID PASS.**

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
- `lw-007-round` on `round/007-village` @ `5a42736` (integration tree, pushed).
- `lw-007-claude` on `claude/007-village-render` @ `c164ef7` (render + gate fix +
  its signoff of codex + claude 009 sig). Reuse for the next claude dispatch.
- `lw-007-codex` on `codex/007-village-assets` @ `54e3811` (real assets + manifest
  + process_assets + codex 009 sig + its signoff of claude's c164ef7). Reuse for
  the paid generation dispatch.
- `lw-007-agy` on `agy/007-ballot` (idle; agy's first execution dispatch is QA of
  the first real-asset capture, after the paid pass).
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

**Last updated:** 2026-07-18 (round 007 EXECUTION run: dispatched both slices
parallel [codex assets 019bbd9, claude render+gate 17611ac]; ran a cross peer-
review that CAUGHT A REAL DEFECT [claude's gate regenerated placeholders before
export, would overwrite real assets -- codex changes-requested]; fix landed
[c164ef7] + codex re-signed [54e3811]; integrated both onto round/007-village
resolving asset add/add to codex's real art + the 009 sig conflict; suite green +
the HONEST export gate PASSED on real assets [16/16 resolve from an isolated .pck,
non-mutation guard clean]; pushed round branch @ 5a42736. Handled the 0445 inbox
steer [dashboard /team POST disabled]. Every dispatch verified from end marker +
tree. Balance 2970, ZERO paid Meshy. Stopped at a clean pre-spend milestone. NEXT:
supervised FIRST PAID pass -- generate the 6 generated-pending objects via image-
to-image, per the NEXT block above.)
