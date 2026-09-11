# Prototype status

The latest tested cut is shared_village_06, build b66cb8e51e26. shared_village_07 is unfinished admin work and is not a runnable replacement yet.

- Original 05: UDP 7777, volume longwalk-playtest_world-data.
- Separate 06 playtest: UDP 7778, volume longwalk-sprint06_world-data, copied and migration-verified from 05. Their later progress is independent.
- Local host at the last runtime check: 172.16.3.13. These addresses are environment-specific, not services a fresh clone creates.
- Temporary load/recovery containers and the kind test node were stopped with data retained.
- No live world saves, credentials, build caches or exported ZIP/image archives belong in this source backup. See SESSION-HANDOFF.md for local artifact and private recovery locations.
- A new machine can rebuild 06 using tools/fetch_godot.sh, tools/fetch_export_templates.sh and prototypes/shared_village_06/tools/build_playtest.py --server. Docker is needed for the server image build. Generated downloads must be rebuilt; report links refer to the original lab host.
- Main-project tracked .pka/.team/TEAM-STATE deletions predate the interactive prototype session. They are deliberately excluded from this backup commit.

Current plan: ROADMAP.md. Full session context: SESSION-HANDOFF.md. 07 work-in-progress notes: shared_village_07/SPRINT-STATE.md.
