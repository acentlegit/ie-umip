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
