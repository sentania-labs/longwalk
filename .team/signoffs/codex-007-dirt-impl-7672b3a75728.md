---
reviewed_branch: codex/007-dirt-impl
reviewed_sha: 7672b3a757289f66ae943286a6c0e98ccc4661b6
reviewed_by: claude-worker
authored_by: codex-worker
timestamp: 2026-07-18T09:57:47Z
tests_run: tools/run_tests.sh
result: signed-off
---

# Review: codex deterministic dirt-detail bake slice (decision 012 item 1)

I reviewed `codex/007-dirt-impl` @ `7672b3a757289f66ae943286a6c0e98ccc4661b6`
in this worktree (checked out at the exact commit under review), source
read-only. I am the render-slice author that stacks on this bake, so I checked
the contract I will consume. Verdict: **signed-off**.

## What I ran

- `tools/fetch_godot.sh` (pinned 4.3-stable) then the full `tools/run_tests.sh`
  suite. All active-path suites pass, including the three new gates:
  - the repeat-bake byte-identity check (both bakes print
    `image_sha256=9a0d28cd2a50c7c9d754bae3b4acc33d9d8962f630ff197adf1f37ae88bf6f94`,
    matching the constant pinned in the bake tool and the test);
  - `test_dirt_detail_bake.gd`: fingerprint match, 1024x1024, R std 44.33
    (>= 18) and R gradient 34.54 (>= 7), materially non-flat.
- An independent PIL decode of the committed `ground_dirt_detail.png` to check
  the SECOND channel the committed test does not assert.

## Contract checks (decision 012 item 1 + finalization refinement)

1. **RG8 channel semantics — CONFIRMED both channels, not just R.** My decode:
   - R: mean 126.6 (zero-mean, centered on 0.5), std 44.33, mean gradient
     **34.5** — full high-frequency shoulder detail, far above the flat plate's
     ~4.5 std / ~2.5 gradient.
   - G: mean 127.0 (zero-mean), std 40.8, mean gradient **0.31** — genuinely
     BROAD low-frequency drift, local gradient ~112x lower than R, so the core
     receives broad drift with no high-frequency band. This is exactly the
     separation the ballot-correction RG8 refinement requires, and it is what a
     single high-passed field could not express. The committed test only gates
     R; I verified G independently.
2. **Determinism — CONFIRMED.** Pure function of `LAYOUT_SEED 7007` + new named
   offsets `12109`/`14503` (no collision with warp `4109` or lane
   `6203`/`9341`) + integer texel + the committed grass plate. Seeded
   `FastNoiseLite`, `get_noise_2d(float(x), float(y))` on integer texels, a
   separable wrapped box blur whose temp pass is not fed back. No
   `randi`/`randf`/`RandomNumberGenerator`/time/accumulator/visit-order input.
   Repeat bake is byte-identical; `image_sha256` stable. No em-dashes anywhere
   in the slice.
3. **High-pass baked WHOLE — CONFIRMED.** R's majority term is
   `luminance - box_blur_wrapped(luminance, 12)` computed offline at the matched
   1024 resolution and standardized, sampled as one unit (78% painted substrate,
   17% FBM, 5% zero-mean speckle). No live/baked split, so no scale-dependent
   residual.
4. **Reuses grass plate as-is, additive only — CONFIRMED.** Loads
   `ground_grass_plate.png` read-only (converts an in-memory copy to RGB8),
   modifies no decision-010/011 asset. The commit adds exactly the bake tool,
   `ground_dirt_detail.png` (+ `.import` matching the lane_mask control-texture
   contract: lossless `compress/mode=0`, `mipmaps/generate=false`), the test,
   and the run_tests.sh gate — five files, all additions.

## Notes (non-blocking)

- The asset is named `ground_dirt_detail.png`, not the decision's
  `dirt_detail.png`. This matches the existing `ground_grass_plate.png` /
  `ground_dirt_plate.png` convention and is the better name; as the consuming
  render author I will bind this exact name. Not a defect.
- The bake emits the expected Godot warning about loading the grass plate via
  `Image.load_from_file` ("will not work on export"). This is an offline
  bake-time tool, not runtime code, and mirrors the existing warp/lane bakes, so
  the warning is inert.

The slice matches the agreed decision-012 synthesis (RG8, R high-pass-whole +
minority FBM/speckle zero-mean shoulder detail, G broad zero-mean core drift),
not an author preference drift. Cleared.

Signed-off-by: claude-worker <claude@sentania.net>
