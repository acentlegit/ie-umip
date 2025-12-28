#!/usr/bin/env bash
set -e

echo "📌 Initializing Git"

git init
git add .
git commit -m "Initial import: UMIP full platform with pharmacy support"
git branch -M main

echo "🔗 Adding remote"
git remote add origin https://github.com/acentlegit/ie-umip.git

echo "🚀 Pushing to GitHub"
git push -u origin main

echo "✅ Done!"

