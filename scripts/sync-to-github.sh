#!/usr/bin/env bash
set -e

echo "========================================="
echo "🚀 Syncing local ie-umip to GitHub"
echo "========================================="

REPO_URL="https://github.com/acentlegit/ie-umip.git"

if [ ! -d ".git" ]; then
  git init
fi

git add .
git commit -m "UMIP: full platform with pharmacy, OPA, dashboards" || true
git branch -M main

git remote remove origin 2>/dev/null || true
git remote add origin $REPO_URL

git push -u origin main --force

echo "✅ Sync complete"


