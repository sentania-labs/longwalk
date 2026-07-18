#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
cd "$repo_root"

blender_bin="tools/blender/blender-4.0.2-linux-x64/blender"
if [[ ! -x "$blender_bin" ]]; then
    echo "Blender is missing. Run tools/fetch_blender.sh before offline reproduction." >&2
    exit 1
fi

"$blender_bin" -b --python tools/art/blender_pose_rig.py -- --production
python3 tools/art/treat_candidate_a.py
python3 tools/art/build_player_walk.py \
    assets/art_src/pilot/candidate_a/player_walk_manifest.json \
    --output assets/art_src/pilot/candidate_a/player_walk_atlas.png
python3 tools/art/check_scale_contract.py assets/art_src/pilot/candidate_a/player_scale.json
python3 tools/art/check_scale_contract.py assets/art_src/pilot/candidate_a/cottage_scale.json
python3 tools/art/check_walk_sheet.py assets/art_src/pilot/candidate_a/player_walk_atlas.png
