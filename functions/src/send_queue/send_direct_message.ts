import {Timestamp} from "firebase-admin/firestore";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import {requireAdmin} from "../auth/require_admin";
import {db} from "../shared/firebase";
import type {
  CandidateData,
  ScoutSettingsData,
  SendQueueData,
  SendQueueItemData,
  TemplateData,
} from "../shared/types";
import {numberValue, stringInput} from "../shared/validators";
import {
  sendXDirectMessage,
  xClientId,
  xClientSecret,
  xUserAccessToken,
  xUserRefreshToken,
} from "../x/x_dm";

type LockedSendTarget = {
  candidateId: string;
  xUserId: string;
  username: string;
  displayName: string;
  templateName: string;
  wasFailed: boolean;
};

export const sendDirectMessage = onCall(
  {
    secrets: [
      xUserAccessToken,
      xUserRefreshToken,
      xClientId,
      xClientSecret,
    ],
  },
  async (request) => {
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

    const queueRef = db.doc(`send_queues/${queueId}`);
    const itemRef = queueRef.collection("items").doc(itemId);
    const templateRef = db.doc(`templates/${templateId}`);
    const settingsRef = db.doc("settings/scout");
    const now = Timestamp.now();

    let lockedTarget: LockedSendTarget;

    try {
      lockedTarget = await db.runTransaction(async (transaction) => {
        const [
          settingsSnapshot,
          queueSnapshot,
          itemSnapshot,
          templateSnapshot,
        ] = await Promise.all([
          transaction.get(settingsRef),
          transaction.get(queueRef),
          transaction.get(itemRef),
          transaction.get(templateRef),
        ]);

        if (!settingsSnapshot.exists) {
          throw new HttpsError("failed-precondition", "システム設定が見つかりません。");
        }

        const settings = settingsSnapshot.data() as ScoutSettingsData;
        if (settings.apiDmEnabled !== true) {
          throw new HttpsError(
            "failed-precondition",
            "X API DM送信が無効です。",
          );
        }

        if (!queueSnapshot.exists) {
          throw new HttpsError("not-found", "送信キューが見つかりません。");
        }

        if (!itemSnapshot.exists) {
          throw new HttpsError("not-found", "送信キュー明細が見つかりません。");
        }

        if (!templateSnapshot.exists) {
          throw new HttpsError("not-found", "テンプレートが見つかりません。");
        }

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
            "この候補は送信対象にできません。",
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

        transaction.update(itemRef, {
          status: "sending",
          templateId,
          messageBodySnapshot: messageBody,
          apiSendStartedAt: now,
          apiSendError: null,
          updatedAt: now,
        });

        return {
          candidateId,
          xUserId,
          username: stringInput(candidate.username) || stringInput(item.username),
          displayName: stringInput(candidate.displayName),
          templateName: stringInput(template.name),
          wasFailed: item.status === "failed",
        };
      });
    } catch (error) {
      throw error;
    }

    try {
      const xResult = await sendXDirectMessage(lockedTarget.xUserId, messageBody);
      const historyRef = db.collection("send_histories").doc();
      const sentAt = Timestamp.now();

      await db.runTransaction(async (transaction) => {
        const [queueSnapshot, itemSnapshot] = await Promise.all([
          transaction.get(queueRef),
          transaction.get(itemRef),
        ]);

        if (!queueSnapshot.exists || !itemSnapshot.exists) {
          throw new HttpsError(
            "not-found",
            "送信キューまたは明細が見つかりません。",
          );
        }

        const queue = queueSnapshot.data() as SendQueueData;
        const item = itemSnapshot.data() as SendQueueItemData;
        if (item.status !== "sending") {
          throw new HttpsError(
            "failed-precondition",
            "送信キュー明細の状態が変わりました。",
          );
        }

        const candidateRef = db.doc(`candidates/${lockedTarget.candidateId}`);
        const completedCount = numberValue(queue.completedCount);
        const failedCount = numberValue(queue.failedCount);
        const totalCount = numberValue(queue.totalCount);
        const nextCompletedCount = completedCount + 1;
        const nextFailedCount = lockedTarget.wasFailed ?
          Math.max(0, failedCount - 1) :
          failedCount;
        const queueStatus =
          nextCompletedCount + nextFailedCount >= totalCount ?
            "completed" :
            "active";

        transaction.set(historyRef, {
          historyId: historyRef.id,
          candidateId: lockedTarget.candidateId,
          xUserId: lockedTarget.xUserId,
          username: lockedTarget.username,
          displayName: lockedTarget.displayName,
          queueId,
          queueItemId: itemId,
          templateId,
          templateName: lockedTarget.templateName,
          messageBodySnapshot: messageBody,
          sentAt,
          sentBy: admin.uid,
          sendMethod: "api",
          xDmEventId: xResult.dmEventId,
          xDmConversationId: xResult.dmConversationId,
          createdAt: sentAt,
        });

        transaction.update(candidateRef, {
          status: "sent",
          isSent: true,
          lastSendHistoryId: historyRef.id,
          firstContactedAt: sentAt,
          updatedAt: sentAt,
        });

        transaction.update(itemRef, {
          status: "sent",
          templateId,
          sendHistoryId: historyRef.id,
          xDmEventId: xResult.dmEventId,
          xDmConversationId: xResult.dmConversationId,
          sentAt,
          updatedAt: sentAt,
        });

        transaction.update(queueRef, {
          completedCount: nextCompletedCount,
          failedCount: nextFailedCount,
          currentIndex: Math.min(numberValue(item.order) + 1, totalCount),
          status: queueStatus,
          updatedAt: sentAt,
        });
      });

      return {
        historyId: historyRef.id,
        xDmEventId: xResult.dmEventId,
        xDmConversationId: xResult.dmConversationId,
      };
    } catch (error) {
      const failedAt = Timestamp.now();
      await db.runTransaction(async (transaction) => {
        const [queueSnapshot, itemSnapshot] = await Promise.all([
          transaction.get(queueRef),
          transaction.get(itemRef),
        ]);

        if (!queueSnapshot.exists || !itemSnapshot.exists) {
          return;
        }

        const queue = queueSnapshot.data() as SendQueueData;
        const item = itemSnapshot.data() as SendQueueItemData;
        if (item.status !== "sending") {
          return;
        }

        const failedCount = numberValue(queue.failedCount);
        const completedCount = numberValue(queue.completedCount);
        const totalCount = numberValue(queue.totalCount);
        const nextFailedCount = lockedTarget.wasFailed ?
          failedCount :
          failedCount + 1;
        const queueStatus = completedCount + nextFailedCount >= totalCount ?
          "completed" :
          "active";

        transaction.update(itemRef, {
          status: "failed",
          apiSendError: error instanceof Error ? error.message : String(error),
          failedAt,
          updatedAt: failedAt,
        });

        transaction.update(queueRef, {
          failedCount: nextFailedCount,
          status: queueStatus,
          updatedAt: failedAt,
        });
      });

      throw error;
    }
  },
);
