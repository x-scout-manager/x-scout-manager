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
  displayName?: string;
  profileText?: string;
  matchedKeywords?: unknown;
  sourceTags?: unknown;
  firstFoundAt?: unknown;
  status?: string;
  isSent?: boolean;
  isExcluded?: boolean;
  firstContactedAt?: unknown;
};

type SendHistoryData = {
  historyId?: string;
  candidateId?: string;
  xUserId?: string;
  username?: string;
  displayName?: string;
  queueId?: string;
  queueItemId?: string;
  templateId?: string;
  templateName?: string;
  messageBodySnapshot?: string;
  sendMethod?: string;
  sentAt?: unknown;
  sentBy?: string;
  xDmEventId?: string;
  createdAt?: unknown;
};

type SendQueueData = {
  totalCount?: number;
  completedCount?: number;
  failedCount?: number;
};

type SendQueueItemData = {
  candidateId?: string;
  xUserId?: string;
  username?: string;
  status?: string;
  order?: number;
};

type TemplateData = {
  name?: string;
  body?: string;
  isActive?: boolean;
};

type ScoutSettingsData = {
  defaultRewardRate?: unknown;
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

    const xUserId = typeof candidate.xUserId === "string" &&
      candidate.xUserId.trim().length > 0 ?
      candidate.xUserId.trim() :
      candidateId;
    const username = typeof candidate.username === "string" ?
      candidate.username.trim() :
      "";
    const displayName = typeof candidate.displayName === "string" ?
      candidate.displayName.trim() :
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

export const markAsManuallySent = onCall(async (request) => {
  const admin = await requireAdmin(request);
  const data = request.data as {
    queueId?: unknown;
    itemId?: unknown;
    templateId?: unknown;
    messageBody?: unknown;
  };
  const queueId = stringInput(data.queueId);
  const itemId = stringInput(data.itemId);
  const templateId = stringInput(data.templateId);
  const messageBody = stringInput(data.messageBody);

  if (!queueId || !itemId || !templateId || !messageBody) {
    throw new HttpsError(
      "invalid-argument",
      "送信キュー、候補、テンプレート、本文を確認してください。",
    );
  }

  const historyRef = db.collection("send_histories").doc();
  const queueRef = db.doc(`send_queues/${queueId}`);
  const itemRef = queueRef.collection("items").doc(itemId);
  const templateRef = db.doc(`templates/${templateId}`);
  const now = Timestamp.now();

  await db.runTransaction(async (transaction) => {
    const [queueSnapshot, itemSnapshot, templateSnapshot] = await Promise.all([
      transaction.get(queueRef),
      transaction.get(itemRef),
      transaction.get(templateRef),
    ]);

    if (!queueSnapshot.exists) {
      throw new HttpsError("not-found", "送信キューが見つかりません。");
    }

    if (!itemSnapshot.exists) {
      throw new HttpsError("not-found", "送信キュー明細が見つかりません。");
    }

    if (!templateSnapshot.exists) {
      throw new HttpsError("not-found", "テンプレートが見つかりません。");
    }

    const queue = queueSnapshot.data() as SendQueueData;
    const item = itemSnapshot.data() as SendQueueItemData;
    const template = templateSnapshot.data() as TemplateData;
    const candidateId = stringInput(item.candidateId);
    const xUserId = stringInput(item.xUserId) || candidateId;

    if (!candidateId || !xUserId) {
      throw new HttpsError(
        "failed-precondition",
        "候補情報が不足しています。",
      );
    }

    if (item.status !== "pending") {
      throw new HttpsError(
        "failed-precondition",
        "この候補は送信済み、または送信対象外です。",
      );
    }

    if (template.isActive === false) {
      throw new HttpsError(
        "failed-precondition",
        "無効なテンプレートは使用できません。",
      );
    }

    const candidateRef = db.doc(`candidates/${candidateId}`);
    const candidateSnapshot = await transaction.get(candidateRef);

    if (!candidateSnapshot.exists) {
      throw new HttpsError("not-found", "候補が見つかりません。");
    }

    const candidate = candidateSnapshot.data() as CandidateData;

    if (
      candidate.status !== "candidate" ||
      candidate.isSent === true ||
      candidate.isExcluded === true
    ) {
      throw new HttpsError(
        "failed-precondition",
        "この候補は送信対象にできません。",
      );
    }

    const historySnapshot = await transaction.get(
      db.collection("send_histories").where("xUserId", "==", xUserId).limit(1),
    );

    if (!historySnapshot.empty) {
      throw new HttpsError(
        "already-exists",
        "このXユーザーは既に送信済みです。",
      );
    }

    const completedCount = numberValue(queue.completedCount);
    const failedCount = numberValue(queue.failedCount);
    const totalCount = numberValue(queue.totalCount);
    const nextCompletedCount = completedCount + 1;
    const queueStatus = nextCompletedCount + failedCount >= totalCount ?
      "completed" :
      "active";

    transaction.set(historyRef, {
      historyId: historyRef.id,
      candidateId,
      xUserId,
      username: stringInput(candidate.username) || stringInput(item.username),
      displayName: stringInput(candidate.displayName),
      queueId,
      queueItemId: itemId,
      templateId,
      templateName: stringInput(template.name),
      messageBodySnapshot: messageBody,
      sentAt: now,
      sentBy: admin.uid,
      sendMethod: "manual",
      createdAt: now,
    });

    transaction.update(candidateRef, {
      status: "sent",
      isSent: true,
      lastSendHistoryId: historyRef.id,
      firstContactedAt: candidate.firstContactedAt ?? now,
      updatedAt: now,
    });

    transaction.update(itemRef, {
      status: "sent",
      templateId,
      sendHistoryId: historyRef.id,
      sentAt: now,
      updatedAt: now,
    });

    transaction.update(queueRef, {
      completedCount: nextCompletedCount,
      currentIndex: Math.min(numberValue(item.order) + 1, totalCount),
      status: queueStatus,
      updatedAt: now,
    });
  });

  return {
    historyId: historyRef.id,
  };
});

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

export const calculateReward = onCall(async (request) => {
  await requireAdmin(request);
  const data = request.data as {salesAmount?: unknown; rewardRate?: unknown};
  const salesAmount = positiveNumber(data.salesAmount);
  const rewardRate = data.rewardRate === undefined || data.rewardRate === null ?
    await defaultRewardRate() :
    positiveNumber(data.rewardRate);

  if (salesAmount <= 0 || rewardRate <= 0) {
    throw new HttpsError(
      "invalid-argument",
      "対象売上と報酬率を確認してください。",
    );
  }

  return {
    rewardRate,
    rewardAmount: calculateRewardAmount(salesAmount, rewardRate),
  };
});

export const createConversion = onCall(async (request) => {
  const admin = await requireAdmin(request);
  const data = request.data as {
    sendHistoryId?: unknown;
    salesAmount?: unknown;
    rewardRate?: unknown;
    evidenceNote?: unknown;
  };
  const sendHistoryId = stringInput(data.sendHistoryId);
  const salesAmount = positiveNumber(data.salesAmount);
  const rewardRate = data.rewardRate === undefined || data.rewardRate === null ?
    await defaultRewardRate() :
    positiveNumber(data.rewardRate);
  const evidenceNote = stringInput(data.evidenceNote);

  if (!sendHistoryId) {
    throw new HttpsError("invalid-argument", "送信履歴を選択してください。");
  }

  if (salesAmount <= 0 || rewardRate <= 0) {
    throw new HttpsError(
      "invalid-argument",
      "対象売上と報酬率を確認してください。",
    );
  }

  const historySnapshot = await db.doc(`send_histories/${sendHistoryId}`).get();
  if (!historySnapshot.exists) {
    throw new HttpsError("not-found", "送信履歴が見つかりません。");
  }

  const history = historySnapshot.data() as SendHistoryData;
  const candidateId = stringInput(history.candidateId);
  if (!candidateId) {
    throw new HttpsError(
      "failed-precondition",
      "送信履歴の候補情報が不足しています。",
    );
  }

  const [candidateSnapshot, existingConversionSnapshot] = await Promise.all([
    db.doc(`candidates/${candidateId}`).get(),
    db
      .collection("conversions")
      .where("sendHistoryId", "==", sendHistoryId)
      .limit(1)
      .get(),
  ]);

  if (!existingConversionSnapshot.empty) {
    throw new HttpsError(
      "already-exists",
      "この送信履歴は既に成果登録済みです。",
    );
  }

  const candidate = candidateSnapshot.data() as CandidateData | undefined;
  const conversionRef = db.collection("conversions").doc();
  const now = Timestamp.now();
  const rewardAmount = calculateRewardAmount(salesAmount, rewardRate);
  const sourceTags = Array.isArray(candidate?.sourceTags) ?
    candidate.sourceTags.filter((tag): tag is string => {
      return typeof tag === "string" && tag.trim().length > 0;
    }) :
    [];

  await conversionRef.set({
    conversionId: conversionRef.id,
    candidateId,
    xUserId: stringInput(history.xUserId) || stringInput(candidate?.xUserId),
    username: stringInput(history.username) || stringInput(candidate?.username),
    displayName: stringInput(history.displayName) ||
      stringInput(candidate?.displayName),
    sendHistoryId,
    sendHistorySnapshot: {
      historyId: sendHistoryId,
      queueId: stringInput(history.queueId),
      queueItemId: stringInput(history.queueItemId),
      templateId: stringInput(history.templateId),
      templateName: stringInput(history.templateName),
      messageBodySnapshot: stringInput(history.messageBodySnapshot),
      sendMethod: stringInput(history.sendMethod),
      sentAt: history.sentAt ?? null,
      sentBy: stringInput(history.sentBy),
      xDmEventId: stringInput(history.xDmEventId),
      createdAt: history.createdAt ?? null,
    },
    candidateSnapshot: {
      candidateId,
      xUserId: stringInput(candidate?.xUserId),
      username: stringInput(candidate?.username),
      displayName: stringInput(candidate?.displayName),
      profileText: stringInput(candidate?.profileText),
      sourceTags,
      firstFoundAt: candidate?.firstFoundAt ?? null,
      firstContactedAt: candidate?.firstContactedAt ?? null,
    },
    sourceTags,
    firstFoundAt: candidate?.firstFoundAt ?? null,
    firstContactedAt: candidate?.firstContactedAt ?? null,
    salesAmount,
    rewardRate,
    rewardAmount,
    evidenceNote,
    status: "draft",
    createdBy: admin.uid,
    createdAt: now,
    updatedAt: now,
  });

  return {
    conversionId: conversionRef.id,
    rewardAmount,
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

function stringInput(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

function numberValue(value: unknown): number {
  return typeof value === "number" && Number.isFinite(value) ? value : 0;
}

function positiveNumber(value: unknown): number {
  if (typeof value === "number" && Number.isFinite(value)) {
    return value;
  }
  if (typeof value === "string" && value.trim().length > 0) {
    const parsed = Number(value.trim());
    return Number.isFinite(parsed) ? parsed : 0;
  }
  return 0;
}

function calculateRewardAmount(salesAmount: number, rewardRate: number): number {
  return Math.round(salesAmount * rewardRate);
}

async function defaultRewardRate(): Promise<number> {
  const settingsSnapshot = await db.doc("settings/scout").get();
  const settings = settingsSnapshot.data() as ScoutSettingsData | undefined;
  const rate = positiveNumber(settings?.defaultRewardRate);
  return rate > 0 ? rate : 0.1;
}
