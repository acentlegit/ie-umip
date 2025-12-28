#!/usr/bin/env bash
set -e

echo "========================================="
echo "🔧 FIXING PHARMACY UI (one-shot)"
echo "========================================="

ROOT_DIR=$(pwd)
PHARMACY_DIR="apps/pharmacy-ui"

# -------------------------------
# 1️⃣ Verify pharmacy-ui exists
# -------------------------------
if [ ! -d "$PHARMACY_DIR" ]; then
  echo "❌ $PHARMACY_DIR not found"
  echo "➡️  Make sure pharmacy-ui code is merged correctly"
  exit 1
fi

echo "✅ Found $PHARMACY_DIR"

# -------------------------------
# 2️⃣ Fix Dockerfile
# -------------------------------
echo "🛠 Writing Dockerfile..."

cat > "$PHARMACY_DIR/Dockerfile" <<'EOF'
FROM node:22-alpine

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

EXPOSE 3000

CMD ["npm", "run", "dev"]
EOF

# -------------------------------
# 3️⃣ Fix vite.config.ts
# -------------------------------
echo "🛠 Writing vite.config.ts..."

cat > "$PHARMACY_DIR/vite.config.ts" <<'EOF'
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  server: {
    host: true,
    port: 3000,
  },
});
EOF

# -------------------------------
# 4️⃣ Ensure dev script exists
# -------------------------------
echo "🛠 Ensuring npm dev script..."

node <<'EOF'
const fs = require("fs");
const path = "apps/pharmacy-ui/package.json";

const pkg = JSON.parse(fs.readFileSync(path, "utf8"));
pkg.scripts = pkg.scripts || {};
pkg.scripts.dev = pkg.scripts.dev || "vite";

fs.writeFileSync(path, JSON.stringify(pkg, null, 2));
EOF

# -------------------------------
# 5️⃣ Patch docker-compose.dev.yml
# -------------------------------
echo "🛠 Patching docker-compose.dev.yml..."

COMPOSE="docker-compose.dev.yml"

if ! grep -q "pharmacy-ui:" "$COMPOSE"; then
  cat >> "$COMPOSE" <<'EOF'

  pharmacy-ui:
    build: ./apps/pharmacy-ui
    container_name: ie-umip-pharmacy-ui
    depends_on:
      - intent-gateway
    environment:
      VITE_API_URL: http://intent-gateway:8080
    ports:
      - "3003:3000"
    restart: unless-stopped
EOF
else
  echo "ℹ️ pharmacy-ui already present in compose file"
fi

# -------------------------------
# 6️⃣ Clean rebuild pharmacy-ui only
# -------------------------------
echo "🐳 Rebuilding Pharmacy UI container..."
docker compose -f docker-compose.dev.yml build pharmacy-ui

echo "========================================="
echo "✅ Pharmacy UI FIX COMPLETE"
echo "========================================="
echo ""
echo "Next steps:"
echo "1) docker compose -f docker-compose.dev.yml up"
echo "2) Open http://localhost:3003"
