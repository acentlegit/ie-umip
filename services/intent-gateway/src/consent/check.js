export async function checkConsent(db, intent) {
  const consents = db.collection("consents");

  const record = await consents.findOne({
    patient: intent.subject,
    actor: intent.actor,
    scope: intent.action
  });

  return !!record;
}
