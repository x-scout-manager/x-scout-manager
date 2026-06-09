import {Timestamp} from "firebase-admin/firestore";
import type {DocumentReference, WriteBatch} from "firebase-admin/firestore";
import type {SyncRunItemAction} from "../shared/types";

export function setSyncRunItem(
  batch: WriteBatch,
  runRef: DocumentReference,
  candidateId: string,
  payload: {
    action: SyncRunItemAction;
    beforeSnapshot: Record<string, unknown> | null;
    afterSnapshot: Record<string, unknown>;
    beforeExcludedSnapshot: Record<string, unknown> | null;
    afterExcludedSnapshot: Record<string, unknown> | null;
  },
): void {
  const itemRef = runRef.collection("changes").doc(candidateId);
  batch.set(itemRef, {
    candidateId,
    xUserId: candidateId,
    action: payload.action,
    beforeSnapshot: payload.beforeSnapshot,
    afterSnapshot: payload.afterSnapshot,
    beforeExcludedSnapshot: payload.beforeExcludedSnapshot,
    afterExcludedSnapshot: payload.afterExcludedSnapshot,
    revertStatus: "active",
    createdAt: Timestamp.now(),
  });
}
