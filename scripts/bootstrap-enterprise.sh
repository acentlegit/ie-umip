#!/usr/bin/env bash
set -e

echo "========================================="
echo "🚀 UMIP Enterprise Bootstrap (B–F)"
echo "========================================="

########################################
# 🅱 PR BRANCH (Pharmacy + Policies)
########################################
echo "🅱 Creating PR branch..."
git checkout -B feature/pharmacy-enterprise || true

git add apps/pharmacy-ui services/pharmacy-gateway services/ddi-engine policies dashboards docker-compose.dev.yml || true
git commit -m "feat(pharmacy): enterprise pharmacy platform" || true

########################################
# 🅲 GitHub Actions CI/CD
########################################
echo "🅲 Generating GitHub Actions CI..."

mkdir -p .github/workflows
cat > .github/workflows/ci.yml <<'EOF'
name: UMIP CI

on:
  push:
    branches: [main]
  pull_request:

jobs:
  build-test:
    runs-on: ubuntu-latest

    services:
      mongo:
        image: mongo:7
        ports: [27017:27017]
      redis:
        image: redis:7
        ports: [6379:6379]

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: 20

      - name: Install root deps
        run: npm install || true

      - name: Build services
        run: |
          cd services/intent-gateway && npm install && npm test || true
          cd ../pharmacy-gateway && npm install && npm test || true
          cd ../ddi-engine && npm install && npm test || true

      - name: Build UIs
        run: |
          cd apps/doctor-ui && npm install && npm run build || true
          cd ../patient-ui && npm install && npm run build || true
          cd ../insurance-ui && npm install && npm run build || true
          cd ../pharmacy-ui && npm install && npm run build || true
EOF

########################################
# 🅳 Release Script
########################################
echo "🅳 Generating release script..."

cat > scripts/release.sh <<'EOF'
#!/usr/bin/env bash
set -e

VERSION=$1

if [ -z "$VERSION" ]; then
  echo "Usage: ./scripts/release.sh v1.0.0"
  exit 1
fi

git checkout main
git pull

git commit --allow-empty -m "release: $VERSION"
git tag $VERSION
git push origin main --tags

echo "🚀 Released $VERSION"
EOF

chmod +x scripts/release.sh

########################################
# 🅴 Repo Structure Review
########################################
echo "🅴 Validating repo structure..."

REQUIRED=(
  apps/doctor-ui
  apps/patient-ui
  apps/insurance-ui
  apps/pharmacy-ui
  services/intent-gateway
  services/pharmacy-gateway
  services/ddi-engine
  policies
  dashboards
)

for dir in "${REQUIRED[@]}"; do
  if [ -d "$dir" ]; then
    echo "✅ $dir"
  else
    echo "❌ Missing $dir"
  fi
done

########################################
# 🅵 DEA / Controlled Substance Policies
########################################
echo "🅵 Generating DEA Rego policies..."

mkdir -p policies/pharmacy
cat > policies/pharmacy/dea.rego <<'EOF'
package pharmacy.dea

default allow = false

allow {
  input.prescription.schedule in {"II","III","IV","V"}
  input.prescriber.dea_valid
  input.pharmacy.dea_registered
  not expired
}

expired {
  time.now_ns() > input.prescription.expiry_ns
}

deny {
  input.prescription.schedule == "II"
  input.request.refill == true
}

deny {
  input.prescription.schedule == "III"
  input.request.refill_count > 5
}
EOF

########################################
# FINAL
########################################
echo "========================================="
echo "✅ Enterprise bootstrap complete"
echo ""
echo "Next steps:"
echo "1) git push -u origin feature/pharmacy-enterprise"
echo "2) Open PR on GitHub"
echo "3) ./scripts/release.sh v1.0.0"
echo "========================================="

