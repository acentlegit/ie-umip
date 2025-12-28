#!/usr/bin/env bash
set -e

echo "🧠 Phase 2 — Policy engine + audit + explainability"

GW_DIR="services/intent-gateway"
SRC="$GW_DIR/src"

mkdir -p "$SRC/policy"
mkdir -p "$SRC/audit"

# -----------------------------------
# 1️⃣ Policy Evaluator
# -----------------------------------
cat > "$SRC/policy/evaluate.js" <<EOF
export function evaluatePolicy(intent) {
  const { actor, action, subject } = intent;

  if (actor === "doctor" && action.startsWith("view")) {
    return {
      decision: "allow",
      rule: "doctor_read_access"
    };
  }

  if (actor === "insurance" && action === "view_labs") {
    return {
      decision: "deny",
      rule: "insurance_no_lab_access"
    };
  }

  return {
    decision: "deny",
    rule: "default_deny"
  };
}
EOF

# -----------------------------------
# 2️⃣ Explanation Engine
# -----------------------------------
cat > "$SRC/policy/explain.js" <<EOF
export function explainDecision(intent, result) {
  return {
    decision: result.decision,
    rule: result.rule,
    because: [
      {
        condition: "actor == " + intent.actor,
        matched: true
      },
      {
        condition: "action == " + intent.action,
        matched: true
      }
    ]
  };
}
EOF

# -----------------------------------
# 3️⃣ Audit Logger
# -----------------------------------
cat > "$SRC/audit/log.js" <<EOF
export async function writeAudit(db, record) {
  const audits = db.collection("audits");
  await audits.insertOne({
    ...record,
    timestamp: new Date()
  });
}
EOF

# -----------------------------------
# 4️⃣ Patch Intent Gateway
# -----------------------------------
cat > "$SRC/index.js" <<EOF
import http from "http";
import { MongoClient } from "mongodb";
import Redis from "ioredis";

import { evaluatePolicy } from "./policy/evaluate.js";
import { explainDecision } from "./policy/explain.js";
import { writeAudit } from "./audit/log.js";

const PORT = process.env.PORT || 8080;
const MONGO_URL = process.env.MONGO_URL || "mongodb://localhost:27017/ie_umip";
const REDIS_URL = process.env.REDIS_URL || "redis://localhost:6379";

let mongo;
let db;
let redis;

async function bootstrap() {
  mongo = new MongoClient(MONGO_URL);
  await mongo.connect();
  db = mongo.db();
  console.log("✅ Mongo connected");

  redis = new Redis(REDIS_URL);
  redis.on("connect", () => console.log("✅ Redis connected"));
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

      const result = evaluatePolicy(intent);
      const explanation = explainDecision(intent, result);

      await writeAudit(db, {
        intent,
        decision: result.decision,
        rule: result.rule
      });

      res.writeHead(200, { "Content-Type": "application/json" });
      res.end(
        JSON.stringify({
          decision: result.decision,
          rule: result.rule,
          explanation
        })
      );
    });
    return;
  }

  res.writeHead(404);
  res.end();
});

bootstrap()
  .then(() => {
    server.listen(PORT, () =>
      console.log(`🚀 Intent Gateway running on http://localhost:${PORT}`)
    );
  })
  .catch(err => {
    console.error("❌ Startup failure", err);
    process.exit(1);
  });
EOF

echo "✅ Phase 2 complete"
echo ""
echo "▶️ Restart gateway:"
echo "cd services/intent-gateway && npm run dev"

