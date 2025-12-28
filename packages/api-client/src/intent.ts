
import { http } from "./http";
export const decideIntent = (payload: any) =>
  http("/intent/decide", { method: "POST", body: JSON.stringify(payload) });
