import {Timestamp} from "firebase-admin/firestore";
import {HttpsError} from "firebase-functions/v2/https";
import {db} from "../shared/firebase";
import {numberValue, stringInput} from "../shared/validators";

const senderTokenRef = db.doc("x_api_tokens/sender");

export type SenderXToken = {
  accessToken: string;
  refreshToken: string;
  source: "firestore" | "secret";
};

export type XTokenRefreshResult = {
  accessToken: string;
  refreshToken?: string;
  tokenType?: string;
  scope?: string;
  expiresInSeconds?: number;
};

export async function loadSenderXToken(
  fallback: {accessToken: string; refreshToken: string},
): Promise<SenderXToken> {
  const storedToken = await loadStoredSenderXToken();
  if (storedToken) {
    return storedToken;
  }

  if (!fallback.accessToken || !fallback.refreshToken) {
    throw new HttpsError(
      "unauthenticated",
      "X API認可情報が設定されていません。送信用アカウントのOAuth認可情報をSecretへ設定してください。",
    );
  }

  const now = Timestamp.now();
  await senderTokenRef.set(
    {
      accessToken: fallback.accessToken,
      refreshToken: fallback.refreshToken,
      source: "secret_seed",
      createdAt: now,
      updatedAt: now,
    },
    {merge: true},
  );

  return {
    accessToken: fallback.accessToken,
    refreshToken: fallback.refreshToken,
    source: "secret",
  };
}

export async function loadStoredSenderXToken(): Promise<SenderXToken | null> {
  const snapshot = await senderTokenRef.get();
  const data = snapshot.data();
  if (!snapshot.exists || !data) {
    return null;
  }

  const accessToken = stringInput(data.accessToken);
  const refreshToken = stringInput(data.refreshToken);
  if (!accessToken || !refreshToken) {
    return null;
  }

  return {
    accessToken,
    refreshToken,
    source: "firestore",
  };
}

export async function saveRefreshedSenderXToken(
  currentRefreshToken: string,
  refreshResult: XTokenRefreshResult,
): Promise<SenderXToken> {
  const refreshToken = refreshResult.refreshToken || currentRefreshToken;
  const now = Timestamp.now();
  const expiresInSeconds = numberValue(refreshResult.expiresInSeconds);
  const expiresAt = expiresInSeconds > 0 ?
    Timestamp.fromMillis(now.toMillis() + expiresInSeconds * 1000) :
    null;

  await senderTokenRef.set(
    {
      accessToken: refreshResult.accessToken,
      refreshToken,
      tokenType: refreshResult.tokenType ?? null,
      scope: refreshResult.scope ?? null,
      expiresInSeconds: expiresInSeconds || null,
      expiresAt,
      source: "refresh",
      lastRefreshAt: now,
      updatedAt: now,
    },
    {merge: true},
  );

  return {
    accessToken: refreshResult.accessToken,
    refreshToken,
    source: "firestore",
  };
}
