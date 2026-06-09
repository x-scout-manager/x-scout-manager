import {HttpsError} from "firebase-functions/v2/https";

export function functionErrorPayload(
  error: unknown,
): Record<string, unknown> {
  if (error instanceof HttpsError) {
    return {
      code: error.code,
      message: error.message,
    };
  }
  if (error instanceof Error) {
    return {
      message: error.message,
      name: error.name,
    };
  }
  return {
    message: String(error),
  };
}
