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
