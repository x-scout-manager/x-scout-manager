import {Timestamp} from "firebase-admin/firestore";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import {requireAdmin} from "../auth/require_admin";
import {db} from "../shared/firebase";
import type {CandidateData} from "../shared/types";
import {mapRecord, stringInput} from "../shared/validators";

export const revertCandidateSyncRun = onCall(async (request) => {
  const admin = await requireAdmin(request);
  const data = request.data as {runId?: unknown};
  const runId = stringInput(data.runId);

  if (!runId) {
    throw new HttpsError("invalid-argument", "抽出履歴IDを確認してください。");
  }

  const runRef = db.doc(`candidate_sync_runs/${runId}`);
  const runSnapshot = await runRef.get();

  if (!runSnapshot.exists) {
    throw new HttpsError("not-found", "抽出履歴が見つかりません。");
  }

  const run = runSnapshot.data();
  if (run?.status === "reverted") {
    throw new HttpsError("failed-precondition", "この抽出はすでに解除済みです。");
  }
  if (run?.status !== "completed") {
    throw new HttpsError("failed-precondition", "完了済みの抽出のみ解除できます。");
  }

  const itemsSnapshot = await runRef.collection("changes").get();
  const now = Timestamp.now();
  let revertedCount = 0;
  let deletedCount = 0;
  let skippedCount = 0;
  const skipped: Array<{candidateId: string; reason: string}> = [];
  let batch = db.batch();
  let batchWrites = 0;

  const commitIfNeeded = async (force = false) => {
    if (batchWrites === 0 || (!force && batchWrites < 450)) {
      return;
    }
    await batch.commit();
    batch = db.batch();
    batchWrites = 0;
  };

  for (const itemSnapshot of itemsSnapshot.docs) {
    const item = itemSnapshot.data();
    const candidateId = stringInput(item.candidateId) || itemSnapshot.id;
    const xUserId = stringInput(item.xUserId) || candidateId;
    const candidateRef = db.doc(`candidates/${candidateId}`);
    const [
      candidateSnapshot,
      historySnapshot,
      queueItemsSnapshot,
    ] = await Promise.all([
      candidateRef.get(),
      db.collection("send_histories")
        .where("xUserId", "==", xUserId)
        .limit(1)
        .get(),
      db.collectionGroup("items")
        .where("candidateId", "==", candidateId)
        .limit(1)
        .get(),
    ]);

    if (!historySnapshot.empty) {
      skippedCount++;
      skipped.push({candidateId, reason: "sent_history_exists"});
      continue;
    }
    if (await hasActiveQueueItem(queueItemsSnapshot)) {
      skippedCount++;
      skipped.push({candidateId, reason: "send_queue_item_exists"});
      continue;
    }

    const current = candidateSnapshot.data() as CandidateData | undefined;
    if (current && current.lastSyncRunId !== runId) {
      skippedCount++;
      skipped.push({candidateId, reason: "newer_sync_exists"});
      continue;
    }

    const beforeSnapshot = mapRecord(item.beforeSnapshot);
    const beforeExcludedSnapshot = mapRecord(item.beforeExcludedSnapshot);
    const excludedRef = db.doc(`excluded_accounts/${xUserId}`);

    if (beforeSnapshot) {
      batch.set(candidateRef, {
        ...beforeSnapshot,
        restoredFromSyncRunId: runId,
        updatedAt: now,
        updatedBy: admin.uid,
      });
      revertedCount++;
      batchWrites++;
    } else if (candidateSnapshot.exists) {
      batch.delete(candidateRef);
      deletedCount++;
      batchWrites++;
    }

    if (beforeExcludedSnapshot) {
      batch.set(excludedRef, {
        ...beforeExcludedSnapshot,
        restoredFromSyncRunId: runId,
        updatedAt: now,
        updatedBy: admin.uid,
      });
      batchWrites++;
    } else if (item.action === "excluded_by_keyword") {
      batch.delete(excludedRef);
      batchWrites++;
    }

    batch.update(itemSnapshot.ref, {
      revertStatus: "reverted",
      revertedAt: now,
      revertedBy: admin.uid,
    });
    batchWrites++;
    await commitIfNeeded();
  }

  batch.update(runRef, {
    status: "reverted",
    revertedAt: now,
    revertedBy: admin.uid,
    updatedAt: now,
    revertResult: {
      revertedCount,
      deletedCount,
      skippedCount,
      skipped,
    },
  });
  batchWrites++;
  await commitIfNeeded(true);

  return {
    runId,
    revertedCount,
    deletedCount,
    skippedCount,
    skipped,
  };
});

async function hasActiveQueueItem(
  queueItemsSnapshot: FirebaseFirestore.QuerySnapshot,
): Promise<boolean> {
  for (const itemDoc of queueItemsSnapshot.docs) {
    const queueRef = itemDoc.ref.parent.parent;
    if (!queueRef) {
      continue;
    }
    const queueSnapshot = await queueRef.get();
    if (queueSnapshot.data()?.status !== "deleted") {
      return true;
    }
  }
  return false;
}
