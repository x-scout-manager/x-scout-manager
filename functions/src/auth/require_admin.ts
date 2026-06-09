import {HttpsError} from "firebase-functions/v2/https";
import type {CallableRequest} from "firebase-functions/v2/https";
import {db} from "../shared/firebase";
import type {AdminUser} from "../shared/types";

export async function requireAdmin(
  request: CallableRequest,
): Promise<AdminUser> {
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
