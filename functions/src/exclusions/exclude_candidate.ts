import {Timestamp} from "firebase-admin/firestore";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import {requireAdmin} from "../auth/require_admin";
import {db} from "../shared/firebase";
import type {CandidateData} from "../shared/types";
import {stringInput} from "../shared/validators";

export const excludeCandidate = onCall(async (request) => {
  const admin = await requireAdmin(request);
  const data = request.data as {candidateId?: unknown; reason?: unknown};
  const candidateId = stringInput(data.candidateId);
  const reason = stringInput(data.reason);

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
  const now = Timestamp.now();
  const excludedRef = db.doc(`excluded_accounts/${xUserId}`);
  const [excludedSnapshot, queueItemsSnapshot] = await Promise.all([
    excludedRef.get(),
    db.collectionGroup("items").where("candidateId", "==", candidateId).get(),
  ]);
  const batch = db.batch();
  const matchedKeywords = Array.isArray(candidate.matchedKeywords) ?
    candidate.matchedKeywords.filter((keyword): keyword is string => {
      return typeof keyword === "string" && keyword.trim().length > 0;
    }) :
    [];

  batch.set(excludedRef, {
    candidateId,
    xUserId,
    username: stringInput(candidate.username),
    displayName: stringInput(candidate.displayName),
    profileTextSnapshot: stringInput(candidate.profileText),
    matchedKeywords,
    reason,
    source: "manual",
    ...(!excludedSnapshot.exists ? {createdAt: now} : {}),
    updatedAt: now,
    ...(!excludedSnapshot.exists ? {createdBy: admin.uid} : {}),
    updatedBy: admin.uid,
  }, {merge: true});

  batch.update(candidateRef, {
    status: "excluded",
    isExcluded: true,
    updatedAt: now,
  });

  queueItemsSnapshot.docs
    .filter((snapshot) => snapshot.data().status === "pending")
    .forEach((snapshot) => {
      batch.update(snapshot.ref, {
        status: "excluded",
        updatedAt: now,
      });
    });

  await batch.commit();

  return {
    candidateId,
    xUserId,
  };
});
