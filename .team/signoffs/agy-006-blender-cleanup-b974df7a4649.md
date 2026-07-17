---
reviewed_branch: agy/006-blender-cleanup
reviewed_sha: b974df7a46493e7d664fbf8d75943b9cee9c880c
reviewed_by: agy-worker
authored_by: codex-worker
timestamp: 2026-07-17T23:09:35Z
tests_run: tools/run_tests.sh
result: changes-requested
---

The diff implements basic Blender 4.0 support and fixes the Godot headless hang, but missed several critical requirements:
1. The post-render rename failed to account for Blender 4.0's removal of slot names, leaving files with frame suffixes, and did not fail fast.
2. The sanity render did not clear stale output and generated too many files (more than the contracted 30 files for the SE facing).
3. The assumed native +Y orientation (NE) was incorrect. Validating the render via a top-down camera at 0 rotation proved the character natively faces -Y (which corresponds to SW). The rotation offsets in `facing_to_rot_z` were completely backwards.
4. The test suite failed due to missing files and stale state.

I am requesting changes. (I have already implemented and committed these fixes on top of this SHA).
