import express from "express";

const app = express();
app.use(express.json());

app.post("/score", (req, res) => {
  res.json({ severity: "LOW", explanation: "No interaction detected" });
});

app.listen(8092, () =>
  console.log("🧬 DDI Engine running on 8092")
);
