#!/usr/bin/env bash
set -e

ZIP_FILE="ie_umip_missing_packages.zip"
TMP_DIR="/tmp/ie-umip-missing"
TARGET_DIR="$(pwd)"

echo "🔧 Merging missing packages into existing repo..."
echo "📦 ZIP: $ZIP_FILE"
echo "📂 Target: $TARGET_DIR"

if [ ! -f "$ZIP_FILE" ]; then
  echo "❌ ZIP file not found: $ZIP_FILE"
  exit 1
fi

# Clean temp dir
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

echo "📤 Extracting ZIP..."
unzip -q "$ZIP_FILE" -d "$TMP_DIR"

echo "📁 Copying packages/ (non-destructive)..."
rsync -av --ignore-existing \
  "$TMP_DIR/packages/" \
  "$TARGET_DIR/packages/"

echo "📁 Copying tests/ (non-destructive)..."
rsync -av --ignore-existing \
  "$TMP_DIR/tests/" \
  "$TARGET_DIR/tests/"

echo "🧹 Cleaning up temp files..."
rm -rf "$TMP_DIR"

echo "✅ Merge complete!"
echo "ℹ️ No existing files were overwritten."

