
import { http } from "./http";
export const exportPreview = () => http("/compliance/export/preview");
export const exportDiff = () => http("/compliance/export/diff");
export const exportData = () => http("/compliance/export", { method: "POST" });
