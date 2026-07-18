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
GROUND-TEXTURE (010, checkerboard tell fixed) + LANE MACRO-GEOMETRY (011,
straight-X tell fixed) + DIRT TRANSITION/COVERAGE (012, hard-cut + over-coverage
tells fixed). Round head **`7548872`** (pushed to origin). The DIRT-FIDELITY
sub-round (decision 012, fork B) landed + integrated + gated + QA'd this run, and
CLOSED two of the three dirt tells but the DOMINANT one (flat CORE) survives.
agy QA pass 4 = NOT-CONFUSABLE. NOT surfaced to Scott (bar not met). The
pre-authorized HYBRID-C PAID REGEN is teed up for a FRESH TURN below.

=== 010 (ground-texture) + 011 (lane-geometry) -- DONE ==========================
`docs/decisions/010-*.md` + `011-*.md` (both 4-0). Killed checkerboard + straight-X.

=== DIRT-FIDELITY SUB-ROUND (decision 012) -- FORK B DONE, DOMINANT TELL SURVIVES =
`docs/decisions/012-dirt-fidelity.md` (SIGNED 4-0, check_consensus PASS, covers
`src/sim/`). On round branch. Full protocol ran end-to-end THIS run:
- **Phase 1 blind:** ALL THREE chose FORK B (zero-cost shader-composite); NONE
  chose pure paid regen. Proposals claude `960b30ea`, codex `e2242ea1`, agy
  `d49929c2`.
- **Phase 2 critique:** CONVERGED. Painted-luminance substrate beat pure noise by
  concession (agy withdrew pure-FastNoiseLite); codex conceded its 4-channel RGBA
  as over-engineered; bake the high-pass WHOLE (claude's catch). Critiques claude
  `318d238f`, codex `3d5c5f3f`, agy `36d884ac`.
- **Four-ballot (one contested Q: protected-core tonal texture):** 4-0 UNANIMOUS
  FOR codex's bounded middle path (broad low-amplitude drift on core; STRONG
  high-freq shoulder-only; 012 supersedes 010's true-tone prose for the bounded
  case). Ballots claude `11c4a75b`, codex `e1929123`, agy `17c9b6f1`. Critic NOT
  invoked (4-0). No Scott escalation (conformance HONORED via signed record).
  codex mechanism correction folded -> RG8 bake (R high-freq shoulder, G broad
  core). Decision 012 committed `24e4c11`.
- **Impl (stacked, both orchestrator-verified GREEN):** codex bake `7672b3a`
  (`bake_dirt_detail.gd` + `ground_dirt_detail.png` RG8 [R std44/grad34.5 shoulder,
  G std41/grad0.3 broad core] + byte-identity test; suite green, sha256
  9a0d28cd). claude render `6bf5e1d` STACKED (shader composite R-shoulder/G-core
  decorrelated + widened feather + half_widths ~30% narrow + lane re-bake + decode
  harness + export-gate assertion + fresh captures; suite green + export gate PASS).
- **Cross sign-off (both genuine non-author):** codex reviews claude
  (`.team/signoffs/claude-007-dirt-impl-6bf5e1d7e632.md`); claude reviews codex
  (`.team/signoffs/codex-007-dirt-impl-7672b3a75728.md`, incl. independent decode
  of BOTH channels + seed-offset no-collision check).
- **Integration:** stacked -> FF'd round to 6bf5e1d + cherry-picked both markers ->
  full suite + export gate GREEN on integrated tree -> agy QA report cherry-picked.
  **Round head `7548872`, PUSHED.**

**DECODED GATE RESULTS (orchestrator-verified, not narration):**
- Gate 2 (transition): PASS (soft patchy non-monotone edge-break, 12.7/17.6px feather).
- Gate 3 (coverage): PASS (dirt fraction 0.295, grass-dominant).
- Gate 1 (structure): **6.9 < 8.0 target** (up from 4.5; spike ~11.7). Shoulders
  reach 8-9.3 (~spike); the large pooled CLEARING core stays 5.6-6.1 because the
  4-0 honesty ruling confines strong high-freq detail to the shoulder and the core
  shows the FLAT SOURCE PLATE through only a broad drift. Orchestrator-confirmed by
  independent decode (shoulder 9.45, core-region 7.5 on a coarse crop).

**agy QA PASS 4 VERDICT: NOT-CONFUSABLE** (`docs/art/village/qa-agy-dirt-004.md`,
on round branch; agy `8c0414c`). RESOLVED: transition (soft fade) + coverage
(grass-dominant). REMAINING tells, dominant first:
  1. **Flat dirt CORE (dominant, all zooms).** The pooled clearing (protected core)
     reads dead flat; broad drift insufficient; the textured-shoulder-vs-flat-core
     CONTRAST is itself a tell. **Root cause = the FLAT SOURCE PLATE
     `ground_dirt_plate.png` (std 4.5), which the core samples directly.** The
     honesty ruling (vindicated by the shimmer finding below) forbids high-freq
     shader detail on the core, so the ONLY fix is a RICHER PLATE = the paid regen.
  2. **Retinted-grass morphology (1x/2x).** The shoulder detail borrows GRASS
     luminance, so the dirt reads tufted/leafy, not earthy/pebbly. = the "reads as
     retinted grass" hybrid-C trigger, confirmed blind. Fix: switch the shoulder
     detail substrate from the grass plate to the NEW rich dirt plate's own
     luminance (or the legacy dirt-hued `ground_lane.png`, gradient ~12).
  3. **Shimmer at 0.5x.** The shoulder high-freq detail aliases (no committed
     mips). Fix: prefilter/reduce the high-freq band.

=== NEXT TURN (FRESH): HYBRID-C PAID REGEN + COMPOSITE RE-TUNE ==================
All three decision-012 item-5 hybrid-C triggers are MET (gradient<8.0; agy calls
core flat; blinded reads retinted-grass). The single supervised paid regen is
**pre-authorized by decision 012 item 5** (no new decision record needed for the
spend itself). Give it a FULL FRESH TURN (paid-spend-not-at-a-tail rule); this run
was already long. EXACT PLAN:
1. **DOUBLE-SPEND GUARD FIRST:** `meshy_list_tasks` (assert no PENDING/IN_PROGRESS),
   `meshy_check_balance` (expect 2946). Cost-confirm before the call. NEVER pass
   `save_to`.
2. **Regen `ground_dirt_plate.png`:** `meshy_text_to_image`, nano-banana-2 (6cr) or
   nano-banana-pro (9cr), SINGLE generation. Prompt (DROP the seamless-tile framing
   that flattened the original per decision 012): painterly hand-painted top-down
   RPG worn dirt/earth, warm sandy-tan, VISIBLE small pebbles + gravel, scattered
   dry grass tufts, worn patches, strong mottled TONAL/VALUE variation, uneven
   trodden ground, soft painterly brushwork, no characters/buildings, flat even
   lighting. `meshy_check_balance` AFTER; record spend.
3. **ACCEPTANCE decode (do NOT eyeball):** the regen plate std RGB **>= 12** AND
   mean gradient **>= 8** (vs current 4.5/2.5). If it comes back flat again, KEEP
   the fork-B composite and do NOT chase a third spend (decision 012 item 5).
4. **Composite RE-TUNE (impl slice, likely claude render; triage: fast-lane
   re-tune under decision 012, cross-signed -- unless the substrate switch is
   judged contested, then a quick check):** swap in the new plate; the CORE now
   shows real structure via the plate itself (fixes dominant tell without touching
   the honesty ruling); switch the SHOULDER detail substrate from grass to the new
   dirt plate's luminance / a dirt-detail re-bake (fixes retinted-grass); prefilter
   the high-freq band for the 0.5x shimmer. Re-capture 0.5x/1x/2x; re-decode
   (target core-inclusive dirt gradient >= 8, no shimmer, no green cast); cross
   sign-off; FF-integrate; suite + export gate; push.
5. **agy QA pass 5.** If NOT-CONFUSABLE clears to a genuine confusable pass AND the
   orchestrator's own decode agrees -> **SURFACE A BUILD TO SCOTT** (his stated bar;
   cross-workspace `to: dalinar`). If still failing, root-cause by decoding the
   artifacts (not narration) and tee up decision 013.
6. After dirt clears: fast-lane halo re-cut (agy defect #2) to codex; expand to the
   full ~12-16-structure village; open the ONE round PR + external Codex review;
   address findings; merge; sweep.

**Live worktrees + branches (all LOCAL except `round/007-village` on origin):**
- `lw-007-round` on `round/007-village` @ `7548872` (integration tree, pushed).
- `lw-007-codex` on `codex/007-dirt-impl` @ `7672b3a` (bake slice, integrated).
- `lw-007-claude` on `claude/007-dirt-impl` @ `6bf5e1d` (render slice, integrated;
  reuse next by branching a `claude/007-dirt-retune` off round head 7548872).
- `lw-007-agy` on `agy/007-dirt-qa` @ `8c0414c` (reuse for QA pass 5).
- Deliberation branches `<d>/007-dirt-fidelity` hold decision-012-cited
  proposal/critique/ballot SHAs (LOCAL-ONLY; archive `refs/archive/007/*` at round
  close). Ephemeral rev/cxc + rev/clc review worktrees REMOVED this run.

## Round 006 -- CLOSED (superseded)

Everything recoverable under `refs/archive/006/*` (pushed). `git show
refs/archive/006/<name>:<path>`.

## Durable lessons (paid for repeatedly; honor them)

- **A dispatch is synchronous; nothing external re-invokes you when a detached proc
  finishes.** Only supervisor respawn re-invokes you. Own tool calls cap at ~600s
  -- SET the Bash `timeout` param up to ~560000ms when polling (DEFAULT 120s killed
  one poll early this run). EITHER block in one call OR detach (setsid) + poll the
  end marker across calls, capturing in-flight state HERE first.
- **Detach recipe:** `setsid bash -c "'$DISPATCH' <harness> <wt> <brief> <prompt>
  --cap-seconds N --model opus[claude only] --label L >> LOG 2>&1 < /dev/null" &
  disown`, poll `<wt>/.team/markers/<label>-<stamp>-end.md`. Ran this run:
  proposals/critiques/ballots 30-230s; bake slice 186s; render slice (with a
  decode->re-bake->re-capture tuning loop + Godot headless captures) **1570s (26
  min)** -- long but healthy; `claude -p` buffers ALL output so no mid-run file
  activity is visible (verify liveness via `ps -o etimes=` on the `timeout ... claude
  -p` pid, not file mtimes). `uncommitted_work: yes` is usually just `.pka/` +
  `.team/` -- check `git status --porcelain | grep -vE '\.pka/|\.team/'`.
- **Verify from the end marker + tree, NEVER exit code or narration.** Then RUN the
  suite + export gate yourself (`tools/run_tests.sh`, `tools/art/village_export_gate.sh`)
  and DECODE the actual PNGs (captures AND source fields). Decoding is what proved
  codex's RG8 channels (R high-freq, G broad) and confirmed the core-drag this run.
- **The gradient metric is necessary but NOT sufficient; agy's multimodal read is
  the bar.** This run: gradient 6.9 looked like "close-ish" but agy caught that the
  shoulder detail reads as RETINTED GRASS (wrong morphology) and shimmers at 0.5x --
  neither is a gradient number. Always run agy QA before believing a decode.
- **Stacked slices integrate by fast-forward** (B off A; round FFs to B preserving
  both authored SHAs + trailers). Cross sign-off = ephemeral detached review
  worktrees (`git worktree add -b rev/<slug> <wt> <sha>`, dispatch NON-AUTHOR,
  cherry-pick the marker, `git worktree remove`). reviewed_by != authored_by.
- **agy adapter passes `--add-dir`** but can no-op into a scratch project; markers
  catch it. agy QA ~68s, genuinely multimodal.
- **Doer seats NEVER push to origin.** Only the orchestrator, only the round branch.
- **Long render/gate/decode proofs run to completion in the FOREGROUND same turn.**
- **Cross-workspace asks to Scott: address `to: dalinar`, NOT `to: scott`.**
- **Do NOT start a paid spend at a run tail; sequence into a fresh turn.** Fork B was
  zero-cost; the hybrid-C paid regen is now TRIGGERED and teed up for the next turn.

## Meshy

Key live at `~/.claude/pka-secrets/longwalk/meshy.env`; MCP `meshy` in `.mcp.json`.
Balance **2946** last confirmed. NO paid spend this run (fork B is zero-cost).
The NEXT run's hybrid-C regen IS a paid spend (~6-9 credits): double-spend guard
(`meshy_list_tasks` no PENDING, `meshy_check_balance` before/after, cost-confirm,
NEVER `save_to`); accept only if regen decode std>=12 grad>=8; ONE spend, no chase.
Paid source downloads at `.pka/round007/ground-source/*.png` are the ONLY copies
(URLs expired); do NOT regenerate/overwrite those.

## Active decision records (on main / round branch)

001-008 on main. Round-007 decisions **009** (art method), **010** (ground/lane
shader-quad plate), **011** (lane geometry fork B), **012** (dirt fidelity fork B
shader-composite) are on the round branch, all signed 4-0. Round-006's own 009/010
are archive-only. Round-007's NEXT decision, if the paid regen path needs a new
design fork, is **013**; the regen SPEND itself is pre-authorized under 012 item 5.

## Notes for the next run

- **Dashboard `/team` tab is KILLED by Scott** (inbox `2026-07-18-0445`): do NOT
  POST to `dashboard.int.sentania.net/api/team`. No in-repo sync tool exists;
  compliance = simply not posting. Duty suspended; a missing POST is not a failure.
  Inbox fully processed through 04:45Z; no new orchestrator inbox messages this run.
- `gh pr edit` is broken (GraphQL projectCards). Use REST `gh api -X PATCH
  repos/sentania-labs/longwalk/pulls/N ...`.
- No round PR is open (correct -- opens only once the district passes the bar).
- Sweep verified THIS run: 0 open team PRs; origin carries only `main`,
  `round/007-village` @ 7548872, unrelated `issue-4-world-eras`; leak guard OK (no
  doer/rev branches on origin). Ephemeral review worktrees removed.

**Last updated:** 2026-07-18 (DIRT-FIDELITY sub-round decision 012, full protocol
end-to-end in ONE turn: 3 blind proposals [UNANIMOUS fork B, none paid] -> 3
adversarial critiques [painted-luminance beat pure noise by concession; RGBA
over-engineering conceded] -> decision 012 -> four-ballot 4-0 UNANIMOUS [protected-
core tonal texture -> codex bounded broad-drift middle path; critic NOT invoked;
RG8 mechanism correction folded] -> codex bake 7672b3a + claude render 6bf5e1d
[both orchestrator-verified GREEN, decoded] -> cross sign-off [both non-author] ->
FF-integrated round 7548872 + suite + export gate GREEN + PUSHED -> agy QA pass 4 =
NOT-CONFUSABLE. Fork B CLOSED the transition + coverage tells but NOT the dominant
FLAT-CORE tell [Gate 1 = 6.9 < 8.0; root cause = flat source plate, which the core
samples directly and the honesty ruling correctly keeps high-freq detail off].
agy also found the shoulder detail reads as RETINTED GRASS + shimmers at 0.5x. NOT
surfaced to Scott [bar not met]. Teed up the pre-authorized HYBRID-C PAID REGEN
[balance 2946, ~6-9cr, exact prompt + acceptance decode recorded] + composite
re-tune [dirt-source substrate + shimmer prefilter] for a FRESH TURN. Every
dispatch verified from end marker + tree + decoded images + self-run gates. Sweep
OK.)
