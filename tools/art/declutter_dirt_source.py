#!/usr/bin/env python3
"""Deterministic source-level de-clutter for the round-007 dirt ground plate
(decision 014). Removes the discrete PAINTED debris (grey lozenge stones, the
stray amber rocks, dry grass tufts) from the paid regen source and fills the
vacated regions with the surrounding dusty-tan substrate, so the graded plate
reads as the spike's smooth dry dusty-tan path instead of a stone-littered one.

## Why source-level, not another luminance-band operator

Decision 013's de-peak follow-on (docs/art/village/dirt-depeak-013.md) PROVED by
rendered measurement that NO luminance-band winsorize/de-peak removes these
stones at any strength (including strengths that breach both hard gates): a
painted rock is coherent across every frequency band at once (body in mid, edge
in lomid, outline+specular in fine), so it is not a statistical outlier in any
single band and reassembles from the others when one band's tail is clamped. The
stones are PAINTED CONTENT in the source plate, so they must be removed at the
source (segment + fill), upstream of the multiband reshape in grade_dirt_plate.py.

CRUCIALLY, the dusty-tan substrate BETWEEN the stones is already spike-correct
(decision 014 dispatch, orchestrator-verified). So the method segments only the
debris and reconstructs each vacated region from the surrounding substrate,
preserving the accepted richness while killing the tell.

## Method

DETECTION (union of chroma detectors, then morphology):
  - grey stones: the warm tan substrate sits at saturation ~0.44-0.48; the grey
    stones are the desaturated tail (absolute sat < GREY_SAT_ABS) OR pixels that
    are markedly greyer than their own local dirt (local-sat deficit >
    GREY_SAT_DEFICIT). Saturation, NOT luminance, is the clean separator: the
    brown brush-stroke streaks in the substrate are DARK but still saturated, so
    a saturation gate keeps them (accepted richness) while catching true grey.
  - amber rocks: distinctly redder than tan (R-G > AMBER_RG) AND darker than the
    local field (a compact dark saturated blob), which the sat gate misses.
  - grass tufts: green (greenness > GRASS_GREEN), taken only where a solid core
    survives an erosion (isolated green substrate speckle is not a tuft), then
    dilated generously so the thin blades are covered too.
  The chroma seeds are closed (bridge a stone interior), opened (drop sub-blob
  substrate speckle) and dilated (cover each stone's soft cast-shadow halo).

FILL (smooth harmonic base + deterministic grain transplant), NOT cv2 inpaint:
  - base: a weighted image-pyramid pull-push solves a smooth membrane across each
    masked region whose values match the surrounding substrate EXACTLY at the
    mask boundary (Dirichlet), so there is no patch seam. A few Jacobi smoothing
    sweeps at full resolution erase any residual pyramid blockiness. Because the
    substrate under a stone is just smooth tan (no sharp content), this diffusion
    introduces no blur-smear tell: there is nothing sharp to smear.
  - grain: the base alone would read as a flat smudge and would drop the plate's
    protected-core richness. So the source's own fine speckle (the radius-GRAIN
    high-pass) is transplanted back over the base by a FIXED integer roll of the
    whole grain field. The roll lands each masked pixel on real dusty-dirt
    speckle from elsewhere in the SAME source; only the fine residual moves (no
    rock bodies, which live in the low band the membrane replaced), so there is
    no visible clone-stamp of structure and the fine-grain statistics (hence the
    core richness and the shimmer band) are preserved. Grain sampled from a
    masked source location is zeroed, so a stone's own speckle is never re-injected.

## Determinism (constitution)

Pure function of the committed source bytes. Every primitive is an
order-independent reduction: wrapped separable box blurs (kernel wrap only),
box-count morphology thresholds, fixed-count pull-push / Jacobi sweeps, and fixed
integer np.roll offsets. No randi/randf/RandomNumberGenerator, no time, no
visit-order accumulator. Re-running on the same source yields byte-identical
output.

This is a DEV tool under tools/art/ (never packed into the game asset path). It
never overwrites the .pka source; grade_dirt_plate.py imports `declutter` and
applies it in-memory as the pre-reshape step. Run standalone to emit the cleaned
source and a detection overlay for review:

    python3 tools/art/declutter_dirt_source.py
"""
from __future__ import annotations

import hashlib
from pathlib import Path

import numpy as np
from PIL import Image

REPO_ROOT = Path(__file__).resolve().parents[2]
SOURCE = REPO_ROOT / ".pka/round007/ground-source/dirt-regen-nbpro-019f74b2.png"
# Review artifacts (never consumed by the pipeline; committed as evidence).
CLEAN_OUT = REPO_ROOT / "docs/art/village/dirt-source-declutter/cleaned-source.png"
OVERLAY_OUT = REPO_ROOT / "docs/art/village/dirt-source-declutter/detection-overlay.png"

# --- detection thresholds (measured against the source, see module docstring) ---
GREY_SAT_ABS = 0.40       # absolute saturation below this reads as a grey stone
GREY_SAT_DEFICIT = 0.06   # OR this much less saturated than the local dirt field
LOCAL_RADIUS = 48         # local-field radius for the sat/luma background
AMBER_RG = 44.0           # R-G above this (redder than tan) ...
AMBER_DARK = -6.0         # ... and this much darker than local => amber rock
GRASS_GREEN = 11.0        # greenness (G - (R+B)/2) above this reads as a tuft
# morphology radii
STONE_CLOSE = 3           # bridge a stone interior
STONE_OPEN = 2            # drop sub-blob substrate speckle
STONE_HALO = 2            # cover the soft cast-shadow ring
GRASS_CORE_DILATE = 1
GRASS_CORE_ERODE = 2      # require a ~3px-solid green core (no isolated speckle)
GRASS_HALO = 4            # generous, so thin blades are covered

# --- structural rock detector (decision 014 synthesis: catch the amber/brown rock
# bodies the chroma classes under-catch). The amber/brown rocks are the SAME hue
# and saturation as the tan substrate (measured: rock R-G 21-44, sat 0.42-0.60;
# substrate R-G 33-44, sat 0.47-0.49), so chroma cannot separate them. What DOES
# separate them is that a painted rock is a COMPACT luminance blob (a lit cap over
# a dark cast-shadow rim) at the ~10-30 texel scale, whereas the substrate
# brushwork is smooth and extended. A bandpass (blur ROCK_BP_LO minus blur
# ROCK_BP_HI) responds to exactly that blob scale; its local RMS energy is a clean
# object detector: measured global p98 17.1 vs unmasked-rock scores 18-33, and an
# opening drops diffuse brush-edge response while keeping the compact rock blobs.
# This is the auto supplement the synthesis asked for; no hand-annotation list was
# needed because the bandpass-energy detector reaches every prominent survivor. ---
ROCK_BP_LO = 4            # bandpass low radius (below the rock cap scale)
ROCK_BP_HI = 20           # bandpass high radius (above the rock scale)
ROCK_ENERGY_RADIUS = 10   # RMS window for the blob energy
ROCK_SCORE = 12.0         # energy above this reads as a compact rock blob. A
                          # rendered-decode diagnostic (mask painted into the plate,
                          # re-rendered) showed the last render survivors are small
                          # rocks whose bandpass energy sits between 12 and 16;
                          # lowering the threshold to 12 catches them, and because
                          # the bandpass fires only on compact blobs (NOT on smooth
                          # dark brush) it is false-positive-safe: the clean-window
                          # FP is flat at 3.90% from ROCK_SCORE 16 down to 11.
ROCK_SPECK_ERODE = 1      # drop 1px energy specks (brush-edge noise) ...
ROCK_SPECK_DILATE = 1     # ... restoring the blob after the speck drop
ROCK_HALO = 2             # cover the rock's soft cast-shadow ring

# Cast-shadow grow. A painted rock has a dark cast-shadow ellipse that extends past
# its body; the chroma/structural classes catch the BODY but not the full shadow,
# so removing the body while leaving the shadow leaves a dark lozenge in the render
# (the exact "surviving rock body" the orchestrator decode still saw). So the mask
# is grown into locally-dark pixels ADJACENT to detected debris: bounded reach, so
# an isolated dark brush streak (not next to a rock) is never grown. Two passes
# reach the far edge of a big rock's shadow. contrast = lum - local(48) is already
# the local-field deficit; a shadow sits well below it.
SHADOW_DARK = -12.0       # local-contrast (lum - local mean) below this reads dark
SHADOW_REACH = 6          # how far the shadow may sit from the detected body
SHADOW_PASSES = 1        # grow iterations (reach the far shadow edge of big rocks)

# Fixed audit target set: the 20 most prominent rock blobs by bandpass energy
# (greedy non-max suppression, min separation 40px), picked ONCE from the source
# and frozen here. Detector-independent, so object-level recall over these is an
# honest completeness metric (not the circular "grey-pixel fraction"). Recall is
# reported by main(); the synthesis requires object-level recall be auditable.
AUDIT_TARGETS = (
    (444, 364), (56, 364), (1000, 624), (988, 352), (760, 184),
    (476, 928), (176, 736), (12, 348), (752, 300), (700, 940),
    (576, 56), (396, 12), (76, 664), (140, 900), (684, 604),
    (656, 644), (760, 244), (524, 548), (860, 836), (404, 192),
)
# Cleanest substrate window (lowest mean blob energy, 128x128), frozen from a
# scan; masked fraction here is the false-positive proxy (mask eating brushwork).
FP_WINDOW = (0, 480, 128)  # (y, x, size)

# --- fill parameters ---
PYRAMID_LEVELS = 8        # weighted pull-push depth (>= log2(hole span))
JACOBI_SWEEPS = 60        # full-res smoothing sweeps that erase pyramid blockiness
GRAIN_RADIUS = 16        # substrate-texture high-pass radius transplanted back
                          # (0-16px dusty speckle; refills the vacated richness
                          # without transplanting recognizable mid-scale structure)
# Fine-grain transplant offsets, a FIXED priority list. For each masked pixel the
# fill picks the first roll whose rolled SOURCE location is outside the debris mask
# (an explicit rolled validity mask, decision 015 / agy + codex). The primary roll
# supplies the speckle for almost every footprint pixel; a pixel only falls to the
# next roll where the primary roll's donor lands ON a removed stone (so a stone's
# own speckle is never re-injected). Selecting by donor VALIDITY, not by grain
# magnitude, is what removes the jigsaw discontinuity the decision-014 hole-fill
# carried: the old magnitude test misclassified genuinely flat-but-valid donors as
# holes and scattered a decorrelated second field through the footprint. Here a
# contiguous footprint draws from ONE roll except in the small sub-region whose
# primary donor is masked, so the two decorrelated fields meet along the pre-image
# of the debris mask (few, structure-aligned boundaries), not a speckle-magnitude
# jigsaw. Residual all-rolls-masked fraction is ~mask^len(rolls), negligible.
GRAIN_ROLLS = ((307, 461), (613, 137), (419, 157))  # fixed (dy, dx) priority list
FILL_STATS_RADIUS = 32    # local KNOWN-substrate window for the fill tone anchor
                          # (codex, decision 015): re-centers each footprint's
                          # interior DC on the surrounding real substrate mean, so
                          # the muddy local DC the membrane leaves is killed at the
                          # boundary rather than by a global tone shift.

# --- multiscale mid-band graft (decision 014 synthesis: kill the 16-64px
# membrane-smooth islands). The pull-push base supplies the low (>64) band and an
# exact boundary match; the GRAIN_RADIUS transplant supplies the fine (<16) band.
# The 16-64px band in between is smooth in the membrane, so a fill larger than
# ~16px reads as a flat smudge against the busy substrate. This grafts real
# 16-64px substrate STRUCTURE into the fill: the source's own mid band is taken
# from VERIFIED stone-free regions (the mask is pull-push-diffused OUT of the mid
# band first, so no rock body is in the donor field), then transplanted by a fixed
# integer roll and feathered to ZERO at the mask boundary (the membrane already
# matches there, so the graft must not disturb the boundary). Deterministic: fixed
# radii, fixed roll, fixed-depth pull-push, no RNG. ---
MID_LO = 16              # graft band low radius (matches GRAIN_RADIUS: no gap)
MID_HI = 64             # graft band high radius (matches the membrane low band)
MID_ROLL = (211, 373)   # fixed integer (dy, dx) mid-band transplant offset
MID_FEATHER = 3         # feather radius: graft weight 0 at boundary -> 1 interior.
                        # Kept small so the many 10-30px rock fills (eroded away by
                        # a larger feather, hence left flat) still receive the graft.
MID_GAIN = 1.20         # graft amplitude, ENERGY-MATCHED to the local substrate on
                        # the GRADED plate (decision 015). The decision-014 value 3.80
                        # over-injected the 16-64px band to ~1.85x the surrounding
                        # substrate's own mid energy (graded-plate mid std inside
                        # footprints 17.1 vs local-ring 9.3), and a rolled donor at
                        # that gain carries a nonzero LOCAL DC into the footprint:
                        # together those are exactly agy QA7's "membrane-smooth
                        # out-of-focus island + muddy-brown tone" tell (the graft meant
                        # to KILL flat islands became the island). The phase-1 proposal
                        # matched the graft at the SOURCE level (1.40, source mid 7.60
                        # vs ring 7.61), but the grade's lomid lift amplifies the
                        # graft's residual, so on the GRADED plate 1.40 left a +8%
                        # positive mid deficit (a mild over-graft the decision-015
                        # fill-island check forbids). Matching on the plate instead,
                        # 1.20 lands the graded footprint mid std at 1.03x the local
                        # ring (deficit +0.30, within measurement noise) with a +0.02
                        # tone delta, so a footprint is statistically indistinguishable
                        # from the dirt around it and there is no over-graft. The
                        # flat-core std the old over-graft propped up is carried instead
                        # by the GLOBAL grade lomid gain (grade_dirt_plate BAND_GAINS),
                        # which lifts every pixel uniformly and so introduces no
                        # localized island. See docs/proposals/claude-015-fill.md.


def _box_blur_wrapped(a: np.ndarray, radius: int) -> np.ndarray:
    """Separable wrapped box blur via a summed-area table (matches
    grade_dirt_plate.py::_box_blur_wrapped and bake_dirt_detail.gd to float
    precision). Pure function of the input and integer coordinates."""
    if radius <= 0:
        return a.copy()
    k = 2 * radius + 1
    pad = np.pad(a, ((radius, radius), (radius, radius)), mode="wrap")
    csum = np.cumsum(np.cumsum(pad, axis=0), axis=1)
    csum = np.pad(csum, ((1, 0), (1, 0)), mode="constant")
    h, w = a.shape
    y0 = np.arange(h)[:, None]
    x0 = np.arange(w)[None, :]
    total = (csum[y0 + k, x0 + k] - csum[y0, x0 + k]
             - csum[y0 + k, x0] + csum[y0, x0])
    return total / (k * k)


def _box_c(a: np.ndarray, radius: int) -> np.ndarray:
    """Per-channel wrapped box blur for an HxWxC array."""
    return np.stack([_box_blur_wrapped(a[..., c], radius) for c in range(a.shape[2])], axis=-1)


def _dilate(mask: np.ndarray, radius: int) -> np.ndarray:
    """Binary dilation: any 1 within the box. Order-independent (box-count)."""
    return _box_blur_wrapped(mask.astype(np.float64), radius) > 1e-9


def _erode(mask: np.ndarray, radius: int) -> np.ndarray:
    """Binary erosion: fully 1 within the box. Order-independent (box-count)."""
    return _box_blur_wrapped(mask.astype(np.float64), radius) > 1.0 - 1e-9


def detect(source: np.ndarray) -> np.ndarray:
    """Boolean debris mask: grey stones + amber rocks + grass tufts."""
    r, g, b = source[..., 0], source[..., 1], source[..., 2]
    lum = r * 0.2126 + g * 0.7152 + b * 0.0722
    greenness = g - 0.5 * (r + b)
    mx = source.max(axis=-1)
    mn = source.min(axis=-1)
    sat = np.where(mx > 0.0, (mx - mn) / mx, 0.0)

    local_lum = _box_blur_wrapped(lum, LOCAL_RADIUS)
    local_sat = _box_blur_wrapped(sat, LOCAL_RADIUS)
    contrast = lum - local_lum

    grey = (sat < GREY_SAT_ABS) | ((local_sat - sat) > GREY_SAT_DEFICIT)
    amber = ((r - g) > AMBER_RG) & (contrast < AMBER_DARK)
    grass = greenness > GRASS_GREEN

    stone_seed = grey | amber
    # close (bridge interior) -> open (drop speckle) -> dilate (shadow halo)
    stone = _dilate(stone_seed, STONE_CLOSE)
    stone = _erode(stone, STONE_CLOSE)
    stone = _erode(stone, STONE_OPEN)
    stone = _dilate(stone, STONE_OPEN)
    stone = _dilate(stone, STONE_HALO)

    # Structural rock class: compact bandpass-energy blobs (the amber/brown rocks
    # that share the substrate hue, so chroma misses them). Opening drops diffuse
    # brush-edge response; the halo covers the cast-shadow ring.
    rock = _rock_score(lum) > ROCK_SCORE
    rock = _dilate(_erode(rock, ROCK_SPECK_ERODE), ROCK_SPECK_DILATE)
    rock = _dilate(rock, ROCK_HALO)

    grass_core = _erode(_dilate(grass, GRASS_CORE_DILATE), GRASS_CORE_ERODE)
    grass_mask = _dilate(grass_core, GRASS_HALO)

    debris = stone | rock | grass_mask
    # Grow into the cast shadow: dark pixels adjacent to detected debris.
    dark = contrast < SHADOW_DARK
    for _ in range(SHADOW_PASSES):
        debris = debris | (dark & _dilate(debris, SHADOW_REACH))
    return debris


def _rock_score(lum: np.ndarray) -> np.ndarray:
    """Local RMS energy of a rock-scale bandpass: high on compact luminance blobs
    (rock cap + cast-shadow rim), low on smooth extended brushwork. Pure function
    of the input and integer coordinates (wrapped box blurs only)."""
    bp = _box_blur_wrapped(lum, ROCK_BP_LO) - _box_blur_wrapped(lum, ROCK_BP_HI)
    return np.sqrt(np.maximum(_box_blur_wrapped(bp * bp, ROCK_ENERGY_RADIUS), 0.0))


def _pull_push(img: np.ndarray, known: np.ndarray, levels: int = PYRAMID_LEVELS) -> np.ndarray:
    """Weighted image-pyramid pull-push: a smooth membrane over the unknown
    (masked) pixels that matches the known pixels at the boundary. `known` is the
    confidence (1 keep, 0 fill). Deterministic: fixed-depth weighted 2x2 pooling
    down, smooth (repeat + box1) prolongation up, confidence-blended."""
    w0 = known.astype(np.float64)
    pyr_c = [img * w0[..., None]]
    pyr_w = [w0]
    for _ in range(levels):
        c = pyr_c[-1]
        w = pyr_w[-1]
        if c.shape[0] < 2 or c.shape[1] < 2:
            break
        c2 = c[0::2, 0::2] + c[1::2, 0::2] + c[0::2, 1::2] + c[1::2, 1::2]
        w2 = w[0::2, 0::2] + w[1::2, 0::2] + w[0::2, 1::2] + w[1::2, 1::2]
        pyr_c.append(c2)
        pyr_w.append(w2)
    up = pyr_c[-1] / np.maximum(pyr_w[-1], 1e-9)[..., None]
    for lvl in range(len(pyr_c) - 2, -1, -1):
        c = pyr_c[lvl]
        w = pyr_w[lvl]
        val = c / np.maximum(w, 1e-9)[..., None]
        coarse = np.repeat(np.repeat(up, 2, axis=0), 2, axis=1)
        coarse = _box_c(coarse, 1)[:c.shape[0], :c.shape[1]]
        alpha = np.clip(w, 0.0, 1.0)[..., None]
        up = alpha * val + (1.0 - alpha) * coarse
    return up


def fill(source: np.ndarray, mask: np.ndarray) -> np.ndarray:
    """Reconstruct masked regions: smooth harmonic base, local-tone anchored to the
    surrounding known substrate, + a grafted stone-free 16-64px mid band (kills the
    membrane islands) + validity-masked transplanted fine grain."""
    known = ~mask
    base = _pull_push(source, known)
    # Jacobi smoothing sweeps (Dirichlet boundary = source), erase pyramid blockiness.
    m3 = mask[..., None]
    for _ in range(JACOBI_SWEEPS):
        base = np.where(m3, _box_c(base, 1), source)

    # Local-tone anchoring (codex, decision 015). The pull-push membrane matches the
    # boundary but its footprint interior can drift to a muddy DC (agy QA7's
    # "localized muddy-brown tone"). Re-center each masked interior on the mean of
    # the surrounding KNOWN substrate over a FILL_STATS_RADIUS window
    # (base + local_tone - box(base)) so the muddy DC is killed LOCALLY at the
    # boundary rather than by a global tone shift. local_tone is the box mean of the
    # source over known pixels only (masked pixels excluded from the average), so no
    # removed-stone tone leaks into the anchor. Pure box blurs => deterministic.
    known_f = known.astype(np.float64)
    known_weight = _box_blur_wrapped(known_f, FILL_STATS_RADIUS)
    local_tone = np.stack([
        _box_blur_wrapped(source[..., c] * known_f, FILL_STATS_RADIUS)
        / np.maximum(known_weight, 1e-9)
        for c in range(source.shape[2])
    ], axis=-1)
    base = base + local_tone - _box_c(base, FILL_STATS_RADIUS)

    # Multiscale graft: real 16-64px substrate structure from stone-free regions.
    # Build a donor mid band whose masked pixels are pull-push-diffused away (so no
    # rock body survives in the donor), transplant it by a fixed roll, and feather
    # it to zero at the mask boundary so the exact membrane boundary match holds.
    mid = _box_c(source, MID_LO) - _box_c(source, MID_HI)
    donor_mid = _pull_push(mid, known)  # stone-free continuous mid-structure field
    donor_mid = np.roll(np.roll(donor_mid, MID_ROLL[0], axis=0), MID_ROLL[1], axis=1)
    feather = _box_blur_wrapped(_erode(mask, MID_FEATHER).astype(np.float64), MID_FEATHER)
    graft = (MID_GAIN * feather)[..., None] * donor_mid

    # Transplant the source's own fine speckle back over the smooth base via an
    # explicit rolled VALIDITY mask (decision 015). For each masked pixel, pick the
    # first roll in GRAIN_ROLLS whose donor SOURCE location is outside the debris
    # mask, so a stone's own speckle is never re-injected and a genuinely flat
    # (but valid) donor is kept instead of being misread as a hole. Selecting by
    # donor validity, not grain magnitude, removes the decision-014 jigsaw: a
    # footprint draws its speckle from ONE roll except in the small sub-region whose
    # primary donor is masked. The fine residual (0-GRAIN_RADIUS band) carries no
    # rock body (those live in the low band the membrane replaced), so no visible
    # clone-stamp of structure; the fine statistics (core richness, shimmer) hold.
    detail = source - _box_c(source, GRAIN_RADIUS)
    grain = np.zeros_like(source)
    chosen = np.zeros(mask.shape, dtype=bool)
    for dy, dx in GRAIN_ROLLS:
        cand = np.roll(np.roll(detail, dy, axis=0), dx, axis=1)
        cand_valid = np.roll(np.roll(known, dy, axis=0), dx, axis=1)
        take = (~chosen) & cand_valid
        grain = np.where(take[..., None], cand, grain)
        chosen |= take
    filled = base + graft + grain
    return np.where(m3, filled, source)


def declutter(source: np.ndarray) -> np.ndarray:
    """Full de-clutter: detect debris, fill from substrate. Returns a float64 RGB
    array (unclipped) so the caller can grade before the final clip+round."""
    mask = detect(source)
    return fill(source, mask)


def main() -> int:
    source = np.asarray(Image.open(SOURCE).convert("RGB"), dtype=np.float64)
    mask = detect(source)
    cleaned = fill(source, mask)
    cleaned_u8 = np.clip(np.rint(cleaned), 0.0, 255.0).astype(np.uint8)

    CLEAN_OUT.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(cleaned_u8, "RGB").save(CLEAN_OUT)
    overlay = source.copy()
    overlay[mask] = [255.0, 0.0, 0.0]
    Image.fromarray(overlay.astype(np.uint8), "RGB").save(OVERLAY_OUT)

    def _core_std(a):
        lum = a[..., 0] * 0.2126 + a[..., 1] * 0.7152 + a[..., 2] * 0.0722
        return float(lum[384:640, 384:640].std())

    # Object-level recall over the frozen audit targets: a target is REMOVED if its
    # 5x5 center is masked. Detector-independent, so this is an honest completeness
    # measure (not the circular grey-pixel fraction). Also report the audit targets
    # the mask misses, so any survivor is named, not hidden in an aggregate.
    hits = []
    misses = []
    for (ty, tx) in AUDIT_TARGETS:
        covered = mask[ty - 2:ty + 3, tx - 2:tx + 3].any()
        (hits if covered else misses).append((ty, tx))
    recall = len(hits) / len(AUDIT_TARGETS)
    fy, fx, fs = FP_WINDOW
    fp = float(mask[fy:fy + fs, fx:fx + fs].mean()) * 100.0

    print(f"debris mask coverage {100.0 * mask.mean():.2f}%")
    print(f"object-level recall {len(hits)}/{len(AUDIT_TARGETS)} = {100.0 * recall:.0f}%"
          f"  (targets missed: {misses if misses else 'none'})")
    print(f"false-positive mask fraction in clean window {FP_WINDOW}: {fp:.2f}%")
    print(f"source center-256 lum std {_core_std(source):.2f} -> cleaned {_core_std(cleaned):.2f}")
    print(f"cleaned sha256 {hashlib.sha256(CLEAN_OUT.read_bytes()).hexdigest()}")
    print(f"wrote {CLEAN_OUT.relative_to(REPO_ROOT)}")
    print(f"wrote {OVERLAY_OUT.relative_to(REPO_ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
