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
