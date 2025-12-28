
export async function http(url: string, options: RequestInit = {}) {
  const res = await fetch(url, {
    credentials: "include",
    headers: { "Content-Type": "application/json", ...(options.headers || {}) },
    ...options
  });
  if (!res.ok) throw new Error(await res.text());
  return res.json();
}
