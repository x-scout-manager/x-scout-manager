import {getApps, initializeApp} from "firebase-admin/app";
import {
  getFirestore,
  Timestamp,
} from "firebase-admin/firestore";
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

type CandidateData = {
  candidateId?: string;
  xUserId?: string;
  username?: string;
  status?: string;
  isSent?: boolean;
  isExcluded?: boolean;
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
  }> = [];
  let skippedCount = 0;

  for (const candidateId of candidateIds) {
    const candidateSnapshot = await db.doc(`candidates/${candidateId}`).get();
    const candidate = candidateSnapshot.data() as CandidateData | undefined;

    if (!candidateSnapshot.exists || !candidate) {
      skippedCount++;
      continue;
    }

    const xUserId = typeof candidate.xUserId === "string" &&
      candidate.xUserId.trim().length > 0 ?
      candidate.xUserId.trim() :
      candidateId;
    const username = typeof candidate.username === "string" ?
      candidate.username.trim() :
      "";

    const [historySnapshot, excludedSnapshot] = await Promise.all([
      db.collection("send_histories").where("xUserId", "==", xUserId).limit(1).get(),
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

    queueItems.push({candidateId, xUserId, username});
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

function normalizeCandidateIds(value: unknown): string[] {
  if (!Array.isArray(value)) {
    return [];
  }

  const candidateIds = value
    .filter((candidateId): candidateId is string => {
      return typeof candidateId === "string" && candidateId.trim().length > 0;
    })
    .map((candidateId) => candidateId.trim());

  return [...new Set(candidateIds)];
}
