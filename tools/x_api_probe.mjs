#!/usr/bin/env node

import {createHash, randomBytes} from "node:crypto";
import {createServer} from "node:http";
import {readFileSync, existsSync} from "node:fs";
import {resolve} from "node:path";

const API_ORIGIN = "https://api.x.com";
const AUTH_URL = "https://x.com/i/oauth2/authorize";
const TOKEN_URL = `${API_ORIGIN}/2/oauth2/token`;
const DEFAULT_SCOPES = "tweet.read users.read dm.read dm.write offline.access";
const TOKEN_AUTH_METHODS = new Set(["basic", "body", "public"]);

loadEnv(".env.x-api.local");

const command = process.argv[2] ?? "help";
const args = process.argv.slice(3);

try {
  switch (command) {
    case "oauth-url":
      printOauthUrl();
      break;
    case "oauth-local":
      await runLocalOauth();
      break;
    case "env-check":
      printEnvCheck();
      break;
    case "token":
      await exchangeToken(args[0], args[1]);
      break;
    case "callback-code":
      printCallbackCode(args[0]);
      break;
    case "refresh":
      await refreshToken(args[0]);
      break;
    case "search":
      await searchPosts(args.join(" ").trim());
      break;
    case "user":
      await lookupUser(args[0]);
      break;
    case "dm":
      await sendDm(args[0], args.slice(1).join(" ").trim());
      break;
    default:
      printHelp();
  }
} catch (error) {
  console.error(error instanceof Error ? error.message : error);
  process.exitCode = 1;
}

function loadEnv(fileName) {
  const path = resolve(process.cwd(), fileName);
  if (!existsSync(path)) {
    return;
  }

  const lines = readFileSync(path, "utf8").split(/\r?\n/);
  for (const line of lines) {
    const trimmed = line.trim();
    if (trimmed.length === 0 || trimmed.startsWith("#")) {
      continue;
    }

    const separator = trimmed.indexOf("=");
    if (separator === -1) {
      continue;
    }

    const key = trimmed.slice(0, separator).trim();
    const value = trimmed.slice(separator + 1).trim();
    if (!(key in process.env)) {
      process.env[key] = unquote(value);
    }
  }
}

function unquote(value) {
  if (
    (value.startsWith("\"") && value.endsWith("\"")) ||
    (value.startsWith("'") && value.endsWith("'"))
  ) {
    return value.slice(1, -1);
  }
  return value;
}

function printOauthUrl() {
  const clientId = requiredEnv("X_CLIENT_ID");
  const redirectUri = requiredEnv("X_REDIRECT_URI");
  const scopes = process.env.X_SCOPES ?? DEFAULT_SCOPES;
  const state = base64Url(randomBytes(24));
  const codeVerifier = base64Url(randomBytes(48));
  const codeChallenge = base64Url(createHash("sha256").update(codeVerifier).digest());
  const params = new URLSearchParams({
    response_type: "code",
    client_id: clientId,
    redirect_uri: redirectUri,
    scope: scopes,
    state,
    code_challenge: codeChallenge,
    code_challenge_method: "S256",
  });

  console.log("Open this URL in the X account that will authorize the app:");
  console.log(`${AUTH_URL}?${params.toString()}`);
  console.log("");
  console.log("Save these values until token exchange is complete:");
  console.log(`state=${state}`);
  console.log(`code_verifier=${codeVerifier}`);
}

async function runLocalOauth() {
  const redirectUri = process.env.X_LOCAL_REDIRECT_URI ?? "http://127.0.0.1:8765/callback";
  const url = new URL(redirectUri);
  const expectedPath = url.pathname;
  const state = base64Url(randomBytes(24));
  const codeVerifier = base64Url(randomBytes(48));
  const codeChallenge = base64Url(createHash("sha256").update(codeVerifier).digest());
  const authUrl = buildAuthorizeUrl({
    clientId: requiredEnv("X_CLIENT_ID"),
    redirectUri,
    scopes: process.env.X_SCOPES ?? DEFAULT_SCOPES,
    state,
    codeChallenge,
  });

  const server = createServer(async (request, response) => {
    try {
      const requestUrl = new URL(request.url ?? "/", redirectUri);
      if (requestUrl.pathname !== expectedPath) {
        response.writeHead(404);
        response.end("Not found");
        return;
      }

      const actualState = requestUrl.searchParams.get("state");
      const code = requestUrl.searchParams.get("code");
      const error = requestUrl.searchParams.get("error");

      if (error) {
        throw new Error(`OAuth error: ${error}`);
      }
      if (actualState !== state) {
        throw new Error("OAuth state mismatch.");
      }
      if (!code) {
        throw new Error("Callback URL does not include code.");
      }

      response.writeHead(200, {"content-type": "text/plain; charset=utf-8"});
      response.end("X OAuth callback received. You can close this tab.");
      server.close();

      console.log("Callback received. Exchanging code for token...");
      await exchangeToken(code, codeVerifier, redirectUri);
    } catch (error) {
      response.writeHead(500, {"content-type": "text/plain; charset=utf-8"});
      response.end(error instanceof Error ? error.message : String(error));
      server.close();
      throw error;
    }
  });

  await new Promise((resolveServer) => {
    server.listen(Number(url.port), url.hostname, resolveServer);
  });

  console.log("Local callback server started.");
  console.log(`Callback URL: ${redirectUri}`);
  console.log("");
  console.log("Add this Callback URL to X Developer Portal if it is not registered yet.");
  console.log("");
  console.log("Open this URL and approve the app:");
  console.log(authUrl);
  console.log("");
  console.log("Waiting for callback...");
}

function buildAuthorizeUrl({clientId, redirectUri, scopes, state, codeChallenge}) {
  const params = new URLSearchParams({
    response_type: "code",
    client_id: clientId,
    redirect_uri: redirectUri,
    scope: scopes,
    state,
    code_challenge: codeChallenge,
    code_challenge_method: "S256",
  });

  return `${AUTH_URL}?${params.toString()}`;
}

function printEnvCheck() {
  const redirectUri = process.env.X_REDIRECT_URI ?? "";
  const scopes = process.env.X_SCOPES ?? DEFAULT_SCOPES;
  const method = tokenAuthMethod();

  console.log(`X_CLIENT_ID=${redactedPresence(process.env.X_CLIENT_ID)}`);
  console.log(`X_CLIENT_SECRET=${redactedPresence(process.env.X_CLIENT_SECRET)}`);
  console.log(`X_BEARER_TOKEN=${redactedPresence(process.env.X_BEARER_TOKEN)}`);
  console.log(`X_USER_ACCESS_TOKEN=${redactedPresence(process.env.X_USER_ACCESS_TOKEN)}`);
  console.log(`X_REDIRECT_URI=${redirectUri}`);
  console.log(`X_SCOPES=${scopes}`);
  console.log(`X_TOKEN_AUTH_METHOD=${method}`);
}

function redactedPresence(value) {
  if (!value) {
    return "missing";
  }
  return `set (${value.length} chars)`;
}


function printCallbackCode(callbackUrl) {
  if (!callbackUrl) {
    throw new Error("Usage: node tools/x_api_probe.mjs callback-code '<callback_url>'");
  }

  const url = new URL(callbackUrl);
  const code = url.searchParams.get("code");
  const state = url.searchParams.get("state");

  if (!code) {
    throw new Error("The callback URL does not contain a code query parameter.");
  }

  console.log(`state=${state ?? ""}`);
  console.log(`code=${code}`);
}

async function exchangeToken(code, codeVerifier, redirectUri = requiredEnv("X_REDIRECT_URI")) {
  if (!code || !codeVerifier) {
    throw new Error("Usage: node tools/x_api_probe.mjs token <authorization_code> <code_verifier>");
  }

  const body = new URLSearchParams({
    grant_type: "authorization_code",
    code,
    redirect_uri: redirectUri,
    code_verifier: codeVerifier,
    client_id: requiredEnv("X_CLIENT_ID"),
  });
  addClientSecretForBodyAuth(body);

  const response = await fetch(TOKEN_URL, {
    method: "POST",
    headers: tokenHeaders(),
    body,
  });

  await printResponse(response);
}

async function refreshToken(refreshTokenValue) {
  if (!refreshTokenValue) {
    throw new Error("Usage: node tools/x_api_probe.mjs refresh <refresh_token>");
  }

  const body = new URLSearchParams({
    grant_type: "refresh_token",
    refresh_token: refreshTokenValue,
    client_id: requiredEnv("X_CLIENT_ID"),
  });
  addClientSecretForBodyAuth(body);

  const response = await fetch(TOKEN_URL, {
    method: "POST",
    headers: tokenHeaders(),
    body,
  });

  await printResponse(response);
}

async function searchPosts(query) {
  if (!query) {
    throw new Error("Usage: node tools/x_api_probe.mjs search \"#keyword -is:retweet\"");
  }

  const params = new URLSearchParams({
    query,
    max_results: "10",
    expansions: "author_id",
    "tweet.fields": "id,text,author_id,created_at,conversation_id,lang,public_metrics",
    "user.fields": "id,username,name,description,protected,verified,public_metrics,receives_your_dm",
  });

  const response = await fetch(`${API_ORIGIN}/2/tweets/search/recent?${params.toString()}`, {
    headers: bearerHeaders(requiredEnv("X_BEARER_TOKEN")),
  });

  await printResponse(response);
}

async function lookupUser(value) {
  if (!value) {
    throw new Error("Usage: node tools/x_api_probe.mjs user <username_or_user_id>");
  }

  const fields = "id,username,name,description,protected,verified,public_metrics,receives_your_dm";
  const isId = /^\d+$/.test(value);
  const path = isId ? `/2/users/${value}` : `/2/users/by/username/${stripAt(value)}`;
  const params = new URLSearchParams({"user.fields": fields});
  const token = process.env.X_USER_ACCESS_TOKEN || requiredEnv("X_BEARER_TOKEN");

  const response = await fetch(`${API_ORIGIN}${path}?${params.toString()}`, {
    headers: bearerHeaders(token),
  });

  await printResponse(response);
}

async function sendDm(participantId, text) {
  if (!participantId || !text) {
    throw new Error("Usage: node tools/x_api_probe.mjs dm <recipient_user_id> \"message text\"");
  }

  const response = await fetch(
    `${API_ORIGIN}/2/dm_conversations/with/${participantId}/messages`,
    {
      method: "POST",
      headers: {
        ...bearerHeaders(requiredEnv("X_USER_ACCESS_TOKEN")),
        "content-type": "application/json",
      },
      body: JSON.stringify({text}),
    },
  );

  await printResponse(response);
}

function tokenHeaders() {
  const headers = {
    "content-type": "application/x-www-form-urlencoded",
  };
  const secret = process.env.X_CLIENT_SECRET;
  if (tokenAuthMethod() === "basic" && secret) {
    const clientId = encodeURIComponent(requiredEnv("X_CLIENT_ID"));
    const clientSecret = encodeURIComponent(secret);
    const credentials = Buffer.from(`${clientId}:${clientSecret}`).toString("base64");
    headers.authorization = `Basic ${credentials}`;
  }
  return headers;
}

function addClientSecretForBodyAuth(body) {
  const secret = process.env.X_CLIENT_SECRET;
  if (tokenAuthMethod() === "body" && secret) {
    body.set("client_secret", secret);
  }
}

function tokenAuthMethod() {
  const method = process.env.X_TOKEN_AUTH_METHOD ?? "basic";
  if (!TOKEN_AUTH_METHODS.has(method)) {
    throw new Error("X_TOKEN_AUTH_METHOD must be one of: basic, body, public.");
  }
  return method;
}

function bearerHeaders(token) {
  return {
    authorization: `Bearer ${token}`,
  };
}

async function printResponse(response) {
  const text = await response.text();
  console.log(`status=${response.status}`);
  console.log(`x-rate-limit-limit=${response.headers.get("x-rate-limit-limit") ?? ""}`);
  console.log(`x-rate-limit-remaining=${response.headers.get("x-rate-limit-remaining") ?? ""}`);
  console.log(`x-rate-limit-reset=${response.headers.get("x-rate-limit-reset") ?? ""}`);
  console.log("");

  try {
    console.log(JSON.stringify(JSON.parse(text), null, 2));
  } catch {
    console.log(text);
  }
}

function requiredEnv(name) {
  const value = process.env[name];
  if (!value) {
    throw new Error(`${name} is required. Copy .env.x-api.example to .env.x-api.local and fill it.`);
  }
  return value;
}

function stripAt(value) {
  return value.startsWith("@") ? value.slice(1) : value;
}

function base64Url(buffer) {
  return buffer
    .toString("base64")
    .replaceAll("+", "-")
    .replaceAll("/", "_")
    .replaceAll("=", "");
}

function printHelp() {
  console.log(`X API probe

Usage:
  node tools/x_api_probe.mjs oauth-url
  node tools/x_api_probe.mjs oauth-local
  node tools/x_api_probe.mjs env-check
  node tools/x_api_probe.mjs callback-code '<callback_url>'
  node tools/x_api_probe.mjs token <authorization_code> <code_verifier>
  node tools/x_api_probe.mjs refresh <refresh_token>
  node tools/x_api_probe.mjs search "#keyword -is:retweet"
  node tools/x_api_probe.mjs user <username_or_user_id>
  node tools/x_api_probe.mjs dm <recipient_user_id> "message text"

Env file:
  Copy .env.x-api.example to .env.x-api.local and fill values.
`);
}
