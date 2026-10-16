#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
python3 tools/ci/test_release_tag.py
python3 -m py_compile prototypes/shared_village_07/tools/*.py
python3 prototypes/shared_village_07/test/test_package_permissions.py
node --check prototypes/shared_village_07/web/app.js
actionlint .github/workflows/admin07.yml
helm lint charts/longwalk
python3 prototypes/shared_village_07/tools/build_playtest.py --version "${RELEASE_VERSION:-development}" --export-only
timeout 120 prototypes/shared_village_07/build/linux/Longwalk-Shared-Village-07.x86_64 --headless --script res://test/exported_client.gd > prototypes/shared_village_07/build/exported-client.log 2>&1
cat prototypes/shared_village_07/build/exported-client.log
if grep -E 'SCRIPT ERROR:|^ERROR:' prototypes/shared_village_07/build/exported-client.log; then exit 1; fi
grep -q 'EXPORTED CLIENT CHECK PASSED:' prototypes/shared_village_07/build/exported-client.log
python3 prototypes/shared_village_07/tools/smoke_admin.py --client-executable prototypes/shared_village_07/build/linux/Longwalk-Shared-Village-07.x86_64
python3 prototypes/shared_village_07/server/prepare_context.py
docker build -t longwalk-admin07:smoke --label "org.opencontainers.image.revision=$(git rev-parse HEAD)" prototypes/shared_village_07/build/server-context
python3 prototypes/shared_village_07/tools/smoke_chart.py
mkdir -p prototypes/shared_village_07/artifacts/evidence
render_data="$(mktemp -d /tmp/longwalk-render-XXXXXX)"
trap 'rm -rf "$render_data"' EXIT
XDG_DATA_HOME="$render_data" timeout 180 xvfb-run -a prototypes/shared_village_07/build/linux/Longwalk-Shared-Village-07.x86_64 --audio-driver Dummy -- --capture-offline --capture="$(pwd)/prototypes/shared_village_07/artifacts/evidence/client.png" > prototypes/shared_village_07/build/render.log 2>&1
if grep -E 'SCRIPT ERROR:|^ERROR:' prototypes/shared_village_07/build/render.log; then exit 1; fi
test -s prototypes/shared_village_07/artifacts/evidence/client.png
