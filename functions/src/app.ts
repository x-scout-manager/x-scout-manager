import {onCall} from "firebase-functions/v2/https";
import {requireAdmin} from "./auth/require_admin";

export const healthCheck = onCall(() => {
  return {
    ok: true,
    projectId: process.env.GCLOUD_PROJECT ?? null,
    checkedAt: new Date().toISOString(),
  };
});

export const adminHealthCheck = onCall(async (request) => {
  const admin = await requireAdmin(request);

  return {
    ok: true,
    uid: admin.uid,
    checkedAt: new Date().toISOString(),
  };
});
