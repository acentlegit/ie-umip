
import { http } from "./http";
export const getConsentHistory = (patientId: string) =>
  http(`/consent/history?patientId=${patientId}`);
