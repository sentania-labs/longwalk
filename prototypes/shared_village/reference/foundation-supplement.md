# Foundation supplement, review proposal

Knowledge work, 2026-09-09. This records evidence and proposals for later incorporation, not a replacement constitution. The current finite authored map and headless simulation boundary in `CLAUDE.md` and `ARCHITECTURE.md` still govern. The standalone rotating-camera prototypes have not replaced the active starter-town project.

## Useful additions to the world bible

The foundation already captures history, ordinary lives, citizen NPCs, and simulation-owned facts. Its world bible contains headings rather than a specified world. These details from Scott's own messages make those principles more concrete:

| Topic | Confirmed direction | Still open |
| --- | --- | --- |
| A player's life | A lumberjack raising a family should be as rewarding to play as becoming a hero. Personal events can motivate long pursuits. [S3] | What makes an ordinary working session satisfying; family mechanics. |
| Skills | Broad skills develop through doing. Scott selected thoughtful practice, with difficulty and instruction relevant to learning. Tools matter; attempting tree cutting without a tool can hurt the character. [S2, S3] | Rates, ceilings, discovery, instruction, and protections against repetitive idle grinding. |
| A changing place | Trails can evolve, vegetation grows and is harvested, buildings can burn. Physical consequences should remain part of the world. [S2] | Recovery times, ownership, permissions, and how much destruction a shared world tolerates. |
| Citizens | Relationships grow from repeated shared experience. An innkeeper's daughter and a familiar visitor were the concrete example. [S4] | Relationship rules, player consent, simulation time, and which memories matter. |
| Magic | Magic exists, is secret and rare, and can be hated or revered. [S3] | Who can learn it, its costs, and whether early play exposes any. |
| Continuity | Death, old age, continuing as a child, and wills interest Scott. [S3] | These were explicitly uncertain. The foundation's legacy principle does not settle permanent death or mandatory succession. |
| Causality | Neighboring villages can affect each other through the same river. Scott gave poisoning as an example of consequences arising from conflict. [S3] | No river chemistry, diplomacy, war, or poisoning feature is authorized by that example. |

Additional direction from this working conversation:

- Skills may include obscure or playful accomplishments, inspired by DCC. Their presence need not mean each produces a combat advantage. This is a tone and breadth reference, not a requirement to import modern VHS or Nintendo objects into this setting.
- Running is a skill that affects speed and stamina cost. Stamina depends on constitution. Shift-click requests running now; the progression and attribute systems remain later gameplay work.
- Two Rivers imagery guides rural composition: a village with surrounding working countryside. Specific franchise places, lore, and names are not required.
- Two Rivers is one regional architectural palette, not the universal world style. Scott explicitly wants villages, towns, and cities to have different styles. Retain the existing tiled/slate-roof assets for reuse in other settlements and regions; the thatched village direction does not invalidate them.
- Scott wants Docker compatibility and personally targets Kubernetes for a future server. Planet scale remains an aspiration from conversation, not a reversal of the documented finite-map pivot.
- The currently approved playable village area is 1024 by 1024 metres, approximately one square kilometre (1.048576 square kilometres exactly). This sets the authored landscape boundary, not a population, concurrency, or simulation-fidelity target.

## Art and authoring guidance

Keep an asset inventory, consistent dimensions and materials, and verified footprints/navigation. Reusable terrain surfaces and building parts are useful. The exact tile or modular representation must serve the approved rotating camera; a fixed-view sprite sheet alone cannot supply unseen building sides.

The shared chat contains generated tile-sheet material and a prior assistant review calling it concept material with inconsistent cells and incomplete transitions. That review is a claim from the previous assistant, not a fresh inspection of the original sheets. Do not list those sheets as production-ready assets without opening and testing them. [S5]

Local inventory: `Longwalk_Foundation_v0.1/` contains 13 Markdown files and no images. The shared chat's three tile-sheet entries have no identified originals in this workspace. The inspected `tools/art/out/grass_ground_tile.png` and `ground_path_tile.png` are individual flat ground textures; `prototypes/village_lane/reference/terrain-atlas.png` contains three vertical material panels (grass, gravelly earth, leaf-litter soil). None is a village/object tile sheet or a complete terrain transition set. The cached Two Rivers previews are scene references. Character animation sheets also exist locally but do not fill the missing terrain/building sheet inventory.

The previous assistant's proposals for hundreds of assets, an autonomous civilization compiler, and additional specialist teams are not requirements. Preserve reproducible prompts and a small useful kit, then expand where the playable village demonstrates a need.

## Sources and evidence boundary

The original [shared conversation](https://chatgpt.com/share/6aa232c5-eba0-83ea-974c-7e2b98e01523) was reviewed from its cached message data. Stable message IDs below distinguish Scott's answers from assistant elaboration:

- S1, user `813046d8-13d9-402e-a885-5d41dcda3f91`: Two Rivers village and surrounding farms; roughly 10 km square imagery, with a closer 1 km square view suggested. This was an illustration request, not a tested simulation specification.
- S2, user `19690a77-3bd3-4ad9-bef1-f1f59aaff095`: persistent trails, growth, harvesting, fire, action-based skills and tool consequences.
- S3, user `556cb443-a91d-484e-802e-ee64c07fd93f`: ordinary lives, rare magic, uncertain succession, thoughtful practice, upstream consequences. Its Q3 and Q5 answers refer to assistant questions `0f3b0004-e17e-4909-9081-d3064f83642c`.
- S4, user `98dfa232-11b7-4ebe-a57c-fe92ca3d4fdb`: relationships through shared experience.
- S5, assistant `7b868933-2bd5-4aa5-919a-efcf065eaf19`: earlier tile-sheet assessment, not independently established technical readiness.
- Visual references supplied by Scott: [closer piece](https://chatgpt.com/s/m_6aa232a288408191a9dd7e986cb8fa1f), [regional piece](https://chatgpt.com/s/m_6aa232ba5fd48191af47b8e677554e8d).
- Local baseline reviewed: `Longwalk_Foundation_v0.1/` manifesto, commandments, bible template, team and agent briefs, foundry vision and simulation/AI note; `ARCHITECTURE.md`; `ROADMAP.md`; `prototypes/village_lane/ROADMAP.md`.

This document adds no settled answer for calendar speed, lifespan, permanent death, inheritance, PvP, global economy, population scale, or offscreen simulation fidelity.

## Bridge art direction from the village playtest

Scott considers the current bridges suitable for the prototype, but their visual character reads as city or large-town infrastructure rather than a village crossing. Keep the prototype bridges unchanged. Future rural bridge studies should explore simpler, more modest construction suited to the settlement; retain the current bridge style as a candidate for larger settlements. Specific materials and replacement designs remain undecided. This is art direction, not a prototype change request.
