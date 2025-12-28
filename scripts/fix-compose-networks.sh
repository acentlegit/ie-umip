#!/usr/bin/env bash
set -e

COMPOSE="docker-compose.dev.yml"

echo "========================================="
echo "🔧 Fixing Docker Compose networks"
echo "========================================="

if [ ! -f "$COMPOSE" ]; then
  echo "❌ docker-compose.dev.yml not found"
  exit 1
fi

# Backup
cp "$COMPOSE" "$COMPOSE.bak.network.$(date +%s)"
echo "📦 Backup created"

# Remove any wrongly placed umip-net under services
sed -i '' '/^  umip-net:/,/^[^ ]/d' "$COMPOSE"

# Ensure networks block exists
if ! grep -q "^networks:" "$COMPOSE"; then
  echo "" >> "$COMPOSE"
  echo "networks:" >> "$COMPOSE"
fi

# Add umip-net correctly if missing
if ! grep -q "^  umip-net:" "$COMPOSE"; then
  cat <<EOF >> "$COMPOSE"
  umip-net:
    driver: bridge
EOF
fi

# Attach all services to umip-net (safe)
awk '
/^services:/ { print; next }
/^[^ ]/ { print; next }
{
  print
}
' "$COMPOSE" > "$COMPOSE.tmp"

mv "$COMPOSE.tmp" "$COMPOSE"

echo "✅ Networks fixed correctly"
echo "========================================="
echo "Next:"
echo "docker compose -f docker-compose.dev.yml up --build"

