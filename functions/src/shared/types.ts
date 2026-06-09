export type AdminUser = {
  uid: string;
  role: "admin";
  isActive: true;
};

export type CandidateData = {
  candidateId?: string;
  xUserId?: string;
  username?: string;
  displayName?: string;
  profileText?: string;
  matchedKeywords?: unknown;
  sourceTags?: unknown;
  sourcePostIds?: unknown;
  sourceTypes?: unknown;
  firstFoundAt?: unknown;
  createdAt?: unknown;
  createdBy?: unknown;
  status?: string;
  isSent?: boolean;
  isExcluded?: boolean;
  firstContactedAt?: unknown;
  lastSyncRunId?: string;
  syncRunIds?: unknown;
};

export type XTweet = {
  id?: string;
  text?: string;
  author_id?: string;
};

export type XUser = {
  id?: string;
  username?: string;
  name?: string;
  description?: string;
  verified?: boolean;
  protected?: boolean;
  receives_your_dm?: boolean;
};

export type XSearchResponse = {
  data?: XTweet[];
  includes?: {
    users?: XUser[];
  };
  meta?: {
    next_token?: string;
    result_count?: number;
  };
  title?: string;
  detail?: string;
  errors?: unknown;
};

export type SendHistoryData = {
  historyId?: string;
  candidateId?: string;
  xUserId?: string;
  username?: string;
  displayName?: string;
  queueId?: string;
  queueItemId?: string;
  templateId?: string;
  templateName?: string;
  messageBodySnapshot?: string;
  sendMethod?: string;
  sentAt?: unknown;
  sentBy?: string;
  xDmEventId?: string;
  createdAt?: unknown;
};

export type SendQueueData = {
  totalCount?: number;
  completedCount?: number;
  failedCount?: number;
};

export type SendQueueItemData = {
  candidateId?: string;
  xUserId?: string;
  username?: string;
  status?: string;
  order?: number;
};

export type TemplateData = {
  name?: string;
  body?: string;
  isActive?: boolean;
};

export type ScoutSettingsData = {
  tags?: unknown;
  exclusionKeywords?: unknown;
  tagSearchMode?: unknown;
  searchMaxResults?: unknown;
  searchMaxPages?: unknown;
  recentSearchDays?: unknown;
};

export type SyncRunItemAction =
  "created" |
  "updated" |
  "excluded_by_keyword" |
  "existing_excluded_updated" |
  "sent_updated";

export type TagSearchMode = "per_tag" | "any" | "all";
