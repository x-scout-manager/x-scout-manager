import {Timestamp} from "firebase-admin/firestore";
import {onCall} from "firebase-functions/v2/https";
import {requireAdmin} from "../auth/require_admin";
import {db} from "../shared/firebase";
import type {CandidateData} from "../shared/types";
import {
  boundedInteger,
  mapRecord,
  stringInput,
} from "../shared/validators";

type CleanupDecision =
  {type: "delete"} |
  {type: "restore"; beforeSnapshot: Record<string, unknown>} |
  {type: "skip"; reason: string};

export const cleanupRevertedCandidates = onCall(async (request) => {
  const admin = await requireAdmin(request);
  const data = request.data as {limit?: unknown};
  const limit = boundedInteger(data.limit, undefined, 1, 500, 300);
  const now = Timestamp.now();
  const candidatesSnapshot = await db.collection("candidates")
    .where("status", "==", "candidate")
    .limit(limit)
    .get();

  let restoredCount = 0;
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

  for (const candidateSnapshot of candidatesSnapshot.docs) {
    const candidate = candidateSnapshot.data() as CandidateData;
    const candidateId = stringInput(candidate.candidateId) ||
      candidateSnapshot.id;
    const xUserId = stringInput(candidate.xUserId) || candidateId;

    const [historySnapshot, queueItemsSnapshot] = await Promise.all([
      db.collection("send_histories")
        .where("xUserId", "==", xUserId)
        .limit(1)
        .get(),
      db.collectionGroup("items")
        .where("candidateId", "==", candidateId)
        .limit(20)
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

    const decision = await resolveCleanupDecision(candidateId, candidate);
    if (decision.type === "skip") {
      skippedCount++;
      skipped.push({candidateId, reason: decision.reason});
      continue;
    }

    if (decision.type === "restore") {
      batch.set(candidateSnapshot.ref, {
        ...decision.beforeSnapshot,
        restoredFromCleanupAt: now,
        restoredFromCleanupBy: admin.uid,
        updatedAt: now,
        updatedBy: admin.uid,
      });
      restoredCount++;
      batchWrites++;
    } else {
      batch.delete(candidateSnapshot.ref);
      deletedCount++;
      batchWrites++;
    }
    await commitIfNeeded();
  }

  await commitIfNeeded(true);

  return {
    restoredCount,
    deletedCount,
    skippedCount,
    skipped,
  };
});

async function resolveCleanupDecision(
  candidateId: string,
  candidate: CandidateData,
): Promise<CleanupDecision> {
  let currentRunId = stringInput(candidate.lastSyncRunId);
  if (!currentRunId) {
    return {type: "skip", reason: "last_sync_run_missing"};
  }

  const visitedRunIds = new Set<string>();
  for (let depth = 0; depth < 30; depth++) {
    if (visitedRunIds.has(currentRunId)) {
      return {type: "skip", reason: "sync_run_cycle"};
    }
    visitedRunIds.add(currentRunId);

    const runSnapshot = await db.doc(`candidate_sync_runs/${currentRunId}`)
      .get();
    const run = runSnapshot.data();
    if (!runSnapshot.exists || run?.status !== "reverted") {
      return {type: "skip", reason: "active_sync_run_exists"};
    }

    const changeSnapshot = await db
      .doc(`candidate_sync_runs/${currentRunId}/changes/${candidateId}`)
      .get();
    if (!changeSnapshot.exists) {
      return {type: "skip", reason: "sync_change_missing"};
    }

    const beforeSnapshot = mapRecord(changeSnapshot.data()?.beforeSnapshot);
    if (!beforeSnapshot) {
      return {type: "delete"};
    }

    const beforeLastSyncRunId = stringInput(beforeSnapshot.lastSyncRunId);
    if (stringInput(beforeSnapshot.status) === "candidate" &&
      beforeLastSyncRunId) {
      const beforeRunSnapshot = await db
        .doc(`candidate_sync_runs/${beforeLastSyncRunId}`)
        .get();
      if (beforeRunSnapshot.data()?.status === "reverted") {
        currentRunId = beforeLastSyncRunId;
        continue;
      }
    }

    return {type: "restore", beforeSnapshot};
  }

  return {type: "skip", reason: "sync_run_chain_too_deep"};
}

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
