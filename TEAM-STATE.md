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

**Status:** active. Pilot run of the multi-harness team framework (build order
step 7). Phases 1, 2, and 3 are complete and signed. Implementation not started.

**Assignment (goal statement, verbatim as Scott gave it):**

> Bring motion to the starter town: player walk cycle at minimum, ambient town
> motion if cheap.

**Dispatched:** 2026-07-16T23:52:59Z. Phase 1 launched for real on the third
attempt, 2026-07-17T00:02:56Z.

**Lane:** `full protocol`. Directed by Scott, not left to orchestrator triage.
Recorded reasoning as directed: "full protocol: pilot run, design-level (three
viable animation approaches), Scott directed full protocol explicitly for this
assignment."

**Constraints (beyond the constitution):**

- Render-layer work. The sim/render separation applies in full: no
  simulation-side timing or state may leak into animation logic.
- Any new generated art assets follow the existing `tools/art/` pipeline
  conventions already in the repo.
- Nothing else beyond the constitution.

**Protected paths touched:** **none, now settled rather than forecast.** The
phase-0 forecast flagged `src/sim/town_layout.gd` as a live possibility (ambient
motion wanting authored anchors). It did not happen: both workers rejected that
move independently and unprompted, for the same reason, and the synthesis holds
them to it. Chimney position is a fact about a texture, not about a town.

Consequences, both confirmed rather than assumed: the consensus CI gate does not
apply to decision 001, and the critic seat was not auto-invoked at synthesis.

**Scope:** settled by `docs/decisions/001-town-motion.md`. The scoping fight
(generated sprite-sheet frames vs. procedural animation vs. hybrid) was resolved
by the workers, not from the referee seat. Summary, but read the record before
acting on this:

- Generated 3x4 sprite sheet wins the representation argument. Claude conceded
  the crux outright: a bob on a rigid billboard is not a walk cycle.
- The choice is gated behind a time-boxed art spike (Codex generates one sheet
  candidate, views it at game scale, one prompt revision allowed).
- If the spike fails, the fallback is Claude's procedural pose function, NOT
  Codex's three-strips path (strips reintroduce the identity drift that
  single-image generation existed to avoid).
- **If the fallback is taken, that is a Scott escalation, not a team call.**
  Shipping something both workers agree is not a walk cycle is a change to the
  assignment. This trigger is conditional and is NOT open today.
- Mechanics binding regardless of representation: drive from resolved motion not
  input; advance by per-tick displacement in `_physics_process()`; render-side
  state owns last-facing and appearance variant and must survive
  `set_appearance()` before tree entry; pin sheet cell height to 160 so
  `player.tscn`'s `offset = Vector2(0, -80)` stays correct by construction;
  animate the visual child only, never `CharacterBody2D.position`.
- Ambient: `CPUParticles2D`, single render offset per cottage keyed by
  `sprite_key`, no anchor table, no facade descriptor, grass shimmer cut, no
  determinism claim (smoke makes no placement decision). Ships independent of
  the spike.

## Phase

**Status:** `phase 3: synthesis` COMPLETE and signed. Next step is
`implementation` (dashboard phase enum: `execution`), not yet dispatched.

- Claude worker: branch `claude/town-motion`, worktree
  `/home/scott/claude/longwalk-worktrees/claude-town-motion`
- Codex worker: branch `codex/town-motion`, worktree
  `/home/scott/claude/longwalk-worktrees/codex-town-motion`

Both branches carry that worker's proposal and critique. Neither carries any
implementation. `main` carries the signed decision record.

**What the next run does:** dispatch implementation per the division of labor in
decision 001. The spike is the first thing and it gates the rest:

1. **Codex first, alone: the art spike.** Generate one 3x4 sheet candidate, view
   at game scale, call the gate. One prompt revision. Do not dispatch the
   controller work in parallel with this: the representation it selects
   determines what the controller is animating. This is the one place the
   pipeline is genuinely sequential.
2. **Then, in parallel:** Codex takes the sheet processing path plus the chimney
   smoke (smoke is independent of the spike outcome and can start immediately if
   worker slots allow). Claude takes the player controller/animator and the
   tests.
3. **Cross-slice dependency to watch,** flagged by Claude in its sign-off and
   worth carrying: Codex owns the sheet's per-cell sizing, Claude is bound to
   `player.tscn`'s `offset = -80`, and that offset is only correct if the cell
   height is pinned to 160. Item 8 of the record makes this explicit and gives
   the escape hatch (compute the offset if the height floats). It is a
   coordination point, not a defect, but it lives across the harness split.

Then: pre-PR peer sign-off under `.team/signoffs/` (each resident reviews the
OTHER's diff, no self-sign-off), PR, Codex review gate, orchestrator merges.

## Active decision record

**`docs/decisions/001-town-motion.md`, status accepted, signed by both.**

    Signed-off-by: claude-worker <claude@sentania.net> 2026-07-17T00:13:00Z
    Signed-off-by: codex-worker <codex@sentania.net> 2026-07-17T00:13:44Z

Commits: record `236dde3`, claude sign-off `7bd5311`, codex sign-off `282c521`.

Artifact SHAs the record cites (full 40 characters):

- Claude proposal: `00a717edb5f1d12d9f3a322ee0a680ed9868785d` on
  `claude/town-motion`, at `docs/proposals/claude-town-motion.md`.
- Codex proposal: `ad0a0b3c77c930b6a5ac3306dad2c20766319f95` on
  `codex/town-motion`, at `docs/proposals/codex-town-motion.md`.
- Claude critique: `6552e1df50434ab2a036db2181d71ba0a9c50573` on
  `claude/town-motion`, at `docs/proposals/claude-critique-codex.md`.
- Codex critique: `4ab315e37da0d44413b75009c01959d87952865d` on
  `codex/town-motion`, at `docs/proposals/codex-critique-claude.md`.

Next free decision number is `002`.

## Outstanding sign-offs

**Status:** none owed. Decision 001 is signed by both residents.

Nothing has been built yet, so no pre-PR peer sign-off is owed. When
implementation lands, each resident reviews the OTHER's diff and writes a marker
under `.team/signoffs/`. No marker, no PR.

## Open escalations to Scott

**Status:** none open.

**One conditional trigger is armed and the next run must not miss it:** if the
art spike fails and the team falls back to the procedural pose function, that
escalates to Scott before anything ships. Both workers agree a bob is not a walk
cycle, and the assignment named the walk cycle as the minimum, so shipping the
fallback silently would be redefining the assignment rather than delivering it.
Codex asked for exactly this acceptance in its critique and it was right to.

## Notes for the next run

**The dispatch wrapper exists. It is in the VAULT, not longwalk.**
`/home/scott/claude/vault/scripts/team/dispatch.sh`, with adapters for `claude`,
`codex`, `cursor` (the critic seat), and `agy` in
`/home/scott/claude/vault/scripts/team/adapters/`. Read
`/home/scott/claude/vault/scripts/team/README.md` before invoking.

This file previously asserted, twice, that the wrapper was never built. That was
wrong, and the error was mechanical: both runs looked for `scripts/team/`
relative to the longwalk checkout, did not find it, and concluded it did not
exist anywhere. It is harness-neutral by design and lives in the vault. The
correction came from Scott via the spectator steer channel
(`.pka/inbound/orchestrator/2026-07-17-0001-dalinar-steer-dispatch-mechanics.md`),
logged for the pilot retro as one informational steer.

Invocation form that worked, both workers in parallel, blocking:

    D=/home/scott/claude/vault/scripts/team/dispatch.sh
    "$D" claude <worktree> roles/claude-worker.md <prompt-file> \
      --cap-seconds 2400 --model opus --label <slug> &
    "$D" codex <worktree> roles/codex-worker.md <prompt-file> \
      --cap-seconds 2400 --label <slug> &
    wait

For a sign-off round against `main` itself, pass `--allow-primary` and run the
workers SEQUENTIALLY (the flag exists for exactly this; concurrent writes to one
checkout corrupt each other).

**A dispatch is synchronous. Block on it, in your own turn.** This is what
killed two runs, and it is worth stating plainly because the failure is silent
and it looks like success. Nothing an orchestrator launches survives its turn
ending. Both prior runs narrated a dispatch and exited 0 in a few minutes,
having launched nothing. `exit_code=0` on an orchestrator run says nothing about
whether any worker ran.

Blocking is nearly free: phase 1 took 143s (Claude) and 59s (Codex) in parallel,
phase 2 took 189s and 99s. The whole protocol from re-dispatch through both
sign-offs ran in about twelve minutes.

**Verify dispatches from the wrapper's end markers, never the exit code.** The
markers are the durable artifact the wrapper exists to produce. Read
`branch_sha_before` vs `branch_sha_after`, `branch_changed`, and
`uncommitted_work`. A worker can report success with real work sitting
uncommitted, and a cap-kill can land right after a good commit. Markers for this
assignment are in each worktree's `.team/markers/` and, for the sign-off round,
in `/home/scott/claude/longwalk/.team/markers/`.

**The critique round worked, and it is worth knowing what "worked" looked like,**
since a failed round is defined as both workers saying "looks good." Each worker
conceded the other's central point and still attacked hard. Claude conceded the
representation crux; Codex conceded that its input-driven animation would walk
against a wall. The most valuable single output was a correction to Claude's own
idea by Codex (per-tick displacement in the physics tick rather than
`get_real_velocity()` times a render delta), which is better than what either
proposed alone. Do not send a round back that looks like this one.

**The critic seat was not invoked and that was deliberate.** Neither trigger
fired: the round converged rather than deadlocking, and no protected path is
touched. The brief is explicit that routine synthesis stays two-voice and the
critic is not invoked because a decision feels weighty. The `cursor` adapter is
built and ready if a later round genuinely deadlocks.

**Still outstanding:** the Dashboard "Team" tab (build order step 5).

**Two known contract gaps against the dashboard's `POST /api/team` schema,** both
worked around in `roles/orchestrator.md` and both worth closing dashboard-side:
the schema has no `critic` author value (critic votes post as
`author: "orchestrator"`, `kind: "decision"`, identity folded into the body
text), and its phase enum has no `implementation` or `done` (folded into
`execution` and `review`, with the truth carried in `status_note`).

**2026-07-17T00:15Z: dashboard POST still not attempted this run, token is still
stale.** The 401 logged by the prior run
(`{"detail":"Invalid or missing X-Bridge-Token"}`) has not been fixed, and this
run did not fix it, for the same reason the prior run did not: `deploy.sh`
rotates the token on every deploy, so the recorded token in
`/home/scott/.claude/pka-secrets/dashboard-config.md` is stale, and rotating a
shared token that other services depend on is an outward change taken as a side
effect of narration. Narration is explicitly not allowed to block or bend the
protocol, and it is not allowed to reach outside the repo on its own initiative
either.

The fix needs Scott, or a run whose actual assignment is the dashboard: re-run
`deploy.sh` and update the secrets file with the new `BRIDGE_API_TOKEN`, or read
the live value from `/srv/services/dashboard/dashboard.env` on docker.int.

Per the brief: logged, not retried in a loop, and every phase proceeded. The
Team tab is stale for this entire assignment. The truth is in this file and in
`docs/decisions/001-town-motion.md`, both of which are complete and current.

---

**Last updated:** 2026-07-17T00:15Z (phases 1-3 complete, decision 001 signed by
both residents, implementation ready to dispatch)
