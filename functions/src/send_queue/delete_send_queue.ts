import {Timestamp} from "firebase-admin/firestore";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import {requireAdmin} from "../auth/require_admin";
import {db} from "../shared/firebase";
import {stringInput} from "../shared/validators";

export const deleteSendQueue = onCall(async (request) => {
  const admin = await requireAdmin(request);
  const data = request.data as {queueId?: unknown};
  const queueId = stringInput(data.queueId);

  if (!queueId) {
    throw new HttpsError("invalid-argument", "送信キューIDが不正です。");
  }

  const queueRef = db.doc(`send_queues/${queueId}`);
  const now = Timestamp.now();

  await db.runTransaction(async (transaction) => {
    const queueSnapshot = await transaction.get(queueRef);
    if (!queueSnapshot.exists) {
      throw new HttpsError("not-found", "送信キューが見つかりません。");
    }

    const queue = queueSnapshot.data();
    if (queue?.status === "deleted") {
      return;
    }

    transaction.update(queueRef, {
      status: "deleted",
      deletedAt: now,
      deletedBy: admin.uid,
      updatedAt: now,
    });
  });

  return {queueId};
});
