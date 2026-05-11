import {getApps, initializeApp} from "firebase-admin/app";
import {getFirestore} from "firebase-admin/firestore";
import {setGlobalOptions} from "firebase-functions/v2";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import type {CallableRequest} from "firebase-functions/v2/https";

setGlobalOptions({
  region: "asia-northeast1",
  maxInstances: 10,
});

if (getApps().length === 0) {
  initializeApp();
}

type AdminUser = {
  uid: string;
  role: "admin";
  isActive: true;
};

const db = getFirestore();

async function requireAdmin(request: CallableRequest): Promise<AdminUser> {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "ログインしてください。");
  }

  const userSnapshot = await db.doc(`users/${request.auth.uid}`).get();

  if (!userSnapshot.exists) {
    throw new HttpsError("permission-denied", "管理者権限がありません。");
  }

  const user = userSnapshot.data();

  if (user?.role !== "admin" || user?.isActive !== true) {
    throw new HttpsError("permission-denied", "管理者権限がありません。");
  }

  return {
    uid: request.auth.uid,
    role: "admin",
    isActive: true,
  };
}

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
