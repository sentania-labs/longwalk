# TEAM-STATE

<!--
MACHINERY, NOT A CHANGELOG.

This file is the orchestrator's memory. The orchestrator is ephemeral: it is
spawned with an assignment, runs the protocol, and dies. Nothing it holds in
memory survives. So it reads this file first thing on every run and rewrites
it before it exits, and that read/write cycle is the only reason the team has
continuity between runs at all.

Consequences worth knowing before you edit this file:

  - It is overwritten. Do not park notes here expecting them to persist. The
    durable record of a decision is docs/decisions/NNN-topic.md, which is
    append-only and never rewritten.
  - It describes the present, not the past. When an assignment finishes, its
    state is replaced, not appended to. History lives in git and in the
    decision records.
  - Humans read it, but it is not written for humans the way a changelog is.
    It is a state dump the next orchestrator run can act on.

Keep the section structure below stable: the orchestrator (and eventually the
Dashboard "Team" tab, a follow-up dispatch) parse it by heading.
-->

## Current assignment

**ROUND 006: Two Rivers iteration + art-production fork. FULL PROTOCOL,
contested, four-ballot. PHASE 1 (blind proposal) IS IN FLIGHT.** Round branch
`round/006-two-rivers` created from `main` at `2805f00`. Three blind proposals
dispatched DETACHED at run stamp `20260717-202010`:
- claude on `claude/006-proposal` (worktree `lw-006-claude`)
- codex on `codex/006-proposal` (worktree `lw-006-codex`)
- agy on `agy/006-proposal` (worktree `lw-006-agy`)
Each writes `docs/proposals/<prefix>-006-two-rivers-production.md` and commits it.
Cap 2400s. Poll end markers in each worktree's `.team/markers/`; verify
`branch_changed`/`uncommitted_work`/`cap_expired`, then read each proposal doc.

**The contested phase-1 question (directive 1515):** which art-PRODUCTION path,
of three: (1) stay pure-sprite, (2) real-time Meshy 3D through an iso-locked
Godot 3D camera, (3) 3D pre-rendered to painterly 2D sprites (Dalinar's
recommended bias; preserves the iso spine + most of codex's pipeline). Meshy is a
NEW DEPENDENCY = escalation-class: any Meshy-adoption recommendation must be
called out to Scott in decision 009, though a SMALL pilot (one building + player)
is pre-authorized. The GOAL is fixed (spike fidelity + Two Rivers vibe in the
running game); only the production METHOD is contested.

**The four named defects (directive 1500), the execution target once the method
is chosen:** (1) walk-cycle animation not dialed in; (2) building-to-player scale
off (document + enforce a ratio); (3) fidelity gap (whole-scene generation
collapses when bridged to game tiles/sprites); (4) runtime bug "Instance base is
null" prints top-left in playtest (independently fast-lane-able).

**Posture (directive 1500, standing):** autonomous multi-round iteration toward
the approved iso-five-asset-spike + Two Rivers vibe. "Burn the tokens, run rounds
back to back, do NOT stop-and-wait after every slice." Surface a playable build
to Scott only when the team believes it genuinely hits the bar, or on a real
decision (constitution question, deadlock the critic can't settle, or the
Meshy-adoption call specifically). Check the `.pka/inbound/orchestrator/` inbox
at EVERY phase boundary, not just spawn.

## Phase

**Status:** `ROUND 006 MESHY PILOT: the GENERATION slice is DISPATCHED and IN
FLIGHT (detached, ppid 1, survives orchestrator turns). Non-Meshy slices remain
DELIVERED/signed/MERGED into round/006-two-rivers, now @ aa8eab5 (added .mcp.json,
pushed). FULL SUITE GREEN as of 22f8e4c. Decision 010 accepted 4-0. No PR yet.`

**MESHY MCP REACHABILITY: CONFIRMED in a claude-worker doer.** The dispatched
doer connected the `meshy` MCP server (npm `@meshy-ai/meshy-mcp-server`, child
proc verified) and progressed past the free `meshy_check_balance` probe into
scaffolding (`.gitignore` += `/meshy_output/`, created
`assets/art_src/pilot/{cottage,player}/`). So the `.mcp.json` + `--dangerously-
skip-permissions` path works; no first-use approval block materialized.

**CAPABILITY RE-DIVISION (orchestrator call, NOT contested/four-ballot):** the
2026-07-17T16:20Z capability update ("meshy-live") confirms Meshy is wired ONLY
for the codex and claude-worker seats, NOT agy. Decision 009's DoL table assigned
the Meshy generation + provenance slice to agy; agy physically cannot reach Meshy.
Agy's non-Meshy work (Blender render tool + camera calibration + ledger tooling)
is already done/merged (1fac9b0). The remaining Meshy generation + provenance
portion is REASSIGNED to claude-worker (project `.mcp.json` is claude-native;
claude-worker owns the downstream integration that consumes the mesh). This is a
capability-forced amendment recorded here; if agy objects it escalates.

**INFRA: `.mcp.json` cherry-picked onto the round branch.** It landed on `main`
via Scott's commit 9a0e2c8 AFTER the round branch was cut (at 2805f00), so a
worktree off the round branch lacked the Meshy config. Cherry-picked 9a0e2c8
(Scott's authorship preserved) onto `round/006-two-rivers` -> `aa8eab5`, pushed.
Integration action, not orchestrator-authored code.

**IN-FLIGHT DISPATCH (poll this):**
- run_id `006-pilot-gen-20260717-214426`, harness claude, model opus, cap 3600s.
- worktree `/home/scott/claude/lw-006-pilot-gen`, branch `claude/006-pilot-gen`
  (cut from round branch @ aa8eab5).
- prompt: `.pka/round006/pilot-gen-prompt.md` (generation ONLY: one 2x2
  half-timbered cottage + one rigged player, provenance manifest, commit under
  `assets/art_src/pilot/`; NEVER pass `save_to` to meshy_download_model).
- POLL: `/home/scott/claude/lw-006-pilot-gen/.team/markers/006-pilot-gen-20260717-214426-end.md`.
  Verify `branch_changed`/`uncommitted_work`/`cap_expired`, then inspect the tree
  (models present? manifest? sha256s?) and re-derive, never trust narration.
- Process root pid was 3356924 (`ps -o etimes= -p <pid>` to see if still alive).

**DOUBLE-LAUNCH INCIDENT (resolved, lesson):** the first detached launch's setsid
grandchild reparented to init but emitted no output for minutes (claude -p buffers
until done) and wrote no end marker while running, so it LOOKED dead. A manual
adapter probe (rc=143 at its own 15s cap) plus a second full launch were fired.
Result: TWO claude+meshy sessions briefly ran in the SAME worktree (the exact
corruption/double-spend hazard). The second tree was SIGKILLed (incl. its orphan
`timeout claude -p` that reparented to init after its adapter died, plus its meshy
MCP child). Only the first (3356924) survives. LESSON: a detached claude -p that
is alive with ppid 1 but silent is NORMAL for minutes; verify liveness with
`ps`/child-MCP-procs BEFORE concluding death or relaunching. Brief double-spend of
Meshy credits is possible (the killed session may have made an early paid call);
the surviving doer's PROVENANCE manifest + balance delta will reveal actual spend.

**Three non-Meshy slices, delivered + verified + signed + merged:**
- **claude** `claude/006-nullfix` @ `dd86f7e` (peer-signed by codex `f880a6d`,
  merged `06ca900`): fixed "Instance base is null". Root cause =
  `character_creation.gd` `@onready _name_edit` node path was
  `.../VBoxContainer/NameEdit` but the LineEdit is at `.../NameRow/NameEdit` -> null
  base at play time; old boot test stayed green because bare `instantiate()` never
  fires `@onready` (resolves on `_ready()`). Fix = one-line path correction + a
  `_check_character_creation_handoff()` regression in `test/active_path/test_boot_flow.gd`
  that fires `_ready()` and asserts refs resolve. Diagnosed from a clean-import
  repro + real engine output (constraint 9), not a guessed load site.
- **codex** `codex/006-scale-contract` @ `3b85b28` (peer-signed by agy `ce5cbe5`,
  merged `a62ecc4`): `docs/art/scale-contract.md` + `tools/art/check_scale_contract.py`
  (build-failing validator) + `test/art/test_check_scale_contract.py`, wired into
  `run_tests.sh`. Per decision 010 the UPRIGHT rate is `32*sqrt(6)` (~78.3837 px/m),
  table player 137.1714 / door 156.7673 / eaves 188.1208 / ridge 376.2416-438.9485.
  GROUND projection (`TILE_W=128`, `TILE_H=64`) UNCHANGED; `projection.gd` untouched.
- **agy** `agy/006-camera-calibration` @ `1fac9b0` (peer-signed by claude `7b419ab`,
  merged `22f8e4c`): provisioned Blender 4.0.2 (`tools/fetch_blender.sh`, gitignored
  binary), `tools/art/blender_calibration.py` + `render.sh`. Camera = 30 deg
  (arcsin 0.5), azimuth 45, ortho; proves 2:1 ground agreement with `projection.gd`
  (0.0002px) AND the physical upright rate `32*sqrt(6)` incl. a golden 2.0m-pole
  check (measured 156.7674 vs contract 156.7673). `render.sh` PASSES (verified by
  orchestrator re-run).

**DECISION 010 (accepted, on round branch @ `de0173f`): upright render-scale
reconciliation, 4-0 Option B.** Execution's camera calibration proved the render
camera must sit at 30 deg (arcsin 0.5, NOT atan(0.5) which is the 2D diamond
screen-slope), where it foreshortens height to the exact analytic `32*sqrt(6)`
px/m, conflicting with codex's signed 64 px/m contract. Orchestrator's coupling
proof (ground-depth via sin, upright-height via cos, both on screen-Y, locked by
the 30 deg elevation; needed ratio sqrt(2) vs actual cot(30)=sqrt(3)) showed no
ortho projection scalar can keep both, so Option A reduces to mesh-Z squash
(distorts normals/painterly lighting) or a brittle custom projection. Round-1
ballots were A(claude),A(codex),B(agy),B(orch); after a CRITIQUE round put the
coupling on the table, both A-voters WITHDREW A of their own accord and the team
went 4-0 for Option B (accept the physical rate, revise the contract, no vertical
correction step). No 2-2, critic correctly not invoked. Ballot rationales preserved
in `/tmp/round006-exec/BALLOT1-*.txt` (round 1) and `BALLOT2-*.txt` (critique).

**MESHY IS PROVISIONED (corrects the prior run's assumption):** a real key is at
`~/.claude/pka-secrets/longwalk/meshy.env` (`MESHY_API_KEY=msy_...`, len 40), and
an MCP server `meshy` is wired in longwalk's `.mcp.json` -> `vault/scripts/mcp/
meshy-launch.sh` (sources the key). README says the Claude Code doer seat and the
Codex global config both point at that wrapper. CAVEAT TO VERIFY before dispatching
generation: confirm the `meshy` MCP is actually reachable inside a dispatched doer
(claude.sh uses `--dangerously-skip-permissions` but no explicit `--mcp-config`;
agy harness MCP wiring for longwalk's .mcp.json is unconfirmed). Pilot is
pre-authorized (1515); ADOPTING Meshy for production beyond the pilot still
escalates to Scott (decision 009).

**NEXT STEP = THE MESHY PILOT (round 006's actual art deliverable, the riskiest
under-owned slice; decision 009 constraints 5-8 + division of labor).** Sequence:
(1) agy generates ONE 2x2 half-timbered cottage + ONE player via the meshy MCP,
commits models + a provenance manifest (service version, request params, license,
source hashes) per constraint 8; (2) shared/sequenced Blender topology cleanup +
armature weighting + 6-pose/8-facing gait tuning (least-owned, log the cleanup
ledger per constraint 6); (3) render candidate A (deterministic NPR/composite,
codex) AND candidate B (texture-space/whole-sheet fixed-seed generative, claude)
from the 30 deg rig; (4) integrate onto the iso spine via `tools/art/` +
`starter_town.gd` (claude); (5) the anonymized in-engine ACCEPTANCE GATE vs the
SPIKE (constraint 7) with static + walk-GIF captures + the cleanup ledger. Start by
verifying meshy MCP reachability in a doer, then dispatch agy generation. This
phase is large and may span multiple orchestrator runs.

Prompt files + all ballots: `/tmp/round006-exec/` (may not survive a reboot;
substance is captured above and in decision 010).

**Round 006 artifact SHAs (archived under refs/archive/006/*, pushed to origin):**
| Worker | Proposal | Critique | Ballot |
| --- | --- | --- | --- |
| claude | `8da1420640a1461b936111e42db7419749490f7f` | `0b496efe1f15ade69a8232a61cc176be203bc3a9` | `b182a2819ab8b4388e51f6db9ae30faf4905139b` |
| codex | `b707cf7f7e7102ff57e34df0b47377b751f11eea` | `e4237a22d75a9f47d601b10223948f9fb81d9735` | `d9bef93d2a809e17df671c2f05f5c785545d581b` |
| agy | `d6a0f8288ba266ceeda3f0d66afce1b2bdc783cb` | `b7327bec27e149e42d6ad62795db5f7ea7415da6` | `e5989621ac7299ff60f62999e450b040a7d4a904` |

**Decision 009 outcome (full detail in the record on the round branch):**
unanimous Path 3; per-frame generative repaint BANNED (both converged, no
ballot). Four-ballot on two contested questions, both 4-0:
- Q1 (fidelity recovery): dual-candidate pilot. (A) deterministic NPR/composite
  baseline AND (B) generative stylization in TEXTURE SPACE (mesh albedo, once) OR
  a single fixed-seed WHOLE-SHEET pass, never per-frame; the pilot MEASURES both
  under rejection rules (no landmark mutation, no boiling; freeze accepted outputs
  + provenance; gate fails if A misses the spike and B cannot close it cleanly).
- Q2 (render tool): Blender headless single offline authoring+render source; Godot
  only for acceptance capture. agy conceded its Godot-sub-viewport position.
Plus: camera-calibration-first vs `src/render/iso/projection.gd` (verify the iso
angle); codex's meter scale contract + build-failing validation; the 008-QC
offline-derived shadow MASK stays SHIPPED (Blender cast-shadow = cross-check);
small pilot = one 2x2 cottage + one player (6-pose walk, 8 facings) + minimal
dressing; cleanup-labor ledger extrapolated to ~200 assets before any production
tranche; anonymized in-engine gate vs the SPIKE; `src/sim/` untouched.
**Meshy adoption beyond the pilot is ESCALATED to Scott in decision 009** (pilot
pre-authorized; production adoption needs his explicit approval, brought with the
pilot result + ledger).

## Round 006 EXECUTION plan (phases 1-3 done; this is what's next)

Decision 009 division of labor (all three ACCEPTED their slices in their ballots):
- **claude:** in-engine integration into `starter_town.gd`/`player_controller_2d.gd`,
  camera + `building_contact_cell` anchor-contract conformance, candidate B
  (texture-space/whole-sheet generative) design, AND the "Instance base is null"
  fast-lane fix (independent lane; clean-import repro + engine stack, NOT a guessed
  `load()` site; boot-flow regression assertion on that exact text).
- **codex** (sprite-forge mandate): 2D delivery boundary, deterministic NPR/
  composite baseline (candidate A), render-pass specs + pre-render manifests,
  anchor+scale validation scripts, 8-facing atlas assembly, acceptance-capture +
  walk-GIF harness.
- **agy:** Meshy API integration + provenance manifest, Blender-headless offline
  render tool + primitive camera-calibration scene, cleanup-labor ledger tooling.
- **shared, sequenced:** Blender topology cleanup, armature weighting, gait tuning.

Ordered execution steps:
1. **Defect #4 (null bug), independent FAST-LANE, no Meshy needed:** dispatch claude
   to reproduce "Instance base is null" from a clean import, fix from the engine
   stack, add the regression assertion. Cross-sign (non-author), `--no-ff` into
   `round/006-two-rivers`, suite green. This can go FIRST and in parallel with
   scaffolding, since it does not depend on the art pipeline.
2. **Non-Meshy scaffolding (can proceed WITHOUT Meshy access):** agy's Blender
   camera-calibration scene proving agreement vs `projection.gd` using PRIMITIVES;
   codex's scale-contract validation script; the render-pass/manifest spec. Prove
   camera + scale on primitives before any Meshy asset is judged (009 constraint 2).
3. **Meshy-dependent pilot steps (BLOCKED on Meshy credentials, see below):** one
   cottage + one player generated in Meshy, cleaned/rigged/posed in Blender,
   rendered to candidate A and B, integrated, run the anonymized acceptance gate
   vs the spike + the cleanup ledger.
4. Round PR to main, one external Codex review round, address findings, merge on
   the ordinary gate, close-out sweep (delete branches + worktrees, archive already
   done under `refs/archive/006/*`, write `.review-passed`).

**PROVISIONING (RESOLVED):** Meshy IS provisioned. Real key at
`~/.claude/pka-secrets/longwalk/meshy.env`; MCP `meshy` in longwalk `.mcp.json` ->
`vault/scripts/mcp/meshy-launch.sh`. Steps 1-2 (non-Meshy) are DONE, signed,
merged, suite green. Step 3 (the Meshy pilot) is the next phase and is NOT
blocked. Verify MCP reachability inside a dispatched doer first (see Phase
section caveat). Do NOT introduce a second external dependency (e.g. Mixamo).

## Round 005 (COMPLETED + MERGED + SWEPT this run)

Round 005 (isometric visual identity, decision 008) is DONE. PR #21 merged to
`main` at merge commit **`5d83f477`** (2026-07-17T20:16Z), via a merge commit
(round-branch norm, matches PR #20). `.review-passed` on main records `5d83f47`
(commit `2805f00`, straight to main per the sanctioned exception).

External Codex review reached FIVE rounds, all findings addressed by the owning
doer + peer-signed + integrated before merge:
- r1: facing-from-square-velocity P1 (claude facing-fix).
- r2: two P2s (capture-freeze, manifest-doc).
- r3: two P2s THIS RUN: camera zoom-clamp ordering (agy `618b578`) + README
  build_player_walk stale invocation (codex; first attempt `ec176dc` documented a
  non-running command, CAUGHT by claude peer review as `changes-requested`;
  re-fixed `cd35047` adding `tools/art/rebuild_player_walk_option_c.py`, verified
  byte-for-byte artifact reproduction sha256 `0e4c952b...`).
- r4: two more P2s THIS RUN: camera pan drag-threshold only applied to the first
  gesture (agy `db71051`, adds a `FREE` state + regression test) + README:84
  stale `out/processed/` attribution (codex `b43daf9`).
- r5 (head `84aa8cf`): CLEAN ("Didn't find any major issues. Delightful!").
All CI green at merge. Close-out sweep done: round + all doer branches deleted
(remote round branch, both stale remote codex/005 fix branches, all local 005
branches); doer worktrees torn down; nine 008-cited proposal/critique/ballot SHAs
archived under `refs/archive/005/*` (pushed to origin).

## Active decision records

- **`010-upright-render-scale-reconciliation.md`** (on round branch @ `de0173f`,
  not yet on main). 4-0 Option B. Amends 009 constraint 3's upright numbers to the
  `32*sqrt(6)` px/m rate; clarifies 009 constraint 2 (verified camera elevation =
  30 deg). No protected path. Rides to main with the round PR.
- **`009-3d-authored-2d-delivered-pipeline.md`** (on round branch, not yet on
  main). 4-0/4-0. Path 3 (author 3D -> pre-render 2D). Authorizes `project.godot`.
  Meshy production adoption escalates to Scott; pilot pre-authorized.
- **`008-isometric-visual-identity.md`** (on main via PR #21). 4-0. Authorizes
  the `project.godot` protected path. Supersedes 005's cardinal facing SET.
- **`007-isometric-and-own-art-override.md`** (main). Binding for iso + own-art.
  Supersedes 006 grounds 1-2.
- **`006-asset-pack-and-rendering-model.md`** (main). Grounds 1/2 superseded by
  007; 3/4/5 survive; 7 superseded by 008.
- **`004-round-branch-integration-and-voting-model.md`**: round-branch
  integration, doers never open PRs, one PR + one external review per round,
  four-ballot voting with critic tiebreaker on a 2-2 split. Governs round 006.
- `005`/`003`/`001`/`002` accepted (002's standing critic vote rescinded by 004;
  001's SHAs pinned under `refs/archive/001/*`; 005's under `refs/archive/005/*`).
  **Next free decision number is `011`.**

## Branch and PR sweep (round 006 in flight)

- **Zero open team PRs** (round 006 has no PR yet; the round PR opens only after
  the Meshy pilot completes, per decision 004's one-PR-per-round rule).
- **Remote branches:** `origin/main`; `origin/round/006-two-rivers` @ `22f8e4c`
  (integration tree, 3 slices merged + decision 009/010, suite green; PR after the
  pilot); `origin/issue-4-world-eras` (a HUMAN branch, author sentania, predates
  the team framework; NOT the team's to delete, retained). The
  `claude/006-proposal`/`codex/006-proposal` (+local `agy/006-proposal`) branches
  are archived under `refs/archive/006/*`. The three EXECUTION branches
  `claude/006-nullfix`, `codex/006-scale-contract`, `agy/006-camera-calibration`
  are LOCAL-ONLY, already merged into the round branch (retained on purpose only
  as worktree checkouts; disposable, their work is in the round branch).
- **Worktrees (retained on purpose, round 006 in flight):** primary `longwalk`
  (main); `lw-006-round` (round/006-two-rivers @ `22f8e4c`, the integration tree);
  `lw-006-claude` (`claude/006-nullfix`), `lw-006-codex` (`codex/006-scale-contract`),
  `lw-006-agy` (`agy/006-camera-calibration`) - reuse these for the pilot slices
  (cut fresh pilot branches off the round branch in each). All round-005 worktrees
  torn down.

## Open escalations to Scott

**None open.** The Meshy-adoption call (1515) becomes an escalation-class
call-out IN decision 009 IF the team chooses a Meshy path; it is not an open
dispute now. A 2-2 four-ballot split in round 006 invokes the critic; a
constitution violation or critic-vs-orchestrator standoff escalates.

## Notes for the next run

**IMMEDIATE NEXT STEP: the MESHY PILOT** (see the Phase section's "NEXT STEP =
THE MESHY PILOT" for the 5-step sequence). Check the `.pka/inbound/orchestrator/`
inbox FIRST (per-phase-boundary rule). The non-Meshy scaffolding is DONE (merged,
signed, green). FIRST verify the `meshy` MCP is reachable inside a dispatched doer
(the .mcp.json is claude-oriented; test a tiny meshy MCP call in a claude-worker
dispatch before committing to a full generation). Then dispatch agy to generate
the pilot cottage + player + provenance manifest. Cut fresh pilot branches off
`round/006-two-rivers` @ `22f8e4c`. Dispatch DETACHED, poll end markers, verify
from disk + re-run render/tests yourself. This phase is large and may span runs.
Do NOT open the round PR until the pilot's acceptance gate passes (one PR per
round). This is also the point where, if the pilot clears the acceptance gate vs
the spike, you bring the result + cleanup ledger to Scott for the Meshy
production-adoption call (decision 009 escalation) AND likely the vision-bar
surface (directive 1500).

**Watch the agy adapter's `--add-dir`** (the adapter now passes it internally at
`adapters/agy.sh:88`; markers still catch a scratch no-op). Verify every dispatch
from `.team/markers/<run_id>-end.md`, not the transcript.

**`gh pr edit` is broken** (GraphQL projectCards deprecation). Use REST
(`gh api -X PATCH repos/sentania-labs/longwalk/pulls/N ...`). `gh pr comment`,
`gh pr merge`, `gh pr view --json` work.

**Dashboard POST** works (token in `/home/scott/.claude/pka-secrets/dashboard-config.md`,
header `X-Bridge-Token`, `--cacert /etc/ssl/certs/sentania.root.pem`). Schema
gaps: no `critic`/`agy` in `DOCUMENT_AUTHORS`, no `agy` in `SIGNOFF_AUTHORS`, no
`implementation`/`done` phase; use the role-brief workarounds (post agy/critic
docs as `author: orchestrator` with a naming line in `body_markdown`; carry an
agy sign-off in `status_note`, not `signoffs[]`). A failed POST never blocks the
protocol.

**RETRO GAP:** inbox-check convention only fires at spawn; directive 1500 asks
for per-phase-boundary re-scans. Honor that every round-006 phase boundary.
Inbox as of this run: 1500 + 1515 PROCESSED; newest inbox item is 1515 (14:26),
no unprocessed message remains.

**agy tends to commit stray `.team/markers/` files** (it hand-committed
`006-camera-end.md` in its first pass; removed on the revision). Marker files ARE
tracked in this repo by precedent (rounds 001-004 markers are on main), so a
stray marker is untidy but not a merge blocker. Watch for it; ask agy to drop it.

**Style-rule tension still on `main`, Scott's to rule on:** tracked files with
em-dashes CLAUDE.md forbids (`.pka/CLAUDE.md`, an inbound steering message, a
verbatim critic vote in `docs/decisions/003`). None in an open diff.

**Deferred non-blocking follow-ups:** pin the zoom index remap + epsilon on
bounds assertions; the `check_consensus.py` `covered_entries()` prose-scan bug;
an anchor-drift gate in `process_assets.py`.

---

**Last updated:** 2026-07-17T~21:35Z (orchestrator run
`orchestrator-run-20260717-204425`). This run ran round-006 EXECUTION for all
non-Meshy work, end to end: (1) dispatched 3 non-Meshy slices detached, verified
each from its end marker + tree: claude null-fix (`dd86f7e`, real node-path root
cause + regression), codex scale-contract (`fd73f04`), agy camera-calibration
(`8168e65`). (2) Orchestrator VERIFICATION of agy's calibration caught a real
cross-slice conflict: the render camera must be 30 deg (arcsin 0.5), not atan(0.5),
and at 30 deg it foreshortens height to `32*sqrt(6)` px/m, conflicting with codex's
signed 64 px/m. (Orchestrator initially mis-forced atan(0.5); agy's evidence + a
hand-derivation corrected it.) (3) Ran the reconciliation as a four-ballot with an
adversarial CRITIQUE round: round-1 A,A,B,B; the coupling proof (upright+depth share
screen-Y, locked at 30 deg) refuted Option A's "clean projection scalar" premise;
both A-voters withdrew; team went 4-0 Option B. Authored decision 010, committed to
the round branch (`de0173f`). (4) Dispatched the 010 implementations (codex contract
-> `3b85b28`, agy calibration -> `1fac9b0`), verified both (agy's render.sh now
PASSES at 30 deg with the 32*sqrt(6) golden-pole check). (5) Orchestrated 3
non-author cross-signs (codex->claude, agy->codex, claude->agy, all signed-off),
merged all 3 --no-ff into `round/006-two-rivers` (`22f8e4c`), FULL SUITE GREEN,
pushed. (6) Discovered Meshy IS provisioned (key + MCP wired) - the expected pilot
blocker does NOT exist. Every dispatch verified from end marker + tree, never
narration. NEXT: the Meshy pilot (round 006's art deliverable) - verify MCP
reachability in a doer, then generate the cottage + player.
