import {HttpsError} from "firebase-functions/v2/https";
import {defineSecret} from "firebase-functions/params";
import {stringInput} from "../shared/validators";
import {
  loadSenderXToken,
  loadStoredSenderXToken,
  saveRefreshedSenderXToken,
  type SenderXToken,
  type XTokenRefreshResult,
} from "./x_token_store";

export const xUserAccessToken = defineSecret("X_USER_ACCESS_TOKEN");
export const xUserRefreshToken = defineSecret("X_USER_REFRESH_TOKEN");
export const xClientId = defineSecret("X_CLIENT_ID");
export const xClientSecret = defineSecret("X_CLIENT_SECRET");

export type XDirectMessageResult = {
  dmConversationId: string;
  dmEventId: string;
};

export async function sendXDirectMessage(
  recipientUserId: string,
  text: string,
): Promise<XDirectMessageResult> {
  let token = await senderToken();
  let response = await postDirectMessage(
    recipientUserId,
    text,
    token.accessToken,
  );
  if (response.status === 401) {
    const latestToken = await loadStoredSenderXToken();
    if (latestToken && latestToken.accessToken !== token.accessToken) {
      token = latestToken;
      response = await postDirectMessage(
        recipientUserId,
        text,
        token.accessToken,
      );
    }
  }

  if (response.status === 401) {
    const refreshResult = await refreshUserAccessToken(token.refreshToken);
    token = await saveRefreshedSenderXToken(
      token.refreshToken,
      refreshResult,
    );
    response = await postDirectMessage(
      recipientUserId,
      text,
      token.accessToken,
    );
  }

  const responseText = await response.text();
  const responseBody = parseJson(responseText);

  if (!response.ok) {
    const detail = errorDetail(responseBody, responseText);
    throw new HttpsError(
      mapXApiStatus(response.status),
      detail || "X API DM送信に失敗しました。",
    );
  }

  const data = mapRecord(responseBody)?.data;
  const dmConversationId = stringInput(mapRecord(data)?.dm_conversation_id);
  const dmEventId = stringInput(mapRecord(data)?.dm_event_id);
  if (!dmConversationId || !dmEventId) {
    throw new HttpsError(
      "internal",
      "X API DM送信結果を確認できませんでした。",
    );
  }

  return {dmConversationId, dmEventId};
}

async function senderToken(): Promise<SenderXToken> {
  const accessToken =
    xUserAccessToken.value() || process.env.X_USER_ACCESS_TOKEN || "";
  const refreshToken =
    xUserRefreshToken.value() || process.env.X_USER_REFRESH_TOKEN || "";
  return loadSenderXToken({accessToken, refreshToken});
}

function clientCredentials(): {clientId: string; clientSecret: string} {
  const clientId = xClientId.value() || process.env.X_CLIENT_ID;
  const clientSecret = xClientSecret.value() || process.env.X_CLIENT_SECRET;
  if (!clientId || !clientSecret) {
    throw new HttpsError(
      "unauthenticated",
      "X API Client情報が設定されていません。Client IDとClient SecretをSecretへ設定してください。",
    );
  }
  return {clientId, clientSecret};
}

async function postDirectMessage(
  recipientUserId: string,
  text: string,
  token: string,
): Promise<Response> {
  return fetch(
    `https://api.x.com/2/dm_conversations/with/${encodeURIComponent(recipientUserId)}/messages`,
    {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${token}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({text}),
    },
  );
}

async function refreshUserAccessToken(
  refreshToken: string,
): Promise<XTokenRefreshResult> {
  const {clientId, clientSecret} = clientCredentials();
  if (!refreshToken || !clientId || !clientSecret) {
    throw new HttpsError(
      "unauthenticated",
      "X API認可情報が期限切れです。Refresh TokenとClient情報をSecretへ設定してください。",
    );
  }

  const body = new URLSearchParams({
    grant_type: "refresh_token",
    refresh_token: refreshToken,
    client_id: clientId,
  });

  const response = await fetch("https://api.x.com/2/oauth2/token", {
    method: "POST",
    headers: {
      "Authorization": `Basic ${basicCredential(clientId, clientSecret)}`,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body,
  });

  const responseText = await response.text();
  const responseBody = parseJson(responseText);
  if (!response.ok) {
    const detail = errorDetail(responseBody, responseText);
    throw new HttpsError(
      mapXApiStatus(response.status),
      detail || "X APIアクセストークンの更新に失敗しました。",
    );
  }

  const accessToken = stringInput(mapRecord(responseBody)?.access_token);
  const nextRefreshToken = stringInput(mapRecord(responseBody)?.refresh_token);
  const tokenType = stringInput(mapRecord(responseBody)?.token_type);
  const scope = stringInput(mapRecord(responseBody)?.scope);
  const expiresIn = mapRecord(responseBody)?.expires_in;
  if (!accessToken) {
    throw new HttpsError(
      "internal",
      "X APIアクセストークン更新結果を確認できませんでした。",
    );
  }
  return {
    accessToken,
    refreshToken: nextRefreshToken || undefined,
    tokenType: tokenType || undefined,
    scope: scope || undefined,
    expiresInSeconds: typeof expiresIn === "number" ? expiresIn : undefined,
  };
}

function basicCredential(clientId: string, clientSecret: string): string {
  const encodedClientId = encodeURIComponent(clientId);
  const encodedClientSecret = encodeURIComponent(clientSecret);
  return Buffer.from(`${encodedClientId}:${encodedClientSecret}`).toString(
    "base64",
  );
}

function parseJson(value: string): unknown {
  try {
    return value ? JSON.parse(value) : null;
  } catch {
    return null;
  }
}

function mapRecord(value: unknown): Record<string, unknown> | null {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    return null;
  }
  return value as Record<string, unknown>;
}

function errorDetail(body: unknown, fallback: string): string {
  const record = mapRecord(body);
  const detail = stringInput(record?.detail);
  if (detail) {
    return detail;
  }
  const title = stringInput(record?.title);
  if (title) {
    return title;
  }
  const error = stringInput(record?.error_description) ||
    stringInput(record?.error);
  if (error) {
    return error;
  }
  return fallback;
}

function mapXApiStatus(status: number): HttpsError["code"] {
  if (status === 400) {
    return "invalid-argument";
  }
  if (status === 401) {
    return "unauthenticated";
  }
  if (status === 403) {
    return "permission-denied";
  }
  if (status === 404) {
    return "not-found";
  }
  if (status === 429) {
    return "resource-exhausted";
  }
  return "internal";
}
