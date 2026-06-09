import {Timestamp} from "firebase-admin/firestore";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import {requireAdmin} from "../auth/require_admin";
import {db} from "../shared/firebase";
import type {CandidateData, SendHistoryData} from "../shared/types";
import {positiveNumber, stringInput} from "../shared/validators";

export const createConversion = onCall(async (request) => {
  const admin = await requireAdmin(request);
  const data = request.data as {
    sendHistoryId?: unknown;
    salesAmount?: unknown;
    evidenceNote?: unknown;
  };
  const sendHistoryId = stringInput(data.sendHistoryId);
  const salesAmount = positiveNumber(data.salesAmount);
  const evidenceNote = stringInput(data.evidenceNote);

  if (!sendHistoryId) {
    throw new HttpsError("invalid-argument", "送信履歴を選択してください。");
  }

  if (salesAmount <= 0) {
    throw new HttpsError(
      "invalid-argument",
      "対象売上を確認してください。",
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
    evidenceNote,
    status: "draft",
    createdBy: admin.uid,
    createdAt: now,
    updatedAt: now,
  });

  return {
    conversionId: conversionRef.id,
  };
});
