#!/usr/bin/env bash
set -e

echo "========================================="
echo "🚀 UMIP Enterprise Bootstrap (FIXED)"
echo "========================================="

########################################
# 🅱 PR BRANCH
########################################
git checkout -B feature/pharmacy-enterprise

########################################
# 🧱 Ensure Required Directories Exist
########################################
echo "📦 Ensuring required directories exist..."

mkdir -p services/pharmacy-gateway/src
mkdir -p services/ddi-engine/src
mkdir -p dashboards/pharmacy
mkdir -p policies/pharmacy

########################################
# 🧠 Stub Pharmacy Gateway
########################################
if [ ! -f services/pharmacy-gateway/package.json ]; then
  cat > services/pharmacy-gateway/package.json <<'EOF'
{
  "name": "pharmacy-gateway",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "node src/index.js"
  },
  "dependencies": {
    "express": "^4.19.2",
    "mongodb": "^6.5.0",
    "ioredis": "^5.4.1"
  }
}
EOF

  cat > services/pharmacy-gateway/src/index.js <<'EOF'
import express from "express";

const app = express();
app.use(express.json());

app.get("/health", (_, res) => res.json({ ok: true }));

app.listen(8093, () =>
  console.log("💊 Pharmacy Gateway running on 8093")
);
EOF
fi

########################################
# 🤖 Stub DDI Engine
########################################
if [ ! -f services/ddi-engine/package.json ]; then
  cat > services/ddi-engine/package.json <<'EOF'
{
  "name": "ddi-engine",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "node src/index.js"
  }
}
EOF

  cat > services/ddi-engine/src/index.js <<'EOF'
import express from "express";

const app = express();
app.use(express.json());

app.post("/score", (req, res) => {
  res.json({ severity: "LOW", explanation: "No interaction detected" });
});

app.listen(8092, () =>
  console.log("🧬 DDI Engine running on 8092")
);
EOF
fi

########################################
# 📊 Grafana Dashboard Stub
########################################
if [ ! -f dashboards/pharmacy/overview.json ]; then
  cat > dashboards/pharmacy/overview.json <<'EOF'
{
  "title": "Pharmacy Overview",
  "panels": [
    { "type": "stat", "title": "Claims Today" },
    { "type": "stat", "title": "Controlled Substances" }
  ]
}
EOF
fi

########################################
# 🅵 DEA Rego Policy
########################################
cat > policies/pharmacy/dea.rego <<'EOF'
package pharmacy.dea

default allow = false

allow {
  input.prescriber.dea_valid
  input.pharmacy.dea_registered
  input.prescription.schedule != "I"
}
EOF

########################################
# 🧾 Git Add + Commit
########################################
git add \
  apps/pharmacy-ui \
  services/pharmacy-gateway \
  services/ddi-engine \
  dashboards \
  policies \
  scripts

git commit -m "feat(pharmacy): enterprise pharmacy services, policies, dashboards" || true

########################################
# ✅ Done
########################################
echo "========================================="
echo "✅ Bootstrap complete (FIXED)"
echo ""
echo "Next steps:"
echo "1) git push -u origin feature/pharmacy-enterprise"
echo "2) Open PR"
echo "3) docker compose up --build"
echo "========================================="

