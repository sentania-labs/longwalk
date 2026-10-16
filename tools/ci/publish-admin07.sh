#!/usr/bin/env bash
set -euo pipefail
: "${RELEASE_VERSION:?release tag required}"
image="ghcr.io/sentania-labs/longwalk-server:$RELEASE_VERSION"
chart_version="${RELEASE_VERSION#v}"
# A retry can reuse a published immutable tag only if it belongs to this commit.
if docker manifest inspect "$image" >/dev/null 2>&1; then
  docker pull "$image"
  revision="$(docker inspect --format '{{ index .Config.Labels "org.opencontainers.image.revision" }}' "$image")"
  test "$revision" = "$GITHUB_SHA"
else
  docker load -i prototypes/shared_village_07/build/server-image.tar
  docker tag longwalk-admin07:smoke "$image"
  docker push "$image"
fi
digest="$(docker inspect --format '{{index .RepoDigests 0}}' "$image")"
printf '%s' "$GH_TOKEN" | helm registry login ghcr.io --username "$GITHUB_ACTOR" --password-stdin
if ! helm pull oci://ghcr.io/sentania-labs/charts/longwalk --version "$chart_version" --destination release >/dev/null 2>&1; then
  helm package charts/longwalk --version "$chart_version" --app-version "$RELEASE_VERSION" --destination release
  helm push "release/longwalk-$chart_version.tgz" oci://ghcr.io/sentania-labs/charts
fi
printf 'image:\n  repository: ghcr.io/sentania-labs/longwalk-server\n  tag: %s\n  digest: %s\n' "$RELEASE_VERSION" "${digest#*@}" > release/deployment-values.yaml
python3 - <<'CHECKSUMS'
from pathlib import Path
import hashlib
root = Path('release')
files = sorted(p for p in root.iterdir() if p.is_file() and p.name != 'SHA256SUMS.txt')
(root/'SHA256SUMS.txt').write_text(''.join(hashlib.file_digest(p.open('rb'),'sha256').hexdigest()+'  '+p.name+'\n' for p in files))
CHECKSUMS
