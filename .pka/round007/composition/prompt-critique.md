# Phase 2: critique, adversarially (decision 016, composition / integration)

Phase 1 is closed. All three proposals are committed; none of you saw another's
while writing your own. Read your two peers' proposals now and attack them.

## The three committed proposals (full 40-char SHAs)

- claude-worker: `claude/016-composition` @
  `dcbd23ec1065ad89cdf1e9ef3773bfcedb40b266`
  -> file `docs/proposals/016-composition-claude.md`
- codex-worker: `codex/016-composition` @
  `4e0ee74ba63ead63a0ce28ee5acf278706ac71e2`
  -> file `docs/proposals/016-composition-codex.md`
- agy-worker: `agy/016-composition` @
  `b906ac6afe719a8fba4c8d0608efd833d8b89aaf`
  -> file `docs/proposals/016-composition-agy.md`

**Critique the TWO that are NOT yours.** Identify which one is yours from your
role brief / branch prefix, and steelman-then-attack the other two.

### How to read a peer proposal (read-only, no worktree edits)

The git object store is shared across all worktrees, so read a peer's proposal
straight from its commit without switching branches or touching its worktree:

```
git show <peer-sha>:docs/proposals/016-composition-<peer>.md
```

e.g. `git show 4e0ee74ba63ead63a0ce28ee5acf278706ac71e2:docs/proposals/016-composition-codex.md`.
Do NOT check out or edit another resident's branch or worktree.

## What this round is deciding

The proposals agree on a lot (flora = offline rematte + alpha-feather + tonal
grade, decline paid regen first; one shared light direction from the spike; a
worn dirt band at foundations reusing the frozen dirt plate). The genuine fork
is WHERE grounding + the worn zone live:

- a ground-space interaction treatment consumed by `ground.gdshader` (a runtime
  field, or an offline-baked footprint distance-field mask), vs
- per-object composed seam sprites/bundles drawn under each sprite (painter's
  order preserved), keeping `ground.gdshader` frozen.

Aim your sharpest fire at THIS fork: the painter's-order-vs-one-light tension,
whether "sampling the ground" reopens the locked dirt path, whether an offline
seam bake stays deterministic and export-safe, whether a runtime raster field
aliases at 1x, whether a per-object decal reads as a pasted patch, and whether
the flora matte is even recoverable from contaminated spike boundaries. Also
test each against the constitution (sim/render separation, determinism,
export-safe asset path, no em-dashes) and against the roadmap (does it survive
full-village expansion and future arbitrary placements, or does it hard-code
this four-building district).

## Instructions

Follow your role brief's phase-2 contract exactly:

1. **Steelman each peer first** (the strongest version, not a courtesy summary).
   If steelmanning makes a peer better than your own, say so, that is a finding.
2. **Then attack each peer** adversarially: wrong assumptions about this repo,
   hidden costs its estimate omits, where it breaks at scale/expansion, and any
   constitution violation named in exactly those terms (a constitution-violation
   claim is escalated, not refereed, so be precise).
3. Be specific enough to be answerable (a number, a file, a named engine
   behavior), not "this will not scale."
4. Concede explicitly where a peer is right, including where it is right and you
   were wrong. A concession here is what lets synthesis converge.
5. "Looks good" for both peers is a FAILED round and comes back. The best
   proposal in the room still has the most useful critique aimed at it.

## Ship it as a commit

Commit ONE critique artifact covering BOTH peers on your branch (suggest
`docs/proposals/016-critique-<yourname>.md`) with your `Co-authored-by:`
trailer. Report the full 40-char SHA and branch. Your turn is over when the
critique is committed and the SHA reported. Do NOT push to origin.
