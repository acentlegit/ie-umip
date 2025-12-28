#!/usr/bin/env bash
set -e

echo "========================================="
echo "🧪 Phase 5: End-to-End Tests"
echo "Doctor → Patient → Insurance"
echo "========================================="

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# -----------------------------------------
# 1️⃣ Verify required services are running
# -----------------------------------------
REQUIRED_PORTS=(3001 3002 3004 8080 27017 6379)

echo "🔍 Checking required ports..."
for PORT in "${REQUIRED_PORTS[@]}"; do
  if ! lsof -i ":$PORT" >/dev/null 2>&1; then
    echo "❌ Port $PORT is not running"
    echo "➡️  Please start docker-compose.dev.yml first"
    exit 1
  fi
done
echo "✅ All required services are running"

# -----------------------------------------
# 2️⃣ Install Playwright if missing
# -----------------------------------------
echo "📦 Ensuring Playwright is installed..."
cd "$ROOT_DIR"

if [ ! -d "node_modules/@playwright" ]; then
  npm install -D @playwright/test
  npx playwright install --with-deps
fi

# -----------------------------------------
# 3️⃣ Run API smoke tests (Intent Gateway)
# -----------------------------------------
echo "🔐 Testing intent-gateway decisions..."

curl -s -X POST http://localhost:8080/intent/decide \
  -H "Content-Type: application/json" \
  -d '{
    "actor": "doctor",
    "action": "view_labs",
    "subject": "patient:123",
    "tenant": "hospital-a"
  }' | grep -q '"allow":true' \
  && echo "✅ Doctor intent allowed" \
  || { echo "❌ Doctor intent failed"; exit 1; }

# -----------------------------------------
# 4️⃣ UI E2E tests
# -----------------------------------------
echo "🖥️ Running UI E2E tests..."

export BASE_DOCTOR_URL="http://localhost:3001"
export BASE_PATIENT_URL="http://localhost:3002"
export BASE_INSURANCE_URL="http://localhost:3004"

npx playwright test <<'EOF'
import { test, expect } from '@playwright/test';

test('Doctor → Patient → Insurance flow', async ({ page }) => {
  // Doctor views patient labs
  await page.goto(process.env.BASE_DOCTOR_URL);
  await page.click('text=Patients');
  await page.click('text=John Doe');
  await page.click('text=View Labs');

  await expect(page.locator('text=Lab Results')).toBeVisible();

  // Trigger intent explanation
  await page.hover('text=Why allowed');
  await expect(page.locator('text=Policy Explanation')).toBeVisible();

  // Patient consent
  await page.goto(process.env.BASE_PATIENT_URL);
  await page.click('text=Consent');
  await page.click('text=Grant Consent');

  await expect(page.locator('text=Consent granted')).toBeVisible();

  // Insurance claim review
  await page.goto(process.env.BASE_INSURANCE_URL);
  await page.click('text=Claims');
  await page.click('text=Review Claim');

  await expect(page.locator('text=Approved')).toBeVisible();
});
EOF

# -----------------------------------------
# 5️⃣ Audit verification
# -----------------------------------------
echo "📜 Verifying audit logs..."

curl -s http://localhost:8080/audit/recent | grep -q "view_labs" \
  && echo "✅ Audit logs recorded" \
  || { echo "❌ Audit logs missing"; exit 1; }

# -----------------------------------------
# 6️⃣ Summary
# -----------------------------------------
echo "========================================="
echo "✅ Phase 5 E2E Tests PASSED"
echo "Doctor → Patient → Insurance flow verified"
echo "========================================="

