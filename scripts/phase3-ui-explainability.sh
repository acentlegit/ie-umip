#!/usr/bin/env bash
set -e

echo "🎨 Phase 3 — UI Explainability + Audit Drill-down"

UI_APPS=(
  "apps/doctor-ui"
  "apps/patient-ui"
  "apps/insurance-ui"
  "apps/government-ui"
)

# -------------------------------
# 1️⃣ Shared Explainability UI
# -------------------------------
echo "🧠 Creating shared explainability components..."

mkdir -p packages/ui-common/src/components

cat > packages/ui-common/src/components/PolicyExplanationPanel.tsx <<'EOF'
import React from "react";

export function PolicyExplanationPanel({ explanation }: { explanation: any }) {
  if (!explanation) return null;

  return (
    <div style={{ border: "1px solid #ccc", padding: 12, marginTop: 8 }}>
      <strong>Decision:</strong> {explanation.decision}
      <br />
      <strong>Rule:</strong> {explanation.rule}
      <ul>
        {explanation.because?.map((b: any, i: number) => (
          <li key={i}>
            {b.condition} → {b.matched ? "✔" : "✖"}
          </li>
        ))}
      </ul>
    </div>
  );
}
EOF

cat > packages/ui-common/src/components/WhyDeniedButton.tsx <<'EOF'
import React, { useState } from "react";
import { PolicyExplanationPanel } from "./PolicyExplanationPanel";

export function WhyDeniedButton({ explanation }: { explanation: any }) {
  const [open, setOpen] = useState(false);

  if (!explanation || explanation.decision !== "deny") return null;

  return (
    <>
      <button onClick={() => setOpen(!open)}>
        Why denied?
      </button>
      {open && <PolicyExplanationPanel explanation={explanation} />}
    </>
  );
}
EOF

echo "✅ Shared UI components created"

# -------------------------------
# 2️⃣ Wire into all UIs
# -------------------------------
for APP in "${UI_APPS[@]}"; do
  echo "🔌 Wiring explainability into $APP"

  mkdir -p "$APP/src/components"

  cat > "$APP/src/components/IntentDecisionResult.tsx" <<'EOF'
import React from "react";
import { WhyDeniedButton } from "@allmerge/ui-common/WhyDeniedButton";

export function IntentDecisionResult({ decision }: { decision: any }) {
  if (!decision) return null;

  return (
    <div style={{ marginTop: 12 }}>
      <strong>Decision:</strong> {decision.decision}
      <WhyDeniedButton explanation={decision.explanation} />
    </div>
  );
}
EOF
done

# -------------------------------
# 3️⃣ Developer Instructions
# -------------------------------
echo ""
echo "✅ Phase 3 complete"
echo ""
echo "📌 How to use in UI screens:"
echo "import { IntentDecisionResult } from '@/components/IntentDecisionResult';"
echo ""
echo "<IntentDecisionResult decision={decisionResponse} />"
echo ""
echo "▶️ Restart UIs to see explainability panels"

