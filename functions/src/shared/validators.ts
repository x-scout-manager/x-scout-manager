import type {TagSearchMode} from "./types";

export function normalizeCandidateIds(value: unknown): string[] {
  if (!Array.isArray(value)) {
    return [];
  }

  const candidateIds = value
    .filter((candidateId): candidateId is string => {
      return typeof candidateId === "string" && candidateId.trim().length > 0;
    })
    .map((candidateId) => candidateId.trim());

  return [...new Set(candidateIds)];
}

export function normalizeTags(input: unknown, fallback: unknown): string[] {
  const source = Array.isArray(input) ? input : fallback;
  return normalizeStringList(source)
    .map((tag) => tag.startsWith("#") ? tag : `#${tag}`)
    .filter((tag) => tag.length > 1);
}

export function normalizeTagSearchMode(value: unknown): TagSearchMode {
  if (value === "any" || value === "all") {
    return value;
  }
  return "per_tag";
}

export function normalizeStringList(value: unknown): string[] {
  if (!Array.isArray(value)) {
    return [];
  }

  const values = value
    .filter((item): item is string => typeof item === "string")
    .map((item) => item.trim())
    .filter((item) => item.length > 0);

  return [...new Set(values)];
}

export function stringInput(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

export function boundedInteger(
  input: unknown,
  fallbackInput: unknown,
  min: number,
  max: number,
  defaultValue: number,
): number {
  const source = typeof input === "number" ? input : fallbackInput;
  const value = typeof source === "number" && Number.isFinite(source) ?
    Math.trunc(source) :
    defaultValue;
  return Math.max(min, Math.min(max, value));
}

export function numberValue(value: unknown): number {
  return typeof value === "number" && Number.isFinite(value) ? value : 0;
}

export function positiveNumber(value: unknown): number {
  if (typeof value === "number" && Number.isFinite(value)) {
    return value;
  }
  if (typeof value === "string" && value.trim().length > 0) {
    const parsed = Number(value.trim());
    return Number.isFinite(parsed) ? parsed : 0;
  }
  return 0;
}

export function mergeStringArrays(
  existing: unknown,
  additions: string[],
  limit?: number,
): string[] {
  const merged = [
    ...normalizeStringList(existing),
    ...additions.map((item) => item.trim()).filter((item) => item.length > 0),
  ];
  const unique = [...new Set(merged)];
  return typeof limit === "number" ? unique.slice(0, limit) : unique;
}

export function matchedExclusionKeywords(
  text: string,
  keywords: string[],
): string[] {
  const normalizedText = text.toLowerCase();
  return keywords.filter((keyword) => {
    return normalizedText.includes(keyword.toLowerCase());
  });
}

export function mapRecord(value: unknown): Record<string, unknown> | null {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    return null;
  }
  return value as Record<string, unknown>;
}
