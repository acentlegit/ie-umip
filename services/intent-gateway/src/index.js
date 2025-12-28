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
  server.on("error", err => {
  if (err.code === "EADDRINUSE") {
    console.error(`❌ Port ${PORT} already in use.`);
    console.error("👉 Stop the existing gateway or run with PORT=8081");
    process.exit(1);
  }
  throw err;
});

server.listen(PORT, () => {
  console.log(`🚀 Intent Gateway running on http://localhost:${PORT}`);
});

});
