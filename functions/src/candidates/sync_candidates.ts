import {Timestamp} from "firebase-admin/firestore";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import {requireAdmin} from "../auth/require_admin";
import {
  boundedInteger,
  matchedExclusionKeywords,
  mergeStringArrays,
  normalizeStringList,
  normalizeTags,
  normalizeTagSearchMode,
  stringInput,
} from "../shared/validators";
import {functionErrorPayload} from "../shared/errors";
import {db} from "../shared/firebase";
import type {
  CandidateData,
  ScoutSettingsData,
  SyncRunItemAction,
  XUser,
} from "../shared/types";
import {
  buildSearchQueries,
  searchRecentPosts,
  xApiBearerToken,
  xBearerToken,
} from "../x/x_search";
import {setSyncRunItem} from "./candidate_sync_run_repository";

export const syncCandidates = onCall(
  {secrets: [xBearerToken]},
  async (request) => {
    const admin = await requireAdmin(request);
    const data = request.data as {
      tags?: unknown;
      maxResults?: unknown;
      maxPages?: unknown;
    };
    const settingsSnapshot = await db.doc("settings/scout").get();
    const settings = settingsSnapshot.data() as ScoutSettingsData | undefined;
    const tags = normalizeTags(data.tags, settings?.tags);
    const exclusionKeywords = normalizeStringList(settings?.exclusionKeywords);
    const maxResults = boundedInteger(
      data.maxResults,
      settings?.searchMaxResults,
      10,
      100,
      50,
    );
    const maxPages = boundedInteger(
      data.maxPages,
      settings?.searchMaxPages,
      1,
      10,
      1,
    );
    const recentSearchDays = boundedInteger(
      undefined,
      settings?.recentSearchDays,
      1,
      7,
      7,
    );
    const tagSearchMode = normalizeTagSearchMode(settings?.tagSearchMode);

    if (tags.length === 0) {
      throw new HttpsError(
        "failed-precondition",
        "タグ設定を1件以上登録してください。",
      );
    }

    const token = xApiBearerToken();
    const now = Timestamp.now();
    const startedAt = Timestamp.now();
    const runRef = db.collection("candidate_sync_runs").doc();
    const runId = runRef.id;
    await runRef.set({
      runId,
      status: "running",
      tags,
      tagSearchMode,
      maxResults,
      maxPages,
      recentSearchDays,
      createdAt: startedAt,
      updatedAt: startedAt,
      createdBy: admin.uid,
    });

    try {
      const discovered = new Map<string, {
        user: XUser;
        sourceTags: Set<string>;
        sourcePostIds: Set<string>;
      }>();
      const searchQueries = buildSearchQueries(tags, tagSearchMode);
      let eligibleDiscoveryCount = 0;
      let existingExcludedDiscoveryCount = 0;
      let pagesFetched = 0;
      let extraPagesFetched = 0;

      for (const searchQuery of searchQueries) {
        let nextToken = "";
        for (let page = 0; page < 10; page++) {
          const response = await searchRecentPosts({
            token,
            query: searchQuery.query,
            maxResults,
            recentSearchDays,
            nextToken,
          });
          const users = new Map(
            (response.includes?.users ?? [])
              .filter((user): user is XUser & {id: string} => {
                return typeof user.id === "string" &&
                  user.id.trim().length > 0;
              })
              .map((user) => [user.id, user]),
          );

          for (const tweet of response.data ?? []) {
            const userId = stringInput(tweet.author_id);
            const postId = stringInput(tweet.id);
            const user = users.get(userId);
            if (!user || !userId) {
              continue;
            }

            const current = discovered.get(userId) ?? {
              user,
              sourceTags: new Set<string>(),
              sourcePostIds: new Set<string>(),
            };
            for (const sourceTag of searchQuery.sourceTags) {
              current.sourceTags.add(sourceTag);
            }
            if (postId) {
              current.sourcePostIds.add(postId);
            }
            if (!discovered.has(userId)) {
              const status = await resolveDiscoveryStatus(userId);
              if (status.isExistingExcluded) {
                existingExcludedDiscoveryCount++;
              } else {
                eligibleDiscoveryCount++;
              }
            }
            discovered.set(userId, current);
          }

          pagesFetched++;
          if (page >= maxPages) {
            extraPagesFetched++;
          }
          nextToken = stringInput(response.meta?.next_token);
          if (!nextToken) {
            break;
          }
          const pageLimit = Math.min(
            10,
            maxPages + Math.ceil(existingExcludedDiscoveryCount / maxResults),
          );
          if (page + 1 >= pageLimit) {
            break;
          }
          if (page + 1 >= maxPages && eligibleDiscoveryCount >= maxResults) {
            break;
          }
        }
      }

      let createdCount = 0;
      let updatedCount = 0;
      let excludedCount = 0;
      let skippedSentCount = 0;
      let skippedExistingExcludedCount = 0;

      for (const [xUserId, item] of discovered.entries()) {
        const candidateRef = db.doc(`candidates/${xUserId}`);
        const [
          candidateSnapshot,
          historySnapshot,
          excludedSnapshot,
        ] = await Promise.all([
          candidateRef.get(),
          db.collection("send_histories")
            .where("xUserId", "==", xUserId)
            .limit(1)
            .get(),
          db.doc(`excluded_accounts/${xUserId}`).get(),
        ]);
        const existing = candidateSnapshot.data() as CandidateData | undefined;
        const username = stringInput(item.user.username);
        const displayName = stringInput(item.user.name);
        const profileText = stringInput(item.user.description);
        const profileUrl = username ? `https://x.com/${username}` : "";
        const sourceTags = mergeStringArrays(
          existing?.sourceTags,
          [...item.sourceTags],
        );
        const sourceTypes = mergeStringArrays(
          existing?.sourceTypes,
          ["post_search"],
        );
        const sourcePostIds = mergeStringArrays(
          existing?.sourcePostIds,
          [...item.sourcePostIds],
          50,
        );
        const syncRunIds = mergeStringArrays(existing?.syncRunIds, [runId], 20);
        const matchedKeywords = matchedExclusionKeywords(
          [username, displayName, profileText].join(" "),
          exclusionKeywords,
        );
        const baseCandidate = {
          candidateId: xUserId,
          xUserId,
          username,
          displayName,
          profileText,
          profileUrl,
          sourceTypes,
          sourceTags,
          sourcePostIds,
          receivesYourDm: item.user.receives_your_dm === true,
          isProtected: item.user.protected === true,
          isVerified: item.user.verified === true,
          lastFoundAt: now,
          lastCheckedAt: now,
          lastSyncRunId: runId,
          syncRunIds,
          updatedAt: now,
          updatedBy: admin.uid,
        };

        if (!historySnapshot.empty || existing?.isSent === true) {
          skippedSentCount++;
          if (candidateSnapshot.exists) {
            const candidatePayload = {
              ...baseCandidate,
              status: "sent",
              isSent: true,
            };
            const batch = db.batch();
            batch.set(candidateRef, candidatePayload, {merge: true});
            setSyncRunItem(batch, runRef, xUserId, {
              action: "sent_updated",
              beforeSnapshot: existing ?? null,
              afterSnapshot: candidatePayload,
              beforeExcludedSnapshot: excludedSnapshot.data() ?? null,
              afterExcludedSnapshot: excludedSnapshot.data() ?? null,
            });
            await batch.commit();
          }
          continue;
        }

        if (excludedSnapshot.exists || existing?.isExcluded === true) {
          skippedExistingExcludedCount++;
          const candidatePayload = {
            ...baseCandidate,
            status: "excluded",
            isExcluded: true,
          };
          const batch = db.batch();
          batch.set(candidateRef, candidatePayload, {merge: true});
          setSyncRunItem(batch, runRef, xUserId, {
            action: "existing_excluded_updated",
            beforeSnapshot: existing ?? null,
            afterSnapshot: candidatePayload,
            beforeExcludedSnapshot: excludedSnapshot.data() ?? null,
            afterExcludedSnapshot: excludedSnapshot.data() ?? null,
          });
          await batch.commit();
          continue;
        }

        if (matchedKeywords.length > 0) {
          excludedCount++;
          const excludedRef = db.doc(`excluded_accounts/${xUserId}`);
          const excludedPayload = {
            candidateId: xUserId,
            xUserId,
            username,
            displayName,
            profileTextSnapshot: profileText,
            reason: "除外キーワードに一致",
            matchedKeywords,
            createdAt: now,
            updatedAt: now,
            createdBy: admin.uid,
          };
          const candidatePayload = {
            ...baseCandidate,
            status: "excluded",
            isExcluded: true,
            isSent: false,
            matchedKeywords,
            excludeMatchedKeywords: matchedKeywords,
            firstFoundAt: existing?.firstFoundAt ?? now,
            createdAt: existing?.createdAt ?? now,
            createdBy: existing?.createdBy ?? admin.uid,
          };
          const batch = db.batch();
          batch.set(excludedRef, excludedPayload, {merge: true});
          batch.set(candidateRef, candidatePayload, {merge: true});
          setSyncRunItem(batch, runRef, xUserId, {
            action: "excluded_by_keyword",
            beforeSnapshot: existing ?? null,
            afterSnapshot: candidatePayload,
            beforeExcludedSnapshot: excludedSnapshot.data() ?? null,
            afterExcludedSnapshot: excludedPayload,
          });
          await batch.commit();
          continue;
        }

        const action: SyncRunItemAction = candidateSnapshot.exists ?
          "updated" :
          "created";
        const candidatePayload = {
          ...baseCandidate,
          status: "candidate",
          isExcluded: false,
          isSent: false,
          firstFoundAt: existing?.firstFoundAt ?? now,
          createdAt: existing?.createdAt ?? now,
          createdBy: existing?.createdBy ?? admin.uid,
        };
        const batch = db.batch();
        batch.set(candidateRef, candidatePayload, {merge: true});
        setSyncRunItem(batch, runRef, xUserId, {
          action,
          beforeSnapshot: existing ?? null,
          afterSnapshot: candidatePayload,
          beforeExcludedSnapshot: excludedSnapshot.data() ?? null,
          afterExcludedSnapshot: excludedSnapshot.data() ?? null,
        });
        await batch.commit();

        if (candidateSnapshot.exists) {
          updatedCount++;
        } else {
          createdCount++;
        }
      }

      const result = {
        createdCount,
        updatedCount,
        excludedCount,
        skippedSentCount,
        skippedExistingExcludedCount,
        totalFoundCount: discovered.size,
        eligibleFoundCount: eligibleDiscoveryCount,
        pagesFetched,
        extraPagesFetched,
        tags,
        tagSearchMode,
        runId,
      };

      await db.collection("function_logs").add({
        functionName: "syncCandidates",
        status: "success",
        input: {
          tags,
          tagSearchMode,
          maxResults,
          maxPages,
          recentSearchDays,
        },
        result,
        createdAt: Timestamp.now(),
        startedAt,
        executedBy: admin.uid,
      });

      await runRef.set({
        status: "completed",
        result,
        completedAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      }, {merge: true});

      return result;
    } catch (error) {
      await runRef.set({
        status: "failed",
        error: functionErrorPayload(error),
        failedAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      }, {merge: true});
      throw error;
    }
  },
);

async function resolveDiscoveryStatus(
  xUserId: string,
): Promise<{isExistingExcluded: boolean}> {
  const [candidateSnapshot, excludedSnapshot] = await Promise.all([
    db.doc(`candidates/${xUserId}`).get(),
    db.doc(`excluded_accounts/${xUserId}`).get(),
  ]);
  const existing = candidateSnapshot.data() as CandidateData | undefined;
  return {
    isExistingExcluded: excludedSnapshot.exists || existing?.isExcluded === true,
  };
}
