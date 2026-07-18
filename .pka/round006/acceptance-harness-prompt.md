# Build the anonymized acceptance-capture harness + gate verdict (round 006, step 5)

You (codex-worker) own the acceptance-capture + walk-GIF harness (decision 009
DoL, line 189). This is the pilot's acceptance gate. Build it in a fresh worktree
cut from the current round head `round/006-two-rivers` @ **`5eee7bf`** (both
candidate atlases + cottages are now wired in-engine behind
`LONGWALK_ART_CANDIDATE=current|a|b`; the manifest-driven integration is signed
and merged).

## Goal

Produce the artifacts and measurements the orchestrator needs to rule the pilot
against decision 009's **six independently-failable pass conditions** (009 lines
142-149), verbatim:

1. **painterly fidelity**
2. **structural preservation** (no landmark mutation)
3. **motion stability** (no boiling, real gait, eight distinct facings, feet
   within a **2 px contact-anchor tolerance**)
4. **scale** (ratios met with **no runtime tweak**)
5. **grounding** (no ground seams, shared light vector)
6. **production economics** (the cleanup-labor ledger)

The capture must be **matched-composition, shipping-zoom, fixed-color-management**,
and a **full rerender from committed local inputs**. **NO second Meshy call** (see
hard constraints).

## Four subjects, anonymized

Capture all four, blind-labeled so the orchestrator (and any ballot voters) judge
the visuals before knowing which candidate is which:

- **candidate A**: `assets/art_src/pilot/candidate_a/` (atlas + manifest + finished sprites)
- **candidate B**: `assets/art_src/pilot/candidate_b/`
- **the SPIKE reference**: `docs/art/iso-five-asset-spike.png` (static) +
  `docs/art/player-walk-iso-spike.gif` (motion). This is the fidelity bar. It is a
  fixed reference image, not an in-engine render; crop/scale it to matched
  composition and label it as the reference.
- **the CURRENT build**: the round-005 default path (`LONGWALK_ART_CANDIDATE`
  unset: 4-facing proxy fold player + placeholder cottage facade).

For each subject emit, under `docs/art/acceptance/subject-<N>/`:
- a **static** matched-composition PNG of the town at shipping zoom, and
- a **walk-cycle GIF** of the player (cycle the six poses; show a representative
  facing and/or a facing sweep, consistently across all four subjects).

Write the anonymization key to `docs/art/acceptance/_key.json`
(`{"subject-1":"spike","subject-2":"a",...}`) as a SEPARATE file so the
orchestrator forms an aesthetic judgment from the subject-N images first, then
opens the key. Shuffle the subject-N assignment deterministically (e.g. by a fixed
permutation), not alphabetically.

### Capture mechanism caveat (important)

Under `--headless` with the dummy display, `RenderingServer.frame_post_draw` never
fires, so a live-viewport capture is skipped (the integration verifier already hits
this). Do NOT emit skipped/empty/placeholder captures. Produce **real pixels**:
either (a) run under `xvfb-run` if available so a GPU frame exists, or (b)
deterministically composite the actual atlas frames / finished sprites onto a
render of the real town background at shipping zoom via `Image` operations. Same
camera framing, zoom, and color management for all four subjects so they are
directly comparable. State in the verdict which mechanism you used.

## Measure the deterministic conditions (report numbers, per candidate A and B)

- **motion stability:** eight distinct facings (atlas rows are non-identical, not a
  4-row fold); feet stay within the **2 px** contact-anchor tolerance across all
  six frames per facing (measure and report the max deviation); no-boiling metric
  (bounded frame-to-frame delta; no per-frame generative jitter).
- **scale:** `tools/art/check_scale_contract.py` passes for the candidate scale
  manifests; the in-engine integration applies **no runtime scaling** (confirm and
  state it); report the player/door/eaves ratios vs the decision-010 contract.
- **grounding:** no ground seam at the sprite base (alpha/edge check at the contact
  plane); estimate the dominant light direction per sprite and confirm a shared
  light vector across the set.
- **production economics:** pull the cleanup-labor ledger from the candidate
  `PROVENANCE.md` files and extrapolate to the ~200-asset production curve.

## Verdict document

Write `docs/art/acceptance/VERDICT.md`: for EACH of the six conditions, give a
PASS/FAIL for the measurable parts with the measured numbers, and a
DEFER-TO-ORCHESTRATOR marker (with pointers to the relevant subject-N images) for
the aesthetic parts (painterly fidelity, structural preservation, Two-Rivers vibe).
Keep candidate identity anonymized in the body (refer to subject-N); the key file
is separate. Do NOT declare the overall gate pass/fail yourself; the orchestrator
rules. Summarize what you measured and where each subject stands.

## Hard constraints

- **NO Meshy. Zero paid calls.** Balance must stay **2970**. Full rerender uses
  ONLY committed local inputs (atlases, finished sprites, spike reference).
- **Do NOT background work and end your turn on an intention.** Run the full
  capture + measurement to completion in the FOREGROUND this turn, then commit.
  Nothing re-invokes a dispatched worker after its turn ends. A turn that ends on
  "the capture is rendering, I will commit after" produces no artifact and fails.
- **No em-dashes** anywhere (code, docs, commit message).
- This slice adds `tools/art/` code + `docs/art/acceptance/` artifacts. It must
  NOT touch `src/sim/`, protected paths, or any candidate deliverable. Keep the
  default in-engine behavior unchanged.
- Suite (`tools/run_tests.sh`) exits 0 with your additions.
- Produce ONE commit with a `Co-authored-by: Codex` trailer. Do NOT write a
  sign-off marker (author never signs its own work). Do NOT open a PR.

Note the committed capture artifacts may be a few MB of PNG/GIF; that is expected
for the gate. End your turn with the commit made, the captures + `_key.json` +
`VERDICT.md` on disk, and the tree clean.
