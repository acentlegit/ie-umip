#!/usr/bin/env bash
set -e

echo "🔐 Phase 4 — Consent + HIPAA enforcement"

GW="services/intent-gateway/src"

mkdir -p "$GW/consent"
mkdir -p "$GW/hipaa"

# -----------------------------------
# 1️⃣ Consent Checker
# -----------------------------------
cat > "$GW/consent/check.js" <<'EOF'
export async function checkConsent(db, intent) {
  const consents = db.collection("consents");

  const record = await consents.findOne({
    patient: intent.subject,
    actor: intent.actor,
    scope: intent.action
  });

  return !!record;
}
EOF

# -----------------------------------
# 2️⃣ HIPAA Minimum Necessary Rules
# -----------------------------------
cat > "$GW/hipaa/minimum.js" <<'EOF'
export function hipaaMinimumNecessary(intent) {
  if (intent.actor === "insurance" && intent.action.includes("labs")) {
    return {
      allowed: false,
      reason: "HIPAA minimum necessary violation"
    };
  }

  return { allowed: true };
}
EOF

# -----------------------------------
# 3️⃣ Break-Glass Override
# -----------------------------------
cat > "$GW/hipaa/breakGlass.js" <<'EOF'
export function isBreakGlass(intent) {
  return intent.breakGlass === true;
}
EOF

# -----------------------------------
# 4️⃣ Patch Intent Gateway
# -----------------------------------
cat > "$GW/index.js" <<'EOF'
import http from "http";
import { MongoClient } from "mongodb";
import Redis from "ioredis";

import { evaluatePolicy } from "./policy/evaluate.js";
import { explainDecision } from "./policy/explain.js";
import { writeAudit } from "./audit/log.js";

import { checkConsent } from "./consent/check.js";
import { hipaaMinimumNecessary } from "./hipaa/minimum.js";
import { isBreakGlass } from "./hipaa/breakGlass.js";

const PORT = process.env.PORT || 8080;
const MONGO_URL = process.env.MONGO_URL || "mongodb://localhost:27017/ie_umip";
const REDIS_URL = process.env.REDIS_URL || "redis://localhost:6379";

let mongo, db, redis;

async function bootstrap() {
  mongo = new MongoClient(MONGO_URL);
  await mongo.connect();
  db = mongo.db();
  redis = new Redis(REDIS_URL);
}

const server = http.createServer(async (req, res) => {
  if (req.url === "/health") {
    res.writeHead(200, { "Content-Type": "application/json" });
    return res.end(JSON.stringify({ status: "ok" }));
  }

  if (req.url === "/intent/decide" && req.method === "POST") {
    let body = "";
    req.on("data", c => (body += c));
    req.on("end", async () => {
      const intent = JSON.parse(body);

      let decision = "deny";
      let rule = "default_deny";
      let explanation;

      // 1️⃣ Consent check
      const hasConsent = await checkConsent(db, intent);
      if (!hasConsent && !isBreakGlass(intent)) {
        explanation = {
          decision: "deny",
          rule: "missing_consent",
          because: ["No patient consent"]
        };
      } else {
        // 2️⃣ HIPAA minimum necessary
        const hipaa = hipaaMinimumNecessary(intent);
        if (!hipaa.allowed && !isBreakGlass(intent)) {
          explanation = {
            decision: "deny",
            rule: "hipaa_minimum_necessary",
            because: [hipaa.reason]
          };
        } else {
          // 3️⃣ Policy evaluation
          const result = evaluatePolicy(intent);
          decision = result.decision;
          rule = result.rule;
          explanation = explainDecision(intent, result);
        }
      }

      // 4️⃣ Audit everything
      await writeAudit(db, {
        intent,
        decision,
        rule,
        breakGlass: isBreakGlass(intent)
      });

      res.writeHead(200, { "Content-Type": "application/json" });
      res.end(JSON.stringify({ decision, rule, explanation }));
    });
    return;
  }

  res.writeHead(404);
  res.end();
});

bootstrap().then(() => {
  server.listen(PORT, () =>
    console.log(`🚀 Intent Gateway running on http://localhost:${PORT}`)
  );
});
EOF

echo "✅ Phase 4 complete"
echo ""
echo "▶️ Restart gateway:"
echo "cd services/intent-gateway && npm run dev"

