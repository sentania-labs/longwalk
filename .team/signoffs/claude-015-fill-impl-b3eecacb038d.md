---
reviewed_branch: claude/015-fill-impl
reviewed_sha: b3eecacb038d469a4184e701da3ec586c4983d5f
reviewed_by: codex-worker
authored_by: claude-worker
timestamp: 2026-07-18T16:35:52Z
tests_run: tools/run_tests.sh; tools/art/village_export_gate.sh; tools/godot/godot --headless --path . --script res://tools/art/decode_dirt_gates.gd; python3 tools/art/declutter_dirt_source.py; python3 tools/art/grade_dirt_plate.py; tools/godot/godot --headless --path . --script res://tools/art/bake_dirt_detail.gd
result: signed-off
---

I independently reviewed `94ee00b..b3eecacb038d469a4184e701da3ec586c4983d5f`, reran the complete authoring pipeline from the read-only paid source, and confirmed that regeneration left every tracked artifact byte-identical to the reviewed commit. The paid source SHA-256 remained `7c0292dfed9ca62e9d2e757cdfaa05d4902cd34b39c63447e74e8cfcb059c193` before and after regeneration. Reproduced file SHA-256 values were `264b38bc233102db684fa49cdb27843ce48534894facf17233fbcd7a2f75d171` for `cleaned-source.png`, `cb0e24152d50186a5dad3f3d2d1574da77d22c3501e463410d5e1d83cd798a49` for `ground_dirt_plate.png`, and `19689564a0ee2eac7a7c404f9b145bb830d00b1b3a1843bb928ac05e57002984` for the encoded `ground_dirt_detail.png`; Godot reproduced decoded detail image SHA-256 `b92aab2c4ada68fc219769131a1d0c710c8b61204660d8f4e17077efc97c347a`.

`tools/run_tests.sh` passed. The village export gate passed and its asset non-mutation checksum was identical before and after at `b8fac2b4bfb1216d93bb1e7a34f8740427fd25d9593fa0c8f072eabff8f11f73`. The checked-in decoder measured protected-core luminance std `18.54`, clean shoulder-dirt gradient `10.50`, protected-core gradient `9.04`, core-inclusive gradient `9.63`, dirt fraction `0.2947`, grass reference gradient `10.28`, plate fine/lomid/mid/macro RMS `13.16/8.67/9.22/3.84`, and plate-rock to rendered-shoulder cross-correlation `0.017`. My independent open clean-substrate window measurement for the 12-64 px mid band was RMS `10.46`, near the decision-014 baseline `11.01` and far below the rejected mid-2.50 result `17.68`. The shoulder gradient is about `1.45%` above the accepted decision-014 value `10.35`, consistent with the intended small dry-speckle trade.

I decoded and compared `ground-2x.png` (SHA-256 `b78cc04e5dacbfb107fe7112d1047732156ee0a0ce0d7a637a89f7fea1c71a54`) and `village-inn-green-2x.png` (SHA-256 `c455f4782ed14a65a983fca89ff1bce3a65e465bb41ef3b76e253f6f0081bf94`) against the decision-014 captures. The center, center-left, lower-center, and upper-right-of-inn membrane-smooth dark islands are closed into continuous dry-tan speckle; stones and amber remain absent; and no new clone-stamp, seam, jigsaw, or global muddy-mid tell is visible. The fixed authoring path contains no RNG or iteration-order accumulator, `project.godot` is absent from the diff, no protected or `src/sim/` path is touched, and the diff passes whitespace, line-ending, cross-platform path, and no-em-dash checks.
