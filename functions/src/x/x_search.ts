import {Timestamp} from "firebase-admin/firestore";
import {defineSecret} from "firebase-functions/params";
import {HttpsError} from "firebase-functions/v2/https";
import {db} from "../shared/firebase";
import type {TagSearchMode, XSearchResponse} from "../shared/types";

export const xBearerToken = defineSecret("X_BEARER_TOKEN");

export function buildSearchQueries(
  tags: string[],
  mode: TagSearchMode,
): Array<{query: string; sourceTags: string[]}> {
  const terms = tags.map((tag) => xSearchTerm(tag));
  if (mode === "any") {
    return [{
      query: `(${terms.join(" OR ")}) -is:retweet`,
      sourceTags: tags,
    }];
  }
  if (mode === "all") {
    return [{
      query: `${terms.join(" ")} -is:retweet`,
      sourceTags: tags,
    }];
  }
  return tags.map((tag, index) => ({
    query: `${terms[index]} -is:retweet`,
    sourceTags: [tag],
  }));
}

export function xApiBearerToken(): string {
  try {
    const secretValue = xBearerToken.value();
    if (secretValue.trim().length > 0) {
      return secretValue.trim();
    }
  } catch (_) {
    // Local probes and emulators can use process.env instead of Secret Manager.
  }

  const envValue = process.env.X_BEARER_TOKEN;
  if (envValue && envValue.trim().length > 0) {
    return envValue.trim();
  }

  throw new HttpsError("failed-precondition", "X_BEARER_TOKEN が設定されていません。");
}

export async function searchRecentPosts({
  token,
  query,
  maxResults,
  recentSearchDays,
  nextToken,
}: {
  token: string;
  query: string;
  maxResults: number;
  recentSearchDays: number;
  nextToken: string;
}): Promise<XSearchResponse> {
  const params = new URLSearchParams({
    query,
    max_results: String(maxResults),
    expansions: "author_id",
    "tweet.fields": "id,text,author_id,created_at,conversation_id,lang,public_metrics",
    "user.fields": "id,username,name,description,protected,verified,public_metrics,receives_your_dm",
    start_time: new Date(Date.now() - recentSearchDays * 24 * 60 * 60 * 1000).toISOString(),
  });

  if (nextToken) {
    params.set("next_token", nextToken);
  }

  const response = await fetch(
    `https://api.x.com/2/tweets/search/recent?${params.toString()}`,
    {
      headers: {
        authorization: `Bearer ${token}`,
      },
    },
  );
  const payload = await response.json() as XSearchResponse;

  if (!response.ok) {
    await db.collection("function_logs").add({
      functionName: "syncCandidates",
      status: "error",
      error: {
        httpStatus: response.status,
        title: payload.title ?? null,
        detail: payload.detail ?? null,
        errors: payload.errors ?? null,
      },
      createdAt: Timestamp.now(),
    });
    throw new HttpsError(
      "failed-precondition",
      `X API検索に失敗しました。status=${response.status}`,
    );
  }

  return payload;
}

function xSearchTerm(value: string): string {
  const trimmed = value.trim();
  if (!/\s/.test(trimmed)) {
    return trimmed;
  }
  return `"${trimmed.replace(/"/g, "\\\"")}"`;
}
