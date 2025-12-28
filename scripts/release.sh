#!/usr/bin/env bash
set -e

VERSION=$1

if [ -z "$VERSION" ]; then
  echo "Usage: ./scripts/release.sh v1.0.0"
  exit 1
fi

git checkout main
git pull

git commit --allow-empty -m "release: $VERSION"
git tag $VERSION
git push origin main --tags

echo "🚀 Released $VERSION"
