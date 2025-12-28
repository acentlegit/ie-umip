#!/usr/bin/env bash
set -e

echo "=============================================="
echo "🔥 Fixing AllMerge UI + Intent Gateway (ONE SHOT)"
echo "=============================================="

ROOT_DIR="$(pwd)"

##############################################
# 1️⃣ Fix ALL UI Dockerfiles → Node 22
##############################################

fix_ui_dockerfile () {
  local dir="$1"
  echo "🔧 Fixing Dockerfile for $dir"

  cat > "$dir/Dockerfile" <<'EOF'
FROM node:22-alpine

WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm install

COPY . .

EXPOSE 3000
CMD ["npm", "run", "dev"]
EOF
}

for ui in apps/*-ui; do
  [ -d "$ui" ] && fix_ui_dockerfile "$ui"
done

##############################################
# 2️⃣ Fix ALL vite.config.ts (syntax + ports)
##############################################

fix_vite_config () {
  local dir="$1"
  echo "🧹 Fixing vite.config.ts for $dir"

  cat > "$dir/vite.config.ts" <<'EOF'
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  server: {
    port: Number(process.env.PORT) || 3000,
    host: true,
  },
});
EOF
}

for ui in apps/*-ui; do
  [ -f "$ui/vite.config.ts" ] && fix_vite_config "$ui"
done

##############################################
# 3️⃣ Fix intent-gateway deps
##############################################

IG="services/intent-gateway"

if [ -d "$IG" ]; then
  echo "📦 Fixing intent-gateway dependencies"

  cat > "$IG/package.json" <<'EOF'
{
  "name": "intent-gateway",
  "type": "module",
  "version": "1.0.0",
  "scripts": {
    "dev": "node src/index.js"
  },
  "dependencies": {
    "express": "^4.19.2",
    "mongodb": "^6.5.0",
    "ioredis": "^5.4.1",
    "jsonwebtoken": "^9.0.2"
  }
}
EOF

  cat > "$IG/Dockerfile" <<'EOF'
FROM node:22-alpine

WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm install

COPY . .

EXPOSE 8080
CMD ["npm", "run", "dev"]
EOF
fi

##############################################
# 4️⃣ HARD Docker Reset (REQUIRED)
##############################################

echo "🧨 Stopping containers + clearing cache"
docker compose -f docker-compose.dev.yml down -v || true
docker system prune -af

##############################################
# 5️⃣ Rebuild & Start
##############################################

echo "🚀 Rebuilding everything"
docker compose -f docker-compose.dev.yml up --build

echo ""
echo "✅ FIX COMPLETE"
echo ""
echo "Doctor UI    → http://localhost:3001"
echo "Patient UI   → http://localhost:3002"
echo "Insurance UI → http://localhost:3004"
echo "Intent API   → http://localhost:8080"
echo ""

