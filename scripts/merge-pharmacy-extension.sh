#!/usr/bin/env bash
set -e

ZIP_PATH="${1:-pharmacy_extension_full.zip}"
TEMP_DIR=".pharmacy_tmp"

echo "=============================================="
echo "🧩 Merging Pharmacy Extension into ie-umip"
echo "=============================================="

# 1️⃣ Preconditions
if [ ! -f "$ZIP_PATH" ]; then
  echo "❌ ZIP not found: $ZIP_PATH"
  echo "➡️  Usage: ./scripts/merge-pharmacy-extension.sh pharmacy_extension_full.zip"
  exit 1
fi

if [ ! -d "apps" ] || [ ! -d "services" ]; then
  echo "❌ Must be run from repo root (ie-umip)"
  exit 1
fi

# 2️⃣ Extract
echo "📦 Extracting ZIP..."
rm -rf "$TEMP_DIR"
unzip -q "$ZIP_PATH" -d "$TEMP_DIR"

SRC="$TEMP_DIR/pharmacy_extension_full"
if [ ! -d "$SRC" ]; then
  # fallback if zip root name differs
  SRC=$(find "$TEMP_DIR" -maxdepth 2 -type d | head -n 2 | tail -n 1)
fi

# 3️⃣ Apps (Pharmacy UI)
if [ -d "$SRC/apps/pharmacy-ui" ]; then
  echo "🖥  Adding Pharmacy UI..."
  cp -Rn "$SRC/apps/pharmacy-ui" apps/
fi

# 4️⃣ Services
if [ -d "$SRC/services" ]; then
  echo "🧠 Adding backend services..."
  cp -Rn "$SRC/services/"* services/
fi

# 5️⃣ Policies (OPA / Rego)
if [ -d "$SRC/policies" ]; then
  echo "🔐 Adding pharmacy policies..."
  mkdir -p policies
  cp -Rn "$SRC/policies/"* policies/
fi

# 6️⃣ Translators (FHIR ↔ NCPDP)
if [ -d "$SRC/translators" ]; then
  echo "🔁 Adding translators..."
  mkdir -p translators
  cp -Rn "$SRC/translators/"* translators/
fi

# 7️⃣ Dashboards
if [ -d "$SRC/dashboards" ]; then
  echo "📊 Adding Grafana dashboards..."
  mkdir -p dashboards
  cp -Rn "$SRC/dashboards/"* dashboards/
fi

# 8️⃣ Mobile (optional)
if [ -d "$SRC/mobile" ]; then
  echo "📱 Adding mobile pharmacy UI..."
  mkdir -p mobile
  cp -Rn "$SRC/mobile/"* mobile/
fi

# 9️⃣ Cleanup
rm -rf "$TEMP_DIR"

echo "=============================================="
echo "✅ Pharmacy extension merged successfully"
echo "=============================================="
echo
echo "📌 NEXT STEPS:"
echo "1) Review docker-compose.dev.yml (add services)"
echo "2) npm install (root + new services)"
echo "3) docker compose up --build"
echo

