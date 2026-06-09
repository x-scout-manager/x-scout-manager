# Firestore詳細設計

## 1. 目的

Xスカウト支援ツールで利用するFirestoreコレクション、ドキュメントID、フィールド、インデックス、Security Rules方針を定義する。

本設計では、以下を重視する。

- 同一Xユーザーへの重複接触を防止する
- 除外対象を正本として保持する
- 送信履歴と成果証跡を後から追跡できる形で保存する
- 重要な更新はCloud Functions経由に限定する

## 2. 共通ルール

### 2.1 Timestamp

日時フィールドはFirestore `timestamp` 型で保存する。

| フィールド | 用途 |
|---|---|
| createdAt | 作成日時 |
| updatedAt | 更新日時 |
| deletedAt | 論理削除が必要になった場合のみ利用 |

### 2.2 ID方針

| 対象 | ID方針 |
|---|---|
| candidates | `xUserId` |
| excluded_accounts | `xUserId` |
| users | Firebase Auth `uid` |
| send_queues | Firestore auto id |
| send_queues/items | `candidateId` または auto id。初期MVPでは `candidateId` 推奨 |
| send_histories | Firestore auto id |
| templates | Firestore auto id |
| conversions | Firestore auto id |
| function_logs | Firestore auto id |

### 2.3 状態値

候補状態:

```text
candidate / sending / sent / excluded / failed
```

送信キュー状態:

```text
active / completed / canceled
```

送信キュー明細状態:

```text
pending / sending / sent / skipped / excluded / failed
```

成果状態:

```text
draft / reported / paid / canceled
```

## 3. users

### パス

```text
users/{uid}
```

### 用途

管理ユーザーの権限判定に利用する。

### フィールド

| フィールド | 型 | 必須 | 内容 |
|---|---|---|---|
| uid | string | ○ | Firebase Auth UID |
| email | string | - | メールアドレス |
| displayName | string | - | 表示名 |
| role | string | ○ | `admin` |
| isActive | boolean | ○ | 有効ユーザーか |
| createdAt | timestamp | ○ | 作成日時 |
| updatedAt | timestamp | ○ | 更新日時 |

### 備考

Cloud Functionsでは `role = admin` かつ `isActive = true` の場合のみ重要処理を許可する。

## 4. settings

### パス

```text
settings/scout
```

### 用途

スカウト運用に必要な基本設定を保持する。

### フィールド

| フィールド | 型 | 必須 | 内容 |
|---|---|---|---|
| tags | array<string> | ○ | 対象タグ |
| exclusionKeywords | array<string> | ○ | 除外キーワード |
| tagSearchMode | string | ○ | タグ検索条件。`per_tag` / `any` / `all` |
| searchMaxResults | number | ○ | 1回の検索取得件数 |
| searchMaxPages | number | ○ | 最大ページ数 |
| recentSearchDays | number | ○ | 検索対象日数。X API制限内で設定 |
| defaultRewardRate | number | - | 旧仕様互換用。現行UIでは使用しない |
| apiDmEnabled | boolean | ○ | API送信を有効化するか |
| manualSendEnabled | boolean | ○ | API送信失敗時などの手動送信フォールバックを有効化するか |
| createdAt | timestamp | ○ | 作成日時 |
| updatedAt | timestamp | ○ | 更新日時 |
| updatedBy | string | ○ | 更新者UID |

## 5. templates

### パス

```text
templates/{templateId}
```

### 用途

DMテンプレートを保存する。

### フィールド

| フィールド | 型 | 必須 | 内容 |
|---|---|---|---|
| templateId | string | ○ | テンプレートID |
| name | string | ○ | テンプレート名 |
| body | string | ○ | 本文 |
| isActive | boolean | ○ | 利用可能か |
| sortOrder | number | - | 表示順 |
| createdAt | timestamp | ○ | 作成日時 |
| updatedAt | timestamp | ○ | 更新日時 |
| createdBy | string | ○ | 作成者UID |
| updatedBy | string | ○ | 更新者UID |

### 本文変数

初期MVPでは高度な差し込みは行わない。実装する場合は以下に限定する。

```text
{{displayName}}
{{username}}
```

## 6. candidates

### パス

```text
candidates/{candidateId}
```

### ID方針

```text
candidateId = xUserId
```

### フィールド

| フィールド | 型 | 必須 | 内容 |
|---|---|---|---|
| candidateId | string | ○ | 候補ID |
| xUserId | string | ○ | XユーザーID |
| username | string | ○ | Xユーザー名 |
| displayName | string | - | 表示名 |
| profileText | string | - | プロフィール文 |
| profileUrl | string | - | XプロフィールURL |
| sourceTypes | array<string> | ○ | 抽出元種別。初期は `post_search`。追加開発で `profile_search` を追加予定 |
| sourceTags | array<string> | ○ | 抽出元タグ一覧 |
| sourcePostIds | array<string> | - | 抽出元投稿ID一覧 |
| status | string | ○ | `candidate / sending / sent / excluded / failed` |
| excludeMatchedKeywords | array<string> | - | 該当した除外キーワード |
| isExcluded | boolean | ○ | 除外対象か |
| isSent | boolean | ○ | 送信済みか |
| lastSendHistoryId | string | - | 最終送信履歴ID |
| firstFoundAt | timestamp | ○ | 初回抽出日時 |
| lastFoundAt | timestamp | ○ | 最終抽出日時 |
| lastCheckedAt | timestamp | - | 最終確認日時 |
| firstContactedAt | timestamp | - | 初回接触日時 |
| createdAt | timestamp | ○ | 作成日時 |
| updatedAt | timestamp | ○ | 更新日時 |

### 更新方針

- `sourceTags` は重複を除いて追記する
- `sourceTypes` は重複を除いて追記する。初期開発では投稿検索のみを対象にする
- `sourcePostIds` は上限を設ける。初期MVPでは最大50件
- プロフィール文検索は初期開発対象外。追加開発で `sourceTypes = profile_search` として同じ候補モデルへ統合する
- `isExcluded` は `excluded_accounts` を正本として同期する
- `isSent` は `send_histories` 作成時に同期する
- 送信中ロックでは `status = sending` を使用する

## 7. send_queues

### パス

```text
send_queues/{queueId}
send_queues/{queueId}/items/{itemId}
```

### send_queues フィールド

| フィールド | 型 | 必須 | 内容 |
|---|---|---|---|
| queueId | string | ○ | キューID |
| name | string | - | キュー名 |
| status | string | ○ | `active / completed / canceled` |
| candidateIds | array<string> | ○ | 送信対象候補ID |
| currentIndex | number | ○ | 現在位置 |
| totalCount | number | ○ | 総件数 |
| completedCount | number | ○ | 送信済み件数 |
| skippedCount | number | ○ | スキップ件数 |
| failedCount | number | ○ | 失敗件数 |
| createdAt | timestamp | ○ | 作成日時 |
| updatedAt | timestamp | ○ | 更新日時 |
| createdBy | string | ○ | 作成者UID |

### items フィールド

| フィールド | 型 | 必須 | 内容 |
|---|---|---|---|
| itemId | string | ○ | 明細ID |
| queueId | string | ○ | キューID |
| candidateId | string | ○ | 候補ID |
| xUserId | string | ○ | XユーザーID |
| username | string | ○ | Xユーザー名 |
| status | string | ○ | `pending / sending / sent / skipped / excluded / failed` |
| order | number | ○ | 送信順 |
| templateId | string | - | 使用テンプレートID |
| sendHistoryId | string | - | 送信履歴ID |
| sentAt | timestamp | - | 送信日時 |
| errorCode | string | - | エラーコード |
| errorMessage | string | - | エラー内容 |
| createdAt | timestamp | ○ | 作成日時 |
| updatedAt | timestamp | ○ | 更新日時 |

### 注意

`candidateIds` は一覧表示補助として保持する。正確な明細状態は `items` を正とする。

## 8. send_histories

### パス

```text
send_histories/{historyId}
```

### 用途

送信証跡の正本。クライアントから直接作成させず、Cloud Functions経由で作成する。

### フィールド

| フィールド | 型 | 必須 | 内容 |
|---|---|---|---|
| historyId | string | ○ | 履歴ID |
| candidateId | string | ○ | 候補ID |
| xUserId | string | ○ | XユーザーID |
| username | string | ○ | Xユーザー名 |
| displayName | string | - | 表示名 |
| queueId | string | - | 送信キューID |
| queueItemId | string | - | 送信キュー明細ID |
| templateId | string | ○ | テンプレートID |
| templateName | string | ○ | テンプレート名 |
| messageBodySnapshot | string | ○ | 送信本文スナップショット |
| sentAt | timestamp | ○ | 送信日時 |
| sentBy | string | ○ | 送信者UID |
| sendMethod | string | ○ | `api / manual` |
| xDmEventId | string | - | X API側DMイベントID |
| createdAt | timestamp | ○ | 作成日時 |

### 重複判定

送信前に `xUserId` で既存履歴を検索する。初期MVPでは、同一 `xUserId` の履歴が1件でも存在する場合は再送しない。

## 9. excluded_accounts

### パス

```text
excluded_accounts/{xUserId}
```

### 用途

除外対象の正本。

### フィールド

| フィールド | 型 | 必須 | 内容 |
|---|---|---|---|
| xUserId | string | ○ | XユーザーID |
| username | string | ○ | Xユーザー名 |
| displayName | string | - | 表示名 |
| profileTextSnapshot | string | - | 除外時プロフィール文 |
| matchedKeywords | array<string> | - | 該当キーワード |
| reason | string | - | 手動除外理由 |
| source | string | ○ | `keyword / manual / sent_check` |
| createdAt | timestamp | ○ | 作成日時 |
| updatedAt | timestamp | ○ | 更新日時 |
| createdBy | string | - | 作成者UID |

## 10. conversions

### パス

```text
conversions/{conversionId}
```

### 用途

成果発生の証跡。成果報酬の算定はクライアント側で別途行うため、本システムでは報酬率・報酬額を入力/表示しない。

### フィールド

| フィールド | 型 | 必須 | 内容 |
|---|---|---|---|
| conversionId | string | ○ | 成果ID |
| candidateId | string | ○ | 候補ID |
| xUserId | string | ○ | XユーザーID |
| username | string | ○ | Xユーザー名 |
| displayName | string | - | 表示名 |
| sendHistoryId | string | - | 関連送信履歴ID |
| sourceTags | array<string> | ○ | 抽出元タグ |
| firstFoundAt | timestamp | - | 初回抽出日時 |
| firstContactedAt | timestamp | - | 初回接触日時 |
| salesAmount | number | ○ | 対象売上 |
| rewardRate | number | - | 旧仕様互換用。現行UIでは使用しない |
| rewardAmount | number | - | 旧仕様互換用。現行UIでは使用しない |
| evidenceNote | string | - | 補足メモ |
| status | string | ○ | `draft / reported / paid / canceled` |
| createdBy | string | ○ | 登録者UID |
| createdAt | timestamp | ○ | 作成日時 |
| updatedAt | timestamp | ○ | 更新日時 |

### 保存方針

登録時点の候補、送信履歴、対象売上をスナップショットとして保存する。
成果報酬率と成果報酬額は本システムでは計算せず、クライアント側の別管理とする。

## 11. function_logs

### パス

```text
function_logs/{logId}
```

### 用途

Cloud Functions実行結果の簡易ログ。

### フィールド

| フィールド | 型 | 必須 | 内容 |
|---|---|---|---|
| functionName | string | ○ | 関数名 |
| status | string | ○ | `success / failed` |
| requestedBy | string | - | 実行者UID |
| inputSummary | map | - | 入力概要。秘密情報は保存しない |
| resultSummary | map | - | 結果概要 |
| errorCode | string | - | エラーコード |
| errorMessage | string | - | エラー内容 |
| createdAt | timestamp | ○ | 作成日時 |

## 12. candidate_sync_runs

### パス

```text
candidate_sync_runs/{runId}
candidate_sync_runs/{runId}/changes/{candidateId}
```

### 用途

X API候補抽出の実行単位と、解除用の差分を保存する。

### `candidate_sync_runs/{runId}` フィールド

| フィールド | 型 | 必須 | 内容 |
|---|---|---|---|
| runId | string | ○ | 抽出実行ID |
| status | string | ○ | `running / completed / reverted / failed` |
| tags | array<string> | ○ | 実行対象タグ |
| tagSearchMode | string | ○ | タグ検索条件 |
| maxResults | number | ○ | 1ページ件数 |
| maxPages | number | ○ | 最大ページ数 |
| recentSearchDays | number | ○ | 検索対象日数 |
| result | map | - | 実行結果件数 |
| revertResult | map | - | 解除結果件数 |
| createdAt | timestamp | ○ | 実行開始日時 |
| completedAt | timestamp | - | 実行完了日時 |
| revertedAt | timestamp | - | 解除日時 |
| createdBy | string | ○ | 実行者UID |
| revertedBy | string | - | 解除者UID |

### `changes/{candidateId}` フィールド

| フィールド | 型 | 必須 | 内容 |
|---|---|---|---|
| candidateId | string | ○ | 候補ID |
| xUserId | string | ○ | XユーザーID |
| action | string | ○ | `created / updated / excluded_by_keyword / existing_excluded_updated / sent_updated` |
| beforeSnapshot | map/null | ○ | 抽出前のcandidate |
| afterSnapshot | map | ○ | 抽出時に反映したcandidate値 |
| beforeExcludedSnapshot | map/null | ○ | 抽出前のexcluded_accounts |
| afterExcludedSnapshot | map/null | ○ | 抽出時に反映したexcluded_accounts値 |
| revertStatus | string | ○ | `active / reverted` |
| createdAt | timestamp | ○ | 作成日時 |
| revertedAt | timestamp | - | 解除日時 |

### 解除方針

- 新規作成候補は削除する
- 既存更新候補は `beforeSnapshot` に戻す
- 除外キーワード一致で作成した除外データは抽出前状態へ戻す
- 送信履歴または送信キューitemが存在する候補はスキップする
- `lastSyncRunId` が対象runと異なる候補は後続抽出済みとしてスキップする

## 13. インデックス方針

初期MVPで想定する複合インデックスは以下。
単一フィールドの昇順・降順検索はFirestoreの標準単一フィールドインデックスを利用する。

| コレクション | クエリ | 用途 |
|---|---|---|
| candidates | `status asc, updatedAt desc` | 候補一覧 |
| candidates | `isExcluded asc, isSent asc, lastFoundAt desc` | 送信対象候補抽出 |
| candidates | `sourceTags array-contains, lastFoundAt desc` | タグ別確認 |
| send_histories | `xUserId asc, sentAt desc` | 既送信確認 |
| send_queues | `createdBy asc, createdAt desc` | キュー一覧 |
| send_queues/{queueId}/items | `status asc, order asc` | キュー明細 |
| items collection group | `candidateId asc` | 候補が送信キュー明細に存在するかの確認。候補除外/抽出解除の保護条件 |
| conversions | `status asc, createdAt desc` | 成果一覧 |
| function_logs | `functionName asc, createdAt desc` | 実行ログ確認 |
| candidate_sync_runs | `createdAt desc` | 候補抽出履歴 |

## 14. Security Rules方針

### 14.1 基本方針

- 未ログインユーザーは全拒否
- `users/{uid}.role = admin` かつ `isActive = true` のユーザーのみ参照許可
- 重要な作成・更新はCloud Functions経由に限定
- クライアントから直接作成可能な範囲は、初期MVPでは最小にする

### 14.2 クライアント直接操作の許可方針

| コレクション | read | create/update/delete |
|---|---|---|
| users | adminのみ | 原則Functionsまたは管理者初期設定のみ |
| settings | adminのみ | adminのみ。必要に応じてFunctions化 |
| templates | adminのみ | adminのみ |
| candidates | adminのみ | 原則Functionsのみ |
| send_queues | adminのみ | createはFunctionsのみ |
| send_histories | adminのみ | Functionsのみ |
| excluded_accounts | adminのみ | Functionsのみ |
| conversions | adminのみ | Functionsのみ |
| function_logs | adminのみ | Functionsのみ |
| candidate_sync_runs | adminのみ | Functionsのみ |

## 15. 未確定事項

- Firestore Rulesを厳密にFunctions専用にするか、一部設定画面だけクライアント更新を許可するか
- X API DM送信が利用可能な場合の送信失敗リトライ方針
- `sourcePostIds` の保持上限
