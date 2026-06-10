import {Timestamp} from "firebase-admin/firestore";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import {requireAdmin} from "../auth/require_admin";
import {db} from "../shared/firebase";
import type {
  CandidateData,
  SendQueueData,
  SendQueueItemData,
  TemplateData,
} from "../shared/types";
import {numberValue, stringInput} from "../shared/validators";

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

    if (item.status !== "pending" && item.status !== "failed") {
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
      db.collection("send_histories")
        .where("xUserId", "==", xUserId)
        .limit(1),
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
    const nextFailedCount = item.status === "failed" ?
      Math.max(0, failedCount - 1) :
      failedCount;
    const queueStatus = nextCompletedCount + nextFailedCount >= totalCount ?
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
      failedCount: nextFailedCount,
      currentIndex: Math.min(numberValue(item.order) + 1, totalCount),
      status: queueStatus,
      updatedAt: now,
    });
  });

  return {
    historyId: historyRef.id,
  };
});
