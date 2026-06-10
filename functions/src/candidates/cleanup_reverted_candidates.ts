import {Timestamp} from "firebase-admin/firestore";
import {onCall} from "firebase-functions/v2/https";
import {requireAdmin} from "../auth/require_admin";
import {db} from "../shared/firebase";
import type {CandidateData} from "../shared/types";
import {
  boundedInteger,
  mapRecord,
  normalizeStringList,
  stringInput,
} from "../shared/validators";

type SyncRunInfo = {
  runId: string;
  createdAtMs: number;
};

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
    const runIds = candidateRunIds(candidate);

    if (runIds.length === 0) {
      skippedCount++;
      skipped.push({candidateId, reason: "sync_run_missing"});
      continue;
    }

    const runInfos: SyncRunInfo[] = [];
    let hasUnrevertedRun = false;
    for (const runId of runIds) {
      const runSnapshot = await db.doc(`candidate_sync_runs/${runId}`).get();
      const run = runSnapshot.data();
      if (!runSnapshot.exists || run?.status !== "reverted") {
        hasUnrevertedRun = true;
        break;
      }
      runInfos.push({
        runId,
        createdAtMs: timestampMillis(run?.createdAt),
      });
    }

    if (hasUnrevertedRun) {
      skippedCount++;
      skipped.push({candidateId, reason: "active_sync_run_exists"});
      continue;
    }

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

    runInfos.sort((a, b) => a.createdAtMs - b.createdAtMs);
    let beforeSnapshot: Record<string, unknown> | null = null;
    for (const runInfo of runInfos) {
      const changeSnapshot = await db
        .doc(`candidate_sync_runs/${runInfo.runId}/changes/${candidateId}`)
        .get();
      const changeBeforeSnapshot = mapRecord(
        changeSnapshot.data()?.beforeSnapshot,
      );
      if (changeBeforeSnapshot) {
        beforeSnapshot = changeBeforeSnapshot;
        break;
      }
    }

    if (beforeSnapshot) {
      batch.set(candidateSnapshot.ref, {
        ...beforeSnapshot,
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

function candidateRunIds(candidate: CandidateData): string[] {
  const syncRunIds = normalizeStringList(candidate.syncRunIds);
  const lastSyncRunId = stringInput(candidate.lastSyncRunId);
  if (lastSyncRunId) {
    syncRunIds.push(lastSyncRunId);
  }
  return [...new Set(syncRunIds)];
}

function timestampMillis(value: unknown): number {
  if (value && typeof value === "object" && "toMillis" in value) {
    const toMillis = (value as {toMillis?: unknown}).toMillis;
    if (typeof toMillis === "function") {
      return toMillis.call(value);
    }
  }
  return 0;
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
