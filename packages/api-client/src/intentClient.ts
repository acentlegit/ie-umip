export async function decideIntent(payload: any) {
  const res = await fetch(
    process.env.VITE_INTENT_GATEWAY || "http://localhost:8080/intent/decide",
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload)
    }
  );

  if (!res.ok) {
    throw new Error("Intent gateway error");
  }

  return res.json();
}
