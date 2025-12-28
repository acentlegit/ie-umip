export function hipaaMinimumNecessary(intent) {
  if (intent.actor === "insurance" && intent.action.includes("labs")) {
    return {
      allowed: false,
      reason: "HIPAA minimum necessary violation"
    };
  }

  return { allowed: true };
}
