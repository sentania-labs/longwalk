# 018: generalized composition architecture (evolving chunk derivation)

- **Status:** accepted for the architecture spine and the Checkpoint B slice;
  the ARCHITECTURE.md clarification and the early persistence-layer-(b) slice
  are **escalated to Scott** (see Escalations) and gate only the full-milestone
  sim-side work, NOT Checkpoint B.
- **Date:** 2026-07-19
- **Assignment:** Round 007 generalized-composition milestone. Scott's verdict
  (relayed 2026-07-18T22:40Z): the buildings still read "stitched on / floating"
  because the GROUND does not respond to the buildings; stop polishing the one
  hand-tuned district and make the SYSTEM produce grounded buildings + zoned
  flora anywhere, proven on ground never hand-touched (his 1k x 1k / 10k x 10k
  scale question). The 2255 addendum adds the organic-evolution constraints.
  Checkpoint A (the spike spec, `docs/art/village/spike-spec.md`) was approved
  by Scott pragmatically on 2026-07-19T02:45Z ("I don't fully understand but
  let's build something to iterate on"). This is the architecture decision that
  Checkpoint A gated.
- **Orchestrator run:** Checkpoint-A-approved run, phase-1 stamp `20260719-030541`,
  codex re-dispatch `20260719-031224`, phase-2 stamp `20260719-031908`. See
  TEAM-STATE.md.
- **Lane:** full protocol (Scott directed; a zone-data model and an evolving
  terrain-response architecture are genuinely interpretive, and this touches
  `src/sim/` and proposes an `ARCHITECTURE.md` change).
- **Workers dispatched:** claude-worker, codex-worker, agy-worker

## Context

Checkpoint A converted "built on the ground" into a measured operational
definition: a three-band ground-response stack (contact seam, altered-ground
apron, wear/recovery) plus a precedence-based zone grammar, expressed to
generalize to unauthored ground (spike-spec Parts A/B/C). This decision answers
HOW the system produces that, at world scale, evolving over time.

The 2255 addendum makes three hard constraints binding on THIS decision: (1)
terrain response must be a FUNCTION of sim state and time (structure age,
traffic/usage, zone designations), not a one-time static bake; (2) incremental
chunk RE-bake is a first-class scale-contract requirement; (3) any design that
produces static output from static input is DISQUALIFIED at this gate.

Five decision points were in scope: the zone-data model, the terrain-response
derivation, the full scale contract, the generalization-test district, and the
path to Checkpoint B (one grounded demo tile).

## Proposals (phase 1, blind)

| Worker | Branch | Proposal commit SHA |
| --- | --- | --- |
| claude-worker | `claude/018-arch` | `ba233c6479f14866d131d5b6dba3589a74e34fd5` |
| codex-worker | `codex/018-arch` | `7368784e30a05b9c2bce98664dfcf2ffe0a77580` |
| agy-worker | `agy/018-arch` | `474c9012dbda234084537b8aaef074d110353dcd` |

Provisioning note: codex correctly BLOCKED its first phase-1 dispatch
(`codex-worker-20260719T030642Z`) because the assignment doc had not been
provisioned into its worktree; the orchestrator provisioned it and re-dispatched
(`018arch-codex2`), yielding the SHA above. claude and agy proceeded from the
constraints inlined in the dispatch prompt. The block was an orchestrator
provisioning gap, resolved within the same run; no proposal was anchored.

All three converged, blind, on the same core architecture:

- **Sim owns facts, render derives appearance.** Coarse land-use zone
  (yard/field/wild) and evolving world history (structure age, foot traffic,
  disturbance ticks) live as texture-free `src/sim/` data. The fine terrain
  response (the three-band stack, adjacency asymmetry, exact seam pixels) is
  DERIVED per-texel by the render/bake layer as a pure function of `(world seed,
  world position, sim-state snapshot, rule version)`. Sim never computes a pixel;
  render/bake never invents land-use.
- **Foundation response is a wall-local per-texel modifier, not a stored zone
  tag.** All three independently ruled that a per-cell zone tag cannot carry the
  measured sub-cell band shape or the >3x per-face asymmetry, and that baking a
  per-texel zone tag for the whole world is exactly the static bake the gate
  forbids. So: coarse intent in sim, fine response derived.
- **Chunks are a disposable, re-derivable cache.** The whole world is never
  baked at once; chunks are derived on demand and re-derived incrementally when
  the sim state under them dirties. Resident memory is bounded by the camera
  window, independent of world size. This unifies evolution and scale into one
  code path (addendum constraint 2).

**claude** gave the most concrete channel contract (two response textures per
chunk, explicit insertion at the decision-016 named `ground.gdshader` point), a
64x64-cell / 8-texels-per-cell chunk, an explicit persistence-free Checkpoint B
(pass `age` as a literal kernel argument), and a clean ARCHITECTURE.md
escalation.

**codex** gave the most rigorous boundary: an immutable `composition_snapshot`
with a content fingerprint and monotonic revision, "re-bake off the presentation
path then swap only if the snapshot revision is still current," per-sample
precedence resolution over independent distance/coverage fields (not a single
edge enum), semantic door/service edges as sim-side data, a 32x32-cell /
16-tpc chunk with a 4-cell halo, and a full scale table (191 GiB raw at 10k,
~50 MiB resident window).

**agy** gave the crispest statement of the unifying thesis ("the incremental
re-bake pipeline uses the same machinery as loading a new 10k x 10k sector") and
one genuinely distinctive idea: deriving door/garden adjacency from an actual
`FootTrafficMap` (where entities have walked) rather than an authored label.

## Critique (phase 2, adversarial)

Critique artifacts: claude `792520adb6c08a62425c1edb7f8ec039194c09eb`, codex
`25ae1fe74ed2804488300798702f4a1587fc172e`, agy
`c269ef5458fd0df35e2fbe716b799df70ff4f613`. The round was genuinely adversarial
(no "looks good") and produced clear rulings:

- **codex is the strongest spine.** Both claude and codex independently ranked
  codex's proposal strongest; claude conceded codex's snapshot/fingerprint/
  revision machinery beats its own `chunk_index` byte-stability approach for
  async re-bake safety, and would graft it in.
- **The single-nearest-edge adjacency enum is too lossy (codex vs claude).**
  codex's critique A5: one nearest footprint edge classified once cannot
  represent a door inset on a long lane-facing edge, a partial service bay, or
  overlapping response fields; precedence must be resolved PER SAMPLE over
  independent door/service/lane/footprint fields with stable tie-breaking. This
  is adopted over claude's single-edge classification.
- **Traffic cannot be the PRIMARY adjacency driver (claude B4 + codex #4 vs
  agy).** A newly built structure has near-zero accumulated traffic, so a
  traffic-derived door cannot render the young-building half of the gate proof
  (young vs old). Geometry/semantic door+service edges classify at t=0; traffic
  MODULATES wear over time. agy's emergent-traffic idea is grafted as the
  time-evolution modulator, not the base classifier. (Contested; ruled 3-1, see
  Dissent.)
- **agy's determinism gap (claude B1 + codex #2).** agy's generalization
  generator ("valid but random ... randomized paths of simulated foot traffic")
  and its `FootTrafficMap` ("an accumulator of where entities walk") do not
  state a `(seed, position)` purity or an order-invariant resolution rule. Both
  peers named this against the CLAUDE.md determinism rule. The synthesis adopts
  the deterministic construction both codex and claude specified (coordinate-
  keyed candidate set + canonical priority over a bounded neighborhood; traffic
  as integer counters updated in a stable tick/event order). See Dissent for the
  constitution-violation handling.
- **The runtime execution model is unresolved in ALL proposals (codex #1/#6).**
  The live path loads fixed `res://` PNGs via `ResourceLoader`; a packaged game
  cannot invoke a `tools/` baker as its runtime worker, and freshly written
  cache PNGs are not automatically imported textures. The runtime on-demand
  cache boundary (raw `Image`->`ImageTexture`, a `user://` cache format+loader,
  or an external pre-bake service) must be named before it is built. Ruling: it
  is NOT named in this decision; Checkpoint B stays OFFLINE on the proven
  016/017 substrate, and the runtime cache execution model is deferred and rides
  the ARCHITECTURE.md escalation.
- **Chunk size / texel density is unsettled (claude A1 vs codex/agy).** claude's
  8-tpc / 64-chunk runs ~5x less resident memory than codex's 16-tpc / 32-chunk
  for the same view, justified by the spec's screen-space-seam ruling; agy and
  codex warned 8-tpc may alias the apron edge-break. Both sides offered the
  other's value as a fallback. Ruling: this is resolved by MEASUREMENT, not
  frozen here (see Decision, scale contract).

## Decision (phase 3, synthesis)

The converged architecture, codex's spine with claude's and agy's grafts:

### 1. Zone-data model (sim owns coarse + semantic; render derives fine)

- `src/sim/composition/zone_map.gd` (new sim data): texture-free authored
  baseline, one coarse base zone per cell {LANE, YARD, FIELD, WILD} as an
  unsigned byte, PLUS sparse SEMANTIC overlays for access corridors, door edges,
  and service areas as polylines/polygons in ground units. Base zone is
  land-use (sim owns it; the ecology layer will own field-cultivation and
  wild-regrowth). Foundation response is NOT a base zone; it is a wall-local
  modifier.
- `src/sim/composition/ground_history.gd` (new sim data): time-varying FACTS,
  not colors, quantized: traffic intensity + last-traffic tick, disturbance
  intensity + last-disturbance tick, and sparse structure records (stable id,
  footprint, facing, door/service edges, construction tick, removal tick, usage
  class). Moisture/overgrowth fields are RESERVED for the ecology layer and are
  NOT stood up now (see Risks: do not front-load undesigned ecology state).
- `src/sim/composition/composition_snapshot.gd` (new): the immutable, canonical
  snapshot handed across the sim/render boundary, sorted by stable id, carrying
  a content fingerprint and monotonic revision, containing NO texture path,
  pixel coordinate, palette, shader parameter, or viewport fact.

Precedence (spike-spec Part B: footprint > lane/access > foundation-apron > yard
> field/wild) is resolved PER SAMPLE inside the deriver as a layered result over
independent distance/coverage fields, highest first, with stable tie-breaking.
NOT a single edge enum (codex A5 adopted). Adjacency class per oriented footprint
edge {DOOR, SERVICE, LANE_FACING, GARDEN_FIELD, YARD, WILD, STRUCTURE_NEIGHBOR}
is derived at t=0 from the sim-side semantic geometry, then traffic MODULATES
wear over time (agy's idea, corrected for cold-start).

### 2. Terrain-response derivation (evolving)

`src/render/town/composition_rules.gd` (pure visual policy: age->apron maturity,
recent-traffic->wear, inactivity->recovery, adjacency-subtype->band width) feeds
`src/render/town/composition_chunk_baker.gd` (headless-capable CPU derivation
kernel; generalizes decision-016 `bake_footprint_field.gd` and subsumes
decision-017 foundation vegetation as derived output records on the shared
derived-instance contract). Per texel: edge-oriented signed distances, the
three bands per spec Part C (contact seam as a ground-space coverage channel
whose width is reconstructed SCREEN-SPACE with the 1-2px floor in
`ground.gdshader`; darkening as a clamped RATIO ~0.35-0.4x of local ground
luminance; apron width RELATIVE to a local ground feature; concave coverage-based
recovery). Age/traffic/disturbance parameterize band shape: a 40-year high-use
building and a last-season building ground differently because the INPUTS
differ. Every sample keyed by (world seed, named layer offset, absolute integer
texel coord), never traversal order. Discrete flora keeps the decision-017
positional-hash determinism; conflicts resolved by the minimum canonical tuple
over the COMPLETE local candidate set (input-order invariant).

### 3. Scale contract

- **Chunk = 32x32 cells** (codex's granularity as the default spine), **halo =
  the MAX response reach in cells** (apron/recovery/lane-feather/planting-
  exclusion, derived not assumed; codex's 4-cell figure is the initial target),
  discarded on output so neighbors meet byte-for-byte. A byte-level shared-border
  test is MANDATORY, and it must cover BOTH the SDF fields AND the discrete
  scatter tie-break AND any rasterized semantic vector (claude A2/A4 adopted: the
  halo must contain every candidate that could conflict, which may exceed
  response reach).
- **Texel density is a MEASURED knob, not frozen.** First benchmark renders 8-tpc,
  16-tpc, and a shader-reconstructed reduced-channel variant at 0.5x/1x/2x and
  picks the smallest contract that stays visually equivalent to the spike
  (resolves the claude-A1 vs codex/agy density fork by measurement; both sides
  offered the other's value as fallback).
- **The world is never a monolithic shipped artifact.** What ships is the compact
  sim baseline (zone_map + sparse history, kilobytes/region). Derived chunks are
  a bounded, evictable, view-window-resident cache. Recorded ceilings to
  measure, not promises: raw two-texture output ~2 MiB/chunk at 16-tpc (~0.5-1.5
  MiB at reduced density); full 10k x 10k pre-bake ~190 GiB raw / tens of GiB
  compressed, which is precisely why it MUST be demand-derived and evictable.
- **Re-bake budget:** initial target <=250 ms CPU per 32x32 chunk on the
  reference machine, off the presentation path, swap-if-revision-current, dirty
  events coalesced by chunk revision, time quantized to named age/recovery epochs
  so a passing year does not dirty every occupied chunk every tick (codex #2
  adopted). GDScript feasibility of the budget is UNPROVEN and is the first
  benchmark; if unreachable, optimize kernel + data layout before considering any
  native dependency (which is a separate Scott escalation).
- **Determinism:** kernel is a pure function of (seed, position, sim-state);
  the generalization generator is coordinate-keyed candidates + canonical
  priority over a bounded neighborhood, NO sequential/unseeded RNG and NO
  visit-order accumulator (CLAUDE.md determinism rule; the parked
  `macro_map.gd` FastNoiseLite-keyed-off-seed pattern is the model).

### 4. Generalization-test district

A deterministic district fixture generator (authoring/test harness only): given a
fixed seed and bounds, it places lanes, lots, doors, service yards, one authored
field polygon, and a wild boundary using ONLY positional hashes and canonical
global-coordinate choices, conflicts settled by canonical priority over the full
candidate set. No hand-editing of its output. Acceptance runs the PRODUCTION
chunk baker across it in >=2 traversal orders, asserts byte-identical output,
seam continuity, lane/access flora exclusion, a three-band response around every
footprint, DIFFERENT young/mature responses from different sim inputs, and a
changed-history re-bake that changes only the expected chunk neighborhood. QA is
performed on that untouched output, never on the inn-green plate.

### 5. Checkpoint B (the smallest proof, buildable NOW)

ONE 32x32-cell tile: one cottage, a short lane + door approach, yard, one
AUTHORED sunflower field (spike palette + approved grammar, team-authored since
the spike shows no field: warm dark cultivated-soil bed, coherent clumps/short
staggered rows, soft coverage-broken edges, a clean access gap to the lane, NO
crops in yard or travel core), and a wild edge. Rendered from TWO sim snapshots
of identical geometry+seed: age-1 low-use vs age-40 high-use, with a
byte-difference assertion (unchanged inputs byte-stable; changed inputs
observably different). That single comparison proves the whole claim: the field
stays a field, the door exclusion stays clean, and the three bands + foundation
growth change because state and time changed, not because a patch was painted.

**Checkpoint B stays OFFLINE and passes `age` as an explicit literal argument**
(claude 1.6/1.8, which codex conceded is the clean path). It therefore requires
NO persistence store, NO runtime cache execution model, and NO `src/sim/`
change: it lives in `src/render/town/*` + `tools/art/*` (neither protected). It
is buildable immediately under Scott's "build something to iterate on" approval.
Scott sees the mature tile for Checkpoint B with the young tile beside it as
evidence that this is a rule, not a painted patch, BEFORE any full-district
generation.

### How the three hard constraints + disqualification gate are passed

Terrain response is explicitly a function of structure age, traffic,
disturbance, zone designation, and current tick. The same 32-cell chunk
machinery performs first bake and incremental re-bake. Static semantic input
does NOT imply static visual output because sim history and time are required
inputs, and Checkpoint B is required to PROVE two outputs from two states. World-
scale generation (vary position/seed) and in-place evolution (vary sim-state)
are the same kernel with different arguments, reachable with no redesign. **Gate
passed, and the demo tile is the falsifiable proof of it.**

## Division of labor

| Piece | Assigned to | Why this harness |
| --- | --- | --- |
| Derivation kernel + chunk/scale harness (baker, snapshot consumer, per-sample precedence classifier, edge-oriented SDFs, positional-hash scatter, halo/dirty propagation, byte-stability + traversal-order tests, benchmark fixture, migration of 016 field + 017 records onto the shared contract) | codex-worker | Owns `bake_footprint_field.gd` / `bake_lane_mask.gd`, authored the derived-instance contract and four-invariant test discipline in 017; strongest at reproducible pixel processors and testable data contracts. All three proposals routed this slice to codex. |
| Deterministic generalization-district generator | codex-worker | Needs airtight `(seed, position)` purity and canonical conflict resolution; codex's determinism rigor is the fit. NOT agy, whose own generator proposal defaulted to "random" (see Dissent) and so is the wrong seat for the determinism-critical generator. |
| Checkpoint B demo tile + authored field-zone grammar + render-side consumption and capture-inspect perceptual tuning | claude-worker | The "does it read as built-on to Scott's eye" slice, driven by the capture-inspect loop claude built across 016/017; both peers routed perceptual tuning to claude. |
| QA / acceptance on the never-hand-touched generated district + adversarial determinism/byte-stability audit | agy-worker | The established independent QA seat (QA #004/#005); the generalization gate needs a third eye that did not build the kernel, and agy's adversarial-skeptic value lands squarely on byte-stability and the "young vs old" gate proof. |

Pipeline shape (as 016/017): codex freezes the response-field channel contract
and derives the kernel; claude consumes and tunes the demo tile; agy QAs the
generated district on never-touched ground. The channel contract is frozen
before claude's render slice starts.

## Dissent

**agy's traffic-primary adjacency, ruled 3-1 (claude, codex, orchestrator vs
agy).** agy proposed deriving door/garden adjacency FROM accumulated traffic.
agy's proposal, verbatim:

> "Adjacency (lane/door/garden asymmetry) is derived directly from the
> `FootTrafficMap` and the authored lane positions. High traffic or proximity to
> a lane = door/lane side (clean notch, compressed band). Low traffic = garden
> side (wide, dark, planted response)."

Refuted by measurement/logic on the cold-start case: a newly built structure has
near-zero accumulated traffic, so a traffic-derived door cannot exist at t=0,
yet the spike spec requires the young/lane-facing face to read compressed and
clean from day one, and the disqualification gate is proven by rendering young
vs old of the same building. Both peers found this independently (claude B4,
codex #4). The valid kernel of agy's idea (traffic as an emergent signal) is
ADOPTED as the time-evolution MODULATOR: geometry/semantic edges classify
adjacency at t=0, traffic deepens wear thereafter. This did not reach a 2-2
split, so the critic seat was NOT invoked (per decision 004 and the
orchestrator brief).

**agy's determinism gap: a claimed constitution violation, and its handling.**
Both peers stated in the required terms that agy's proposal VIOLATES the
CLAUDE.md determinism rule (claude B1: "CONSTITUTION VIOLATION (determinism)";
codex #2: "Antigravity's proposal VIOLATES the constitution's determinism
rule"). agy's proposal, verbatim:

> "we will write a script that generates a valid but random sim-state layout
> (buildings of varying ages, randomized paths of simulated foot traffic, and a
> designated logical field zone) without any human artist intervention."

This is a critique finding against a LOSING proposal, not a losing objection
against the winning synthesis: the synthesis does NOT adopt agy's random
generator; it adopts the deterministic `(seed, position)` construction both
peers specified. agy did not defend the random construction in its own critique.
There is therefore no live constitution-violation objection to escalate to
Scott: the escalation rule fires when a LOSING side's objection claims the
WINNING decision violates the constitution, which is the reverse of this. The
synthesis is deterministic and constitution-conformant. Recorded here verbatim
per protocol so the ruling is auditable.

## Escalations (to Scott, not decided by the team)

Two items touch `ARCHITECTURE.md` and the persistence design and so are Scott
escalations, filed separately. They gate the FULL-milestone sim-side work; they
do NOT gate Checkpoint B (which is offline, render+tools only, no protected
path).

1. **ARCHITECTURE.md clarification.** Section 2a currently says the map is not
   computed at runtime, and section 3 lists persistence as documented-only. The
   architecture needs Scott to approve a concrete clarification: the authored
   semantic baseline stays frozen, while PRESENTATION caches (derived pixels)
   may be derived at runtime from baseline plus persistent sim deltas/history,
   and derived pixels are never authoritative state; section 3 should name
   chunked ground-history facts as delta/sim data without prematurely
   implementing the full persistence layer. This is an architecture edit; the
   team does not make it.

2. **Early persistence-layer-(b) slice.** Standing up `ground_history` (age,
   traffic, event ticks) as persistent sim state lands a slice of the
   delta/override layer earlier than the roadmap implies. Scott authorizes (or
   defers) that; if deferred, Checkpoint B still ships (explicit `age`
   argument), and only the full evolution story waits.

The runtime on-demand cache execution model (raw `Image`->`ImageTexture` vs a
`user://` cache format+loader vs an external pre-bake service) is also deferred
and rides escalation 1; it is not built for Checkpoint B.

## Protected paths touched

> Checkpoint B touches NONE of these (it is `src/render/town/*` + `tools/art/*`
> only, and neither is protected). The paths below are listed for the
> FULL-milestone sim-side work this record governs, which is gated on the Scott
> escalations above.

src/sim/
ARCHITECTURE.md

## Sign-offs

Every worker named in `Workers dispatched` signs. Signing means "I read the
synthesis and accept it as the team's decision," not necessarily agreement with
all of it; agy's losing objection is recorded verbatim above and agy still
signs.

    Signed-off-by: claude-worker <claude@sentania.net> PENDING
    Signed-off-by: codex-worker <codex@sentania.net> PENDING
    Signed-off-by: agy-worker <agy@sentania.net> PENDING
