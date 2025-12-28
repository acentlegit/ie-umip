#!/usr/bin/env bash
set -e

echo "🔧 Bootstrapping missing service manifests..."

SERVICES=(
  "services/intent-gateway"
  "apps/doctor-ui"
  "apps/patient-ui"
  "apps/insurance-ui"
  "apps/government-ui"
)

for DIR in "${SERVICES[@]}"; do
  if [ ! -d "$DIR" ]; then
    echo "❌ Missing folder: $DIR"
    continue
  fi

  if [ ! -f "$DIR/package.json" ]; then
    echo "📦 Creating package.json in $DIR"

    cat > "$DIR/package.json" <<EOF
{
  "name": "$(basename $DIR)",
  "private": true,
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "node src/index.js",
    "build": "echo build step",
    "start": "node src/index.js"
  },
  "dependencies": {}
}
EOF
  fi

  if [ ! -f "$DIR/Dockerfile" ]; then
    echo "🐳 Creating Dockerfile in $DIR"

    cat > "$DIR/Dockerfile" <<EOF
FROM node:18-alpine
WORKDIR /app
COPY package.json ./
RUN npm install
COPY . .
CMD ["npm", "run", "dev"]
EOF
  fi

done

echo "✅ Bootstrap complete"

