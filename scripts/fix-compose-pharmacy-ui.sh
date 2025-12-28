#!/usr/bin/env bash
set -e

COMPOSE="docker-compose.dev.yml"

echo "========================================="
echo "🔧 Fixing docker-compose.dev.yml"
echo "========================================="

if [ ! -f "$COMPOSE" ]; then
  echo "❌ docker-compose.dev.yml not found"
  exit 1
fi

# Backup first
cp "$COMPOSE" "$COMPOSE.bak.$(date +%s)"
echo "📦 Backup created"

# Remove any invalid top-level pharmacy-ui block
sed -i '' '/^pharmacy-ui:/,/^[^ ]/d' "$COMPOSE"

# Insert pharmacy-ui UNDER services:
awk '
/^services:/ {
  print
  print "  pharmacy-ui:"
  print "    build: ./apps/pharmacy-ui"
  print "    container_name: ie-umip-pharmacy-ui"
  print "    depends_on:"
  print "      - intent-gateway"
  print "    environment:"
  print "      VITE_API_URL: http://intent-gateway:8080"
  print "    ports:"
  print "      - \"3003:3000\""
  print "    restart: unless-stopped"
  next
}
{ print }
' "$COMPOSE" > "$COMPOSE.tmp"

mv "$COMPOSE.tmp" "$COMPOSE"

echo "✅ docker-compose.dev.yml fixed"

echo "========================================="
echo "Next steps:"
echo "docker compose -f docker-compose.dev.yml up --build"

