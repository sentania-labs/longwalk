<!--
GENERATED FILE, DO NOT EDIT.

Produced from CLAUDE.md by tools/generate_agents_md.sh. CLAUDE.md is the one
canonical source for this constitution. To change anything below, edit
CLAUDE.md and re-run:

    tools/generate_agents_md.sh

Hand edits here will be overwritten and are flagged by CI.
-->

# CLAUDE.md, longwalk

Role-neutral constitution for the longwalk project. Every resident of this
repo (human or agent, whatever role it is running under) must honor these
rules. This file is a summary. The full design writeup lives in
[ARCHITECTURE.md](ARCHITECTURE.md), and the milestone ladder lives in
[ROADMAP.md](ROADMAP.md).

`AGENTS.md` is generated from this file by `tools/generate_agents_md.sh`. Do
not edit `AGENTS.md` by hand: edit this file and re-run the generator.

## Role briefs are injected, never auto-loaded

This constitution is role-neutral on purpose. It says what is true for
everyone. It does not say what an orchestrator does, or what a worker does.

Role briefs are no longer carried in this repo. longwalk was the pilot the
shared team-framework was extracted from, and as of decision 020 it adopts
that framework's thin footprint: the briefs (`orchestrator.md`,
`claude-worker.md`, `codex-worker.md`, `agy-worker.md`, `critic.md`, and the
`phases/` templates) live in the framework install and are read from
`$TEAM_FRAMEWORK_DIR/roles/`.

`TEAM_FRAMEWORK_DIR` is exported by the framework's `bin/team-run` when it
spawns an orchestrator or a solo worker, so prefer the variable over a
hardcoded path. On this box the install is `~/foundry/tools/team-framework`.
The briefs are still never auto-loaded by any harness: the dispatcher injects
the relevant one at dispatch time, which `bin/team-run` handles (it passes
`--role-brief` through to `dispatch/dispatch.sh`, which appends it to the
harness system prompt).

This repo has no `roles/` directory today. If longwalk ever needs protocol
behavior that genuinely differs from the framework's (not just different
constitution content), the framework's "Forking a role brief" procedure
applies: copy that one brief into a local `roles/`, point the dispatch at the
local copy, and accept that it stops receiving framework fixes. `roles/`
remains listed in `.github/protected-paths.txt` precisely so a fork is
protected the day it lands rather than the day someone remembers to add it.

Two project facts the generalized framework briefs deliberately do not
hardcode, which apply here:

- Commit trailers use this project's domain, for example
  `Co-authored-by: Claude <claude@sentania.net>`, not the framework's
  placeholder `@team.local`.
- The repo slug for `gh` invocations is `sentania-labs/longwalk`.

If you are reading this file and no role brief was injected into your session,
you are a plain interactive session. Assume neither role. Do not act as the
orchestrator, and do not assume a worker's branch prefix or sign-off
obligations apply to you. Ask before taking action that a role brief would
otherwise govern.

## Project overview

longwalk is an isometric / top-down 2.5D persistent-world RPG built in Godot 4
(GDScript), in the visual spirit of Warcraft 2, SimCity, and Theme Hospital,
with an Ultima Online feel: the player is a person roaming a persistent world
and developing skills (hunting, boat-building, and similar). Windows is the
primary export target, but the project stays cross-platform-clean: no
Windows-only paths, no backslash path separators in code, no
platform-specific APIs, and no CRLF line-ending assumptions.

## Pivot notice (2026-07-15)

longwalk changed direction on 2026-07-15, away from a runtime procedural
planet-scale exploration game and toward a finite, authored map: possibly
generated once offline as a starting point, then hand-curated and frozen,
rather than derived live from a seed at runtime. The M1/M2 runtime procedural
generator and the walkable 3D world it streamed are parked, not deleted, under
`src/legacy_procedural/` (see that directory's README.md) and
`test/legacy_procedural/`. Nothing in those directories is wired into the
active project. Game art is AI-generated; see `tools/art/` for the generation
pipeline and prompts, not downloaded asset packs.

## Determinism (still load-bearing, now for the authoring path)

There is NO sequential or stateful RNG in any placement decision anywhere in
this codebase, including any offline map-authoring tool. If a draft map is
generated (in whole or in part) from a seed before being hand-curated, that
generation step must be a pure function of (seed, position): every value
sampled depends only on the world seed and the integer coordinates of the
cell, and generation or visit order can never change the result. This is no
longer a runtime requirement for the shipped game (the map is authored and
frozen, not regenerated on every play session), but it is what makes
regenerating or re-rolling a draft map for curation reproducible instead of a
one-off accident. The parked `src/legacy_procedural/macro_map.gd` demonstrates
the established pattern (seeded `FastNoiseLite` instances keyed off the world
seed, each layer at `world_seed + fixed_offset` so layers are decorrelated but
still fully determined by the one seed) and is the likely starting point if
this tooling gets built. Do not introduce `randi()`, `randf()`,
`RandomNumberGenerator` with an unseeded or time-based seed, or any
accumulator that depends on iteration order, anywhere generation logic is
reused or extended.

`test/legacy_procedural/test_determinism.gd` still asserts byte-identical
output for the parked generator; run it manually via
`tools/run_legacy_procedural_tests.sh` if you touch that code. It is not part
of the active CI gate (`tools/run_tests.sh`), since nothing in the active
project depends on it yet.

## World topology (parked, was a runtime requirement, may inform authoring)

The parked procedural world modeled a flat plane wrapped east-west
(cylindrical) with sphere-consistent polar crossings, so that a future flight
mechanic could cross a pole the way a real globe works, not a torus wrap. That
constraint no longer applies to the shipped game: the authored map is finite
and does not need to be a seamless cylinder. If the authoring tool reuses the
parked generator to produce a draft map, the cylindrical wrap logic in
`src/legacy_procedural/macro_map.gd` is still there and still correct, but the
final authored/curated map is not required to preserve wrap-seamlessness once
it is frozen and cropped to a finite play area.

## Ecology and fauna direction (future sim-layer scope, not designed yet)

The sim layer is growing toward an ecology system: flora regrows unless
overharvested, and fauna hunt, reproduce, and migrate, modeled all the way
down to something as small as a fish, each as a minimal agent. This is not
designed yet. It is recorded here so future dispatches (starting with NPC
schedules, which run as sim-layer ticks) build with this direction in mind.
See ROADMAP.md for how this supersedes the old M5 "fauna (deferred)" note.

## Persistence design (documented only, not implemented yet)

Three layers, described in full in ARCHITECTURE.md:

- (a) Authored baseline layer: the frozen, hand-curated map data (whatever its
  origin, hand-built or offline-generated-then-curated) ships as static game
  data. No runtime computation, no stored player state.
- (b) Delta / override layer: records only the cells where the world has
  changed from the authored baseline (for example the player dug a hole or
  chopped a tree). Everything not in this layer falls back to the baseline.
- (c) Entity layer: things that are not derivable from position at all
  (inventory items, saved characters, quest state).

Implementation of persistence is a later milestone. Do not implement it
before then.

## Simulation/rendering separation (hard rule)

The world simulation and generation core must be strictly separated from
rendering and input. Generation and simulation code lives in its own module
tree (`src/sim/`) and has zero dependencies on viewport, camera, or UI nodes.
It must be runnable headless.

Rationale: local saves are the current persistence model, but a lab-hosted
server backend (a continuous world simulation that clients connect to) is an
explicit planned evolution, targeted around the ecology/fauna milestone. This
separation is what makes lifting the simulation onto a server a move, not a
rewrite. NPC schedules (an upcoming dispatch) run as sim-layer ticks, so this
constraint matters more now than it did under the old procedural-world plan,
not less.

## Style rule: no em-dashes

Do not use em-dashes anywhere. Not in code comments, not in docs, not in commit
messages. Use commas, periods, parentheses, or a plain hyphen instead. This is a
hard rule across the whole repo.

## Workspace conventions

- The default branch is `main`. Every dispatch uses a feature branch plus a
  pull request. The one narrow exception, matching established precedent, is
  the `.review-passed` follow-up marker commit written immediately after a PR
  merges: it records the merge commit SHA (exactly one SHA, no trailing
  newline) and may be pushed straight to `main`.
- Branch prefixes are per-resident: the Claude resident branches under
  `claude/*`, the Codex resident branches under `codex/*`. A branch with no
  prefix is a plain human branch.
- Every commit an agent authors carries a `Co-authored-by:` trailer naming the
  resident that wrote it, so authorship survives squash merges.
- No self-merge and no self-approval. The resident that wrote a change never
  merges it and never signs off on it as its own reviewer. Merge authority
  belongs to the orchestrator.
- Before a PR opens, the other resident must review the diff in-worktree and
  write a pre-PR sign-off marker under `.team/signoffs/` (see that directory's
  README.md). No marker, no PR.
- A Codex review gate must pass before any PR merges.
- Changes touching protected paths (enumerated in
  `.github/protected-paths.txt`) must reference a `docs/decisions/NNN-*.md`
  record signed by both agents. See `docs/decisions/README.md`.
- Escalate to Scott rather than deciding as a team: engine changes,
  architecture changes, new dependencies, and edits to this constitution.
  Style, implementation detail, and refactors are the team's call.
- Escalations and steer messages route through `.pka/inbound/`, this
  project's mailbox. The framework's orchestrator brief says to route
  escalations through "whatever channel the human principal actually reads"
  without naming one; for longwalk that channel is `.pka/inbound/`. It
  predates the framework adoption and is the only inbound mailbox: do not
  create a second one. A steer message arriving there is authoritative
  mid-run.
- The seated roster, critic configuration, and pointers to the roadmap,
  protected-paths list, and mailbox live in `.team/team-config.yaml`, which
  the framework's `bin/team-run` checks before dispatching.
- CI is fork-gated per the sentania-labs standard: PR jobs run only for branches
  in this repo, never for forks. See `.github/workflows/ci.yml`.
- The Godot engine version is pinned in `tools/godot/VERSION`. Use
  `tools/fetch_godot.sh` to install it. Do not commit the binary.
- `TEAM-STATE.md` at repo root is the orchestrator's durable state file. It is
  read-and-updated machinery, not a human changelog.
