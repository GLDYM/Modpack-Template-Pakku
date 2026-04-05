#!/usr/bin/env bash
set -euo pipefail

RELEASE_TAG="${1:-}"

if [[ -z "$RELEASE_TAG" ]]; then
  echo "Usage: $0 <release-tag>"
  exit 1
fi

git fetch --tags origin >/dev/null 2>&1 || true

if git ls-remote --exit-code --tags origin "refs/tags/${RELEASE_TAG}" >/dev/null 2>&1; then
  echo "Tag ${RELEASE_TAG} already exists on origin."
else
  echo "Creating release tag ${RELEASE_TAG}"
  git tag "${RELEASE_TAG}"
  git push origin "${RELEASE_TAG}"
fi
