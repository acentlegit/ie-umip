export async function writeAudit(db, record) {
  const audits = db.collection("audits");
  await audits.insertOne({
    ...record,
    timestamp: new Date()
  });
}
