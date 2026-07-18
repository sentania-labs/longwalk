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
GROUND (010) + LANE (011) + DIRT FIDELITY (012) + DIRT RE-TUNE (013) + STONE
REMOVAL (014) + **DIRT FILL QUALITY (decision 015) INTEGRATED + PUSHED**. Round
head **`3c4c905`** on origin. ALL THREE dominant dirt tells now CLOSED in
sequence: grey stones (014), amber/brown rocks (014), membrane-smooth muddy
fill-islands (015). **agy QA PASS 8 = CONFUSABLE**, orchestrator decode AGREES at
0.5x/1x/2x. **SURFACED A BUILD (screenshots) TO SCOTT** (cross-workspace
request_id `6110faed`, filed 2026-07-18 16:42Z) per his confusable bar. Awaiting
his checkpoint read. The PAID PATH IS DONE and CLOSED; zero paid spend from here.

=== STATUS: DECISION 015 INTEGRATED + PUSHED; QA8 = CONFUSABLE; SURFACED TO SCOTT ==
**Decision 015 (dirt fill quality) COMPLETE + on origin @ round head `3c4c905`.**
THIS RUN verified everything from marker+tree+self-run gates+decoded PNGs, never
narration:
- **Impl `b3eecac`** (claude, run 015-impl-claude-20260718-154711, 2184s, exit 0,
  not cap_expired, branch_changed yes, ONE commit). project.godot NOT in commit +
  header intact; no tracked uncommitted work (only untracked .pka/.team scratch).
  Energy-matched mid graft (MID_GAIN 1.40->1.20, lands 1.03x, no over-graft) +
  codex local-tone anchor (base+local_tone-box(base) over 32px known substrate) +
  mid HELD at 014 baseline 1.25 (codex mid-2.50 rejected, muddy revival impossible)
  + only lomid lifted 1.55->2.00 + explicit rolled validity-mask grain (kills agy
  jigsaw). BAND_GAINS (1.95, 2.00, 1.25, 0.14).
- **ORCHESTRATOR SELF-RUN GATES on b3eecac:** suite GREEN (deterministic bake
  byte-identical). export gate PASS (checksum b8fac2b4..., non-mutation guard clean).
  decode_dirt_gates.gd: **flat-core lum_std 18.54 >= 18.44** floor, shoulder-dirt
  gradient 10.50 (vs accepted-014 10.35, +1.45%, intended dry-speckle trade), core
  gradient 9.04. Own numeric decode (center crop): blur-island low-freq std
  9.09->7.89 (-13%, the win), speckle hi-freq 11.87->12.16 (+2.4%), tone mean
  84.33->84.73 (stable, no muddy revival). Visual decode ground-2x + village-2x:
  014 membrane-smooth muddy islands CLOSED into continuous dry-tan speckle,
  stones/amber still gone, no new clone/seam/jigsaw/global-mud tell.
- **codex NON-AUTHOR sign-off `3c4c905`** (rev/015-signoff off b3eecac, run
  015-signoff-codex-20260718-163205, 268s, exit 0, marker only 1 file). reviewed_by
  codex-worker != authored_by claude-worker, reviewed_sha == b3eecac exact.
  Independently reproduced byte-identical (plate/detail sha256 match), suite+export
  gate pass, flat-core 18.54, **open-window 12-64 mid RMS 10.46** (near baseline
  11.01, far below rejected 17.68), decoded islands closed no new tell.
  `.team/signoffs/claude-015-fill-impl-b3eecacb038d.md`.
- **INTEGRATED linear FF:** round 94ee00b -> b3eecac (signed impl) -> 3c4c905
  (marker), signed SHA b3eecac preserved (no rebase). Re-ran suite+export gate on
  integrated tree (same checksum b8fac2b4...). **PUSHED origin 94ee00b..3c4c905.**
- **agy QA PASS 8 = CONFUSABLE** (`docs/art/village/qa-agy-dirt-008.md`, agy
  `b8083e7` on agy/015-qa8 off 3c4c905, run 015-qa8-agy-20260718-163914, workdir
  == real lw-007-agy [NOT scratch], branch_changed yes, exit 0). QA7 fill islands
  closed, muddy tone gone, no new tell, no regression. **Orchestrator own decode at
  0.5x/1x/2x AGREES: CONFUSABLE** (district reads spike-family; dirt = coherent dry
  trodden earth; no shimmer/crawl at 0.5x).
- **SURFACED TO SCOTT** (cross-workspace to: dalinar, request_id `6110faed`,
  2026-07-18 16:42Z): the four export-gate screenshots + spike side-by-side,
  honest scope (ONE inn-green district, not yet full village; no clickable exe
  yet). Ask: do the screenshots clear the confusable bar? If yes -> full-village
  expansion + free-cam playable Windows build. If no -> iterate the named tell.
  Response lands in `.pka/inbound/6110faed-*.md`.

=== SUPERSEDED (decision 014 detail; kept for lineage) ==
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

=== DECISION 015 LINEAGE (full-protocol converged, now DONE) ===
Full protocol ran in one prior run off round head 2302d30. Blind proposals:
claude `d48c7d2` (energy-matched graft, MID_GAIN 3.80->1.40), codex `5bb9579`
(clean-patch full-band fill), agy `ff9f0e4` (over-graft MID_GAIN 5.0). Critiques:
claude 1b18a9c / codex fe9d943 / agy ff829b2. agy DISQUALIFIED (over-graft +12.36
mid deficit + md5-proven STALE ground capture + 2-peer + decode). Contested
question (codex clone-stamp visible at district?) resolved by orchestrator decode:
NOT visible (32px high-pass confines the 83.7% translation to sub-32px speckle). No
2-2, no four-ballot, no critic. Synthesis = claude clone-immune energy-matched mid-
graft spine + codex local-tone anchoring + minimal global lift (reject codex mid-
2.50) + validity-mask grain. Losing objections recorded VERBATIM in
`docs/decisions/015-*.md`. Decision record `94ee00b`. Impl by claude `b3eecac`,
codex NON-AUTHOR sign-off `3c4c905`, agy QA8 CONFUSABLE `b8083e7`. All integrated
+ pushed (round head `3c4c905`). See STATUS block above for the full verify trail.

--- ON RESPAWN, do in order: ---
1. **Check inbox `.pka/inbound/`** for Scott's reply to surface request_id
   `6110faed` (also `.pka/inbound/orchestrator/`). Fetch --all; scan doer branches
   for `.team/blocked/`.
2. **Branch on Scott's checkpoint read:**
   - **If Scott says CONFUSABLE / GO** (or approves the screenshots): proceed to
     FULL-VILLAGE EXPANSION. Scale the confirmed-fidelity inn-green district to the
     full ~12-16-structure Two Rivers village (cottages, inn-anchor, dirt lanes,
     hedges, gardens, trees, flora, props), and wire the free ("disincorporated")
     drag-pan/zoom camera with NO PC / NO NPC (camera-follow paths that assume a PC
     may need a free-cam mode -- in scope). Deliverable = a PLAYABLE Windows build.
     Triage the expansion (likely FULL PROTOCOL for layout/scene design; the dirt
     ART is settled). ONE round PR to main + external Codex review; address; merge;
     sweep. This is the round-007 milestone deliverable.
   - **If Scott names a remaining tell** (grass too olive, dirt too mottled, etc.):
     triage it, run the protocol against the specific tell off round head 3c4c905,
     iterate. Do NOT expand the village until the art bar is settled to his eye.
   - **If NO reply yet** and this is a fresh respawn: do NOT re-surface (a POST/ask
     is not the protocol; a missing reply is not a failure). The confusable bar is
     met by the team's own read; if autonomy directive 1500 + Q2 GO still hold, it
     is defensible to BEGIN full-village expansion autonomously rather than idle --
     but getting Scott's checkpoint read first is the lower-risk path the surface
     was written for. Prefer waiting one respawn cycle for his read before spending
     the expansion effort; if still silent, begin expansion and note it.
3. Whatever the branch: verify every dispatch from marker+tree+self-run gates+
   decoded PNGs, never narration. codex/agy never push; only orchestrator pushes
   the round branch. agy adapter can no-op into scratch -- verify workdir in marker.

**Live worktrees + branches (all LOCAL except `round/007-village`):**
- `lw-007-round` on `round/007-village` @ `3c4c905` (== origin; integration tree;
  decision 015 record + signed impl + signoff marker + all prior 007 slices).
- `lw-007-claude` on `claude/015-fill-impl` @ `b3eecac` (signed 015 impl; also holds
  the ONLY copy of `.pka/round007/ground-source/*`). 015 proposal `claude/015-fill`
  @ d48c7d2, critique 1b18a9c.
- `lw-007-codex` on `codex/015-fill` @ `5bb9579` (proposal), critique fe9d943.
  Reuse (ephemeral rev/ worktree) for the next codex NON-AUTHOR sign-off.
- `lw-007-agy` on `agy/015-qa8` @ `b8083e7` (QA8 report). Reuse for the next agy QA.
- rev/015-signoff worktree REMOVED this run (signoff integrated into round head).
- Prior 007 slices (010-015) all in round head 3c4c905 history. Local doer/
  deliberation branches archive to `refs/archive/007/*` at round close.

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
(dirt re-tune multiband reshape), **014** (source-level stone removal), **015** (dirt
fill quality) all on the round branch @ 3c4c905. 009-012 signed 4-0; 013 + 014 + 015
are full-protocol converged records touching NO protected path (orchestrator synthesis
+ cited proposal/critique SHAs, not gate-required). Round-006's own 009/010 archive-only.

## Notes for the next run

- **Dashboard `/team` tab is KILLED by Scott** (inbox `2026-07-18-0445`): do NOT
  POST to `dashboard.int.sentania.net/api/team`. No in-repo sync tool exists;
  compliance = simply not posting. Duty suspended; a missing POST is not a failure.
  Inbox fully processed through 04:45Z; NO new orchestrator inbox messages this run
  (checked at start).
- `gh pr edit` is broken (GraphQL projectCards). Use REST `gh api -X PATCH
  repos/sentania-labs/longwalk/pulls/N ...`.
- No round PR is open (correct -- opens only for the full-village milestone once
  Scott confirms the art bar and the district is expanded).
- **Sweep DONE this run + clean:** 0 open team PRs; origin carries only `main`,
  `round/007-village` @ `3c4c905`, unrelated `issue-4-world-eras`; leak guard PASS
  (no doer/rev branches on origin). rev/015-signoff worktree+branch REMOVED
  (integrated). NOTE for next: lw-007-codex still on codex/015-fill, lw-007-agy on
  agy/015-qa8 (LOCAL only; rebranch off round head for the next slice, don't leak).

**Last updated:** 2026-07-18 (DECISION 015 INTEGRATED + PUSHED + QA8 CONFUSABLE +
SURFACED TO SCOTT. Verified claude impl b3eecac from marker+tree [exit 0, not cap-
killed, 1 commit, project.godot absent, no tracked uncommitted]. Self-ran gates:
suite GREEN, export gate PASS [checksum b8fac2b4], decode_dirt_gates flat-core
18.54>=18.44, shoulder 10.50 [+1.45% vs accepted-014]; own numeric decode blur-
island -13% / speckle +2.4% / tone stable; visual decode islands CLOSED. codex NON-
AUTHOR sign-off 3c4c905 [reviewed_by codex != authored_by claude, byte-reproduced,
open-window mid RMS 10.46 near baseline 11.01]. FF-integrated linear [94ee00b ->
b3eecac signed -> 3c4c905 marker, signed SHA preserved], re-ran suite+gate on
integrated tree, PUSHED origin 94ee00b..3c4c905. agy QA8 = CONFUSABLE [b8083e7,
workdir==real lw-007-agy verified], orchestrator own decode at 0.5x/1x/2x AGREES.
ALL 3 dirt tells [stones/amber/fill-islands] now closed. SURFACED screenshots to
Scott [cross-workspace request_id 6110faed, honest scope: district not full village].
Sweep clean, rev worktree removed. RESUME: check inbox for Scott's reply; if GO ->
full-village expansion + free-cam playable Windows build; if tell named -> iterate;
if silent -> prefer one wait cycle then begin expansion. Every dispatch verified
from marker+tree+decoded PNGs+self-run gates, never narration.)

**PRIOR update:** 2026-07-18 (DECISION 014 INTEGRATED + PUSHED + QA7. Verified
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
