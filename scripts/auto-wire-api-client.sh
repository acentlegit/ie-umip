#!/usr/bin/env bash
set -e

UI_APPS=(
  "doctor-ui"
  "patient-ui"
  "insurance-ui"
  "government-ui"
  "compliance-portal"
)

API_CLIENT_PKG="@ie-umip/api-client"

echo "🔌 Auto-wiring shared api-client into all UIs..."

for APP in "${UI_APPS[@]}"; do
  APP_DIR="apps/$APP"
  SRC_DIR="$APP_DIR/src"
  API_DIR="$SRC_DIR/api"

  echo ""
  echo "➡️  Processing $APP..."

  if [ ! -d "$SRC_DIR" ]; then
    echo "⚠️  Skipping $APP (src not found)"
    continue
  fi

  # 1️⃣ Ensure api folder exists
  mkdir -p "$API_DIR"

  # 2️⃣ Create api/index.ts if missing
  if [ ! -f "$API_DIR/index.ts" ]; then
    cat > "$API_DIR/index.ts" <<EOF
export * from "@ie-umip/api-client";
EOF
    echo "✅ Created $API_DIR/index.ts"
  else
    echo "ℹ️  $API_DIR/index.ts already exists"
  fi

  # 3️⃣ Ensure api-client dependency exists
  PKG_JSON="$APP_DIR/package.json"
  if [ -f "$PKG_JSON" ]; then
    if ! grep -q "$API_CLIENT_PKG" "$PKG_JSON"; then
      echo "📦 Adding api-client dependency to $APP/package.json"
      node -e "
        const fs = require('fs');
        const pkg = JSON.parse(fs.readFileSync('$PKG_JSON'));
        pkg.dependencies = pkg.dependencies || {};
        pkg.dependencies['$API_CLIENT_PKG'] = 'workspace:*';
        fs.writeFileSync('$PKG_JSON', JSON.stringify(pkg, null, 2));
      "
    else
      echo "ℹ️  api-client already declared"
    fi
  else
    echo "⚠️  package.json not found for $APP"
  fi
done

echo ""
echo "✅ api-client wiring complete"
echo "ℹ️  You can now import APIs from src/api in each UI"

