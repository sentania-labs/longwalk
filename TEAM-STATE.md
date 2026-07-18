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

**HOUSEKEEPING RUN (orchestrator-run-20260718, doer-branch-leak cleanup + root
cause). Round 006 iteration NOT resumed (still paused, awaiting Scott).** This
run was a targeted housekeeping dispatch, not a continuation of the paused
Two Rivers iteration. What it did, all verified on disk:
- INBOX: dalinar's routing reply to escalation `c3ffe894` landed
  (`.pka/inbound/orchestrator/c3ffe894-...md`). It is NOT Scott's vision-bar
  answer. Dalinar confirmed the vision-bar call is Scott's alone, wrote the
  decision brief to Scott's queue
  (`scott/reports/2026-07-18-longwalk-meshy-vision-bar-decision.md`), and
  CONFIRMED my hold on all three questions (stay paused on A-tuning; Meshy
  production stays held). So the escalation is still OPEN, awaiting Scott.
  ADDRESSING LESSON from dalinar: cross-workspace asks addressed `to: scott`
  get swept to `agents/riker/inbox/stuck/` (not a routable target) and never
  reach him; address them `to: dalinar` (as `c3ffe894` was) and they land in
  Scott's queue. Two earlier longwalk escalations (walk-cycle art spike,
  Codex-connector-down PR #18 gate) are stuck this way and never reached Scott.
- DOER-BRANCH LEAK CLEANED: 7 stray doer branches deleted from origin (all
  either integrated into round `5eee7bf` or byte-identically preserved under
  `refs/archive/006/*`). `origin/codex/006-acceptance` RETAINED on purpose
  (real unmerged harness work adaf9a0, not integrated; round is paused). See
  the Branch and PR sweep section.
- ROOT CAUSE FOUND + FIXED (commit **b14e39a** on main): the doer leak was
  caused by the WORKER BRIEFS THEMSELVES telling doers to push. Neither the
  dispatch machinery (`vault/scripts/team/dispatch.sh`) nor the codex adapter
  (`vault/scripts/team/adapters/codex.sh`) runs `git push`; verified by reading
  both. The briefs' "never end your turn on an intention" section said the
  durable artifact "exists on disk (commit PUSHED, ...)" and the blocked-marker
  rule said the marker goes on your branch "committed and PUSHED". Fixed all
  three doer briefs (codex/claude/agy): added a plain imperative that doer seats
  NEVER run `git push` (only the orchestrator pushes, only the round branch),
  and corrected both misleading "pushed" phrasings. Added a third end-of-round
  sweep item to `roles/orchestrator.md` that asserts zero doer-prefixed branches
  on origin and fails LOUDLY (nonzero exit) if any are found.
- CREDENTIAL-LAYER NOTE (for the record): this rule is UNENFORCEABLE at the
  credential layer. Doer seats technically still hold push access, so this is a
  convention being violated, not a hard block. Scoping doer credentials to
  remove push entirely is a VAULT-SIDE INFRA item, not fixable from inside this
  repo. Until that lands, the fix is prevention (briefs) + detection (sweep
  guard), not prohibition.

**Status:** `ROUND 006 MESHY PILOT: steps 1-4 DONE. BOTH candidates A+B
byte-stable + clean-signed + integrated; STEP 4 (in-engine integration) now
DONE, peer-signed, MERGED onto round/006-two-rivers @ **5eee7bf**, suite GREEN,
pushed. STEP 5 (codex acceptance-capture harness + gate verdict) DISPATCHED
DETACHED this run (orchestrator-run-20260718-024xxx). Meshy balance 2970
(verified via meshy_check_balance THIS run; NO paid work all run). No PR yet
(round PR opens only after the acceptance gate passes).

*** THIS RUN (0248): step 4 verified+signed+integrated; step 5 dispatched.
Verified from tree/markers, not narration: ***
- STEP 4 integration landed CLEAN as ONE commit ae74a8a on claude/006-integrate
  (end marker integrate-20260718-022227-end.md: branch_changed=yes, exit0,
  cap_expired=no, uncommitted=no; 4 files +329/-4: src/render/town/candidate_art.gd
  [new], player_controller_2d.gd, starter_town.gd, tools/art/verify_candidate_integration.gd
  [new]). Selector LONGWALK_ART_CANDIDATE=current|a|b; default = byte-for-byte
  round-005. Orchestrator independently ran suite (exit0) + both headless proofs
  (a,b PASS); no protected paths; no em-dash.
- PEER GATE WORKED (codex, non-author). Round 1 (integrate-review, 104s):
  **changes-requested** at .team/signoffs/claude-006-integrate-ae74a8a5fd0f.md --
  REAL defect: commit CLAIMED cell size manifest-driven but set_candidate() only
  ASSERTED cell==hardcoded WALK_CELL_SIZE while _apply_walk_frame() + the verifier
  hardcoded 160. Fix routed to author (claude, fast-lane one-repair, no ballot).
- FIX landed as ONE commit 2b7d94e ("Make candidate atlas cell size genuinely
  manifest-driven"): stores _walk_cell_size from manifest, region math + verifier
  derive cell from manifest; default path unchanged. Orchestrator re-ran suite
  (exit0) + both proofs (PASS), no em-dash, tree clean.
- RE-REVIEW (integrate-resign, codex non-author, 86s): **signed-off** at
  .team/signoffs/claude-006-integrate-2b7d94e7c6c0.md (reviewed_sha 2b7d94e).
  Genuine: mutation probe cell_size 160->161 -> "5x7 cells versus expected 6x8",
  proving manifest-derived geometry. Signed head affa249 = code 2b7d94e +
  marker-only commit.
- INTEGRATED --no-ff: round 84e54f8 + affa249 -> round head **5eee7bf** (no
  conflicts). Round suite GREEN + both candidate proofs (a,b) PASS on the
  integrated tree. PUSHED origin/round/006-two-rivers @ 5eee7bf.
- STEP 5 DISPATCHED (codex, owns the acceptance-capture harness per decision 009
  DoL; DETACHED, cap 2400s, NO Meshy): label acceptance-harness, worktree
  lw-006-accept, branch codex/006-acceptance cut off round @ 5eee7bf (godot
  fetched; xvfb-run available). Prompt .pka/round006/acceptance-harness-prompt.md.
  Scope: anonymized matched-composition shipping-zoom fixed-color-management
  STATIC + walk-GIF captures for FOUR subjects (candidate A, B, the SPIKE
  reference docs/art/iso-five-asset-spike.png + player-walk-iso-spike.gif, the
  CURRENT round-005 default build) under docs/art/acceptance/subject-<N>/ with a
  SEALED _key.json; PLUS deterministic measurements per candidate (8 distinct
  facings, feet within 2px contact-anchor tol, no-boiling metric, scale ratios +
  no-runtime-tweak, ground seams + shared light vector, cleanup-ledger economics
  extrapolated to ~200 assets); PLUS docs/art/acceptance/VERDICT.md scoring the
  SIX pass conditions (measurable = PASS/FAIL+numbers; aesthetic = defer to
  orchestrator, anonymized subject-N). Full rerender from committed local inputs,
  NO Meshy. ONE commit, no self-signoff, no PR. Start marker
  acceptance-harness-20260718-024836-start.md; proc tree confirmed alive.
  POLL lw-006-accept/.team/markers/acceptance-harness-*-end.md; VERIFY from end
  marker + tree; balance must stay 2970.
  AFTER it lands: orchestrator READS the anonymized subject-N images + VERDICT.md
  and RULES the gate against the six conditions (form the aesthetic judgment
  BEFORE opening _key.json; four-ballot if the A-vs-B choice is contested). Then
  peer-sign the harness (non-author = claude or agy). Do NOT open the round PR
  until the acceptance gate PASSES. When it clears: surface the playable build to
  Scott (vision bar, directive 1500) + the Meshy production-adoption escalation
  (decision 009 / directive 1515), paired with the git-lfs/artifact-store call.

*** PRIOR RUN (013944): integrated B; dispatched A's byte-stability re-review
(stale-signoff catch). Both now resolved (see THIS RUN above). ***
Historical detail kept below for context.

*** OLDER (013944 detail) *** Meshy balance 2970. No PR yet.

*** THIS RUN (013944): integrated B, dispatched A's fix-review (stale-signoff
catch). Verified from tree, not narration: ***
- CANDIDATE B (f08e2c7 code + 60ceb9c signoff-marker head): codex sign-off marker
  claude-006-candidate-b-f08e2c74f29c.md is CLEAN (reviewed_by codex / authored_by
  claude / signed-off / byte-stable proven twice / balance 2970). No protected
  paths. INTEGRATED --no-ff -> round/006-two-rivers **80435d1**. Round suite GREEN
  (SUITE_EXIT=0, all active-path suites) in lw-006-round.
- CANDIDATE A STALE-SIGNOFF CATCH: the a56a370 sign-off (agy, marker
  codex-006-candidate-a-a56a3705d3cb.md) does NOT cover the byte-stability fix
  8212464, which landed AFTER it and REGENERATED all 50 delivery PNGs (+pins
  seed/dither/threads in the SHARED tools/art/blender_pose_rig.py, +PROVENANCE).
  8212464 is UNSIGNED -> per merge rule a changed SHA needs review at the new head.
  Round branch head 1208ef0 still merged the OLD (non-byte-stable) A; A must be
  re-integrated at 8212464 after it signs clean.
- DISPATCHED (claude, non-author; author is codex; DETACHED, cap 3600s, NO Meshy):
  label candidate-a-review-fix, worktree lw-006-cand-a, branch codex/006-candidate-a
  @ 8212464. Prompt .pka/round006/candidate-a-review-fix-prompt.md. Claude re-renders
  A twice, md5-diffs all 50 deliverables (must be byte-identical, ZERO drift),
  verifies committed==fresh reproduce, PROVENANCE render time real, suite green,
  no em-dash, then commits ONLY the marker
  .team/signoffs/codex-006-candidate-a-8212464520e9.md (signed-off or
  changes-requested). Start marker candidate-a-review-fix-20260718-014501-start.md;
  proc tree confirmed alive. POLL
  lw-006-cand-a/.team/markers/candidate-a-review-fix-*-end.md; VERIFY from end
  marker + tree; balance must stay 2970.
  After it signs clean: RE-INTEGRATE A at 8212464 --no-ff onto round (on top of
  80435d1; brings A's deliverables to byte-stable), run round suite GREEN.
  If changes-requested: route fix to codex (author), NO Meshy.

*** PRIOR RUN (010412): resolved the shared-vs-specific nondeterminism question,
dispatched both byte-stability closers DETACHED (both landed: A fix 8212464, B
resign marker 60ceb9c). ***
Verified from tree (not narration):
- CANDIDATE B fix landed as REAL commit **f08e2c7** on claude/006-candidate-b
  (worktree head confirms; no fix end-marker was written but the commit is real).
  Commit msg: root cause = multithreaded Cycles + OpenImageDenoise float-order
  nondeterminism; fix pins seed=0/dither=0/threads=1(FIXED) in B's OWN driver
  render_candidate_b.py; claims reproduce-twice byte-identical + render time filled.
  f08e2c7 has NO fresh peer sign-off yet (codex's changes-requested was vs 89a0b59).
- SHARED-PATH QUESTION RESOLVED: Candidate A renders via the SHARED
  tools/art/blender_pose_rig.py `--production` path (A/reproduce.sh:13), which has
  NO thread/seed/dither pinning. B forked its own driver and pinned only that. So
  A almost certainly drifts the SAME 1-ULP way and agy signed A WITHOUT codex's
  per-pixel byte diff. blender_pose_rig.py is NOT a protected path (checked) -> no
  decision record needed to pin it. This is fast-lane (known bug, one obvious repair
  already empirically validated on B), NOT a four-ballot question.
- DISPATCHED (both codex, detached, cap 3000s, ZERO Meshy, balance must stay 2970):
  (1) label candidate-a-determinism, worktree lw-006-cand-a, branch codex/006-candidate-a
      @ a56a370. Prompt .pka/round006/candidate-a-determinism-prompt.md. Pin the
      determinism sources in the SHARED blender_pose_rig.py, re-render A, PROVE
      byte-stability (reproduce twice + md5 diff all sprites/atlas), fill PROVENANCE
      render time, suite green, ONE commit. codex authors (its own candidate A).
      Poll lw-006-cand-a/.team/markers/candidate-a-determinism-*-end.md.
      After it lands: re-review by NON-codex (claude or agy), then re-integrate A
      onto round branch (current A integration 1208ef0 is PROVISIONAL / will change
      bytes on re-render), re-sign at new SHA.
  (2) label candidate-b-resign, worktree lw-006-cand-b, branch claude/006-candidate-b
      @ f08e2c7. Prompt .pka/round006/candidate-b-resign-prompt.md. codex (non-author;
      it raised the finding) RE-RENDERS twice + md5-diffs to verify byte-stability at
      f08e2c7, checks PROVENANCE render time filled + balance 2970 + no em-dash, then
      writes ONLY the marker .team/signoffs/claude-006-candidate-b-f08e2c74f29c.md
      (signed-off or changes-requested). Poll
      lw-006-cand-b/.team/markers/candidate-b-resign-*-end.md.
Both start markers written at stamp 20260718-010843; both codex trees confirmed
alive (timeout->codex->codex-code-mode). VERIFY EACH FROM ITS END MARKER + TREE.

*** PRIOR STATUS (superseded by the block above, kept for context) ***
STEP 3: CANDIDATE A COMPLETE + peer-review IN FLIGHT; CANDIDATE B partial ->
RECOVERY. Meshy balance 2970 (20 legit credits spent by B's 2 retextures).

*** STEP-3 STATE AS OF THIS RUN (verified from end markers + tree, not narration) ***
Both PRIMARY candidate dispatches from run 232726 have ENDED. Verified:
- CANDIDATE A (codex, deterministic NPR, NO Meshy): DONE + CLEAN. End marker
  candidate-a-20260717-233116-end.md: branch_changed=yes, exit0, cap_expired=no,
  uncommitted=no. Delivered commit **a56a370** ("Deliver Candidate A sprite atlas")
  on codex/006-candidate-a: full 8-facing x 6-pose player_walk_atlas.png + manifest
  + player_scale.json + treat_candidate_a.py (deterministic 16-colour palette
  quantise + normal-NPR) + reproduce.sh + finished/ sprites, render/ gitignored.
  60 files. PEER-REVIEW dispatched THIS RUN: agy reviews a56a370 (non-author; author
  is codex), worktree lw-006-cand-a, label candidate-a-review, cap 2400s. Prompt
  .pka/round006/candidate-a-review-prompt.md. Poll marker glob
  lw-006-cand-a/.team/markers/candidate-a-review-*-end.md. Expected artifact:
  .team/signoffs/codex-006-candidate-a-a56a3705d3cb.md.
- CANDIDATE B (claude, PAID Meshy texture-space restyle): PARTIAL. End marker
  candidate-b-20260717-233322-end.md: exit0, cap_expired=no, but branch_changed=NO,
  uncommitted_work=YES. B did the PAID part correctly (option-1 texture-space albedo
  restyle; 2 retexture calls 019f7275-96c8 + 019f7275-a259, 20 credits, balance
  2990->2970, ledger clean in candidate_b/PROVENANCE.md; albedos frozen in tree) AND
  rendered ALL passes (8x6x5 player + cottage), but STOPPED before running the
  treatment, assembling the atlas, and committing. NO finished sprites, NO atlas, and
  branch head still 611664c (uncommitted). RECOVERY dispatched THIS RUN: claude
  finishes the DETERMINISTIC tail (treat -> atlas/manifest matching A's contract ->
  commit) with a HARD zero-paid-call rule (balance must stay 2970; albedos reused).
  worktree lw-006-cand-b, label candidate-b-finish, cap 2400s. Prompt
  .pka/round006/candidate-b-finish-prompt.md. Poll marker glob
  lw-006-cand-b/.team/markers/candidate-b-finish-*-end.md. Verify balance stays 2970.
PROGRESS THIS RUN (orchestrator-run-20260717-233648):
- CANDIDATE A: DONE, agy-signed (marker codex-006-candidate-a-a56a3705d3cb.md,
  reviewed_by agy-worker / authored_by codex-worker, signed-off), orchestrator
  INDEPENDENTLY verified (em-dash clean, no unseeded RNG, manifest contract exact:
  facing order E,SE,S,SW,W,NW,N,NE / cell 160 / anchor [80,159] / 48 frames), and
  INTEGRATED --no-ff onto round/006-two-rivers -> **1208ef0** (signed head 92a9f1e
  = a56a370 code + agy marker). Round suite NOT yet re-run (pending B integration).
- CANDIDATE B: took THREE claude dispatches to land (recurring no-commit failure:
  the doer backgrounds work then ends its turn on an intention to "commit after the
  monitor event", which never re-invokes a claude -p). Primary run rendered+paid but
  did not commit; finish run produced atlas+manifest+finished sprites but again
  ended waiting on a monitor; COMMIT-ONLY run (candidate-b-commit, cap 900s) finally
  committed **89a0b59** ("Deliver Candidate B sprite atlas"). Verified surgical: 60
  files (mirrors A), ZERO raw render passes committed (render/.gitignore works), no
  em-dashes, PROVENANCE + both restyled albedos + atlas + manifest + finished
  sprites + scripts. Balance held 2970 the whole recovery (NO paid call after the
  authored 2 retextures). PEER-REVIEW dispatched: codex reviews 89a0b59 (non-author;
  author is claude), worktree lw-006-cand-b, label candidate-b-review, cap 1800s.
  Prompt .pka/round006/candidate-b-review-prompt.md.
- CANDIDATE B REVIEW (codex): **changes-requested** @ marker
  .team/signoffs/claude-006-candidate-b-89a0b598d39e.md (reviewed_sha 89a0b59,
  reviewed_by codex-worker / authored_by claude-worker). REAL defect, peer gate
  working: a clean reproduce did NOT regenerate byte-for-byte -- N_1.png + S_3.png
  each drifted ONE color channel by ONE value at ONE pixel (2 atlas px), violating
  decision-009 constraint-7's pure-deterministic downstream chain. Plus a
  PLACEHOLDER_RENDER_TIME left in PROVENANCE.md. Everything else codex verified
  CLEAN: suite green, reproduce runs, paid ledger correct (2 retextures, balance
  2970), no em-dashes, NO per-frame generative call, contract 8x6/cell160/[80,159]
  exact. Codex committed ONLY the marker (89a0b59..8825d66).
- CANDIDATE B FIX: dispatched DETACHED this run (claude, label candidate-b-fix,
  worktree lw-006-cand-b, cap 3000s, NO Meshy -- albedos frozen). Prompt
  .pka/round006/candidate-b-fix-prompt.md. Scope: make the Cycles render + composite
  byte-stable (pin seed / deterministic sampling / no dither / pin threads),
  re-render, PROVE byte-stability (reproduce twice + diff), fill the PROVENANCE
  render time, AND REPORT whether the fix is in the SHARED render path
  (blender_pose_rig.py, used by BOTH A and B) or B-specific. Poll marker glob
  lw-006-cand-b/.team/markers/candidate-b-fix-*-end.md; VERIFY balance stays 2970;
  watch for the recurring no-commit failure (if branch_changed=no + uncommitted=yes,
  do a COMMIT-ONLY rescue like candidate-b-commit did). Re-reviewer = codex (it
  raised the finding). B is NOT integrated until it re-signs clean.

*** FAIRNESS / BLAST-RADIUS FLAG (act on this next run): *** Candidate A was
agy-signed AND integrated @ 1208ef0, but agy's review said "fully reproducible"
WITHOUT codex's strict per-pixel byte diff. If B's 1-ULP nondeterminism lives in
the SHARED render path (blender_pose_rig.py), candidate A almost certainly drifts
the same way and agy just did not diff to that rigor. So: when B-fix reports the
root cause, if it is shared, RE-VERIFY A's byte-stability with the same rigor;
if A drifts, A's integration (1208ef0) must be revisited / A re-rendered+re-signed
before the round PR, and the shared fix covers both. Do NOT open the round PR until
both A and B are byte-stable and clean-signed.

LESSON (claude-worker no-commit): for a doer whose job ends in a commit, tell it
explicitly NOT to background work / wait on a Monitor, and if it still fails, a
tiny COMMIT-ONLY re-dispatch (nothing to background) reliably lands it (candidate B
took primary -> finish -> commit-only = 3 dispatches to land 89a0b59).

NEXT after B re-signs clean: integrate B --no-ff onto round/006-two-rivers, run the
round suite (verify GREEN), then step 4 (in-engine integration, claude) and step 5
(anonymized acceptance gate A vs B vs the SPIKE). Meshy balance 2970.

Prior status (steps 1-2, done): GENERATION slice merged @ 1ece706. BLENDER CLEANUP
+ pose/facing-rig slice (step 2) DELIVERED, PEER-SIGNED (codex, 2 rounds), MERGED
into round/006-two-rivers @ 611664c, INTEGRATED SUITE GREEN.

BLENDER SLICE (DONE): branch agy/006-blender-cleanup, signed head 9f61a22 (codex marker
ee3a99d on top), merged --no-ff -> 611664c. Delivers tools/art/blender_pose_rig.py (fixed
iso camera reused from blender_calibration.py, character rotated about world-Z per facing,
SW-native validated, 6-pose sampling of the walk action, per-facing/per-pose PNG passes),
the {facing}_{pose_idx}_{pass}.png NAMING CONTRACT (NAMING-CONTRACT.md; consumed by codex's
build_player_walk.py), RIG-NOTES.md (armature 'Armature', walk action
'Armature|walking_man|baselayer_Armature', frames 1-25, corrected facing_to_rot_z table:
SW=0,S=45,SE=90,E=135,NE=180,N=-135,NW=-90,W=-45), SANITY.md, extended cleanup ledger in
PROVENANCE.md (mesh edits ~5 min/asset, UV/rig 0), cleaned assets under
assets/art_src/pilot/cleaned/ (cottage.blend/glb + player_walk.blend/glb, ~125-130 MB), and
fetch_blender.sh now writes tools/blender/.gdignore so headless Godot's import scan skips
the Blender install (this was the run_tests.sh HANG root cause). PEER GATE WORKED TWICE:
codex changes-requested on d5c8c1b (found 3 real defects: (1) Blender-4.0 rename bug
'NodeOutputFileSlotFile has no attribute name' left frame suffixes on output so the contract
was unmet while Blender still exited 0; (2) facing map unverified / +Y=NE assumption WRONG,
actually SW; (3) run_tests.sh hung on the Blender-install import scan); agy fixed all 3 in
9cb284a; orchestrator INDEPENDENTLY VERIFIED from the tree (fresh sanity = exactly 30
contracted files no suffix; run_tests green exit 0); codex signed off 9f61a22. NO PAID
SERVICE touched this slice (agy has no Meshy; all inputs were already committed).

AGY FAILURE MODES SEEN THIS RUN (honor next time): (a) harness STALLS after committing
('Error: timeout waiting for response'), proc lingers ~0.5% CPU with a clean tree; verify
the commit + clean tree, then SIGKILL the tree (do NOT wait out the cap; the dispatch.sh
trap writes the end marker on kill). (b) leaves scratch litter at repo root (test_rot.py,
top_down.py, top_down_0.png) and un-gitignored render dirs; be surgical, never git add -A.
(c) ONCE wrote a FORBIDDEN self-authored sign-off marker (author never writes .team/signoffs
markers); a hygiene-cleanup dispatch removed it (9f61a22). All three cost extra rounds.

REVIEW GATE WORKED (do not lose these 3 findings if the fix pass is incomplete):
codex changes-requested marker .team/signoffs/agy-006-blender-cleanup-d5c8c1b0df2b.md
(reviewed_sha d5c8c1b, changes-requested) requires: (1) NAMING CONTRACT BROKEN --
render_frame() rename raises AttributeError 'NodeOutputFileSlotFile' has no attribute
'name' on Blender 4.0 yet Blender exits 0; the 30 sanity files were STALE from agy's
first run; produced names keep the frame suffix (SE_0_color_0000.png) so codex's
build_player_walk.py (the consumer) cannot glob the contracted {facing}_{pose}_{pass}.png.
Fix rename + fail-loud (nonzero exit) + clear stale output + prove 30 fresh contracted
files. (2) FACING MAP UNVERIFIED -- only SE rendered; the +Y=NE base-orientation
assumption is unchecked; render NE(0 rot)+1 sign-establishing facing, record evidence,
correct facing_to_rot_z if base orientation differs. (3) run_tests.sh DOES NOT COMPLETE
-- Godot headless import scan hangs on the fetched Blender install (tools/blender/ has
NO .gdignore; stalls on bundled StinsonBeach.tex 5+/27+ min). Fix: fetch_blender.sh
writes tools/blender/.gdignore (or force-add committed marker). assets/art_src/.gdignore
already shields cleaned/, so the cleaned .blend/.glb are NOT the hang source. SHADOW pass
absence is NOT a blocker (decision 009: offline mask is shipped shadow, Blender pass is
cross-check). Footprint note: cleaned assets add ~125-130 MB (both .blend+.glb per asset),
compounds the raw-source footprint for the production escalation.`

**GENERATION SLICE (DONE, signed, merged):** claude-worker `claude/006-pilot-gen`
generated ONE 2x2 half-timbered cottage + ONE player (t-pose -> refine -> remesh
to clear the 300k rig limit -> rig with Meshy's free walk+run) via the Meshy MCP,
committed under `assets/art_src/pilot/{cottage,player}/` with `PROVENANCE.md`
(service meshy-6, all task IDs, verbatim prompts/params, license note, sha256 of
all 14 files, cleanup-ledger seed = 0 quality re-rolls per asset). Raw drafts stay
in gitignored `meshy_output/`; an empty `assets/art_src/.gdignore` keeps Godot from
importing the raw 3D sources. Signed commit `92249ea` (peer-reviewed by codex:
FIRST review `changes-requested` for 7 em-dashes in the manifest -> a real
constitution catch, the peer gate working, NOT a rubber stamp; claude fixed them +
added the .gdignore in `92249ea`; codex re-reviewed + signed
`.team/signoffs/claude-006-pilot-gen-92249ea198bc.md`, all 14 sha256 re-verified,
suite green). Merged `--no-ff` -> `1ece706`, integrated suite GREEN, pushed. The
raw draft previews were eyeballed by the orchestrator and are genuinely on-vibe
(cottage: steep golden thatch, dark timber over pale plaster, brick chimney;
player: grey-green homespun tunic, leather belt, boots, readable silhouette),
slightly glossy/photoreal as raw Meshy renders are (which is exactly what the
downstream painterly pre-render pass exists to resolve).

**ORCHESTRATION ERROR TO SURFACE TO SCOTT (his paid credits): ~40 Meshy credits
wasted.** A transient double-launch of the generation dispatch briefly ran a
SECOND claude+Meshy session in the same worktree before it was SIGKILLed; that
orphan made two `text_to_3d` preview calls (task IDs `019f720c-cbdc-...`,
`019f720c-db8e-...`, prompts differing from the delivered assets). Account delta
was 110 credits vs 70 authored. The doer caught and flagged it in the manifest;
codex confirmed the accounting. Cause = my detachment/verification mistake (a
silent-but-alive detached `claude -p` looked dead, so I probed + relaunched);
fixed process below. Net pilot generation cost: 70 authored + 40 wasted = 110.

**BINARY-SIZE / GIT-LFS CONSIDERATION (for the production-adoption escalation, NOT
blocking the pilot):** the generation slice committed ~180 MB of raw Meshy glb/fbx
+ textures for just 2 assets. Fine for a one-off pilot, but at the ~200-asset
production scale this is untenable in plain git. When the Meshy production-adoption
call goes to Scott (decision 009 constraint 8), pair it with a storage decision
(git-lfs or an out-of-repo artifact store for the raw 3D sources; the constraint-7
re-render input can be the cleaned .blend rather than the raw drafts).

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

**DETACHMENT LESSON (paid for in ~40 wasted credits this run, honor it):** a
`setsid`-detached `claude -p` reparents to init (ppid 1) and then emits NO output
and writes NO end marker for MANY MINUTES while it runs (the harness buffers
`claude -p` output until completion, and Meshy generation legitimately takes
15-20 min). This looks identical to a dead dispatch. Do NOT conclude death or
relaunch on "no output + no end marker" alone. Verify liveness the right way:
`ps -o pid=,etimes= -p <root_pid>` and check for its child MCP procs
(`npm exec @meshy-ai/meshy-mcp-server`). Only relaunch after confirming the
process is genuinely gone. A second launch into the SAME worktree is the
corruption + double-spend hazard, and killing a dispatch tree must SIGKILL the
reparented `timeout claude -p` grandchild too (it survives its adapter's death).
Working detach recipe used this run:
`setsid bash -c "'$DISPATCH' <harness> <wt> <brief> <prompt> --cap-seconds N --label L >> LOG 2>&1 < /dev/null" & disown`,
then poll the end marker at `<wt>/.team/markers/<label>-<stamp>-end.md`.

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

**PILOT SEQUENCE (decision 009 constraints 5-8), steps (1)+(2) DONE, next is (3):**
- (1) Generation (cottage + player + provenance) -- **DONE, signed, merged
  `1ece706`** (see GENERATION SLICE block above). Reassigned agy->claude by
  capability. MCP reachability CONFIRMED in a claude doer.
- (2) Blender topology cleanup + parametric pose/facing rig + gait setup --
  **DONE, signed (codex, 2 rounds), merged `611664c`, suite green** (see BLENDER
  SLICE block above). Delivered by agy. The rig + naming contract that steps 3-4
  consume is now on the round branch.
- (3) **<- NEXT: render candidate A (deterministic NPR/composite, CODEX) AND
  candidate B (texture-space albedo OR single fixed-seed whole-sheet generative,
  CLAUDE) from the 30-deg rig.** Both drive `tools/art/blender_pose_rig.py`
  (fetch Blender first; `run_sanity()` shows the pattern) to render the full 8
  facings x 6 poses walk cycle + passes, then apply their treatment and assemble
  the 8-facing/6-frame atlas via `build_player_walk.py` (cell 160, contact_anchor
  [80,159], facing order E,SE,S,SW,W,NW,N,NE). A is DETERMINISTIC + NO Meshy
  (safe to detach unsupervised). **B likely needs a PAID Meshy generative call
  (retexture/whole-sheet); dispatch B only in a run where you can supervise the
  paid call** (verify prior attempt dead + no duplicate billable work before any
  relaunch; NEVER pass save_to to meshy_download_model). A full 8x6 Cycles CPU
  render at 1024 is SLOW (tens of minutes); give the doer a large cap and verify
  from its end marker next run. codex owns A (sprite-forge mandate: NPR/composite,
  atlas assembly); claude owns B (candidate-B design + integration).
- (4) integrate onto the iso spine via `tools/art/` + `starter_town.gd` (claude),
  building_contact_cell anchor conformance.
- (5) anonymized in-engine ACCEPTANCE GATE vs the SPIKE (constraint 7): static +
  walk-GIF captures, the six independently-failable pass conditions, full rerender
  from committed local inputs with NO second Meshy call, + the cleanup ledger.
  When the pilot clears this gate, THAT is the moment to bring the result +
  cleanup ledger to Scott for the Meshy production-adoption call (decision 009
  escalation) + the vision-bar surface (directive 1500), paired with the
  git-lfs/artifact-store decision for the raw+cleaned binary footprint.

**SCOPING THE NEXT (agy Blender) DISPATCH -- read before writing its prompt:**
Inputs are `assets/art_src/pilot/cottage/cottage.glb` and the player set
(`player_rigged.glb` bind pose; `player_walk.glb`/`player_run.glb` are the skinned
clips). The render rig is agy's `blender_calibration.py`: Cycles CPU, ORTHO camera
at elevation `asin(0.5)` (~30 deg) / azimuth 45, film_transparent, Standard view
transform, 1024x1024, passes Z/normal/position/uv/shadow. SCOPE THIS SLICE TO
cleanup + a PARAMETRIC pose/facing rig (functions that place the camera at facing
F in 45-deg azimuth steps for 8 facings, and sample 6 keyframe poses from the walk
clip) + a SMALL low-sample SANITY render proving it works. Do NOT do the full
8x6x2 Cycles PRODUCTION render in this slice -- Cycles CPU at 1024 is slow and the
full renders belong to the candidate-A/B slices (codex/claude). Nail the OUTPUT
CONTRACT (per-facing/per-pose PNG naming + the render passes) since codex's
8-facing atlas assembly and claude's candidate B both consume it. Player nominal
height 1.75 m (decision 010; `32*sqrt(6)` px/m upright); `check_scale_contract.py`
validates the RENDERED sprites downstream, not the meshes. Consider inspecting the
player rig's bone/anim structure (import the glb, list armature actions) before
finalizing the prompt so the pose-sampling is concrete. Fetch Blender first in the
worktree: `tools/fetch_blender.sh` (binary is gitignored).

Prompt files this run: `.pka/round006/pilot-gen-*.md` (generation, sign-off, fix,
re-sign). Earlier ballots: `/tmp/round006-exec/` (may not survive reboot;
substance is in decision 010).

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
- **DOER-BRANCH LEAK SWEEP (this housekeeping run):** origin held 8 leaked
  doer-prefixed branches. Checked each against round `5eee7bf` before touching
  anything. DELETED 7 stray origin copies (local branches left alone):
  - Integrated into the round branch (head is an ancestor of `5eee7bf`):
    `agy/006-blender-cleanup` (ee3a99d), `claude/006-candidate-b` (60ceb9c),
    `claude/006-nullfix` (f880a6d), `codex/006-candidate-a` (8212464),
    `codex/006-scale-contract` (3b85b28).
  - Proposal/critique/ballot artifact branches, NOT on round but every commit
    byte-identically preserved under `refs/archive/006/*` on origin (zero
    data-loss): `claude/006-proposal` (8da1420 = archive/006/claude-proposal),
    `codex/006-proposal` (d9bef93 = archive/006/codex-{proposal,critique,ballot}).
  - **RETAINED on purpose:** `origin/codex/006-acceptance` @ **adaf9a0**. This is
    the acceptance-capture harness with REAL unmerged work (NOT an ancestor of
    the round branch, 1 unique commit; harness integration is pending the paused
    round). It is itself a leaked branch, but its work is not yet integrated, so
    it cannot be deleted without loss. It goes when the round resumes and the
    harness is signed + integrated + the branch deleted. The new sweep guard
    (roles/orchestrator.md) will correctly fire on it until then; that is the
    intended round-close assertion, and the round is not closed.
- **Remote branches (after cleanup):** `origin/main`; `origin/round/006-two-rivers`;
  `origin/codex/006-acceptance` (retained, above); `origin/issue-4-world-eras`
  (HUMAN branch, author sentania, retained). All other doer branches are
  local-only again.
- **(historical) Remote branches:** `origin/round/006-two-rivers` @ `611664c`
  (integration tree: 3 non-Meshy slices + .mcp.json + decision 009/010 + the pilot
  GENERATION slice + the BLENDER cleanup/pose-rig slice, integrated suite green; PR
  after the acceptance gate); `origin/issue-4-world-eras` (a HUMAN branch, author
  sentania, predates the team framework; NOT the team's to delete, retained). Remote
  `origin/claude/006-nullfix` + `origin/codex/006-scale-contract` are stale doer
  branches (work merged into the round branch); DELETE in the close-out sweep. The
  `claude/006-proposal`/`codex/006-proposal` are archived under `refs/archive/006/*`.
- **Local-only doer branches (merged into the round branch, disposable at close-out):**
  `claude/006-nullfix`, `codex/006-scale-contract`, `agy/006-camera-calibration`,
  `claude/006-pilot-gen` (generation slice, merged @ 1ece706), and now
  `agy/006-blender-cleanup` @ `ee3a99d` (the Blender slice; merged into round
  `611664c`; retained as the `lw-006-blender` worktree checkout).
- **Worktrees (retained on purpose, round 006 in flight):** primary `longwalk`
  (main); `lw-006-round` (round/006-two-rivers @ `611664c`, the integration tree,
  no Blender fetched); `lw-006-blender` (`agy/006-blender-cleanup`, Blender 4.0.2
  FETCHED here, free/idle now -- reuse it for a slice needing Blender, e.g.
  candidate A's render); `lw-006-pilot-gen` (`claude/006-pilot-gen`, free/idle);
  `lw-006-claude` (`claude/006-nullfix`), `lw-006-codex` (`codex/006-scale-contract`),
  `lw-006-agy` (`agy/006-camera-calibration`) - free/idle. For the next (candidate A)
  slice, `git worktree add` a fresh one off the round branch @ 611664c, or reuse a
  free one. All round-005 worktrees torn down.

## Open escalations to Scott

**ONE OPEN, awaiting SCOTT:** the round-006 acceptance-gate ruling +
vision-bar call. Request `c3ffe894-ab59-482a-a85c-a41f3c0b1d76`.
**DALINAR ROUTING REPLY RECEIVED (this housekeeping run), NOT Scott's answer:**
`.pka/inbound/orchestrator/c3ffe894-...md` (status: partial). Dalinar confirmed
the vision-bar call is reserved for Scott (aesthetic direction on shipped art is
his, not the orchestration layer's), wrote the decision brief to Scott's reading
surface `scott/reports/2026-07-18-longwalk-meshy-vision-bar-decision.md`
(carrying my full ruling + candidate A/B breakdown + evidence path + my
recommendation), and CONFIRMED my hold: stay paused on A-tuning until Scott
answers that one specifically; Meshy production stays HELD; no PR / no paid work
expected. Scott's actual answer will arrive as a follow-up cross-workspace reply
(same request_id lineage) or a direct inbound. So this stays OPEN.
ADDRESSING LESSON (from dalinar, honor it for all future asks): address
Scott-only asks `to: dalinar`, never `to: scott`. `to: scott` is not a routable
target and gets swept to `agents/riker/inbox/stuck/` (two earlier longwalk
escalations, the walk-cycle art spike and the Codex-connector-down PR #18 gate,
are stuck there and never reached him). `c3ffe894` routed correctly because it
was addressed `to: dalinar`.
Original filing: request `c3ffe894` filed to dalinar
via cross-workspace. Substance: the Meshy pilot reached the acceptance
gate and does NOT pass on aesthetics (both candidates miss the spike bar; A=NPR
under-tuned/muddy, B=texture-space photoreal-clash); all six measurables pass;
mechanism validated. I asked Scott for (1) the vision-bar read on candidate A's
NPR direction (accept-and-tune vs iterate vs rethink Path 3), (2) whether to
autonomously run the A-treatment tuning iteration now or hold, (3) confirmation
that Meshy production adoption stays HELD. I PAUSED autonomous iteration pending
his read, because the vision bar is his reserved call (directive 1500/1515) and
this is the milestone he asked to see. Treat his reply as authoritative mid-run.

The Meshy-adoption call (1515) stays HELD (pilot inconclusive on fidelity; not
recommending adoption). A 2-2 four-ballot split in round 006 invokes the critic;
a constitution violation or critic-vs-orchestrator standoff escalates.

## Notes for the next run

**HONEST ROUND-006 STATUS READOUT (undecorated):**
- LANDED: the deterministic-baseline PoC (candidate A, codex NPR/composite, no
  Meshy) and the Meshy-based candidate B (claude texture-space restyle) are both
  byte-stable, clean-signed, and integrated in-engine on round `5eee7bf`. The
  acceptance harness ran and produced anonymized captures + a verdict.
- RULED: the acceptance gate does NOT pass on the aesthetic bar. All SIX
  measurables pass and the mechanism is validated, but neither candidate clears
  the spike's fidelity: A is NPR-under-tuned (muddy, but the right direction),
  B is texture-space photoreal-clash (weaker). Full detail + KEY above.
- PAUSED: all further iteration is paused pending Scott's answer to the
  vision-bar escalation `c3ffe894` (already filed; dalinar routed it to Scott's
  queue and confirmed the hold this run; Scott has NOT yet answered).
- CONCRETE NEXT STEP once Scott answers (most likely, per my recommendation): a
  DETERMINISTIC candidate-A NPR treatment-tuning iteration (codex owns A, NO new
  Meshy spend), re-run the acceptance harness, re-rule. No Meshy production
  adoption unless/until Scott approves it.

**IMMEDIATE NEXT STEP (this run's handoff): AWAIT SCOTT'S REPLY to escalation
`c3ffe894` (his vision-bar call), then act on it.** Check `.pka/inbound/` FIRST.
Dalinar's routing reply already arrived (`c3ffe894-...md`) but it is NOT Scott's
answer, only a confirmation that the brief reached his queue and the hold stands.
The acceptance gate is RUN and RULED: does NOT pass on aesthetics (both
candidates miss the spike bar); all measurables pass. Do NOT open the round PR
(gate not passed). Do NOT resume iteration until Scott's actual answer lands.
- IF Scott says "iterate / accept-and-tune candidate A": dispatch a DETERMINISTIC
  candidate-A NPR-treatment tuning slice (codex owns A; NO Meshy needed; brighten,
  raise contrast, warm the palette toward docs/art/iso-five-asset-spike.png,
  sharpen the timber read), re-render byte-stable, then RE-RUN the acceptance
  harness (reuse tools/art/build_acceptance_artifacts.py from codex/006-acceptance
  @ adaf9a0) and re-rule. Iterate until it clears his bar, then surface again.
- IF Scott redirects the direction or path: follow his steer.
- HARNESS INTEGRATION PENDING: codex/006-acceptance @ **adaf9a0** ("Add anonymized
  acceptance capture gate", clean single commit, tools/art/build_acceptance_artifacts.py
  + docs/art/acceptance/{subject-1..4,_key.json,VERDICT.md,measurements.json}) is
  NOT yet peer-signed or integrated onto round (local-only branch, worktree
  lw-006-accept). It is good reusable tooling + the gate evidence; get it
  peer-signed (non-author = claude or agy) and integrated --no-ff onto round when
  the round resumes, or fold it into the round PR at close. The next iteration
  will likely extend it, so signing now is optional.
- KEY (post-ruling): subject-1=B, subject-2=spike, subject-3=current, subject-4=A.
  A = codex NPR (muddy/under-tuned, right direction); B = claude texture-space
  Meshy restyle (glossy/photoreal-clash, weaker). Light-vector: A 0.1deg, B 8.7deg.
--- SUPERSEDED (steps 4-5, DONE this run) ---
- STEP 4 integration: verified clean (ae74a8a), peer-gate found+fixed a real
  cell-size-hardcode defect (changes-requested -> fix 2b7d94e -> signed-off), and
  integrated --no-ff onto round -> 5eee7bf, suite green, pushed.
- STEP 5 acceptance harness: codex delivered adaf9a0 (clean), orchestrator ran +
  ruled the gate (does not pass on fidelity), escalated to Scott (c3ffe894).
- (historical step-5 dispatch scoping): anonymized static +
  walk-GIF captures for candidate A, candidate B, the SPIKE
  (docs/art/iso-five-asset-spike.png + docs/art/player-walk-iso-spike.gif), and
  the current build, at shipping zoom / fixed color management / matched
  composition; then the gate verdict against the SIX independently-failable pass
  conditions (decision 009 constraint 7): painterly fidelity, structural
  preservation (no landmark mutation), motion stability (no boiling / real gait /
  8 distinct facings / feet within 2px contact-anchor tol), scale (ratios, no
  runtime tweak), grounding (no ground seams / shared light vector), production
  economics (the cleanup ledger). Full rerender from committed local inputs, NO
  second Meshy call. Anonymize candidate identity for the comparison; orchestrator
  reads the captures and rules (four-ballot if the A-vs-B choice is contested).
- When the pilot CLEARS the gate: THAT is the surface-to-Scott moment (vision bar,
  directive 1500) + the Meshy production-adoption escalation (decision 009), paired
  with the git-lfs/artifact-store decision for the binary footprint. Do NOT open
  the round PR until both candidates are integrated in-engine + the gate passes.

--- PRIOR IMMEDIATE STEP (DONE, superseded) ---
Verified the A re-review attempt 2 (candidate-a-review-fix2, stamp 015206): it
landed CLEAN (marker acf822f), A re-integrated @ round 84e54f8, suite green,
pushed. Both candidates now byte-stable + clean-signed + integrated. Step 4
dispatched (see Status).
- ATTEMPT 1 (candidate-a-review-fix, stamp 014501) FAILED the recurring claude
  no-commit way: it did all the STATIC checks correctly (pins present
  seed=0/dither=0/threads=FIXED/1; only tools/art/blender_pose_rig.py + PROVENANCE
  + 50 PNGs changed; real render times 841s/832s; no em-dash; balance 2970) but
  then BACKGROUNDED the two-render proof job and ended its turn on a "monitor will
  re-invoke me" intention (log in .pka/round006/candidate-a-review-fix-dispatch.log).
  Nothing re-invokes a claude -p. No proof, no marker.
- ATTEMPT 2 (this run) tightens the proof so backgrounding is not tempting: ONE
  foreground fresh reproduce.sh, then `git status --porcelain` on
  assets/art_src/pilot/candidate_a/ MUST be clean (byte-identical to committed =
  zero drift; unfakeable), then suite green, then commit ONLY the marker. Prompt
  .pka/round006/candidate-a-review-fix2-prompt.md. Dispatched DETACHED; start
  marker candidate-a-review-fix2-20260718-015206-start.md written, proc tree alive.
- B is DONE: integrated @ round **80435d1**, suite green. Nothing left on B.
- Poll `lw-006-cand-a/.team/markers/candidate-a-review-fix2-*-end.md`: read
  branch_changed / uncommitted / cap_expired. Expect ONE marker commit on
  codex/006-candidate-a: `.team/signoffs/codex-006-candidate-a-8212464520e9.md`.
  If signed-off: RE-INTEGRATE A at 8212464 --no-ff onto round (currently 80435d1
  = round + B; this replaces the OLD provisional-A deliverables from 1208ef0 with
  byte-stable ones), then run the round suite GREEN. If branch_changed=no +
  uncommitted=yes: COMMIT-ONLY marker rescue (claude's recurring no-commit bug).
  If changes-requested (any drift / placeholder / em-dash): route fix to codex
  (author), NO Meshy. If attempt 2 ALSO backgrounds and dies: fall back to
  orchestrator-runs-the-render-in-background (harness-tracked, re-invokes) to get
  ground truth, then a COMMIT-ONLY marker dispatch to a non-author doer.
- When A is byte-stable + clean-signed + integrated (B already is): run the round
  suite GREEN, THEN step 4 (in-engine integration, claude) + step 5 (anonymized
  acceptance gate A vs B vs the spike). Do NOT open the round PR until both
  candidates are byte-stable + clean-signed + the acceptance gate passes.

--- PRIOR NEXT-STEP (superseded, kept for context) ---
Dispatch the render-candidate slices (pilot step 3). Check
the `.pka/inbound/orchestrator/` inbox FIRST (per-phase-boundary rule). Steps 1-2
are DONE, signed, merged (`611664c`), suite green. Start with **candidate A (CODEX,
deterministic NPR/composite, NO Meshy -- safe to detach unsupervised):** cut a
fresh branch off `round/006-two-rivers` @ `611664c` in a worktree, have codex run
`tools/fetch_blender.sh` there (or pre-fetch), drive `tools/art/blender_pose_rig.py`
for the FULL 8-facing x 6-pose walk render + passes, apply the deterministic
NPR/composite treatment to painterly 2D, assemble the atlas via
`build_player_walk.py`. Give a LARGE cap (full Cycles CPU render is tens of
minutes) and verify from the end marker + tree next run. Peer reviewer for A =
agy or claude (non-author). **Candidate B (CLAUDE) likely needs a PAID Meshy
generative call -- dispatch it only in a run you can supervise** (verify prior
attempt genuinely dead + no duplicate billable work before ANY relaunch; the
double-launch that wasted 40 credits is the cautionary tale; never pass save_to
to meshy_download_model). Then step 4 (integration, claude) and step 5 (acceptance
gate). Do NOT open the round PR until the acceptance gate passes (one PR per round).
When the pilot clears the anonymized gate vs the spike, THAT is the moment to bring
the result + cleanup ledger to Scott for the Meshy production-adoption call
(decision 009 escalation) AND the vision-bar surface (directive 1500), paired with
a git-lfs/artifact-store decision for the binary footprint.

**SURFACE TO SCOTT (not blocking, but his money): ~40 wasted Meshy credits** from
a double-launch this run (details in the "ORCHESTRATION ERROR" block above). And
when the production-adoption call goes up, pair it with a git-lfs/artifact-store
decision for the ~180 MB/2-asset raw-source footprint (the "BINARY-SIZE" block).

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
Inbox as of this run: 1500 + 1515 + **1620 ("meshy-live")** all PROCESSED. 1620
confirmed Meshy is LIVE and wired for codex + claude-worker seats ONLY (not agy),
lifted the PoC gate on the generative candidate, and set two BINDING constraints
now baked into the art-slice prompts: (a) NEVER pass `save_to` to
`meshy_download_model`, (b) claude-worker project-scoped `.mcp.json` may need a
one-time approval in a fresh worktree (did NOT materialize with
`--dangerously-skip-permissions`). Newest inbox item is 1620 (16:16); no
unprocessed message remains.

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

**Last updated:** 2026-07-18 (HOUSEKEEPING run: doer-branch-leak cleanup + root
cause; iteration NOT resumed). Deleted 7 stray doer branches from origin (kept
`codex/006-acceptance`, unmerged harness); found + fixed the root cause (the
worker briefs told doers to `git push`) in all three doer briefs + added an
origin-doer-branch sweep guard to the orchestrator brief (commit b14e39a on
main); recorded the credential-layer unenforceability; logged dalinar's routing
reply to `c3ffe894` (NOT Scott's answer, hold confirmed) + the `to: dalinar`
addressing lesson; wrote the honest round-006 readout above. Round 006 remains
PAUSED awaiting Scott's vision-bar answer. See the HOUSEKEEPING RUN block at the
top of the Phase section. Full prior-run detail follows.

--- PRIOR RUN, 2026-07-18T~02:58Z (orchestrator run 0248) --- This run drove
STEP 4 + STEP 5 to the acceptance-gate milestone end to end:
(1) inbox clean (1620 newest; no new steer). (2) Step 4 integration ae74a8a
VERIFIED clean; peer gate (codex) caught a REAL cell-size-hardcode defect
(changes-requested) -> author fix 2b7d94e -> re-review signed-off (mutation probe
160->161 proved manifest-driven); INTEGRATED --no-ff -> round **5eee7bf** (suite
green + both proofs pass, pushed). (3) Step 5: codex delivered the acceptance
harness adaf9a0 (clean single commit; 4 anonymized subjects + VERDICT + key +
measurements + tools/art/build_acceptance_artifacts.py). (4) I VIEWED the four
blind subject stills, formed the aesthetic judgment BEFORE opening the key, and
RULED: gate does NOT pass. All six measurables pass; both candidates miss the
spike bar (A=NPR muddy/under-tuned but right direction; B=texture-space
photoreal-clash). Mechanism validated. (5) ESCALATED to Scott (req c3ffe894) for
the vision-bar call + Meshy-adoption steer, and PAUSED autonomous iteration
pending his read (the vision bar is his reserved call and this is the milestone he
asked to see). Balance 2970, ZERO paid work this run; every dispatch verified from
end marker + tree. NEXT: act on Scott's reply (likely: tune candidate A's NPR
toward the spike, re-run the harness, re-rule). Round PR NOT opened (gate not
passed). Harness adaf9a0 not yet integrated (local codex/006-acceptance).

--- PRIOR RUN (`orchestrator-run-20260717-204425`, ~01:53Z) ---
(1) inbox clean (1620 newest, already processed). (2) DIAGNOSED why the A re-review attempt 1 (stamp 014501) left no marker:
end marker showed branch unchanged / exit0 / 99s, and its dispatch log shows the doer
did all static checks then BACKGROUNDED the ~28-min two-render proof and ended its
turn on a monitor-will-re-invoke intention (the recurring claude no-commit failure).
(3) RE-DISPATCHED attempt 2 DETACHED (candidate-a-review-fix2, claude, cap 3600s, no
Meshy, stamp 015206, proc tree confirmed alive) with a tightened prompt: ONE foreground
fresh reproduce + a clean-`git status` zero-drift proof (unfakeable) instead of two
14-min renders, to remove the temptation to background. Set a background poll on its
end marker (re-invokes this run on completion). Balance 2970, no paid work. NEXT: on
marker, verify from end marker + tree; if signed-off, re-integrate A @ 8212464 --no-ff
onto round (currently 80435d1 = round + B), run suite GREEN, then steps 4-5 (in-engine
integration + anonymized acceptance gate A vs B vs spike). Do NOT open round PR until
both A + B byte-stable + clean-signed + acceptance gate passes.

--- PRIOR RUN (`orchestrator-run-20260717-233648`) resolved the STEP-3 render candidates:
(1) Verified from end markers (not narration) that both primary detached candidate
dispatches from the prior run had ended: candidate A CLEAN + delivered atlas
(a56a370); candidate B exit0 but branch_changed=no, uncommitted=yes -- it did the
PAID work (20 credits, 2 retextures, balance 2990->2970, ledger clean) and rendered
all passes but never committed. NO waste (balance matched the authored 20 exactly;
no double-launch). (2) Peer-reviewed A with agy (non-author): signed-off; orchestrator
independently re-verified (em-dash clean, no unseeded RNG, contract exact) and
integrated A --no-ff -> round 1208ef0. (3) Recovered B across THREE claude dispatches
(recurring no-commit bug: doer backgrounds work + ends turn on an intention to
commit-after-a-monitor-event that never re-fires); a tiny COMMIT-ONLY dispatch finally
landed 89a0b59 (clean/surgical: 60 files, zero raw passes, no em-dashes). (4) Peer-
reviewed B with codex (non-author): changes-requested on a REAL determinism defect
(clean reproduce drifts 1 channel/1px on 2 of 48 frames, violating constraint-7).
(5) Dispatched the B determinism fix DETACHED (no Meshy, cap 3000s) to verify next
run, and flagged that candidate A may share the same nondeterminism (agy didn't diff
to codex's rigor). Every dispatch verified from end marker + tree. Meshy balance 2970,
NO credits wasted this run. Nothing left to babysit synchronously; candidate-b-fix is
detached and picked up next run.

--- PRIOR RUN (blender cleanup slice, `orchestrator-run-20260717-222037`) ---
This run drove the ROUND-006 MESHY PILOT
BLENDER CLEANUP + pose/facing-rig slice (step 2) end to end and merged it:
(1) Verified clean starting state (no stray/paid procs; generation slice merged
@ 1ece706; no blocked markers). Inbox: nothing new since 1620. (2) Dispatched agy
(capability seat: owns the Blender tooling, no Meshy needed) for cleanup + a
parametric pose/facing rig + sanity render + ledger. agy delivered d5c8c1b but the
harness STALLED after committing (had to SIGKILL). (3) Ran the peer gate with codex
(the downstream atlas consumer = the right reviewer): codex changes-requested on
d5c8c1b, finding 3 REAL defects (Blender-4.0 rename bug leaving frame suffixes so
the naming contract was silently unmet; the +Y=NE facing assumption was WRONG
(actually SW); run_tests.sh HUNG on Godot's import scan of the fetched Blender
install). (4) agy fixed all 3 in 9cb284a but left a FORBIDDEN self-authored marker
+ scratch litter; a tight hygiene dispatch removed them (9f61a22). (5) Orchestrator
INDEPENDENTLY VERIFIED the fixes from the tree (fresh sanity = exactly 30 contracted
files no suffix; run_tests green). (6) codex re-reviewed + SIGNED OFF 9f61a22.
(7) Merged --no-ff -> 611664c, integrated suite GREEN, pushed. No protected paths
touched (no decision record needed). NO PAID SERVICE this whole run (agy has no
Meshy; all inputs already committed; ZERO credits spent). Every dispatch verified
from end marker + tree, never narration. Closed cleanly at ~61/90 min rather than
cram the large candidate-A render slice into inadequate budget. NEXT: render
candidates A (codex, deterministic, safe) + B (claude, PAID Meshy, supervise),
integration, acceptance gate. Nothing left running.

--- PRIOR RUN (generation slice, `orchestrator-run-20260717-213930`) ---
Drove the ROUND-006 MESHY PILOT GENERATION slice end to end: (1) Processed inbox 1620 ("meshy-live"); recorded the
capability re-division (Meshy wired for codex+claude only, NOT agy, so decision
009's agy generation slice moved to claude-worker). (2) Cherry-picked Scott's
`.mcp.json` infra commit (9a0e2c8) onto the round branch (`aa8eab5`, pushed),
because the round branch was cut before it landed on main. (3) Cut
`claude/006-pilot-gen` off the round branch, dispatched claude to generate ONE
cottage + ONE rigged player via the Meshy MCP -> CONFIRMED MCP reachability in a
doer; verified the completed slice from its end marker + tree (models, manifest,
14 sha256s, 0 quality re-rolls). Raw previews eyeballed = on-vibe. (4) Ran the peer
gate FOR REAL: codex FIRST review `changes-requested` (7 em-dashes in the manifest,
a genuine constitution catch); claude fixed them + added `assets/art_src/.gdignore`
(`92249ea`); codex re-reviewed + signed. Merged `--no-ff` -> `1ece706`, integrated
suite GREEN, pushed. (5) INCIDENT + LESSON: a silent-but-alive detached `claude -p`
looked dead, so a probe + relaunch briefly ran a SECOND Meshy session in the same
worktree before SIGKILL -> ~40 wasted credits (flagged to Scott, in the manifest).
Detachment/verification lesson recorded above. Every dispatch verified from end
marker + tree, never narration. NEXT: the agy Blender cleanup + pose/facing-rig
slice (pilot step 2), scoped in the Phase section. Nothing left running.
