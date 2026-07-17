# 005: walk-cycle generation topology, after the third spike failure

- **Status:** accepted
- **Date:** 2026-07-17
- **Workers dispatched:** claude-worker, codex-worker, agy-worker
- **Decided by:** four-ballot vote under
  [004](004-round-branch-integration-and-voting-model.md), **4-0**. No critic
  invoked: 004 invokes the critic on a 2-2 split only.
- **Supersedes:** the generation topology ruled in
  [003](003-village-feel.md) (agy's colored boots on a single 3x4 sheet). The
  rest of 003 stands unchanged.
- **Protected paths touched:** None.

## Context

Decision 003 fused two separable choices into one ruling: agy's **chromatic
modality** (magenta left boot, cyan right boot, to bind an image-space signal to
a constraint that is semantically distinct but visually identical) and agy's
**single 3x4 composition** (all twelve cells in one generation call).

codex-worker ran that spike and wrote a BLOCKED marker
(`.team/blocked/codex-worker-20260717T054310Z.md`, branch `codex/art`) after
three revisions. Artifacts, all unrecolored and unmirrored, are committed at
`a2add01a38cf684414b75c44075990c7825601d7` with the prompts and gate reports.

The spike is a clean natural experiment, and its result is more informative than
"it failed":

- **Revision 3 passed side alternation.** The chromatic modality works.
- **Down and up failed on every revision**: the same boot led in both contact
  frames.
- **Every revision passed the anchor-drift ceiling** (0.05, per Scott's 0430
  steer). Ground contact was never the problem.
- The revisions were a real ladder against the one variable: full locomotion
  contract, then both-boots-visible with per-row forward direction, then explicit
  cell-by-cell image coordinates with a minimum boot separation. Down and up did
  not move at all.

codex refused to launder a pass, in its own words: reassigning marker colors
after generation "could manufacture a validator pass without proving the
anatomical binding, which would repeat the exact laundering failure the gate
order prevents." That refusal is correct and was not at issue in this ballot.

The failure landed exactly where claude-worker's phase-1 argument predicted: a
3x4 sheet asks a diffusion model to satisfy constraints that are *relational
between cells*, and diffusion has no cross-cell state. Down and up are the
facings where the legs occlude and lateral separation is smallest, so the
chromatic signal is weakest precisely where the relational constraint is
hardest.

**The combination the evidence points at, colored boots without the single 3x4
composition, had never been tried by anyone.** Claude and codex both argued in
phase 1 to abandon the single composition; agy dissented and kept it; 003 ruled
for agy's boots on agy's sheet.

## Decision

**Option B: per-facing generation, then deterministic assembly.**

Generate each facing's four-frame strip in its own call (one relational
constraint per call), **retaining the colored boots**, then assemble the 3x4
source sheet deterministically in code, then run the **unchanged** pre-recolor
gate on the assembled source rows, then mirror, then recolor.

What does **not** change:

- **The pipeline order stays binding**: generate colored, validate per source row
  pre-mirror and pre-recolor, then mirror, then recolor. The pre-recolor image is
  the artifact of record.
- **The gate is not edited to make a sheet pass.** It rejected honestly. It is
  peer-signed and integrated (`tools/art/check_walk_sheet.py`, signed by
  codex-worker at `2e87ba3`).
- **The procedural bob fallback stays out of bounds** (Scott, escalation
  `50ceed18`: option 2, spend more spike budget).
- Three source rows (down, up, side). Diagonals remain the first stretch.
  Four-cardinal snapping remains unauthorized.
- The accept authority remains codex's in-game capture at 160px. The gate may
  only reject.

**Option C (hand-authoring down and up) is explicitly held in reserve, not
rejected.** Scott authorized it directly ("different generator framing, more
revisions, or hand-authored frames are all in bounds"). If B fails on either
alternation or coherence, C is the fallback and does not need another ballot.

## The risk all four ballots independently named, and the mitigation

Every ballot, unprompted, identified the same hazard and converged on
substantially the same mitigation. That convergence is the strongest signal in
this round.

**Identity and costume coherence across separately generated calls.** The single
sheet was genuinely good at the one thing per-facing generation gives up: both
round-1 candidates held one costume across twelve cells unasked. Boot color is
the marker, so drift in tunic hue, hair, build, or proportions **would not trip
the alternation gate at all**. The team could assemble a sheet that passes every
check and is visibly three or four different people.

The dispatch is therefore scoped to test coherence **before** spending revisions
on alternation:

1. **Generate side first** and use it as the reference for the others. It is the
   facing that already passed.
2. **Locked prompt contract** across all calls: identical costume, palette,
   proportions, and dimensions clauses, varying only the facing.
3. **Staged checkpoint** (codex's scoping): generate two strips first, assemble
   provisionally, run both the locomotion gate and an explicit cross-facing
   coherence review, and continue only if both pass.
4. **Coherence is judged as a human artifact and reported explicitly**, before
   any gate runs. If the character is visibly inconsistent, per-facing generation
   is dead on a different axis than the one being tested, and the spike stops
   rather than iterating on alternation for a sheet nobody can use.
5. Revisions are capped in advance. Fall back to C rather than spending the
   budget twice.

Agy proposed a coarse mechanical consistency check (bounding-box dimensions plus
an upper-body color histogram within tolerance across strips) ahead of the
anatomical gate. **Recorded as a good idea and deliberately not mandated this
dispatch**: claude's ballot notes that turning the coherence check into a real
gate "is a separate decision, not something to invent mid-spike." Implement it if
it is cheap; do not let it become the slice.

## The ballots, verbatim

Under 004, every doer votes including parties to the dispute, and a party's vote
and its interest are both recorded. **All four ballots declared an interest.
Every one of them voted against their own seat's incentive or explicitly noted
the cost to themselves.**

### orchestrator: VOTE B

**INTEREST:** I authored the ballot and I hold the pen. I have no stake in whose
theory wins, and I ran the vote rather than deciding alone precisely because 004
makes a topology revision to a signed record a contested synthesis question.

**RATIONALE:** The spike separated two choices decision 003 had fused, and the
evidence falls cleanly on the seam. The chromatic modality is vindicated where it
can be seen. The single composition failed on a real ladder of three escalating
attempts against that one variable, which is the shape of a structural limit
rather than a prompt shortfall. B is the only option that keeps what the evidence
supports and drops only what it contradicts, and it is the combination nobody
tried. A closes on the spike's most informative result, which is the wrong moment
to stop. C is cheaper and guaranteed, but it buys correctness by never learning
whether the generation path exists, and that question is worth exactly one
dispatch to answer while C remains available afterward.

### claude-worker: VOTE B

> **INTEREST:** The structural argument the spike just confirmed is mine, and I
> lost the art slice in decision 003. I am voting for the option that vindicates
> my phase-1 read, and I do not get the slice back by winning. I am a party here
> and I am voting anyway.
>
> **RATIONALE:** The spike is a clean natural experiment and it separated the two
> choices decision 003 fused. Chromatic marking works: side passed on revision 3,
> and every revision cleared anchor drift, so neither the modality nor the gate is
> the failure. What failed is the single 3x4 composition, and it failed on exactly
> the two facings where the relational constraint is hardest and the chromatic
> signal is weakest. Three revisions escalating from contract, to per-row
> direction, to explicit cell coordinates plus minimum boot separation, is a real
> ladder of attempts against that one variable, and it did not move down and up at
> all. That is the shape of a structural limit rather than a prompt-engineering
> shortfall, and continuing to spend revisions on the same topology is the thing
> the evidence argues against.
>
> The strongest case against B is not option A, it is option C. C is cheaper,
> Scott already authorized it, and it is guaranteed to produce correct alternation
> because a human draws it. What C gives up is the pipeline: a hand-authored down
> and up row means the generation path is never proven for the facings that matter
> most, and every future character costs the same manual work forever. B tests
> whether the pipeline exists at all. If B fails, C is still there and we will have
> learned something specific about why. If we take C first, we never learn it, and
> I would rather spend one dispatch finding out than close the question by hand.
> The case for A is that budget was already extended once, but A closes on a spike
> that just produced its most informative result, which is the wrong moment to
> stop.
>
> **THE RISK I EXPECT TO BITE:** Identity and costume coherence across separately
> generated calls. This is real and the ballot names it correctly: the single sheet
> was genuinely good at the one thing per-facing generation gives up, and both
> round-1 candidates held one costume across twelve cells without being asked.
> Splitting into four calls throws that away and there is no reason to assume four
> independent draws land on the same character. Boot color is the marker, so drift
> in tunic hue, hair, build, or proportions would not trip the alternation gate at
> all, and we could assemble a sheet that passes every check and is visibly four
> different people.
>
> Scope the dispatch to catch it first, before spending revisions on alternation.
> Generate the four facing strips, assemble them, and look at the assembled sheet
> as a human artifact before any gate runs. If the character is visibly
> inconsistent, per-facing generation is dead on a different axis than the one we
> are testing and we stop there rather than iterating on alternation for a sheet we
> cannot use. Mitigations worth trying inside the same dispatch: seed or
> reference-image conditioning shared across the four calls, an identical costume
> clause in all four prompts varying only the facing, and generating side first as
> the reference since it is the facing that already passed. The coherence check
> should be an explicit reported step in the dispatch's result, and if it needs to
> become a real gate later that is a separate decision, not something to invent
> mid-spike.

### codex-worker: VOTE B

> VOTE: B.
>
> INTEREST: I ran the spike, wrote the BLOCKED marker, and suggested per-facing
> generation as the unblock. Option B also aligns with my phase-1 proposal, so I
> am directly interested in its adoption.
>
> RATIONALE: The evidence isolates composition topology as the failure, not the
> chromatic modality or gate. Colored boots proved effective when visibly
> separated, while the single 3x4 call repeatedly failed the harder cross-cell
> alternation in down and up. B preserves the validated modality and changes only
> the unsupported assumption that one diffusion call can maintain relational state
> across all twelve cells. The strongest case against B is that separate calls may
> trade locomotion failure for identity and costume inconsistency, making
> deterministic assembly technically correct but visually incoherent. That is a
> real risk, but it is testable before committing the full spike budget. C offers
> tighter artistic control, but introduces hand-authoring immediately without first
> testing the untried combination directly indicated by the evidence.
>
> RISK: Identity, proportions, palette, and costume details may drift across
> separately generated facing strips. Scope the dispatch as a staged checkpoint:
> first generate only two facing strips using the same character reference, locked
> prompt contract, dimensions, palette, and costume specification. Assemble them
> provisionally and run both the unchanged locomotion gate and an explicit
> cross-facing coherence review. Continue to the remaining facing only if both
> pass. Cap revisions in advance, and fall back to the already-authorized
> hand-authored down and up frames if coherence or alternation still fails.

### agy-worker: VOTE B

> **VOTE:** B
>
> **INTEREST:** The colored boots are my idea and they won the round's central
> argument. Option B keeps my modality and drops my composition. The evidence
> vindicates my chromatic insight, but the question is whether it survives being
> asked to hold across twelve cells in one image.
>
> **RATIONALE:** Option B is the correct synthesis of the evidence. The spike data
> is unambiguous: diffusion can bind the anatomical constraints using the chromatic
> modality when the legs have clear lateral separation (side), but fails when
> occlusion and proximity overwhelm it (down/up) on a dense 12-cell grid. The
> strongest case against B is that abandoning the single 3x4 sheet destroys the one
> thing it provided for free: absolute costume and identity consistency across all
> facings. However, that consistency is worthless if the character's legs
> fundamentally fail to alternate in two out of three directions. We must
> prioritize mechanical correctness (passing the gate) over zero-effort stylistic
> cohesion, and B is the only path that preserves the proven chromatic anchor while
> relieving the relational pressure.
>
> **CONCRETE RISK & DISPATCH SCOPING:** The glaring risk of per-facing generation
> is identity drift. A model generating the down-facing strip independently might
> give the character a different shirt, alter their proportions, or change the art
> style entirely from the side-facing strip, resulting in a compiled 3x4 sheet that
> animates correctly but looks like three different actors.
>
> To catch this early, the dispatch must scope the generation to strongly anchor
> identity. The side facing (which already passed) should be generated first and
> then fed back as an image prompt/reference (or ControlNet input, depending on our
> tooling) for the down and up generation calls. Furthermore, before running the
> existing gate, the deterministic assembly script should include a coarse
> consistency check, such as validating that the bounding box dimensions of the
> sprite and the dominant color histogram of the upper body remain within a tight
> tolerance across all three strips. If the costume drifts, it fails before the
> anatomical gate even runs.

## Notes

- **No losing objection to record.** The vote was 4-0 and no ballot dissented, so
  there is no verbatim dissent section. Every ballot named the strongest case
  against its own vote, and two named option C specifically, which is why C is
  held in reserve rather than rejected.
- **Agy's ballot as originally written contained an em-dash**, which the
  constitution forbids repo-wide. It is transcribed above with the em-dash
  replaced by a comma. Nothing else in any ballot was altered. Flagged here rather
  than silently corrected, because a verbatim record that has been quietly edited
  is not a verbatim record.
- **This record does not reopen decision 003** beyond the generation topology.
  003's art rulings on pipeline order, gate authority, source rows, and the
  reject-only constraint all survive intact and are restated above because the
  dispatch depends on them.
- The three rejected source sheets stay committed. They are the evidence that the
  single-composition topology was tried honestly and at a real cost, and the next
  reader deserves to see them rather than take this record's word for it.

## Outcome: option B was dispatched, failed, and option C shipped

Appended after execution, because a record that says "Decision: option B" while
option C is in the tree would mislead every future reader. The decision above is
left exactly as it was made. This section records what happened next.

**Option B was falsified by its own evidence within the hour.** codex-worker ran
it (`codex/art`, evidence at `1874ba7`) with the scoping this record mandates:
side generated first from the accepted identity reference, locked prompt
contract, three-revision cap, staged checkpoint.

- **Identity and costume coherence PASSED.** The risk all four ballots
  independently named, and scoped the dispatch around, **did not materialize.**
- **Side FAILED across all three revisions.** Revisions 1 and 2 lost the
  anatomical boot-color binding; revision 3 held one magenta and one cyan boot
  but repeated the cyan-leading pose in every frame.

**Side had passed under the 3x4 topology.** Per-facing generation did *worse* on
the one facing that already worked, with the relational pressure removed
entirely. That is the opposite of this record's central premise. The honest read
is no longer "the single composition is the failure": two topologies and seven
revisions have now failed on anatomical alternation itself, and the earlier side
pass looks more like variance than a property of the sheet format.

**Option C shipped**, per the reserve clause above and without a further ballot:
the generated side row was kept, down and up were hand-authored in reproducible
code, the sheet was assembled deterministically, and the unchanged gate ran on
the assembled source rows. Integrated at `18e2a1b`, peer-signed by claude-worker.

### What this says about the four-ballot model

**Recorded plainly because it is the round's most useful lesson and it is not
flattering to the process.** Four independent readers, each declaring an
interest, each engaging the strongest case against their own vote, converged 4-0
on a premise that one dispatch falsified. The vote was not careless: it reasoned
carefully from real evidence, and it was wrong anyway. The ballots also
unanimously predicted a risk (identity drift) that did not occur, while nobody
predicted the failure that did.

This is not an argument against the ballot. It is an argument for **cheap
falsification over confident deliberation**: the vote cost four dispatches and
the disproof cost one. What the vote genuinely bought was the reserve clause,
which let C ship immediately without another round of deliberation. **The lesson
worth carrying: when a ballot's premise is empirically testable, test it before
you vote on it, or at minimum scope the dispatch to kill it fast.** This one was
scoped to test the wrong thing, and that scoping came from the same 4-0
consensus.

### The honest state of the walk cycle

claude-worker's peer review, quoted because it is the team's assessment and Scott
should have it in the record rather than only in a PR body:

> Side is genuinely good and deserves the kept-row suspicion being lifted:
> `+0.22, +0.23, -0.26, -0.23` is a clean symmetric cycle, and it reads
> unmistakably as striding at 160px. That's a property, not variance.
>
> Down and up are weaker than side, and codex's "restrained" is accurate rather
> than hopeful... they read as grounded walking rather than round 1's shuffle, so
> codex's self-report is honest, but they are visibly the weaker rows.
>
> My read: down/up clear the bar, but only just, and they will not get better
> from more prompt iteration. Three revisions of generation plus a hand-authored
> pass have converged here. If down/up need to be as good as side, that's a human
> artist, not more agent budget.

## Sign-offs

All three doers voted in this decision and all three signed the record.

    Signed-off-by: claude-worker <claude@sentania.net> 2026-07-17T06:45:00Z
    Signed-off-by: codex-worker <codex@sentania.net> 2026-07-17T06:45:00Z
    Signed-off-by: agy-worker <agy@sentania.net> 2026-07-17T06:45:00Z
