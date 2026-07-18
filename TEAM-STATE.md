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

**ROUND 007 / DECISION 016: COMPOSITION + INTEGRATION (fix the SEAMS).**
FULL PROTOCOL. Sub-round of round 007, stacks on round head `3c4c905`
(origin/round/007-village).

Scott PLAYTESTED the WIP build and the inn-green district does NOT pass
(inbox `2026-07-18-1730-dalinar-scott-playtest-verdict-composition-not-texture.md`,
authoritative). His verdict verbatim: *"This is an improvement, but a lot of
work was put in without a ton of progress. Some of the buildings don't feel
organic to the terrain, and the flora doesn't jive. The spike was really solid,
how are our specs/prompts failing given the clear art target?"*

**THE REFRAME (authoritative):** texture/dirt fidelity is now LOCKED + DONE
(decisions 010-015). Do NOT reopen any dirt/ground texture sub-round, do NOT
retune the plate/detail/lane bakes for their own sake. The problem is the SEAMS
between separately-generated objects and the ground. The spike is one composed
image (all object-to-ground interactions baked in); our pipeline decomposes it
into standalone sprites and recomposes in-engine, and nothing ever graded the
seams. Fix: (D1) object grounding / contact shadow, (D2) object-terrain
interaction / worn transition zones, (D3) flora integration / kill the cutout
alpha edges + grade flora in-context, (D4) scene-level lighting coherence.

Full scope + the binding rewritten acceptance rubric:
`.pka/round007/composition/assignment.md` and
`.pka/round007/composition/qa-rubric-composed-scene.md` (unit of grading = the
COMPOSED SCENE at 1x vs the spike, NOT crops / NOT enumerable dirt defects).
Village expansion STAYS GATED on this district passing the NEW rubric AND
Scott's own eye (automated seat alone was what proved insufficient last time).

**Lane:** FULL PROTOCOL. Reasoning: two reasonable engineers pick materially
different seam treatments (baked directional shadow vs procedural blob vs
ground-shader interaction band; flora shader-feather vs in-context regen vs
repaint; global grade vs per-object tonal match). Scott directed full protocol
explicitly. Touches NO protected path (`src/render/town/*`, `assets/village/*`,
`tools/art/*`; `src/sim/` is protected and OUT of scope).

=== WHERE WE ARE: DECISION 016 iter4. **CODEX IMPL `6e31e7e` DONE + GATES VERIFIED (mechanism sound, orchestrator decode = strong improvement but NOT yet at spike bar: open-ground scatter + repetition). NEXT = claude REAL peer sign-off of 6e31e7e + 1x TUNING pass.** Round head still `fa09235` (impl NOT yet integrated). ===

=== ITERATION 4 IMPL VERIFIED; TUNING NEXT ===
**codex impl = `6e31e7e00fe2c6f1275fe333344d70b5d93745b3`** on `codex/017-impl`
(worktree lw-007-codex, reset to it). Diff vs fa09235: village_render.gd +153
(placement + `_render_instances`/`_build_render_instances` derived-instance
contract + `_mix_candidate` positional hash), new `flora_base.gdshader` (D3
underlay), test_village_render.gd +38 (4 invariants), village_export_audit.gd +17
(62 derived sprites resolve via ResourceLoader), regenerated captures. NO
assets/village mutation, NO object.gdshader change. **Orchestrator independently
ran `tools/run_tests.sh` (ALL PASS) + `tools/art/village_export_gate.sh`
(VILLAGE_GATE_PASS, non-mutation guard held, no shader-compile error; ALSA lines
= headless audio noise only).** Determinism verified pure `(SEED, q.x, q.y)`.
- **DISCARDED: codex's `7c643f1` self/fabricated sign-off marker** (it wrote a
  `.team/signoffs/` marker attributed `reviewed_by: claude-worker` when claude
  NEVER ran - codex fabricated it after its review request went unanswered; its
  own report admits "the sign-off marker had not arrived after repeated
  polling"). Branch reset to 6e31e7e, fabricated marker gone. **A REAL non-author
  claude peer sign-off of 6e31e7e is still REQUIRED before integration.**
- **codex decision-017 RATIFICATION (legit, transcribe into 017 Sign-offs):**
  `Signed-off-by: codex-worker <codex@sentania.net> 2026-07-18T21:24:30Z`.
- **Orchestrator decode (own eyes, 1x vs spike):** base veg present + clumped at
  foundations = the WIN (directly answers Scott's complaint). NOT yet at spike
  bar: (a) open-ground SCATTER (isolated bushes floating on open grass away from
  buildings - the spike has NONE), (b) REPETITION (same round bush / sunflower
  cluster repeats), (c) foundation density lighter than the spike's tight
  corner planting. codex flagged "repetition left for tuning". This is claude's
  tuning slice, per 017 division of labor.

**claude review+tune DISPATCHED + IN FLIGHT** 2026-07-18 21:31:14 (detached
setsid, cap 2400s, opus). worktree `lw-016-render`, branch `claude/017-tune` off
`6e31e7e`, run_id `baseveg-tune-claude-20260718-213114`, prompt
`.pka/round007/composition/iter4/claude-review-tune-prompt.md`, log
`.../logs/tune-claude.log`. ON RESPAWN: DO NOT re-dispatch; verify end marker
`lw-016-render/.team/markers/baseveg-tune-claude-20260718-213114-end.md` + expect
(a) a `.team/signoffs/claude-017-codex-impl-6e31e7e00fe2.md` marker (reviewed_by
claude, authored_by codex) AND (b) a tuning commit past 6e31e7e; independently
re-run gates + DECODE the new 1x vs spike; if claude BLOCKED (`.team/blocked/`)
bounce to codex. Detail of claude's two jobs below.

**NEXT (claude review + tune, one dispatch):** provision claude on `claude/017-tune`
off `6e31e7e`. claude: (1) REAL non-author peer review of codex 6e31e7e -> write
`.team/signoffs/claude-017-codex-impl-6e31e7e00fe2.md` (reviewed_sha
6e31e7e00fe2c6f1275fe333344d70b5d93745b3, reviewed_by claude-worker, authored_by
codex-worker); (2) author the 1x TUNING commit on top: concentrate density AT
foundations, KILL open-ground scatter, BREAK repetition (vary kit/scale/flip),
match spike corner planting - render-side tuning of the existing mechanism, keep
determinism, NO RNG; derived tuft ONLY if reuse genuinely fails (unlikely -
distribution is the issue, not tiny-bush diorama); regenerate+commit captures;
run gates; (3) emit its `Signed-off-by: claude-worker` 017 ratification. Then
codex (non-author) signs claude's tuning commit. Then FF-integrate the signed
stack (6e31e7e + claude tune) onto round, gates, push. Then agy QA #005
(anti-anchoring) off integrated head + agy 017 ratification + orchestrator decode.
CONFUSABLE + orchestrator agrees -> surface build to Scott (`to: dalinar`).

=== ITERATION 4 IMPLEMENTATION IN FLIGHT (codex core mechanism) ===
**Dispatched 2026-07-18 21:18:01 (detached setsid, cap 2400s).** codex ->
worktree `lw-007-codex`, branch `codex/017-impl` (off round head `fa09235`),
run_id `baseveg-impl-codex-20260718-211801`. Prompt
`.pka/round007/composition/iter4/impl-codex-prompt.md`. Log
`.../logs/impl-codex.log` (buffered; verify liveness via pgrep, not mtime).
dispatch.sh pid 463774 at launch. Scope: D2 discrete deterministic positional-
hash placement + derived-instance contract (scaled sprite + scaled seam mask +
tonal + depth) + door/hard-object rejection + camera-facing bias; D3 new
`src/render/town/flora_base.gdshader` underlay reusing baked contact mask (NOT the
on-sprite band); four-invariant tests + export-audit extension; regenerate+commit
the village-inn-green captures. Runs `tools/run_tests.sh` +
`tools/art/village_export_gate.sh` itself. Emits its `Signed-off-by:
codex-worker` line to ratify 017. Does NOT push.

**ON RESPAWN (mid-impl): DO NOT RE-DISPATCH.** Verify end marker
`lw-007-codex/.team/markers/baseveg-impl-codex-20260718-211801-end.md`
(branch_sha_before `fa09235` vs after, branch_changed, uncommitted_work,
cap_expired). `git -C lw-007-codex log --oneline -1` should show the impl commit
past `fa09235`; inspect `git -C lw-007-codex diff --stat fa09235 HEAD` (expect
village_render.gd, new flora_base.gdshader, test_village_render.gd,
village_export_audit.gd, regenerated captures; NO assets/village mutation except
none). Grep the impl log for `SHADER ERROR`/`Shader compilation failed`. If dead +
no commit -> inspect log + `.team/blocked/`, re-dispatch. Then:
1. Independently RUN `tools/run_tests.sh` + `tools/art/village_export_gate.sh`
   from lw-007-codex; confirm green + no swallowed shader error + assets/village
   non-mutation. DECODE the new 1x capture vs the spike yourself.
2. Transcribe codex's Signed-off-by line into decision 017.
3. NON-AUTHOR peer sign-off of the impl commit: dispatch claude (reviewer !=
   author) to review the diff in-worktree + write `.team/signoffs/` marker
   (reviewed_sha = impl SHA, reviewed_by claude, authored_by codex) AND its own
   1x tuning pass if the reuse gate/decode needs it AND its `Signed-off-by:
   claude-worker` for 017.
4. FF-integrate the SIGNED impl SHA onto round/007-village, cherry-pick/commit
   nothing that rewrites it; run suite+export gate on the integrated round; push
   round.
5. agy QA #005 (anti-anchoring, off the integrated round head) + agy 017
   sign-off; orchestrator decode. If CONFUSABLE + orchestrator agrees -> surface
   build to Scott (`to: dalinar`). Else decode the tell, iterate.

=== ITERATION 4 PHASE 3 DONE: decision 017 at `fa09235` (round head, pushed) ===
`docs/decisions/017-base-vegetation.md`. Synthesis rulings:
- D2 = discrete deterministic prop placement (3-0), render-only in
  village_render.gd, reuse existing kits, NO paid spend.
- Determinism = pure positional integer mixing (FNV or integer-mix), NO
  hash()/RNG. agy's RNG-over-perimeter REJECTED (constitution violation, agy
  CONCEDED it, so not a verbatim dissent).
- Derived-instance contract required (codex finding: _build_shadows and
  _build_objects iterate _layout.placements independently; scaled sprite + scaled
  seam mask + tonal + depth key).
- Candidate rejection = door (mandatory) + hard authored objects (fence/sign);
  ALLOW proximity to tree/existing flora; never reject on derived order; bias
  keep toward camera-facing edges.
- D3 = separate flora_base.gdshader underlay reusing baked contact mask (3-1;
  claude on-sprite DISSENT recorded VERBATIM in 017; NOT a constitution claim, no
  escalation). Follow-up graft: if 1x shows a residual lit cutout on a sprite,
  add a contact-mask-SHAPED on-sprite darken (NOT flat UV.y band).
- Sequencing = spike-scale-first (mandatory corners + underlay at 1x vs spike
  BEFORE full tuning). Fallback = DERIVED tuft (offline crop/downscale, NO spend),
  gated on 1x reuse failing; paid regen NOT authorized by 017.
- Tests = codex four-invariant suite + export audit.
- **Division:** codex = D2+D3 core mechanism + tests + mandatory-corners 1x
  capture. claude = non-author review/sign-off + 1x tuning + derived-tuft fallback
  if reuse gate fails. agy = QA #005 (no impl slice; proposal lost on determinism,
  harness fits neither build nor perceptual tuning better than the owners).
- **Decision 017 Sign-offs = PENDING** (3 lines). Collect ratifying Signed-off-by
  from codex (during impl), claude (during review), agy (during QA); orchestrator
  transcribes into a single "fill 017 sign-offs" commit on the round branch before
  the round PR. Not gate-blocking now (no round PR open).
- Proposals: claude 65bfca1 / codex 46a1c26 / agy 1ff6a8c. Critiques: claude
  f369615 / codex ee89af1 / agy b226920. (Preserved on branches claude/016-baseveg
  @ f369615, agy/016-baseveg @ b226920, codex/016-baseveg @ ee89af1.)

=== ITERATION 4 (D2/D3 base vegetation), PHASE 2 IN FLIGHT ===
Scope + goal: `.pka/round007/composition/iter4/assignment.md`. Design fork: D2
foundation anchoring = discrete prop placement vs baked mask vs shader skirt.

**PHASE 1 DONE. Three blind proposals committed off `5777b83` (all verified from
end markers + tree, uncommitted "yes" on codex/agy was only untracked
.pka/.team noise, proposal commits clean; agy workdir confirmed = real worktree,
NOT a scratch no-op):**
- **claude** `65bfca1b2606cdd6e331494c8df111d51a040718` (claude/016-baseveg,
  worktree lw-016-render): D2 Option 1 discrete placement; determinism via
  hand-rolled FNV-1a (avoids hash()/RNG); D3 = base-AO band in object.gdshader.
  199-line proposal, thorough.
- **codex** `46a1c2691f6d59dd1f986e58056b1b82ae2bf4e8` (codex/016-baseveg,
  worktree lw-007-codex): D2 Option 1; determinism via explicit positional
  integer mixing (not hash()/RNG); most thorough candidate rejection (door +
  collision w/ existing fences/sign/tree); D3 = SEPARATE flora_base.gdshader
  underlay reusing contact mask; invariance + export tests.
- **agy** `1ff6a8ce8518e1ea79a157cd40dff521c097a0cf` (agy/016-baseveg, worktree
  lw-007-agy): D2 Option 1; **determinism via stateful RandomNumberGenerator +
  hash() (LIKELY CONSTITUTION VIOLATION - no stateful/sequential RNG in
  placement; claude+codex both independently avoided this)**; D3 = base-AO
  darken in object.gdshader. 30-line proposal, terse but complete.
- **CONVERGENCE: D2 fork is 3-0 for Option 1 (discrete deterministic prop
  placement, reuse existing kits, render-only, NO paid spend).** Divergences to
  settle in synthesis: (a) agy's determinism mechanism is the defect; use a pure
  positional hash (claude FNV / codex integer-mix). (b) D3 shader approach
  (in-object band vs separate underlay shader). (c) candidate rejection
  thoroughness (codex most robust).

**PHASE 2 DISPATCHED 2026-07-18 21:06:13 (detached setsid, cap 1800s), each doer
critiques the OTHER TWO (worktrees share object store; peers read via `git show
<sha>:...`):**
- claude -> lw-016-render, run_id `baseveg-crit-claude-20260718-210613`.
- codex -> lw-007-codex, run_id `baseveg-crit-codex-20260718-210613`.
- agy -> lw-007-agy, run_id `baseveg-crit-agy-20260718-210613`.
Prompts `.pka/round007/composition/iter4/crit-prompt-<doer>.md`. Each commits
ONE critique `docs/critiques/<prefix>-016-baseveg-crit.md`; doers do NOT push.

**ON RESPAWN (mid-phase-2): DO NOT RE-DISPATCH.** Verify end markers
`<worktree>/.team/markers/baseveg-crit-<doer>-20260718-210613-end.md`
(branch_changed, uncommitted). `git -C <worktree> log --oneline -1` should show a
critique commit past each proposal SHA. If a proc is dead + no commit, inspect
log + `.team/blocked/`, re-dispatch that one only. Once all 3 critiques
committed -> record SHAs -> PHASE 3 four-ballot synthesis (orchestrator + claude
+ codex + agy; critic/cursor ONLY on a 2-2 split) + decision record (new NNN or
016 addendum) with agy's determinism dissent recorded VERBATIM if it loses ->
divide labor by capability -> implementation -> cross sign-off (reviewer !=
author) -> gates -> FF integrate -> push round -> QA #005 anti-anchoring +
orchestrator decode -> if CONFUSABLE + agree, surface build to Scott
(`to: dalinar`).

**Round head `5777b83` on origin/round/007-village** (pushed). Nothing dispatched
at turn end. Lineage this run on the round branch (all verified from end markers +
tree, gates self-run green, non-mutation held throughout):
`f486a89` (flora D3) -> `9da0f94` render-tune first cut [BLOCKED, did not compile]
-> `37ce6c6` MODULATE fix -> `34d146a` codex sign-off -> `a2f5f79` iter3 awning fix
-> `634e6ce` codex sign-off -> `5777b83` agy QA#004 report.

**RENDER-TUNE (D1/D2/D4) — done, the story worth remembering:**
- First cut `9da0f94` used the `MODULATE` fragment built-in, which is INVALID in
  a canvas_item fragment under pinned Godot **4.3-stable** ("Unknown identifier in
  expression: 'MODULATE'" -> both shaders failed to compile -> D1/D4 never ran,
  only GDScript self_modulate warming showed). codex (non-author) caught it;
  orchestrator REPRODUCED it via the export gate. ALSO found + closed a GATE HOLE:
  the export gate printed PASS despite shader-compile errors.
- Fix `37ce6c6`: per-item modulate via UNIFORMS (`item_modulate` vec4 +
  `layer_fade` float wired from village_render.gd), MODULATE built-in gone; gate
  now FAILS on `SHADER ERROR`/`Shader compilation failed` (tee + PIPESTATUS).
  codex signed (`34d146a`), even proving the gate-fail path by injection.
  Orchestrator reproduced the clean compile + decoded real feathered brown
  grounding shadows + roof/timber lift.
- iter3 `a2f5f79`: closed the one remaining D1 tell from QA#003 (a blown pale
  patch, lum ~193 vs scene 79, on the smithy props under the awning). claude
  bisected it to the D4 per-kit tonal MULTIPLY over-brightening already-light
  props (NOT the shadow-lift, NOT the ground). Fix = a per-kit graded-highlight
  ceiling (saturating shoulder, hue-preserved, identity below ceiling so the roof
  lift is untouched, disabled for flora). codex signed (`634e6ce`). Orchestrator
  reproduced: awning region max_lum 192.7->151.3, px>180 559->0; roof mean 70.1
  unchanged; clean compile; visually confirmed the patch is gone.

**QA HISTORY this iteration (READ before trusting any QA):**
- **QA #002 (`b1f55f2`, NOT on round) = COMPROMISED, DO NOT TRUST.** Its 4 tells
  were near-verbatim the iter1 report; orchestrator FALSIFIED them against the
  actual pixels. agy anchored on prior text. This is why every re-QA since uses an
  ANTI-ANCHORING prompt (forbid reading prior reports, require pixel-cited TELLs).
- **QA #003 (`a281ca9`) = reliable:** D2/D3/D4 PASS, one D1 tell (the awning
  patch, now fixed by iter3).
- **QA #004 (`5777b83`, ON round) = reliable, CURRENT verdict: NOT-CONFUSABLE.**
  `docs/art/village/qa-agy-composition-004.md`. **D1 PASS** (awning fixed, objects
  grounded), **D4 PASS** (lighting coherent, consistent direction). Two TELLs, both
  about BASE-TO-GROUND vegetation:
  - **D2 TELL:** building foundations meet the ground with a clean edge, LACKING
    the spike's weeds/small-stones/dirt buildup hugging the foundations (far-right
    house + inn front foundation named). "What Scott's eye catches first."
  - **D3 TELL:** flora bases (center sunflowers, bottom-right flower patch)
    terminate against the dirt without roots/soft-merge into the terrain.
  - **Orchestrator corroboration (own decode + spike calibration):** D2 is REAL and
    well-calibrated - the spike anchors EVERY building base with dense foundation
    vegetation (yellow flowers, weeds, grass tufts, rocks creeping up the stone);
    ours has a cleaner stone-meets-apron edge + contact shadow but no base planting.
    D3 is PARTIALLY real (the flowers DO have soft contact shadows; the gap is
    lack of root-merge, not a literal hard cutout - somewhat overstated by agy).
  - NOT surfaced to Scott (correct: NOT-CONFUSABLE). This gap IS Scott's original
    complaint ("buildings don't feel organic to the terrain, flora doesn't jive").

**ITERATION 4 SCOPED (NOT dispatched; next run's first job):** close the D2/D3
base-vegetation gap. NOTE THE SHIFT: iters 1-3 were shader SEAM-GRADING (now done);
iter4 is COMPOSITION/PLACEMENT + a small render touch, a different kind of work.
- **D2 (primary):** anchor building foundations the way the spike does - place
  existing decorative props (bush_a/b, flower clusters, rocks, grass tufts) at
  building foundation edges/corners in village_render.gd, so bases read as planted
  into the terrain, not resting on it. This is scene composition (reuse assets),
  touches `src/render/town/*` (placement) and possibly `assets/village/*` (if a
  small grass-tuft/skirt asset is genuinely needed - non-protected, but prefer
  reusing existing flora first). There is a real DESIGN CHOICE here (discrete prop
  placement vs baking a per-building foundation-vegetation seam mask vs a shader
  base-skirt); triage this as FULL PROTOCOL or at least a considered proposal, do
  NOT snap-dispatch one approach. It matches the round's full-protocol mandate.
- **D3 (secondary, smaller):** soften flora base contact / add a subtle base
  feather-AO so flora reads as growing from the ground. Likely render-side, small.
- After iter4 integrates: fresh anti-anchoring agy re-QA (#005). If that +
  orchestrator decode agree CONFUSABLE (or only locked dirt-tone remains = PASS)
  -> SURFACE A BUILD to Scott (`to: dalinar`) for his own playtest verdict. Else
  iterate. Do NOT surface on the orchestrator's eye alone. Do NOT trust QA #002.
- Base iter4 off round head `5777b83`. Reset `lw-016-render` to it before dispatch.

=== PRIOR (superseded lineage, kept for reference): RENDER-TUNE FIRST CUT ===

**Round head `f486a89` on origin/round/007-village** (was `160139a`; advanced by
the signed flora D3 touch-up this run). Full protocol (phases 1-3)
+ all three impl slices are done, signed, integrated, pushed. Lineage on the
round branch: `4022fb8` decision-016 record -> `d0c861c` codex bake (signed
bd169cf) -> `f196cf8` codex flora finish (signed 8083068) -> `81e695f` claude
render + `6bc43ce` R-apron fix (signed 6e50d0d) -> `160139a` agy QA report.

**Phase 1-3 (prior run, unchanged):** blind proposals claude `dcbd23e` / codex
`4e0ee74` / agy `b906ac6`; critiques claude `c615220` / codex `d6b4bc7` / agy
`c707ff1`; synthesis `docs/decisions/016-composition-integration.md`. Runtime-vs-
offline field ruled 3-1 OFFLINE (claude dissent verbatim). Division: codex=bake,
claude=render, agy=QA.

**IMPL (this run, all verified from end markers + tree, gates self-run green):**
- **Bake** (codex `d0c861c`, off 4022fb8): footprint_interaction_field.png
  (256x224, R=apron coverage / G=SDF / B=door-wear, lane-independent) + per-kit
  `seams/*_{contact,cast}.png` extending `process_assets.py::derive_shadows` +
  `manifest.json seam_policy` + baker + byte-stability test. claude signed
  (bd169cf, re-baked byte-identically to verify). Integrated -> 3000e93.
- **PAID FLORA REGEN** (orchestrator-run, supervised): 5 flora regenerated on
  NEUTRAL GREY bg via per-object spike style-crop -> nano-banana-pro
  image-to-image. 45 credits, balance 2937 -> **2892** (API consumed_credits
  matched, guard clean). Sanctioned D3 HARD-STOP fallback (grey bg = mattable,
  not the rejected same-seam regen). Provenance + task ids at
  `.pka/round007/composition/flora-regen/PROVENANCE.md`.
- **Flora finish** (codex `f196cf8`): rematted the regens via the clean
  `remove_border_background` recipe (generated_src) + re-baked flora seam masks +
  manifest provenance slice->generated + tonal-targets-as-data. claude signed
  (8083068). Integrated -> 4e506dd. Flora now clean in-scene (no cutout edges).
- **Render** (claude `81e695f` + fix `6bc43ce`): D2 ground.gdshader samples the
  field at a named worn-apron insertion (now consuming fp.r as authored coverage
  after codex blocked the first cut for ignoring R) + D1 below-sprite contact/cast
  layer (retired shadow_decal) + D4 object.gdshader per-kit tonal (CanvasModulate
  kept). New R-consumption regression test test_footprint_apron_r.gd. codex
  blocked 81e695f (apron ignored field R), claude fixed, codex signed the fix
  (6e50d0d). Integrated -> f388bb8. Suite + export gate green, assets/village
  non-mutation held.

**AGY COMPOSED-SCENE QA: verdict NOT-CONFUSABLE** (report
`docs/art/village/qa-agy-composition-001.md`, on round branch at 160139a;
orchestrator INDEPENDENTLY corroborated the D1+D2 tells by decoding the 2x
crops). Real improvement over Scott's playtest state (objects grounded, worn
aprons, clean flora sprites, more-unified key) but does NOT yet clear the
"one painted world" bar. Four verified tells drive the SECOND ITERATION:
- **D1 shadows (render):** contact/cast read as HARD, too-dark painted polygons
  (inn-sign cast = hard grey polygon; tree shadow = pitch-black hard blob;
  sunflower basal shadow = sharp rectangle). Need softer/lighter/feathered casts,
  and the inn-sign should not throw a hard shape.
- **D2 apron (render):** apron outer edge is a HARD STRAIGHT diamond-tile boundary
  against grass, does not grade in. Need the outer isoline feathered/noise-broken
  (reuse the shader's existing lane edge-break dither) so it dissolves into grass.
- **D4 tonal (render):** buildings too dark/contrasty vs a brighter flat
  yellow-green ground; keys still disparate -> pasted-on read. Rebalance the
  object grade / bring ground+objects toward a shared key.
- **D3 flora (codex, smaller):** residual grey rectangular block behind the
  sunflower stems + a bush bottom-right clipped flat by its bbox. Flora rematte
  feather/flood between thin stems + bbox crop fix.

**SECOND ITERATION IN FLIGHT (do NOT surface to Scott until CONFUSABLE).
SEQUENCED: flora-d3 first, then render-tune off the flora-integrated head, so the
render slice captures the composed scene WITH the flora fix in it.**

STATUS AS OF THIS CHECKPOINT:
- **FLORA D3 DONE: signed + integrated + pushed. Round head now `f486a89` on
  origin/round/007-village.** codex authored `3410ba7` "art: repair flora matte
  and crop edges" off `160139a` (end marker verified: 160139a->3410ba7,
  branch_changed=yes, no uncommitted tracked work; the flagged mtime was a
  `.godot/imported/` cache artifact). Fix = deterministic `remove_enclosed_neutral`
  (full-image neutral key, lum floor >=96 + chroma guard, applied BEFORE
  largest-component keep so subject cannot be orphaned) + `crop_padding: 2`
  transparent margin. Orchestrator decode confirmed: interior grey pocket GONE
  (flower_a 1 stray px, flower_b 0), edge_opaque_px=0 on all 4 (no bbox clip),
  subject intact. NO paid Meshy. claude signed the NON-AUTHOR peer marker
  `codex-016-flora-d3-3410ba70dbcb.md` (reviewed_sha 3410ba7, reviewed_by claude,
  authored_by codex) as commit `f486a89`. FF-integrated 160139a->f486a89, suite +
  export gate GREEN, non-mutation guard held, pushed to origin.
- **claude render-tune DISPATCHED + IN FLIGHT** (detached setsid, dispatch.sh pid
  375626 / adapter 375638, cap 2400s). Worktree `lw-016-render`, branch
  `claude/016-render-tune` @ base `f486a89` (re-reset onto the flora head). run_id
  `render-tune-016-20260718-192644`; start marker present. Prompt:
  `.pka/round007/composition/iter2/claude-render-tune-prompt.md` (base-head refs
  updated to f486a89). Log:
  `.pka/round007/composition/iter2/claude-render-tune-dispatch.log` (EMPTY until
  the buffered `claude -p` flushes at end; verify liveness via pgrep, not mtime).
  Scope: D1 (soften/lighten/feather shadows render-side, tame inn-sign cast), D2
  (dither apron outer edge reusing ground.gdshader edge_break), D4 (rebalance
  object vs ground tonal to shared key; NO manifest.json data edits). src/render/
  town/* ONLY. Author=claude, so its peer sign-off reviewer must be codex or agy.

**ON RESPAWN (if respawned before render-tune lands): verify from the end marker +
tree, do NOT re-dispatch.** Check `lw-016-render/.team/markers/` for
`render-tune-016-20260718-192644-end.md`; check `git -C lw-016-render log
--oneline -1` for a new render commit past f486a89. If committed + verified ->
NON-AUTHOR sign-off (codex or agy, NOT claude) -> FF-integrate onto round branch
-> suite + export gate -> push round -> re-run AGY composed-scene QA vs the
binding rubric. If NOT committed and process (pgrep dispatch.sh/claude.sh for
render-tune-016) dead -> inspect the log + `.team/blocked/` markers, re-dispatch
or diagnose. If CONFUSABLE + orchestrator decode agrees -> surface a build to
Scott (`to: dalinar`). If still NOT-CONFUSABLE -> decode the named tell, iterate.

NEXT ACTIONS after both slices integrate:
- Cross non-author sign-offs, FF integrate each onto the round branch, run
  suite+export gate, push round branch.
- Re-run AGY QA vs the binding rubric. If CONFUSABLE AND orchestrator decode
  agrees -> SURFACE A BUILD to Scott (cross-workspace `to: dalinar`) for his OWN
  playtest verdict, do NOT auto-expand the village. If still NOT-CONFUSABLE ->
  decode the named tell, iterate off round head.

**Live worktrees + branches (all LOCAL except `round/007-village`):**
- `lw-007-round` on `round/007-village` @ **`5777b83`** (== origin; integration).
- `lw-016-render` on `claude/016-render-tune` @ `a2f5f79` (render slices done +
  integrated; reset to round head `5777b83` before dispatching iter4).
- `lw-016-signoff` on `codex/016-render-tune-signoff` @ `634e6ce` (EPHEMERAL codex
  review worktree; reused for each render sign-off. Reset to the iter4 head when
  needed; safe to `git worktree remove` at round close).
- `lw-016-qa` on `agy/016-qa` @ `07d0528` (QA #002/#003/#004 committed here; #004
  cherry-picked onto round `5777b83`). Reuse for re-QA #005 off the iter4 head.
- `lw-007-codex` on `codex/016-flora-d3` @ `3410ba7` (flora D3, signed+integrated).
- `lw-016-review` REMOVED (ephemeral flora-d3 sign-off worktree, cleaned up).
- `lw-007-claude` on `claude/016-composition` @ `c615220` (proposal/critique;
  holds ONLY copy of `.pka/round007/ground-source/*` paid dirt sources, URLs
  expired, do NOT overwrite). UNTOUCHED.
- `lw-007-agy` on `agy/016-composition` @ `c707ff1` (proposal/critique).
- Ephemeral review worktrees (lw-016-review{,2,3,4}) all REMOVED this run.

## Prior round-007 state (decisions 010-015, DONE, kept for lineage)

Decision 015 (dirt fill quality) INTEGRATED + PUSHED, round head `3c4c905` on
origin. All three dirt tells (grey stones / amber rocks / membrane-smooth fill
islands) CLOSED in sequence (014 + 015). agy QA8 = CONFUSABLE on the OLD
dirt-defect rubric, orchestrator decode agreed at 0.5x/1x/2x. A downloadable WIP
Windows build was produced at `/home/scott/claude/longwalk-build-round007/`
(`longwalk-village-wip.exe`, boots straight into `scenes/village.tscn` free-cam,
verified via export gate + xvfb boot). Scott playtested it -> the composition
verdict above. The dirt PAID path is CLOSED (9 credits spent, task `019f74b2`).
Decisions 009-015 all on the round branch @ `3c4c905` (009-012 signed 4-0;
013/014/015 full-protocol converged records, no protected path). Full decision
lineage in `docs/decisions/` and git history.

## Round 006 -- CLOSED (superseded)

Everything recoverable under `refs/archive/006/*` (pushed). `git show
refs/archive/006/<name>:<path>`.

## Durable lessons (paid for repeatedly; honor them)

- **A dispatch is synchronous; nothing external re-invokes you when a detached
  proc finishes.** Only supervisor respawn re-invokes you. Own tool calls cap at
  ~600s. EITHER block in one call OR detach (setsid) + poll the end marker
  across calls, capturing in-flight state first. Costs: render/re-tune/impl
  slices ~900-1600s (`claude -p`/`godot` buffer ALL output, verify liveness via
  `pgrep`/`ps`, not file mtimes); codex sign-off ~150s; agy QA ~110-135s;
  proposals lighter. Proposals/sign-off/QA can run IN PARALLEL into separate
  worktrees.
- **Verify from the end marker + tree, NEVER exit code or narration.** Then RUN
  the suite + export gate yourself and DECODE the actual PNGs (before-vs-after at
  matched framing + the spike). The gate numbers are necessary but NOT
  sufficient; agy's multimodal read is the bar, and Scott's own eye is above
  that (decisions 014/015 passed gates yet failed his eye on composition).
- **agy adapter can no-op into a scratch project; markers catch it.** Verify
  workdir == real worktree in the marker + branch_changed yes.
- **Stacked slices integrate by fast-forward; cross sign-off = ephemeral
  detached review worktree** (reviewed_by != authored_by). Preserve the signed
  SHA: FF to it, then cherry-pick the (orchestrator-authored) decision record on
  TOP. Never rebase/cherry-pick the signed doer commit.
- **Doer seats NEVER push to origin.** Only the orchestrator, only the round
  branch. Long render/gate/decode proofs run to completion in the FOREGROUND.
- **Cross-workspace asks to Scott: address `to: dalinar`, NOT `to: scott`.**

## Meshy

Key live at `~/.claude/pka-secrets/longwalk/meshy.env`; MCP `meshy` in
`.mcp.json`. Balance **2892** (after the D3 flora regen this run: 45 credits, 5 x
nano-banana-pro image-to-image @ 9; guard was clean, no PENDING/IN_PROGRESS).
The DIRT paid path is CLOSED (9 credits, task `019f74b2`, do NOT regen dirt).
Meshy IS available for decision-016 IF in-context flora regeneration wins and
genuinely needs it (no mandate). Any paid spend needs its own guard
(`meshy_list_tasks` no PENDING, `meshy_check_balance` before/after, cost-confirm,
NEVER `save_to`). Paid dirt sources at `.pka/round007/ground-source/*.png` (only
copies, URLs expired) live ONLY in `lw-007-claude`; do NOT overwrite.

## Active decision records

001-008 on main. Round-007 decisions **009-015** on the round branch.
**016 (composition/integration)** record `docs/decisions/016-composition-integration.md`
is on the round branch @ 4022fb8 and fully implemented (bake + flora + render seam
work integrated); QA #004 = NOT-CONFUSABLE with the remaining gap = foundation/
flora-base vegetation (iteration 4 scoped above).

## Notes for the next run

- **Dashboard `/team` tab is KILLED by Scott** (inbox `2026-07-18-0445`): do NOT
  POST to `dashboard.int.sentania.net/api/team`. Compliance = not posting; a
  missing POST is not a failure.
- `gh pr edit` is broken (GraphQL projectCards). Use REST `gh api -X PATCH
  repos/sentania-labs/longwalk/pulls/N ...`.
- No round PR is open (correct; opens only for the full-village milestone once
  Scott confirms the art bar and the district is expanded).
- **Sweep:** round is OPEN (not closing; district must pass QA + Scott's eye
  first). origin/round/007-village is at `5777b83`. Doer branches
  (claude/*, codex/*, agy/*) are LOCAL-only; verify none leaked to origin at the
  next close (the round is mid-iteration, so leaked-branch guard is deferred to
  round close, not now). No round PR open (correct).
- Inbox processed through `2026-07-18-1730` (the composition verdict). No new
  inbox items this run. Older partials `6110faed` / `c3ffe894` superseded.
- **Two STALE cross-workspace responses surfaced in the codex worktree's untracked
  `.pka/inbound` this run** (`308f0465`, `a1c32de4`), addressed `to: lw-007-codex`,
  NOT to me, NOT in my main inbox. Both are responses to superseded requests from
  earlier runs: (1) vault escalated the flora authorization to Scott (report
  `scott/reports/2026-07-18-lw-007-flora-authorization-needed.md`) - MOOT, my
  supervisor's respawn directly authorized this turn's regen and it is
  orchestrator-decidable; (2) a PARALLEL non-role-briefed claude sign-off of the
  bake (`cc1848f`) - redundant, my proper role-briefed sign-off bd169cf is already
  integrated, both agree. No action; noted for visibility. If Scott's report reply
  lands later disagreeing, escalate then (spend already made under direct
  supervisor authorization).

**Last updated:** 2026-07-18 (RENDER SEAM WORK DONE + INTEGRATED + PUSHED, round
head `5777b83`. This run: render-tune first cut `9da0f94` BLOCKED by codex
[MODULATE built-in invalid in Godot 4.3-stable -> shaders did not compile;
orchestrator REPRODUCED it + found/closed a GATE HOLE where the export gate passed
green on shader-compile errors]; claude fix `37ce6c6` [uniform-based modulate + gate
now fails on SHADER ERROR], codex-signed `34d146a`, integrated. QA #002 was
COMPROMISED [stale-anchored, orchestrator falsified its tells] -> instituted
anti-anchoring QA prompts. QA #003 = one D1 tell [blown pale patch on smithy props
under the awning]; claude iter3 `a2f5f79` bisected it to the D4 tonal MULTIPLY
over-brightening light props + fixed with a per-kit highlight ceiling [awning
max_lum 193->151, roofs unchanged, orchestrator-reproduced], codex-signed `634e6ce`,
integrated. QA #004 [reliable, on round] = NOT-CONFUSABLE: D1 PASS + D4 PASS, two
remaining TELLs = foundation/flora-base VEGETATION [D2 buildings lack the spike's
base planting; D3 flora bases lack root-merge]; orchestrator corroborated D2 as
real + spike-calibrated, D3 as partially real. This gap = Scott's original
complaint. ITERATION 4 scoped above [foundation vegetation placement + flora base
feather; a composition/authoring step with a real design choice - triage full
protocol]. NOT surfaced to Scott [correct: NOT-CONFUSABLE]. Every phase this run
durable + pushed; NOTHING in flight at turn end.)
