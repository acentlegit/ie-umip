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
