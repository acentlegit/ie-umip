import express from "express";

const app = express();
app.use(express.json());

app.get("/health", (_, res) => res.json({ ok: true }));

app.listen(8093, () =>
  console.log("💊 Pharmacy Gateway running on 8093")
);
