#!/usr/bin/env bash
set -e

echo "🧠 Fixing React + Vite JSX runtime for all UIs..."

UI_APPS=(
  "apps/doctor-ui"
  "apps/patient-ui"
  "apps/insurance-ui"
  "apps/government-ui"
)

for app in "${UI_APPS[@]}"; do
  if [ ! -d "$app" ]; then
    echo "⚠️ Skipping missing $app"
    continue
  fi

  echo "🔧 Fixing $app"
  cd "$app"

  # Ensure package.json exists
  if [ ! -f package.json ]; then
    echo "❌ package.json missing in $app"
    exit 1
  fi

  # Force correct deps
  npm install --save \
    react@18 \
    react-dom@18

  npm install --save-dev \
    @vitejs/plugin-react \
    vite

  # Fix main.tsx (overwrite safely)
  mkdir -p src
  cat > src/main.tsx <<'EOF'
import React from "react";
import ReactDOM from "react-dom/client";
import App from "./App";

ReactDOM.createRoot(
  document.getElementById("root") as HTMLElement
).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
EOF

  # Fix vite.config.ts
  cat > vite.config.ts <<'EOF'
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  server: {
    port: Number(process.env.PORT) || 3000,
    host: true
  }
});
EOF

  cd - >/dev/null
done

echo "✅ React + Vite runtime fixed for all UIs"

