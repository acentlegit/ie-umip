#!/usr/bin/env bash
set -e

echo "========================================="
echo "🔧 AllMerge / IE-UMIP Dev Fix Script"
echo "========================================="

ROOT_DIR="$(pwd)"

########################################
# 1. Fix intent-gateway dependencies
########################################
echo "🧠 Fixing intent-gateway dependencies..."

cd services/intent-gateway

if [ ! -f package.json ]; then
  echo "❌ services/intent-gateway/package.json missing"
  exit 1
fi

npm install express mongodb redis --save

########################################
# 2. Fix UI dependencies (vite)
########################################
fix_ui () {
  UI_PATH=$1
  echo "🎨 Fixing UI: $UI_PATH"
  cd "$ROOT_DIR/$UI_PATH"

  if [ ! -f package.json ]; then
    echo "❌ $UI_PATH/package.json missing"
    exit 1
  fi

  npm install --save-dev vite @vitejs/plugin-react
}

fix_ui apps/doctor-ui
fix_ui apps/patient-ui
fix_ui apps/insurance-ui

########################################
# 3. Reset Docker completely
########################################
echo "🧹 Resetting Docker stack..."
cd "$ROOT_DIR"
docker compose -f docker-compose.dev.yml down -v

########################################
# 4. Build + Run
########################################
echo "🚀 Building and starting services..."
docker compose -f docker-compose.dev.yml up --build


