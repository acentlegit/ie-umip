#!/usr/bin/env bash
set -e

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

echo "🏗️  Running local build from repo root: $ROOT_DIR"

# 1️⃣ Validate expected monorepo layout
REQUIRED_DIRS=("apps" "packages" "scripts")

for d in "${REQUIRED_DIRS[@]}"; do
  if [ ! -d "$d" ]; then
    echo "❌ Required directory missing: $d"
    exit 1
  fi
done

# 2️⃣ Build shared packages first
echo "📦 Building shared packages..."
for pkg in packages/*; do
  if [ -f "$pkg/package.json" ]; then
    echo "➡️  $(basename "$pkg")"
    (cd "$pkg" && npm install)
  fi
done

# 3️⃣ Build UI apps
echo "🖥️  Building UI applications..."
for app in apps/*; do
  if [ -f "$app/package.json" ]; then
    echo "➡️  $(basename "$app")"
    (cd "$app" && npm install && npm run build)
  fi
done

echo "✅ Local build completed successfully"
