#!/usr/bin/env bash
set -e

echo "========================================="
echo "🩺 UMIP Full Stack Health Check"
echo "========================================="

# ---------- helpers ----------
fail() {
  echo "❌ $1"
  exit 1
}

pass() {
  echo "✅ $1"
}

check_port() {
  local port=$1
  lsof -i :$port >/dev/null 2>&1 || fail "Port $port is not listening"
  pass "Port $port is listening"
}

check_http() {
  local name=$1
  local url=$2
  curl -sf "$url" >/dev/null || fail "$name not responding at $url"
  pass "$name responding"
}

check_container() {
  local name=$1
  docker ps --format '{{.Names}}' | grep -q "$name" || fail "Container $name is not running"
  pass "Container $name running"
}

# ---------- docker ----------
docker info >/dev/null 2>&1 || fail "Docker is not running"
pass "Docker is running"

# ---------- containers ----------
echo ""
echo "🔍 Checking containers..."
containers=(
  ie-umip-mongo
  ie-umip-redis
  ie-umip-intent-gateway
  ie-umip-doctor-ui
  ie-umip-patient-ui
  ie-umip-pharmacy-ui
  ie-umip-insurance-ui
  ie-umip-pharmacy-gateway
  ie-umip-ddi-engine
  ie-umip-grafana
)

for c in "${containers[@]}"; do
  check_container "$c"
done

# ---------- ports ----------
echo ""
echo "🔌 Checking ports..."
check_port 27017
check_port 6379
check_port 8080
check_port 3001
check_port 3002
check_port 3003
check_port 3004
check_port 8092
check_port 8093
check_port 3000

# ---------- http services ----------
echo ""
echo "🌐 Checking HTTP endpoints..."
check_http "Intent Gateway"      http://localhost:8080/health
check_http "Doctor UI"           http://localhost:3001
check_http "Patient UI"          http://localhost:3002
check_http "Pharmacy UI"         http://localhost:3003
check_http "Insurance UI"        http://localhost:3004
check_http "Pharmacy Gateway"    http://localhost:8093/health
check_http "DDI Engine"           http://localhost:8092/health
check_http "Grafana"              http://localhost:3000/login

# ---------- mongo ----------
echo ""
echo "🗄 Checking MongoDB..."
docker exec ie-umip-mongo mongosh --quiet --eval "db.adminCommand('ping')" >/dev/null \
  || fail "MongoDB not responding"
pass "MongoDB responding"

# ---------- redis ----------
echo ""
echo "⚡ Checking Redis..."
docker exec ie-umip-redis redis-cli ping | grep -q PONG \
  || fail "Redis not responding"
pass "Redis responding"

echo ""
echo "========================================="
echo "🎉 ALL SYSTEMS HEALTHY"
echo "========================================="

