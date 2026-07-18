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
lane/dirt treatment toward the confusable-with-spike bar.**

The bar is Scott's, verbatim: *screenshots confusable with the spike*
(`docs/art/iso-five-asset-spike.png`). Deliverable: a playable Windows build of a
full Two Rivers village at spike fidelity, NO PC/NPC, free ("disincorporated")
drag-pan/zoom camera. Walk-cycle/animation OUT of scope. Method unmandated.
Full scope: `.pka/round007/assignment.md`. Standing posture (directive 1500 +
Scott Q2 GO): autonomous back-to-back iteration; surface a build to Scott ONLY
when the team believes a screenshot genuinely passes the confusable bar.

**WHERE WE ARE:** one inn-green district at spike fidelity for BUILDINGS +
GROUND (010) + LANE (011) + DIRT FIDELITY (012) + DIRT RE-TUNE (013) +
**SOURCE-LEVEL STONE REMOVAL (decision 014) INTEGRATED + PUSHED**. Round head
**`e08786f`** on origin. The stones tell (dominant since QA6) is CLOSED. QA7 is
NOT-CONFUSABLE for ONE new reason: the stone-removal FILL left membrane-smooth /
muddy islands. That is the decision-015 target (see STATUS below). The PAID PATH
IS DONE and CLOSED; zero paid spend from here (all remaining dirt work zero-cost).

=== STATUS: DECISION 014 INTEGRATED + PUSHED; QA7 = NOT-CONFUSABLE (fill islands) ==
**Decision 014 (source-level stone removal) COMPLETE + on origin.** Full protocol
ran last run (blind proposal claude a1e9915 / codex d5725c5 / agy 42ad6a1;
critique claude 38dae8a / codex b012bd3 / agy 770ebf7; synthesis a857db9). Winner:
claude's auto chroma-segmentation detector (only method that removed stones in the
shipped frame; codex hand-list + agy z-score both left ~15 stones in render). Impl
`c10a54c` (extended detector to amber/brown, 20/20 object recall, multiscale
16-64px substrate graft, mid gain 1.30->1.25). First impl dispatch cap-killed with
work uncommitted; FINISH dispatch (935s, marker `014-impl-finish-20260718-142138`)
completed gates+capture+suite, reverted the clobbered project.godot, committed
c10a54c. Codex NON-AUTHOR sign-off `1a2ee48`
(`.team/signoffs/claude-014-stone-impl-c10a54c72282.md`, reviewed_by codex-worker,
byte-reproduced plate+detail, gates core-std 18.80>=18.44 shimmer 8.09<=10.75,
project.godot absent).

**THIS RUN (verified everything from marker+tree, never narration):**
- Confirmed c10a54c: project.godot NOT in commit + working tree clean + pinned
  header intact; uncommitted "work" is only untracked .pka/.team scratch.
- ORCHESTRATOR RENDERED DECODE (viewed ground-2x before[bdfaa28] vs after[c10a54c]
  + spike, matched framing): before = ~15-20 crisp grey lozenge stones w/ speculars
  + cast shadows + 1 amber rock; after = dusty tan, ALL grey stones + amber rock
  GONE. Residuals = dark mid-band mottling + faint amber wash + soft fill islands
  (exactly the synthesis-predicted residuals). Dominant stone tell CLOSED.
- INTEGRATED: reset round to signed 1a2ee48 (FF from 6bb94c6 through
  bdfaa28->a1e9915->c10a54c->1a2ee48; de-peak bdfaa28 rides along as designed),
  cherry-picked decision-014 record a857db9 on top -> round head **`e08786f`**,
  LINEAR, c10a54c signed SHA preserved. Suite GREEN + export gate PASS (non-mutation
  guard clean, checksum 681c83d...) on integrated tree. **PUSHED origin
  6bb94c6..e08786f.**
- **agy QA PASS 7 = NOT-CONFUSABLE** (`docs/art/village/qa-agy-dirt-007.md`, agy
  `69063f3` on `agy/014-qa7`, verified marker `014-qa7-agy-20260718-144052`
  branch_changed yes). Both decision-014 targets RESOLVED: grey stones GONE, amber/
  brown rocks GONE. ONE new dominant tell: **membrane-smooth / out-of-focus fill
  islands + localized muddy-brown tone** where stones were removed (blurry low-freq
  smudges lacking the surrounding dusty speckle; visible ground-2x center/lower +
  village-inn-green-2x path upper-right-of-inn, also at 1x). Localized flat-core +
  muddy-tone regression INSIDE the fill islands only. No tiling/seam/shimmer
  regression. Orchestrator's own decode + district-2x view AGREE with agy.

=== DECISION 015 (fill-quality: kill the membrane-smooth muddy islands) -- NEXT ===
**Triage = FULL PROTOCOL.** The "obvious" fix already exists and proved
insufficient: declutter_dirt_source.py ALREADY does pull-push membrane (low band) +
GRAIN_RADIUS grain transplant (fine band) + a decision-014 multiscale mid-band
graft (MID_LO 16 / MID_HI 64 / MID_GAIN 3.80 / MID_FEATHER 3) added SPECIFICALLY
to kill membrane-smooth islands -- yet agy STILL sees blurry+muddy islands. Root
cause is genuinely uncertain and has method alternatives with distinct failure
modes: (a) pull-push membrane fills with a low-band MEAN darker than local dusty
tan -> muddy; (b) MID_GAIN too low / MID_FEATHER too wide leaves large footprints
flat; (c) fine grain transplant amplitude insufficient -> soft; (d) donor field
tone/variance mismatch. A wrong pick = another full QA cycle. NOT fast-lane.
NOT escalating to Scott (autonomy directive 1500 + Q2 GO: iterate; surface only
when confusable; stones were the last dominant tell and are now closed).

Base decision-015 candidates OFF round head **e08786f** (has the working
detector+removal). TWO HARD GATES unchanged: flat-core center-crop lum_std >= ~18.44
floor; 0.5x dirt fine-grad <= ~10.75 (shimmer). ADD an objective fill-island check:
the removed-stone footprints must match local dusty speckle statistics (fine-band
std + tone mean) within the surrounding substrate, no low-freq blur island, no
darker-than-local muddy tone. Source plate is the ONLY copy + untracked; each doer
worktree needs a COPY of `.pka/round007/ground-source/` (do NOT overwrite original).
`src/render/town/` + tools/art NOT protected; `src/sim/` untouched.

**PHASE 1 BLIND PROPOSALS DONE + VERIFIED + DECODED (all off round head 2302d30):**
- **claude `d48c7d2`** (branch claude/015-fill, elapsed 2019s): root cause = mid
  graft OVER-grafts (MID_GAIN 3.80 = ~1.85x local mid energy) -> the graft became
  the island + muddy DC + ~16% fine-grain dropout holes. Fix: MID_GAIN 3.80->1.40
  (energy-match), 2nd decorrelated roll fills grain holes, restore core std GLOBALLY
  via grade band gains (lomid 1.55->2.00, mid 1.25->1.35, fine UNCHANGED). Island
  check inside/ring: fine 1.05x, mid 1.06x, tone -0.56. Gates flat-core 18.92,
  shimmer unchanged. 20/20 recall.
- **codex `5bb9579`** (codex/015-fill, 1069s): root cause = structural gaps (9.88%
  zero mid-feather from erode(mask,3), 16.31% zero fine grain) + 2.54 lum muddy. Fix:
  REPLACE separate mid+fine grafts with ONE coherent full-band clean-patch fill (4
  fixed rolls pick first donor outside mask, re-centered 32px, >=35% real patch).
  Grade (1.55,1.55,2.50,0.14). Island check fine 1.148x (14.8%), tone -0.27. Gates
  flat-core 20.94, shimmer 9.32. 20/20 recall.
- **agy `ff9f0e4`** (agy/015-fill, 759s): root cause = dark-rim mask anchoring +
  feather erosion. Fix: DILATE mask 4px + INCREASE MID_GAIN 3.80->5.0. Island check
  mid deficit +7.39 (OVER, not matched). Gates flat-core 18.88, shimmer 9.48.
All 3 verified from end markers (branch_changed yes, exit 0, not cap_expired).

**ORCHESTRATOR RENDERED DECODE (viewed all 3 ground-2x vs c10a54c baseline + spike):
claude ~ codex >> agy.** claude closes the muddy islands best (dry tan, continuous,
cleanest center). codex closes them too (slightly more dark mid-structure center-
right). **agy did NOT close the tell -- its ground-2x is nearly identical to the
decision-014 muddy-island baseline; the MID_GAIN 5.0 over-graft entrenched the
island (its own +7.39 mid deficit predicted this).** Strong 2-converge-1-dissent:
claude+codex independently reach matched island energy (the decode rewards it);
agy's opposite direction (over-graft) loses at the render, same failure mode as its
decision-014 candidate. Decode is decisive over the gate numbers (agy passes 18.88
yet the island persists).

**PHASE 2 ADVERSARIAL CRITIQUE DISPATCHED + IN FLIGHT (2026-07-18 15:31:53Z).** All
3 doers running PARALLEL/detached into their worktrees, run ids
`015-crit-{claude,codex,agy}-20260718-153153`, cap 2400s, start markers confirmed +
adapters alive at launch+20s. Prompt `.pka/round007/015-fill-quality-crit-prompt.md`
(each reads the other 2 via `git show <branch>:...`, hunts NEW tells: codex clean-
patch repeat/clone/seam, claude global band-lift reviving muddy mid outside
footprints, agy dilated-mask over-graft). Logs `.pka/round007/015-crit-<doer>-dispatch.log`.

--- ON RESPAWN (decision 015), do in order: ---
1. Check inbox `.pka/inbound/orchestrator/`. Fetch --all; scan doer branches for
   .team/blocked/.
2. **VERIFY the 3 phase-2 critiques** from end markers
   `<wt>/.team/markers/015-crit-<doer>-20260718-153153-end.md` (branch_changed yes,
   critique committed `docs/proposals/<doer>-015-critique.md`). Missing marker =
   still running (pgrep) or died; do NOT re-dispatch a live one. A round where every
   critique says "looks good" is a FAILED round -> re-dispatch. Read each critique;
   note any real defect found in claude's or codex's method (repeat-donor tiling in
   codex clean-patch; muddy-mid revival or tone shift from claude global band lift;
   shimmer from claude hole-fill).
3. **PHASE 3 SYNTHESIS -> docs/decisions/015-*.md.** Provisional read from my decode:
   winner is claude's energy-match OR codex's coherent clean-patch (both close the
   tell); agy's over-graft LOSES (empirically refuted at render). Pick the method
   whose rendered captures are stone-free AND island-free without a new tell; GRAFT
   the better parts (e.g. codex's coherent patch idea + claude's energy-match, if a
   critique shows one dominates). If claude+codex agree and agy dissents -> majority,
   NO four-ballot / NO critic. A 2-2 contested question invokes the critic
   (tiebreaker-only). Record every losing objection verbatim (esp. agy's, and any
   codex-vs-claude method dispute).
4. Winner impl off round head 2302d30, codex (or non-author) NON-AUTHOR sign-off,
   FF-integrate into round/007-village, re-run suite+export gate + DECODE yourself,
   PUSH round branch.
5. Phase-2/3 note: several proposals already ARE working rendered candidates on their
   branches, so the "impl" may be promoting the winning proposal commit directly
   (verify its gates+decode fresh) rather than a new dispatch. -> docs/decisions/015-*.md
   (unanimous/majority = no four-ballot; a 2-2 contested question invokes the critic
   tiebreaker-only). Winner impl off e08786f, codex NON-AUTHOR sign-off, FF-integrate
   into round/007-village, re-run suite+export gate, PUSH round branch.
5. **agy QA PASS 8** off integrated head. If CONFUSABLE **and orchestrator's own
   decode agrees** -> **SURFACE A BUILD TO SCOTT** (cross-workspace `to: dalinar`).
   Stones + amber closed; fill islands are the last known tell. Else decode
   artifacts (never narration), diagnose, tee up next.
6. After dirt clears: expand inn-green district to full ~12-16-structure village;
   ONE round PR + external Codex review; address; merge; sweep.

**Live worktrees + branches (all LOCAL except `round/007-village`):**
- `lw-007-round` on `round/007-village` @ `e08786f` (== origin; integration tree).
- `lw-007-claude` on `claude/014-stone-impl` @ `c10a54c` (impl; also holds the
  ONLY copy of `.pka/round007/ground-source/*`). Rebranch to `claude/015-fill`
  off e08786f for decision 015.
- `lw-007-codex` on `rev/014-signoff` @ `1a2ee48`. Rebranch to `codex/015-fill`.
- `lw-007-agy` on `agy/014-qa7` @ `69063f3` (QA7 report). Rebranch to `agy/015-fill`.
- Prior slices all in round head e08786f history. Local doer/deliberation branches
  archive to `refs/archive/007/*` at round close.

## Round 006 -- CLOSED (superseded)

Everything recoverable under `refs/archive/006/*` (pushed). `git show
refs/archive/006/<name>:<path>`.

## Durable lessons (paid for repeatedly; honor them)

- **A dispatch is synchronous; nothing external re-invokes you when a detached proc
  finishes.** Only supervisor respawn re-invokes you. Own tool calls cap at ~600s --
  SET the Bash `timeout` param up to ~560000ms when polling. EITHER block in one call
  OR detach (setsid) + poll the end marker across calls, capturing in-flight state
  first. Costs seen: paid regen ~24s; render/re-tune/impl slices **~900-1600s**
  (`claude -p`/`godot` buffer ALL output -- verify liveness via `pgrep`, not file
  mtimes); codex sign-off ~150s; agy QA ~110-135s. Sign-off + QA can run IN PARALLEL
  into separate worktrees (both read the same commit).
- **Verify from the end marker + tree, NEVER exit code or narration.** Then RUN the
  suite + export gate yourself and DECODE the actual PNGs (view before-vs-after at
  matched framing + the spike). This run: confirmed c10a54c had no project.godot,
  decoded before/after ground-2x to confirm stones gone, re-ran both gates on the
  integrated tree, read the QA7 marker before trusting the report.
- **The gate numbers are necessary but NOT sufficient; agy's multimodal read is the
  bar.** Decision-014 passed both hard gates AND removed the stones, yet QA7 caught
  fill-island blur + muddy tone that no gate shows. Always run agy QA before believing
  a decode or surfacing. And note the "obvious" fix (the mid-band graft) already
  shipped in 014 and did NOT fully close the islands -> full-protocol, not fast-lane.
- **A paid spend CAN be right when zero-cost is genuinely exhausted, but it TRADES:**
  the one supervised dirt regen fixed the flat core but traded richness for
  seamlessness AND painted-in stones -> multiple downstream zero-cost composite
  rounds (013 re-tune, 014 stone removal, now 015 fill quality). Expect a tail.
- **Stacked slices integrate by fast-forward; cross sign-off = ephemeral detached
  review worktree** (`git worktree add -b rev/<slug> <wt> <sha>`, dispatch NON-AUTHOR,
  cherry-pick the marker). reviewed_by != authored_by. Preserve the signed SHA:
  FF to it, then cherry-pick the (unsigned, orchestrator-authored) decision record
  on TOP -- never rebase/cherry-pick the signed doer commit.
- **agy adapter can no-op into a scratch project; markers catch it.** QA7 committed a
  real report (branch_changed yes, 69063f3) -- verified.
- **Doer seats NEVER push to origin.** Only the orchestrator, only the round branch.
- **Long render/gate/decode proofs run to completion in the FOREGROUND same turn.**
- **Cross-workspace asks to Scott: address `to: dalinar`, NOT `to: scott`.**
- **Do NOT start a paid spend at a run tail.** Remaining dirt work is zero-cost.

## Meshy

Key live at `~/.claude/pka-secrets/longwalk/meshy.env`; MCP `meshy` in `.mcp.json`.
Balance **2937** (9 credits spent total this round on the one accepted dirt regen,
task `019f74b2`, nano-banana-pro). The DIRT paid path is CLOSED -- plate accepted +
rich; remaining dirt tells are zero-cost composite fixes. Do NOT regen dirt again.
Paid source downloads at `.pka/round007/ground-source/*.png` (incl.
`dirt-regen-nbpro-019f74b2.png` = installed plate's source, + legacy
`source-dirt.png`/`source-grass.png`) are the ONLY copies (URLs expired); do NOT
regenerate/overwrite. Any FUTURE paid spend needs its own guard (`meshy_list_tasks`
no PENDING, `meshy_check_balance` before/after, cost-confirm, NEVER `save_to`).

## Active decision records (on main / round branch)

001-008 on main. Round-007 decisions **009** (art method), **010** (ground/lane),
**011** (lane geometry), **012** (dirt fidelity + item-5 paid-regen path), **013**
(dirt re-tune multiband reshape), **014** (source-level stone removal) all on the
round branch @ e08786f. 009-012 signed 4-0; 013 + 014 are full-protocol converged
records touching NO protected path (orchestrator synthesis + cited proposal/critique
SHAs, not gate-required). Round-006's own 009/010 are archive-only.

## Notes for the next run

- **Dashboard `/team` tab is KILLED by Scott** (inbox `2026-07-18-0445`): do NOT
  POST to `dashboard.int.sentania.net/api/team`. No in-repo sync tool exists;
  compliance = simply not posting. Duty suspended; a missing POST is not a failure.
  Inbox fully processed through 04:45Z; NO new orchestrator inbox messages this run
  (checked at start).
- `gh pr edit` is broken (GraphQL projectCards). Use REST `gh api -X PATCH
  repos/sentania-labs/longwalk/pulls/N ...`.
- No round PR is open (correct -- opens only once the district passes the bar).
- **Sweep (verify next run before close):** 0 open team PRs expected; origin should
  carry only `main`, `round/007-village` @ e08786f, unrelated `issue-4-world-eras`;
  run the leak guard (no doer/rev branches on origin). Ephemeral codex review
  worktrees removed. NOTE: lw-007-codex still on rev/014-signoff and lw-007-agy on
  agy/014-qa7 (LOCAL only; rebranch off e08786f for decision 015, don't leak).

**Last updated:** 2026-07-18 (DECISION 014 INTEGRATED + PUSHED + QA7. Verified
c10a54c from marker+tree [project.godot absent, tree clean], decoded before/after
ground-2x [~15-20 grey stones + amber rock GONE], confirmed codex non-author signoff
1a2ee48 [byte-reproduced, gates hold]. Integrated linear: round reset to 1a2ee48
[FF through de-peak bdfaa28] + cherry-picked decision record a857db9 -> round head
e08786f, signed SHA c10a54c preserved. Suite GREEN + export gate PASS on integrated
tree, PUSHED 6bb94c6..e08786f. agy QA7 = NOT-CONFUSABLE: stones + amber GONE [both
014 targets resolved], ONE new tell = membrane-smooth/muddy fill islands where
stones were removed. Orchestrator decode + district-2x AGREE. NOT surfaced to Scott.
Teed up DECISION 015 [fill quality, FULL PROTOCOL -- the obvious mid-band graft
already shipped in 014 and was insufficient] off round head e08786f. Every dispatch
verified from marker+tree+decoded PNGs+self-run gates.)
