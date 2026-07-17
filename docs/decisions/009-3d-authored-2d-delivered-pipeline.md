# 009: 3D-authored, 2D-delivered art production (Path 3), pilot-gated

- **Status:** accepted
- **Date:** 2026-07-17
- **Assignment:** Round 006, Two Rivers iteration (directive 1500) + art-production
  fork (directive 1515): iterate the starter town to iso-five-asset-spike fidelity
  and the Two Rivers vibe in the running game, and choose an art-production method
  (pure-sprite vs real-time 3D vs 3D-pre-rendered-to-2D).
- **Orchestrator run:** `orchestrator-run-20260717-193928` (see TEAM-STATE.md)
- **Lane:** full protocol (contested; three doers dispatched)
- **Workers dispatched:** claude-worker, codex-worker, agy-worker

## Context

Round 005 shipped the isometric visual identity (decision 008) but Scott's
playtest named four defects (walk-cycle animation, building/player scale, a
whole-scene-to-sprite fidelity gap, and an "Instance base is null" runtime bug),
and directive 1515 opened the art-PRODUCTION method as a fork: stay pure-sprite,
go real-time Meshy 3D through an iso-locked camera, or author in 3D and
pre-render to painterly 2D sprites. The goal (spike fidelity + Two Rivers vibe in
the running game) is fixed; only the production method was on the table.
Isometric stays settled (007); `src/sim/` stays projection- and art-ignorant;
Meshy is a new external dependency (escalation-class).

## Proposals (phase 1, blind)

| Worker | Branch | Proposal commit SHA |
| --- | --- | --- |
| claude-worker | `claude/006-proposal` | `8da1420640a1461b936111e42db7419749490f7f` |
| codex-worker | `codex/006-proposal` | `b707cf7f7e7102ff57e34df0b47377b751f11eea` |
| agy-worker | `agy/006-proposal` | `d6a0f8288ba266ceeda3f0d66afce1b2bdc783cb` |

All three independently recommended **Path 3** (author in 3D, pre-render from the
fixed iso angle to painterly 2D sprites), rejecting pure-sprite (the spike proves
the look is reachable in one composed image, but it collapses when decomposed into
independent per-asset sprites, flat ground diamonds, and a proxy walk) and
real-time 3D (discards the just-built iso render spine and risks a "generic indie
3D" read that misses the painterly vibe). They differed on the load-bearing
sub-question: **how to recover the spike's painterly fidelity from a clean 3D
render.** claude argued a generative *repaint* is required because painterliness
is a property of the 2D image generator, not any 3D render ("3D-as-scaffold,
2D-as-skin"). codex argued *deterministic NPR/compositing only*, warning that
per-frame generative repaint reintroduces temporal "boiling," and supplied the
most rigorous scale contract and acceptance gate of the three. agy proposed an
*optional low-strength img2img* pass and claimed the Meshy/render tooling slice.

## Critique (phase 2, adversarial)

- **claude** (`0b496efe1f15ade69a8232a61cc176be203bc3a9`): named codex's temporal-
  boiling objection "the single strongest technical observation in either peer
  proposal" and accepted that any generative repaint must be a single fixed-seed
  whole-sheet pass OR a texture-space (mesh-albedo) pass, never per-frame. But
  showed codex's deterministic-NPR-only resolution has a hole: deterministic NPR
  yields cel/toon, not painterly brushwork, and codex's fallback ("hand-painted
  Blender materials") quietly reintroduces the exact manual-artistry skill gap
  Path 3 exists to avoid. Corrected two repo-specific errors in codex's plan:
  the render camera must be pinned to `src/render/iso/projection.gd`'s 2:1
  dimetric geometry (atan(0.5) elevation / 45 deg azimuth ortho), not a generic
  30-degree iso; and the decision-008 Q-C offline-derived shadow MASK must remain
  the shipped shadow (a Blender cast-shadow pass is a cross-check only, else it
  supersedes a binding 4-0 decision). Attacked agy's proposal as weakest: an
  acceptance gate that cannot detect the "generic 3D" failure mode, a ~3-5x-low
  estimate that zeros the riskiest slice (mesh cleanup + rig weighting), a
  Godot-sub-viewport render option that fights the 2026-07-15 pivot (which parked
  all 3D out of the active project), and no determinism/provenance handling.
- **codex** (`e4237a22d75a9f47d601b10223948f9fb81d9735`): attacked claude's
  "consistency guaranteed by the shared 3D source" as ending at the raw render, a
  generative repaint is a NEW generation boundary that can mutate roof pitch,
  window count, foot contact, and facing identity (conditioning constrains a
  sample, it does not make an identity-preserving transform). Demanded the pilot
  render TWO explicit candidates from the same scene (deterministic vs stylized)
  so a failed repaint cannot be rhetorically converted into a successful Path-3
  pilot, plus a cleanup-labor ledger to price the 200-asset curve, matched/
  anonymized in-engine gating against the SPIKE (not the known-bad current
  build), and a pinned Blender render spec. Attacked agy for making the central
  fidelity decision "optional," the "rig mathematically cannot drift" overclaim,
  the ~16h estimate, the unresolved render-tool choice, and importing Mixamo as a
  second undeclared external dependency "by convenience."
- **agy** (`b7327bec27e149e42d6ad62795db5f7ea7415da6`): conceded the temporal-
  boiling problem, attacking BOTH its own img2img and claude's repaint on
  temporal-consistency and determinism grounds, and attacked codex's
  deterministic-NPR-only as a "delusion" that cannot reach painterly brushwork
  and will fall into the "glossy generic 3D" trap. Pushed a Godot sub-viewport
  over Blender ("tooling bloat") for both peers.

## Decision (phase 3, synthesis)

**Path 3 is adopted** (converged, no ballot needed): author assets in 3D (Meshy
draft geometry, cleaned + rigged + posed in Blender), pre-render from the fixed
isometric angle to 2D sprite sheets, and feed them through the existing
`tools/art/` ingest/process pipeline onto the decision-007/008 iso render spine.
Real-time 3D and pure-sprite are rejected for the reasons all three proposals
gave. **Per-frame independent generative repaint is banned** (converged, no
ballot needed): all three agree it reintroduces temporal boiling and forfeits the
consistency 3D was introduced to guarantee.

The load-bearing synthesis is on the contested fidelity-recovery question, and it
is a merge, not a pick: **the pilot produces and measures TWO candidates from the
same 3D scene, a (A) deterministic NPR/composited baseline and a (B) generative
stylization applied in texture space (mesh albedo, once) OR as a single
fixed-seed whole-sheet pass.** codex supplies the reason B must never run
per-frame and the discipline that B is admissible only if its accepted outputs
are frozen with provenance (archival reproducibility distinguished from
regeneration reproducibility) and it causes no landmark mutation or boiling;
claude supplies the reason A alone underdelivers (the spike's painterliness is a
generative artifact, not a deterministic-NPR one). Running both, side by side,
under the rejection rules, is what lets the pilot decide the mechanism on
evidence instead of on assertion, and prevents a failed B from being laundered
into a Path-3 success.

The full synthesis constraints (grafting codex's rigor, claude's repo-specific
corrections, and agy's tooling bid):

1. **Blender headless** is the single offline authoring + render source, pinned
   (version, camera, color management, render engine, CPU/GPU, alpha, and pass
   settings; an explicit render command, not just a committed `.blend`). Godot is
   used only for shipping-renderer acceptance capture. (Contested; see ballot Q2.)
2. **Camera calibration first.** Prove render-camera agreement with a primitive
   calibration scene against `src/render/iso/projection.gd` (2:1 dimetric, verify
   the elevation/azimuth rather than copying an angle into prose) BEFORE any Meshy
   asset is judged. Sprites author to the frozen `building_contact_cell` anchor
   (`projection.gd:212`).
3. **Scale contract** (codex's, adopted wholesale and extended): 1 world unit =
   1 m; player 1.75 m sole-to-crown; door 2.0 m; eaves ~2.4 m; ridge 4.8-5.6 m;
   plus `pixels_per_meter`, output resolution, contact-plane definition, canvas/
   padding policy, and a prohibition on downstream resampling. A validation script
   FAILS the build when declared scene scale, rendered contact anchor, or expected
   pixel height drift out of tolerance, checked from scene geometry pre-render and
   from projected landmarks post-process. No per-asset aesthetic scale overrides.
4. **Shadows:** the decision-008 Q-C offline-derived deterministic shadow MASK
   (`process_assets.py`) remains the SHIPPED shadow. Any Blender cast-shadow pass
   is a cross-check only; it does not ship without a new decision record.
5. **Pilot scope (small, pre-authorized):** exactly one 2x2 half-timbered cottage
   and one player with one six-pose walk at eight facings, plus minimal textured
   ground/lane/hedge/flora dressing for ONE in-engine comparison plot. It does not
   model the inn, produce the rest of the town, touch `src/sim/`, or commit
   longwalk to Meshy.
6. **Cleanup-labor ledger** (codex's): log human minutes by category (rejected
   generations, mesh edits, UV/texture repair, rig repair, render retries) for the
   cottage and the player separately, and extrapolate the observed range to the
   ~200-asset curve BEFORE any production tranche is authorized.
7. **Acceptance gate:** matched-composition, shipping-zoom, fixed-color-management,
   ANONYMIZED in-engine comparison against the SPIKE (not merely the known-bad
   current build), with static and moving (walk GIF) captures. Separate,
   independently-failable pass conditions: painterly fidelity, structural
   preservation (no landmark mutation), motion stability (no boiling, real gait,
   eight distinct facings, feet within a 2 px contact-anchor tolerance), scale
   (ratios met with no runtime tweak), grounding (no ground seams, shared light
   vector), and production economics (the ledger). A full rerender from committed
   local inputs, with no second Meshy call, is required. It must fail if the
   deterministic render misses the spike and stylization cannot close the gap
   without visible mutation.
8. **Meshy is escalation-class.** The SMALL pilot is pre-authorized. ADOPTING
   Meshy for production is called out to Scott below and requires his explicit
   approval before any tranche beyond the pilot. No second external dependency
   (e.g. Mixamo) enters the pilot by convenience; author the gait locally or from
   already-approved retained inputs unless Scott approves otherwise. A pilot
   provenance manifest records service version, request parameters, license note,
   and source hashes.
9. **`src/sim/` untouched.** The "Instance base is null" repair is an independent
   fast lane, diagnosed from a clean-import reproduction and the engine stack (not
   a guessed `load()` site), with a boot-flow regression assertion that fails on
   that exact text. It is not bundled into evidence for the art path.

### Four-ballot vote

Per decision 004, contested synthesis questions collect four ballots
(orchestrator + claude-worker + codex-worker + agy-worker); a 3-1 or 4-0 decides,
a 2-2 invokes the critic. Two questions were genuinely contested:

- **Q1 (fidelity-recovery mechanism):** adopt the dual-candidate pilot (A
  deterministic baseline + B texture-space/whole-sheet fixed-seed generative,
  never per-frame; pilot measures under the rejection rules).
- **Q2 (offline render tool):** Blender headless as the single authoring+render
  source (Godot only for acceptance capture), rather than a Godot 3D sub-viewport.

<!-- BALLOT RESULTS filled after the four-ballot dispatch. -->
**Result:** _pending ballots (orchestrator votes FOR Q1's dual-candidate merge and
FOR Q2's Blender-headless; the three doer ballots are being collected)._

## Division of labor

| Piece | Assigned to | Why this harness |
| --- | --- | --- |
| 2D delivery boundary: render-pass specs, pre-render manifests, the deterministic NPR/composite baseline (candidate A), chroma/alpha cleanup, anchor + scale validation scripts, 8-facing atlas assembly, the acceptance-capture + walk-GIF harness | codex-worker | Scott's sprite-forge mandate binds the codex seat; codex authored the most rigorous scale contract and acceptance gate and owns the `tools/art/` pipeline this extends. |
| Meshy API integration + pilot provenance manifest, the Blender-headless offline render tool + primitive camera-calibration scene, the cleanup-labor ledger tooling | agy-worker | agy's systems-integration/tooling strength; it made the cleanest DoL bid for the Meshy + render automation and should own the new external-service boundary and its provenance. |
| In-engine integration into `starter_town.gd` / `player_controller_2d.gd`, camera + `building_contact_cell` anchor-contract conformance, candidate B (texture-space/whole-sheet generative stylization) design, AND the "Instance base is null" fast-lane fix | claude-worker | claude owns the round-005 iso render spine and the two files where the null surfaces; the anchor/camera contract is render-spine work; the null-fix DoL collision (agy also claimed it) resolves to code ownership. |
| Blender topology cleanup, armature weighting, and gait tuning | shared, sequenced into the pilot | none of the three claims strong 3D/rig tooling; this is the least-owned, riskiest slice and the ledger exists to price it. Sequence it explicitly rather than time-box it as if owned. |

## Dissent

_Pending: any losing ballot objection will be recorded here verbatim after the
four-ballot dispatch. agy's Godot-sub-viewport position (Q2) and any surviving
minority position are recorded in the objector's own words._

## Protected paths touched

`project.godot`

## Sign-offs

<!-- Filled after ballots; signing = "I read the synthesis and accept it as the
team's decision," a worker whose objection lost still signs and its dissent is
recorded verbatim above. -->

    Signed-off-by: claude-worker <claude@sentania.net> PENDING
    Signed-off-by: codex-worker <codex@sentania.net> PENDING
    Signed-off-by: agy-worker <agy@sentania.net> PENDING
