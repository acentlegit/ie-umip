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
