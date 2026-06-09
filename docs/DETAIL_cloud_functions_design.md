# Cloud Functions詳細設計

## 1. 目的

Cloud Functions for Firebaseで実装するサーバーサイド処理の入出力、権限、バリデーション、状態遷移、エラー方針を定義する。

本システムでは、X API連携、送信履歴作成、成果証跡作成、除外対象更新などの重要処理をCloud Functionsに集約する。

## 2. 共通方針

### 2.0 Runtime

Cloud FunctionsはNode.js 22 runtimeを利用する。

### 2.1 関数形式

初期MVPでは callable functions を利用する。

Flutter WebからはRepository経由で呼び出し、ViewやViewModelから直接Callableを呼ばない。

### 2.2 認証・権限

全関数で以下を実施する。

1. `request.auth` の存在確認
2. `users/{uid}` の取得
3. `role = admin` の確認
4. `isActive = true` の確認

権限がない場合は処理を実行しない。

### 2.3 エラーコード

| code | 内容 |
|---|---|
| unauthenticated | 未ログイン |
| permission-denied | 管理者権限なし |
| invalid-argument | 入力不正 |
| not-found | 対象データなし |
| already-exists | 重複データあり |
| failed-precondition | 状態不整合 |
| resource-exhausted | API制限 |
| unavailable | 外部APIまたはFirebase一時障害 |
| internal | 想定外エラー |

### 2.4 ログ

主要関数は `function_logs` に結果を保存する。

秘密情報、アクセストークン、DM本文の過剰なログ出力は禁止する。

### 2.5 ファイル構成

Cloud Functionsの処理本体は、`functions/src/index.ts` に直接集約しない。
`index.ts` はCallable Functionsのexport集約を主責務とし、処理本体は責務別ファイルへ配置する。

```text
functions/src/
  index.ts
  app.ts
  auth/
    require_admin.ts
  shared/
    firebase.ts
    validators.ts
    errors.ts
    types.ts
  x/
    x_search.ts
  candidates/
    sync_candidates.ts
    revert_candidate_sync_run.ts
    candidate_sync_run_repository.ts
  send_queue/
    create_send_queue.ts
    mark_as_manually_sent.ts
  exclusions/
    exclude_candidate.ts
    restore_candidate.ts
  conversions/
    create_conversion.ts
```

以後追加するFunctionsも、機能別ディレクトリへ処理本体を置き、`index.ts` からexportする。

## 3. 共通ヘルパー

| ヘルパー | 役割 |
|---|---|
| requireAdmin(context) | 認証済み管理者確認 |
| assertNonEmptyString(value, name) | 文字列入力検証 |
| normalizeTag(tag) | タグ整形 |
| matchExclusionKeywords(profileText, keywords) | 除外キーワード判定 |
| buildMessageBody(template, candidate) | DM本文生成 |
| createFunctionLog(payload) | 実行ログ保存 |
| mapXApiError(error) | X APIエラー変換 |

## 4. syncCandidates

### 概要

設定されたタグをもとにX APIで投稿検索を行い、投稿主アカウントを候補として保存する。

### input

| フィールド | 型 | 必須 | 内容 |
|---|---|---|---|
| tags | array<string> | - | 指定がある場合はこのタグで検索 |
| maxResults | number | - | 1ページ件数 |
| maxPages | number | - | 最大ページ数 |

指定がない値は `settings/scout` を利用する。
タグ検索条件は `settings/scout.tagSearchMode` を利用する。

- `per_tag`: タグごとに個別検索する。既存挙動。
- `any`: 複数タグをOR条件でまとめて検索する。
- `all`: 複数タグをAND条件でまとめて検索する。

### output

| フィールド | 型 | 内容 |
|---|---|---|
| createdCount | number | 新規候補数 |
| updatedCount | number | 更新候補数 |
| excludedCount | number | 除外保存数 |
| skippedSentCount | number | 既送信のためスキップした件数 |
| tags | array<string> | 実行対象タグ |
| tagSearchMode | string | 実行時のタグ検索条件 |
| runId | string | 抽出実行ID |

### 処理

1. 管理者権限を確認
2. `settings/scout` を取得
3. 対象タグ、タグ検索条件、取得件数、最大ページ数を決定
4. X APIで投稿検索
5. 投稿主ユーザー情報を取得
6. `candidates/{xUserId}` を確認
7. `send_histories` を `xUserId` で確認
8. `excluded_accounts/{xUserId}` を確認
9. プロフィール文に除外キーワードを適用
10. 除外対象は `excluded_accounts` に保存し、`candidates` にも `status = excluded` として反映
11. 既送信対象は候補化しない。必要に応じて既存candidateを `isSent = true` に更新
12. 候補は `candidates` に upsert
13. `candidate_sync_runs/{runId}` と配下changesに解除用差分を保存
14. `function_logs` に結果保存

### 注意

- X APIのページングは上限を必ず設ける
- 同一ユーザーは `xUserId` で統合する
- X API失敗時は部分成功を許可するか要検討。初期MVPでは関数単位で失敗扱い
- X API Bearer TokenはSecret Manager `X_BEARER_TOKEN` で保持し、Flutter Webへ渡さない
- 2026-05-14実装では `sourcePostIds` は最大50件まで保持する

## 5. revertCandidateSyncRun

### 概要

候補抽出run単位で、抽出時に作成・更新した候補を抽出前の状態へ戻す。

### input

| フィールド | 型 | 必須 | 内容 |
|---|---|---|---|
| runId | string | ○ | `candidate_sync_runs/{runId}` |

### output

| フィールド | 型 | 内容 |
|---|---|---|
| runId | string | 解除対象run |
| revertedCount | number | 既存候補を抽出前状態へ戻した件数 |
| deletedCount | number | 抽出で新規作成された候補を削除した件数 |
| skippedCount | number | 保護条件によりスキップした件数 |

### 処理

1. 管理者権限を確認
2. `candidate_sync_runs/{runId}` が `completed` であることを確認
3. 配下changesを取得
4. 送信履歴が存在する候補はスキップ
5. 送信キューitemが存在する候補はスキップ
6. `lastSyncRunId` が対象runと異なる候補は後続抽出済みとしてスキップ
7. `beforeSnapshot = null` の候補は削除
8. `beforeSnapshot` がある候補は抽出前状態へ戻す
9. 除外データも `beforeExcludedSnapshot` に基づいて戻す
10. runを `status = reverted` に更新し、解除結果を保存する

## 6. createSendQueue

### input

| フィールド | 型 | 必須 | 内容 |
|---|---|---|---|
| candidateIds | array<string> | ○ | キューに追加する候補ID |
| name | string | - | キュー名 |

### output

| フィールド | 型 | 内容 |
|---|---|---|
| queueId | string | 作成したキューID |
| totalCount | number | キュー化した件数 |
| skippedCount | number | 除外・既送信等で除いた件数 |

### 処理

1. 管理者権限を確認
2. `candidateIds` の重複を除去
3. 各候補を取得
4. 以下は除外
   - `status != candidate`
   - `isSent = true`
   - `isExcluded = true`
   - `send_histories` に既存履歴あり
   - `excluded_accounts` に存在
5. `send_queues` を作成
6. `send_queues/{queueId}/items/{candidateId}` を作成
7. `queueId` を返却

### バリデーション

- `candidateIds` は1件以上
- 初期MVPでは一度に最大100件まで

## 6. sendDirectMessage

### 概要

X APIで1候補者にDMを送信する。確認なし一括送信には使用しない。

### input

| フィールド | 型 | 必須 | 内容 |
|---|---|---|---|
| queueId | string | ○ | キューID |
| itemId | string | ○ | キュー明細ID |
| templateId | string | ○ | テンプレートID |
| messageBody | string | - | 画面確認済み本文。未指定の場合はテンプレートから生成 |

### output

| フィールド | 型 | 内容 |
|---|---|---|
| historyId | string | 送信履歴ID |
| xDmEventId | string | X API側イベントID |

### 処理

1. 管理者権限を確認
2. `settings/scout.apiDmEnabled = true` を確認
3. transaction開始
4. queue item、candidate、templateを取得
5. 以下の場合は中断
   - candidate.status が `sent / excluded / sending`
   - item.status が `sent / excluded / sending`
   - `send_histories` に同一 `xUserId` の履歴あり
   - `excluded_accounts/{xUserId}` が存在
6. candidate.status と item.status を `sending` に更新
7. transaction終了
8. X APIでDM送信
9. 成功時transaction
   - `send_histories` 作成
   - `candidates.status = sent`
   - `candidates.isSent = true`
   - `candidates.firstContactedAt` 設定
   - `send_queues/items.status = sent`
   - `send_queues.completedCount` increment
10. 失敗時transaction
   - `candidates.status = failed`
   - `send_queues/items.status = failed`
   - `errorCode / errorMessage` 保存
   - `send_queues.failedCount` increment

### 重要

X API呼び出しはtransaction外で行う。transaction内では送信ロックのみ行う。

## 7. markAsManuallySent

### 概要

管理者がX上で手動送信した後、送信済みとして履歴を保存する。

### input

| フィールド | 型 | 必須 | 内容 |
|---|---|---|---|
| queueId | string | ○ | キューID |
| itemId | string | ○ | キュー明細ID |
| templateId | string | ○ | テンプレートID |
| messageBody | string | ○ | 実際に送信した本文 |

### output

| フィールド | 型 | 内容 |
|---|---|---|
| historyId | string | 作成した送信履歴ID |

### 処理

1. 管理者権限を確認
2. transaction開始
3. queue item、candidate、templateを取得
4. 既送信、除外、sending状態を確認
5. `send_histories` に同一 `xUserId` の履歴がないことを確認
6. `send_histories` を `sendMethod = manual` で作成
7. candidateを `sent` に更新
8. queue itemを `sent` に更新
9. queueの `completedCount` を更新
10. transaction終了

## 8. excludeCandidate

### input

| フィールド | 型 | 必須 | 内容 |
|---|---|---|---|
| candidateId | string | ○ | 候補ID |
| reason | string | - | 除外理由 |

### 処理

1. 管理者権限を確認
2. candidateを取得
3. `excluded_accounts/{xUserId}` を作成または更新
4. candidateを `status = excluded`、`isExcluded = true` に更新
5. 未送信queue itemがあれば `excluded` に更新

## 9. restoreCandidate

### input

| フィールド | 型 | 必須 | 内容 |
|---|---|---|---|
| candidateId | string | ○ | 候補ID |

### 処理

1. 管理者権限を確認
2. candidateを取得
3. `excluded_accounts/{xUserId}` を削除または無効化
4. 既送信履歴がなければ candidateを `candidate`、`isExcluded = false` に戻す
5. 既送信履歴がある場合は `sent` を維持する

## 10. createConversion

### input

| フィールド | 型 | 必須 | 内容 |
|---|---|---|---|
| candidateId | string | ○ | 候補ID |
| sendHistoryId | string | - | 送信履歴ID |
| salesAmount | number | ○ | 対象売上 |
| evidenceNote | string | - | 補足メモ |

### output

| フィールド | 型 | 内容 |
|---|---|---|
| conversionId | string | 成果ID |

### 処理

1. 管理者権限を確認
2. candidateを取得
3. sendHistoryId指定がある場合は履歴を取得
4. candidate、send_history、対象売上をスナップショットとして保存
5. `conversions` 作成
6. 成果報酬率・成果報酬額は保存しない。算定はクライアント側で別途行う

## 11. skipQueueItem

基本設計では未定義だが、UI操作としてスキップが存在するためMVPで実装対象とする。

### input

| フィールド | 型 | 必須 | 内容 |
|---|---|---|---|
| queueId | string | ○ | キューID |
| itemId | string | ○ | キュー明細ID |

### 処理

1. 管理者権限を確認
2. item.status が `pending / failed` の場合のみ `skipped` に更新
3. `send_queues.skippedCount` を更新

## 13. 実装順序

1. 共通認証ヘルパー
2. settings / users 初期読み取り
3. markAsManuallySent
4. createSendQueue
5. excludeCandidate / restoreCandidate
6. createConversion
7. syncCandidates
8. sendDirectMessage

X API DM送信は基本送信手段として実装し、手動送信支援はAPI失敗時や運用停止時のフォールバックとして残す。
