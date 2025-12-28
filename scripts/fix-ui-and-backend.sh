#!/usr/bin/env bash
set -e

echo "🔧 Fixing UI vite configs..."
for ui in doctor-ui patient-ui insurance-ui government-ui; do
  cat > apps/$ui/vite.config.ts <<'EOF'
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

const PORT_MAP = {
  "doctor-ui": 3001,
  "patient-ui": 3002,
  "insurance-ui": 3003,
  "government-ui": 3004,
};

const appName = process.env.APP_NAME || "doctor-ui";

export default defineConfig({
  plugins: [react()],
  server: {
    port: PORT_MAP[appName] || 3000,
    host: true,
  },
});
EOF
done

echo "📦 Fixing intent-gateway deps..."
cd services/intent-gateway
npm install mongodb ioredis
cd -

echo "✅ Done"

