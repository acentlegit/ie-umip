#!/usr/bin/env bash
set -e

echo "🚀 Phase 1 — Wiring Intent Gateway into all UIs"

ROOT_DIR=$(pwd)
GATEWAY_URL="http://localhost:8080"

UI_APPS=(
  "apps/doctor-ui"
  "apps/patient-ui"
  "apps/insurance-ui"
  "apps/government-ui"
)

# -------------------------------
# 1️⃣ Shared Intent Client
# -------------------------------
echo "📦 Creating shared intent client..."

mkdir -p packages/api-client/src

cat > packages/api-client/src/intentClient.ts <<EOF
export async function decideIntent(payload: any) {
  const res = await fetch(
    process.env.VITE_INTENT_GATEWAY || "${GATEWAY_URL}/intent/decide",
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload)
    }
  );

  if (!res.ok) {
    throw new Error("Intent gateway error");
  }

  return res.json();
}
EOF

cat > packages/api-client/src/optimistic.ts <<EOF
export async function optimisticAction({
  optimistic,
  rollback,
  action
}: {
  optimistic: () => void;
  rollback: () => void;
  action: () => Promise<any>;
}) {
  optimistic();
  try {
    const result = await action();
    if (result?.decision !== "allow") {
      rollback();
    }
    return result;
  } catch (e) {
    rollback();
    throw e;
  }
}
EOF

echo "✅ Shared client ready"

# -------------------------------
# 2️⃣ Wire into UIs
# -------------------------------
for APP in "\${UI_APPS[@]}"; do
  echo "🔌 Wiring \$APP"

  mkdir -p "\$APP/src/api"

  # Intent client re-export
  cat > "\$APP/src/api/intent.ts" <<EOF
export { decideIntent } from "@allmerge/api-client/intentClient";
export { optimisticAction } from "@allmerge/api-client/optimistic";
EOF

  # Add env example if missing
  if [ ! -f "\$APP/.env.example" ]; then
    cat > "\$APP/.env.example" <<EOF
VITE_INTENT_GATEWAY=${GATEWAY_URL}
EOF
  fi

done

# -------------------------------
# 3️⃣ Validate folders
# -------------------------------
echo "🔍 Verifying UI folders..."

for APP in "\${UI_APPS[@]}"; do
  if [ ! -d "\$APP/src" ]; then
    echo "❌ Missing src folder in \$APP"
    exit 1
  fi
done

echo "✅ Phase 1 complete"
echo ""
echo "▶️ Next:"
echo "cd services/intent-gateway && npm run dev"
echo "cd apps/doctor-ui && npm run dev"

