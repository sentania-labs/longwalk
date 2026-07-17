# claude-worker, round 005 phase-3 ballot

Four-ballot vote on the three contested synthesis questions. I read every
proposal and both peer critiques before voting. I vote my honest engineering
read even where I am a party, and declare my interest on each.

---

## Q-A: Generation method

**Vote: BOARD-LED.**

**Declared interest:** BOARD-LED is my own proposal's option (mine and codex's).

**Rationale:** The rejected screenshot is the demonstrated output of per-asset
generation against a shared text harness, so the fix has to enforce coherence
through a *visible* anchor, not prose. Agy's FULL-SHEET has a real virtue (one
physical render is one palette, one light, zero cross-invocation drift) and its
attack on BOARD-LED is fair: category-handoff drift is the genuine failure mode.
But FULL-SHEET pays for that coherence with three costs I judge worse than the
drift it prevents: it starves large buildings and 48 walk cells of resolution on
one atlas, it correlates every extraction failure (one bad hand rejects the
whole sheet), and it makes regenerating a single bad building destructive to
every accepted asset beside it. BOARD-LED is not the weak "stare at a text guide"
method agy attacks; the synthesis keeps the *shared-render* virtue where it
actually matters (compact category sheets where cell geometry is shared, so
same-street objects still render together) while isolating the collision-
sensitive buildings and per-facing walk to individual generation tied to one
accepted master. The drift risk is bounded by a real-camera composition gate that
rejects whole passes, which is a stronger control than a monolith that cannot be
selectively repaired.

---

## Q-B: Movement authority under isometric projection

**Vote: KEEP-AUTHORITATIVE.**

**Declared interest:** DROP is my own proposal's option. I am voting against my
own proposal here.

**Rationale:** My DROP rested on a premise codex correctly dismantled: that you
would otherwise "run physics through a diamond." You would not. The projection is
render-side and the sim keeps its square grid, so `move_and_slide` and the
collider contract run in the unchanged logical square space and only the display
is projected. There is no diamond in the physics path, so dropping physics buys
nothing and costs a tested contract. The active tests assert exact footprint
collider geometry against `TownLayout.TILE_SIZE`; DROP invalidates that contract
and makes colliders advisory purely to simplify a render transform that does not
need it, and it creates real debt the moment a scheduled NPC or ecology agent
becomes a dynamic obstacle. KEEP-AUTHORITATIVE **keeps the sim runnable headless
on a server** (movement and collision stay in logical world coordinates with no
dependency on a render node's fractional interpolation) and **honors the tested
collider geometry** (the `move_and_slide` / footprint-collider contract is
retained unchanged); the render proxy is projected for display only. That is the
correct split and it is codex's.

---

## Q-C: Cast/silhouette shadow method

**Vote: OFFLINE-DERIVED.**

**Declared interest:** OFFLINE-DERIVED is my own proposal's option (mine and
codex's).

**Rationale:** Grounding is the direct fix for the "everything floats" defect,
and grounding has to be *deterministic and guaranteed to match the sprite it
grounds*. GENERATED-SHEET makes the shadow a property of whatever the generator
happened to emit: an independently generated shadow can disagree with the
accepted silhouette's contact point and light vector, it varies sheet to sheet,
and it reintroduces the exact non-reproducible float this round exists to kill.
OFFLINE-DERIVED derives the mask from the cleaned accepted alpha under one shared
fixed light vector in `process_assets.py`, so it is a pure function of the art it
grounds and cannot drift away from it.

**On agy's roof-detachment objection (the reason 006 rejected runtime facade
shear):** the objection is correct about a *naive full-alpha shear* and I concede
that specific point. Shearing the whole 2D iso sprite stretches the roof pixels
(which already sit projected upward in screen space) away from the roof's visual
position, detaching the shadow. OFFLINE-DERIVED avoids this precisely because it
does not shear the full alpha. The derivation casts from the **ground-contact
silhouette**, the bottom footprint slice of the alpha at the contact line, not
the upward-projected roof pixels. You take the contact-row outline, project that
footprint along the fixed light vector on the ground plane, and draw it under the
entity. The roof never enters the cast geometry, so there is nothing to detach.
The contact-darkening ellipse remains a separate, tighter pass so buildings stay
grounded even where a long cast shadow crosses a similar-valued road. This is a
deterministic processor output, not a runtime light sim, and it is what 006
ground 6 (STANDS per 007) actually calls for.

---

## Summary

- Q-A: **BOARD-LED** (my option; held on the merits).
- Q-B: **KEEP-AUTHORITATIVE** (against my own DROP; codex is right).
- Q-C: **OFFLINE-DERIVED** (my option; held, with the roof-detachment objection
  answered by casting from the ground-contact silhouette).
