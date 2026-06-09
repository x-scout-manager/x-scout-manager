import {Timestamp} from "firebase-admin/firestore";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import {requireAdmin} from "../auth/require_admin";
import {db} from "../shared/firebase";
import type {CandidateData} from "../shared/types";
import {stringInput} from "../shared/validators";

export const restoreCandidate = onCall(async (request) => {
  await requireAdmin(request);
  const data = request.data as {candidateId?: unknown};
  const candidateId = stringInput(data.candidateId);

  if (!candidateId) {
    throw new HttpsError("invalid-argument", "候補IDを確認してください。");
  }

  const candidateRef = db.doc(`candidates/${candidateId}`);
  const candidateSnapshot = await candidateRef.get();

  if (!candidateSnapshot.exists) {
    throw new HttpsError("not-found", "候補が見つかりません。");
  }

  const candidate = candidateSnapshot.data() as CandidateData;
  const xUserId = stringInput(candidate.xUserId) || candidateId;
  const historySnapshot = await db
    .collection("send_histories")
    .where("xUserId", "==", xUserId)
    .limit(1)
    .get();
  const restoredStatus = candidate.isSent === true || !historySnapshot.empty ?
    "sent" :
    "candidate";
  const now = Timestamp.now();
  const batch = db.batch();

  batch.delete(db.doc(`excluded_accounts/${xUserId}`));
  batch.update(candidateRef, {
    status: restoredStatus,
    isExcluded: false,
    updatedAt: now,
  });

  await batch.commit();

  return {
    candidateId,
    xUserId,
    status: restoredStatus,
  };
});
