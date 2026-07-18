# Multimodal QA Pass 7: Dirt-Surface Fidelity vs Spike

**Verdict:** NOT-CONFUSABLE

## Resolved Items (Decision 014 Targets)

1. **Are the grey stones gone?** 
   Yes. The discrete painted grey stones are completely gone from the dirt paths. Confirmed across `ground-2x.png`, `ground-1x.png`, `ground-0.5x.png`, and all zooms of `village-inn-green`.
2. **Are amber/brown rocks gone?** 
   Yes. The prominent repeating brown rocks have been successfully removed.

## New Tells (Introduced by the Fill)

1. **Membrane-smooth / out-of-focus fill islands and browner tone:** 
   The orchestrator's suspicion is confirmed. Where the stones were removed, there are highly conspicuous soft, blurry blobs. These fill islands are distinctly lower resolution, lacking the crisp high-frequency speckle of the surrounding dusty dirt. They look as though they were painted over with a soft digital smudge tool. 
   Additionally, these patches introduce a darker, muddy brown tone that clashes with the dry tan dirt. 
   Visible at: 
   - `ground-2x.png` (center and lower sections)
   - `village-inn-green-2x.png` (path directly upper-right of the inn, and further down the paths)
   - Also visible at `1x` zooms in both ground and district captures.

2. **Tiling repetition / Grid seams:** 
   No new tiling or grid seams introduced.

3. **Shimmer at 0.5x:** 
   No new synthetic noise, though the blurry brown patches remain visible as dark smudges at 0.5x zoom.

## Regressions

- **Muddy Tone:** Localized regression. While the overall plate is dry tan, the new fill islands reintroduce small patches of dark, muddy brown.
- **Seams:** PASS (No regression).
- **Flat Core:** Localized regression. The dirt core is flat and soft specifically inside the new fill islands.
- **Retinted Grass:** PASS (No regression).
- **Shimmer / Synthetic Noise:** PASS (No regression).

## Remediation

- **Dominant remaining tell:** Membrane-smooth, out-of-focus fill islands. The spots where the stones were removed are blurry, brown smudges that lack the crisp dusty texture of the rest of the dirt. This distinctly clashes with the consistent sharpness of the hand-painted spike. Visible at 2x and 1x zoom on both raw ground and district scales (e.g., path upper-right of the inn in `village-inn-green-2x.png`).
