#!/usr/bin/env bash
set -e

ROOT_DIR="$(pwd)"
COMPOSE_FILE="docker-compose.dev.yml"
BACKUP_FILE="docker-compose.dev.yml.bak.$(date +%s)"

echo "=========================================="
echo "🚀 FINAL FIX — AllMerge / IE-UMIP"
echo "=========================================="

# --------------------------------------------------
# 0. Safety checks
# --------------------------------------------------
command -v docker >/dev/null || { echo "❌ Docker not installed"; exit 1; }
command -v docker-compose >/dev/null || true

if [ ! -f "$COMPOSE_FILE" ]; then
  echo "❌ $COMPOSE_FILE not found"
  exit 1
fi

cp "$COMPOSE_FILE" "$BACKUP_FILE"
echo "📦 Backup created: $BACKUP_FILE"

# --------------------------------------------------
# 1. Rewrite docker-compose.dev.yml (valid schema)
# --------------------------------------------------
cat > "$COMPOSE_FILE" <<'YAML'
services:
  mongo:
    image: mongo:7
    container_name: ie-umip-mongo
    ports:
      - "27017:27017"
    healthcheck:
      test: ["CMD", "mongosh", "--eval", "db.runCommand({ ping: 1 })"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped

  redis:
    image: redis:7
    container_name: ie-umip-redis
    command: ["redis-server", "--appendonly", "yes"]
    ports:
      - "6379:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 5
    restart: unless-stopped

  intent-gateway:
    build: ./services/intent-gateway
    container_name: ie-umip-intent-gateway
    depends_on:
      mongo:
        condition: service_healthy
      redis:
        condition: service_healthy
    environment:
      PORT: 8080
      MONGO_URL: mongodb://mongo:27017/umip
      REDIS_URL: redis://redis:6379
    ports:
      - "8080:8080"
    healthcheck:
      test: ["CMD", "wget", "-qO-", "http://localhost:8080/health"]
      interval: 10s
      timeout: 3s
      retries: 5
    restart: unless-stopped

  doctor-ui:
    build: ./apps/doctor-ui
    container_name: ie-umip-doctor-ui
    depends_on:
      intent-gateway:
        condition: service_healthy
    environment:
      VITE_API_URL: http://intent-gateway:8080
    ports:
      - "3001:3000"
    restart: unless-stopped

  patient-ui:
    build: ./apps/patient-ui
    container_name: ie-umip-patient-ui
    depends_on:
      intent-gateway:
        condition: service_healthy
    environment:
      VITE_API_URL: http://intent-gateway:8080
    ports:
      - "3002:3000"
    restart: unless-stopped

  insurance-ui:
    build: ./apps/insurance-ui
    container_name: ie-umip-insurance-ui
    depends_on:
      intent-gateway:
        condition: service_healthy
    environment:
      VITE_API_URL: http://intent-gateway:8080
    ports:
      - "3004:3000"
    restart: unless-stopped

  pharmacy-ui:
    build: ./apps/pharmacy-ui
    container_name: ie-umip-pharmacy-ui
    depends_on:
      intent-gateway:
        condition: service_healthy
    environment:
      VITE_API_URL: http://intent-gateway:8080
    ports:
      - "3003:3000"
    restart: unless-stopped

  opa:
    image: openpolicyagent/opa:0.63.0
    container_name: ie-umip-opa
    command:
      - "run"
      - "--server"
      - "--log-level=info"
      - "--set=decision_logs.console=true"
      - "/policies"
    volumes:
      - ./policies:/policies:ro
    ports:
      - "8181:8181"
    restart: unless-stopped

  grafana:
    image: grafana/grafana:10.4.1
    container_name: ie-umip-grafana
    ports:
      - "3000:3000"
    volumes:
      - ./grafana/provisioning:/etc/grafana/provisioning
      - ./grafana/dashboards:/var/lib/grafana/dashboards
    restart: unless-stopped
YAML

echo "✅ docker-compose.dev.yml rewritten (schema-valid)"

# --------------------------------------------------
# 2. Ensure Grafana provisioning exists
# --------------------------------------------------
mkdir -p grafana/provisioning/datasources
mkdir -p grafana/provisioning/dashboards

cat > grafana/provisioning/datasources/default.yaml <<'YAML'
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
YAML

cat > grafana/provisioning/dashboards/default.yaml <<'YAML'
apiVersion: 1
providers:
  - name: 'AllMerge Dashboards'
    folder: 'AllMerge'
    type: file
    options:
      path: /var/lib/grafana/dashboards
YAML

echo "✅ Grafana provisioning ready"

# --------------------------------------------------
# 3. Final instructions
# --------------------------------------------------
echo "=========================================="
echo "🎉 FINAL FIX COMPLETE"
echo "=========================================="
echo "Next steps:"
echo ""
echo "docker compose -f docker-compose.dev.yml down -v"
echo "docker compose -f docker-compose.dev.yml up --build"
echo ""
echo "Expected URLs:"
echo "• Intent Gateway  → http://localhost:8080"
echo "• Doctor UI       → http://localhost:3001"
echo "• Patient UI      → http://localhost:3002"
echo "• Pharmacy UI     → http://localhost:3003"
echo "• Insurance UI    → http://localhost:3004"
echo "• Grafana         → http://localhost:3000"
echo ""
echo "OPA → http://localhost:8181"
echo "=========================================="

