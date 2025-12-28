#!/usr/bin/env bash
set -e

echo "🛠 Fixing ALL UI apps (Vite + React)"

UI_APPS=(
  "apps/doctor-ui"
  "apps/patient-ui"
  "apps/insurance-ui"
  "apps/government-ui"
)

for APP in "${UI_APPS[@]}"; do
  echo ""
  echo "🔧 Fixing $APP"

  # ---------------------------
  # Ensure folders
  # ---------------------------
  mkdir -p "$APP/src"

  # ---------------------------
  # package.json
  # ---------------------------
  if [ ! -f "$APP/package.json" ]; then
    echo "📦 Creating package.json"
    cat > "$APP/package.json" <<EOF
{
  "name": "$(basename $APP)",
  "private": true,
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0"
  },
  "devDependencies": {
    "vite": "^5.0.0",
    "@vitejs/plugin-react": "^4.0.0",
    "typescript": "^5.0.0"
  }
}
EOF
  else
    echo "📦 Updating scripts in package.json"
    node - <<EOF
import fs from "fs";
const pkg = JSON.parse(fs.readFileSync("$APP/package.json"));
pkg.scripts = {
  dev: "vite",
  build: "vite build",
  preview: "vite preview"
};
fs.writeFileSync("$APP/package.json", JSON.stringify(pkg, null, 2));
EOF
  fi

  # ---------------------------
  # vite.config.ts
  # ---------------------------
  if [ ! -f "$APP/vite.config.ts" ]; then
    echo "⚙️ Creating vite.config.ts"
    cat > "$APP/vite.config.ts" <<EOF
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  server: {
    port: ${APP##*-ui} == "doctor-ui" ? 3001 : 3000
  }
});
EOF
  fi

  # ---------------------------
  # index.html
  # ---------------------------
  if [ ! -f "$APP/index.html" ]; then
    echo "🌐 Creating index.html"
    cat > "$APP/index.html" <<EOF
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <title>${APP##*/}</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
EOF
  fi

  # ---------------------------
  # src/main.tsx
  # ---------------------------
  if [ ! -f "$APP/src/main.tsx" ]; then
    echo "⚛️ Creating src/main.tsx"
    cat > "$APP/src/main.tsx" <<EOF
import React from "react";
import ReactDOM from "react-dom/client";
import App from "./App";

ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
EOF
  fi

done

echo ""
echo "✅ ALL UI apps fixed"
echo ""
echo "▶️ Next steps:"
echo "cd apps/doctor-ui && npm install && npm run dev"

