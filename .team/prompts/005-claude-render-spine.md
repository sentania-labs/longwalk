# Round 005 implementation slice: render spine (claude-worker)

This is phase-3 IMPLEMENTATION of round 005. Deliberation is closed. Your
authority is **`docs/decisions/008-isometric-visual-identity.md`** on this
branch, signed 4-0. Read it in full before you write code. Do not relitigate
anything it settled; implement it.

You are on branch `claude/005-render-spine`, cut from the round branch
`round/005-isometric-art` at `43459d4`. Commit your slice here. Do not push, do
not open a PR (doers never open PRs, per decision 004). Report your final commit
SHA in your output.

## Your slice, and only your slice

Per decision 008's division of labor, you own the **render spine**. Nothing
else. codex owns art generation + the art pipeline; agy owns the camera drag-pan
rework. Keep their work out of your diff.

Deliverables:

1. **Iso projection module under `src/render/...`** (render-only; a new module,
   e.g. `src/render/iso/projection.gd` or similar). Pure functions:
   `cell_to_screen(cell)`, `screen_to_cell(screen)`, and `projected_bounds()`
   computed from the four projected diamond corners of the walkable area plus
   sprite headroom (NOT from `_layout.pixel_size()` as an axis-aligned rect: the
   walkable diamond does not inscribe that rectangle under iso). This is the
   critique's camera-bounds catch, verbatim. No projection symbol or screen
   coordinate may leak into `src/sim/`.
2. **Footprint-aware y-sort + stable placement-id tie key.** Ground diamonds in a
   non-y-sorted base layer; one y-sorted world-object layer for
   player/flora/buildings, each anchored at ground-contact, sorted on projected
   contact Y with a STABLE placement-id secondary key, and a footprint-aware
   occlusion contract for multi-cell buildings. Bare `y_sort_enabled` on a single
   front anchor mis-sorts a tall/multi-cell building; harden it. Test the actor
   at every footprint edge.
3. **KEEP-AUTHORITATIVE movement (decision 008 Q-B, 4-0).** Movement and
   collision stay authoritative in the existing logical square world space:
   retain `move_and_slide` and the tested footprint-collider contract UNCHANGED.
   The render layer projects a display proxy. Inverse projection is used only at
   the input boundary. Do NOT drop `move_and_slide` (that was your own proposal's
   position and you voted it down yourself; honor the ballot).
4. **`starter_town.gd` render rework** to draw through the projection spine
   (ground diamonds + y-sorted world-object layer).
5. **`capture_player_walk.gd` acceptance-capture retarget** for iso. Fold in the
   round-004 P2 capture-tool node-path fix: it calls
   `player.get_node("Camera2D")` but the camera moved to `World/CameraRig2D` in
   round 004, so that path is stale. Fix it as part of this retarget.

Sim is untouched. Any change under `src/sim/` is the wrong slice by construction
(decision 007 + 008): all iso math is render-side, the sim stays square-grid and
projection-ignorant. If you find yourself editing `src/sim/`, stop.

## Freeze two contracts (this is why you go first)

Your slice is dispatched FIRST specifically because two other slices depend on
interfaces you define. Make them explicit and stable, not implicit in your code:

- **projection <-> camera contract** (consumed by agy): `projected_bounds()` and
  `screen_to_cell()`. agy's rig will clamp to `projected_bounds()` and picture
  input through `screen_to_cell()`. Give these clear, documented signatures and
  return types, and write a short contract note (a header comment block on the
  module, or a brief `docs/` note) stating exactly what they return and their
  coordinate conventions, so agy implements against a frozen surface.
- **manifest/anchor contract** (consumed by codex): the ground-contact anchor
  convention your y-sort and placement expect from generated sprites (where the
  contact point sits in a cell, how per-cell ground-contact anchors are
  expressed). codex generates against this. State it explicitly in your contract
  note.

Do not implement agy's or codex's slice. Just freeze the surfaces they consume.

## Gates

- `tools/run_tests.sh` must pass on your branch before you report done. If you
  change render behavior that existing tests assert, update the tests to the new
  contract (do not weaken an assertion to make it pass; the footprint-collider
  geometry tests in particular must still hold, per Q-B).
- No em-dashes anywhere, including commit messages (constitution, absolute).
- Determinism and sim/render separation hold (constitution). Any flora phase
  animation you touch stays a deterministic function of placement id, no RNG, no
  time seed.
- Every commit carries `Co-authored-by: Claude <claude@sentania.net>`.

## Blocked

If genuinely blocked (a contract you cannot resolve by reading the repo and
decision 008), write a BLOCKED marker on THIS branch per `.team/blocked/README.md`,
commit and push it, and report branch + marker path + one sentence in your
output. The bar is high: work that is merely large gets scoped down and shipped
smaller with a note on what you cut, not blocked.

Do not end your turn on an intention. Your durable artifact is the commit.
