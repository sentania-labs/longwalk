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
FULL PROTOCOL, contested, four-ballot. PHASE 1 (blind proposal) IN FLIGHT.**

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

**NEXT (poll + verify phase 2):** poll
`/home/scott/claude/lw-007-<d>/.team/markers/<d>-007-critique-<stamp>-end.md`;
verify from marker + tree; read each `docs/proposals/<d>-007-critique.md`. If any
critique is all-agreement ("looks good"), send it back. Record critique SHAs.
Then PHASE 3: synthesize (not average, not vote-count), FOUR-BALLOT the contested
method+composition question (orchestrator + 3 doers; critic only on 2-2), write
decision record 009 with every losing objection VERBATIM, divide labor by
capability. Then implementation on the round branch, round-branch integration,
one round PR.

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
- Inbox processed through the 03:30Z village-milestone redefinition. The three
  older stuck escalations (walk-cycle art spike, PR#18 gate) are moot under the
  redefinition.

**Last updated:** 2026-07-18 (round 007 opened: closed + archived round 006,
scoped the village milestone, cut `round/007-village` @ 07078d1, dispatched
three blind proposals detached at stamp 20260718-042834). Polling in progress.
