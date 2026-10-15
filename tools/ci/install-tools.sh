#!/usr/bin/env bash
set -euo pipefail
# Install only missing CI tools into a writable, caller-owned directory.
destination="${RUNNER_TEMP:-/tmp/longwalk-ci-tools}/bin"
mkdir -p "$destination"
export PATH="$destination:$PATH"
if [ -n "${GITHUB_PATH:-}" ]; then echo "$destination" >> "$GITHUB_PATH"; fi
if ! command -v kind >/dev/null; then
  curl -fsSL https://kind.sigs.k8s.io/dl/v0.33.0/kind-linux-amd64 -o "$destination/kind"
  chmod +x "$destination/kind"
fi
if ! command -v helm >/dev/null; then
  curl -fsSL https://get.helm.sh/helm-v3.22.0-linux-amd64.tar.gz -o "$destination/helm.tar.gz"
  tar -xzf "$destination/helm.tar.gz" -C "$destination" linux-amd64/helm
  mv "$destination/linux-amd64/helm" "$destination/helm"
fi
if ! command -v actionlint >/dev/null; then
  curl -fsSL https://github.com/rhysd/actionlint/releases/download/v1.7.12/actionlint_1.7.12_linux_amd64.tar.gz -o "$destination/actionlint.tar.gz"
  tar -xzf "$destination/actionlint.tar.gz" -C "$destination" actionlint
fi
