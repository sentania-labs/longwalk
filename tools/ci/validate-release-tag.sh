#!/usr/bin/env bash
set -euo pipefail
: "${TAG:?release tag required}"
: "${GITHUB_SHA:?release commit required}"
[[ "$TAG" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]
# Checkout may replace its local annotated tag with the event's commit SHA.
# Fetch the authoritative remote object without changing that local tag.
git fetch --no-tags origin "refs/tags/$TAG"
test "$(git cat-file -t FETCH_HEAD)" = tag
test "$(git rev-parse 'FETCH_HEAD^{commit}')" = "$GITHUB_SHA"
git merge-base --is-ancestor "$GITHUB_SHA" origin/main
