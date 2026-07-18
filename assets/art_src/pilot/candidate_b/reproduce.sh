#!/usr/bin/env bash
# Regenerate the Candidate B atlas + cottage sprite from committed inputs only.
# No network, no Meshy call: the restyled albedo PNGs under this directory are the
# frozen generative output (decision 009 constraint 7). This script re-renders the
# cleaned GLBs with those albedos, composites, assembles, and validates.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
cd "$repo_root"

blender_bin="tools/blender/blender-4.0.2-linux-x64/blender"
if [[ ! -x "$blender_bin" ]]; then
    echo "Blender is missing. Run tools/fetch_blender.sh before offline reproduction." >&2
    exit 1
fi

"$blender_bin" -b --python tools/art/render_candidate_b.py -- --production
python3 tools/art/treat_candidate_b.py
python3 tools/art/build_player_walk.py \
    assets/art_src/pilot/candidate_b/player_walk_manifest.json \
    --output assets/art_src/pilot/candidate_b/player_walk_atlas.png
python3 tools/art/check_scale_contract.py assets/art_src/pilot/candidate_b/player_scale.json
python3 tools/art/check_scale_contract.py assets/art_src/pilot/candidate_b/cottage_scale.json
python3 tools/art/check_walk_sheet.py assets/art_src/pilot/candidate_b/player_walk_atlas.png
