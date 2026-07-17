# Claude ballot on decision 009 (round 006, phase 3)

Voting on the orchestrator's synthesis of the 3D-authored, 2D-delivered art
production path. I read the full draft at
`round/006-two-rivers:docs/decisions/009-3d-authored-2d-delivered-pipeline.md`.

## Q1 (fidelity-recovery mechanism): FOR the dual-candidate merge

FOR. This merge is the correct resolution and it resolves the exact tension my
proposal and codex's critique circled. My proposal argued painterliness is a
property of the 2D image generator and not recoverable from any clean 3D render,
so a generative stylization is load-bearing; codex argued a generative repaint is
a new generation boundary that can mutate landmark identity (roof pitch, window
count, foot contact, facing) and that per-frame repaint reintroduces boiling.
Both observations are true, and the honest move is not to pick a winner by
assertion but to render BOTH candidates from the same 3D scene and MEASURE them
under explicit rejection rules. Critically, the synthesis constrains candidate B
to exactly the two forms I already conceded during critique as boiling-safe
(texture-space mesh-albedo once, OR a single fixed-seed whole-sheet pass, never
per-frame), and it adds codex's provenance/freeze discipline plus the
gate-fails-if-A-misses-and-B-cannot-close condition that stops a failed B from
being laundered into a Path-3 success. That is a stronger design than either
original position alone. I accept it.

## Q2 (offline render tool): BLENDER

BLENDER headless as the single offline authoring + render source, Godot only for
shipping-renderer acceptance capture. This is the position I argued in my
critique against agy's Godot-sub-viewport bid, and the reasoning stands: the
2026-07-15 pivot deliberately parked all 3D out of the active Godot project into
`src/legacy_procedural/`. A Godot 3D sub-viewport renderer reintroduces live 3D
scenes into the shipped project, directly against that pivot and against the
sim/render separation the constitution treats as load-bearing. Blender keeps 3D
entirely offline in the authoring tier, which is where authored-and-frozen map
and asset data belong, and it makes the render spec fully pinnable (version,
camera, color management, engine, alpha, passes, explicit render command) in a
way a Godot sub-viewport tangled with the running game cannot match. The one cost
(a second offline tool) is real but is authoring-tier tooling, not a shipped
runtime dependency, so it does not widen the game's dependency surface.

## Overall: ADOPT

ADOPT decision 009 as written. Path 3 and the per-frame-repaint ban are converged
and correct; the two contested rulings are both the stronger synthesis. I accept
my division-of-labor slice: in-engine integration into `starter_town.gd` /
`player_controller_2d.gd`, camera + `building_contact_cell` anchor-contract
conformance, candidate B (texture-space / whole-sheet generative stylization)
design, and the "Instance base is null" fast-lane fix as an independent lane not
bundled into art-path evidence. The camera-calibration-first constraint (prove
agreement against `src/render/iso/projection.gd`'s 2:1 dimetric geometry rather
than asserting an angle) and the decision-008 Q-C shadow-MASK-stays-shipped
constraint are both corrections I raised in critique, and I am glad to own the
contract work that enforces them.

## Dissent

None.

Co-authored-by: Claude <claude@sentania.net>
