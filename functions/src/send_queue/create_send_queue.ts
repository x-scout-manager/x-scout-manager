import {Timestamp} from "firebase-admin/firestore";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import {requireAdmin} from "../auth/require_admin";
import {db} from "../shared/firebase";
import type {CandidateData} from "../shared/types";
import {normalizeCandidateIds, stringInput} from "../shared/validators";

export const createSendQueue = onCall(async (request) => {
  const admin = await requireAdmin(request);
  const data = request.data as {candidateIds?: unknown; name?: unknown};
  const candidateIds = normalizeCandidateIds(data.candidateIds);

  if (candidateIds.length === 0) {
    throw new HttpsError(
      "invalid-argument",
      "候補を1件以上選択してください。",
    );
  }

  if (candidateIds.length > 100) {
    throw new HttpsError(
      "invalid-argument",
      "一度にキュー化できる候補は100件までです。",
    );
  }

  const name = typeof data.name === "string" && data.name.trim().length > 0 ?
    data.name.trim() :
    `送信キュー ${new Date().toISOString()}`;

  const queueRef = db.collection("send_queues").doc();
  const now = Timestamp.now();
  const queueItems: Array<{
    candidateId: string;
    xUserId: string;
    username: string;
    displayName: string;
  }> = [];
  let skippedCount = 0;

  for (const candidateId of candidateIds) {
    const candidateSnapshot = await db.doc(`candidates/${candidateId}`).get();
    const candidate = candidateSnapshot.data() as CandidateData | undefined;

    if (!candidateSnapshot.exists || !candidate) {
      skippedCount++;
      continue;
    }

    const xUserId = stringInput(candidate.xUserId) || candidateId;
    const username = stringInput(candidate.username);
    const displayName = stringInput(candidate.displayName);

    const [historySnapshot, excludedSnapshot] = await Promise.all([
      db.collection("send_histories")
        .where("xUserId", "==", xUserId)
        .limit(1)
        .get(),
      db.doc(`excluded_accounts/${xUserId}`).get(),
    ]);

    if (
      candidate.status !== "candidate" ||
      candidate.isSent === true ||
      candidate.isExcluded === true ||
      !historySnapshot.empty ||
      excludedSnapshot.exists
    ) {
      skippedCount++;
      continue;
    }

    queueItems.push({candidateId, xUserId, username, displayName});
  }

  if (queueItems.length === 0) {
    throw new HttpsError(
      "failed-precondition",
      "キュー化できる候補がありません。",
    );
  }

  const batch = db.batch();
  const queuedCandidateIds = queueItems.map((item) => item.candidateId);

  batch.set(queueRef, {
    queueId: queueRef.id,
    name,
    status: "active",
    candidateIds: queuedCandidateIds,
    currentIndex: 0,
    totalCount: queueItems.length,
    completedCount: 0,
    skippedCount,
    failedCount: 0,
    createdAt: now,
    updatedAt: now,
    createdBy: admin.uid,
  });

  queueItems.forEach((item, index) => {
    const itemRef = queueRef.collection("items").doc(item.candidateId);
    batch.set(itemRef, {
      itemId: itemRef.id,
      queueId: queueRef.id,
      candidateId: item.candidateId,
      xUserId: item.xUserId,
      username: item.username,
      displayName: item.displayName,
      status: "pending",
      order: index,
      createdAt: now,
      updatedAt: now,
    });
  });

  await batch.commit();

  return {
    queueId: queueRef.id,
    totalCount: queueItems.length,
    skippedCount,
  };
});
