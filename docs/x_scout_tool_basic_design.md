# Xスカウト支援ツール 基本設計書

## 1. 文書概要

本書は、Xスカウト支援ツールの要件定義をもとに、実装に必要な基本設計を整理することを目的とする。

本システムは、Flutter Web による管理画面、Firebase Authentication による認証、Firestore によるデータ管理、Cloud Functions for Firebase による X API 連携を中心に構築する。

DM送信については、自動一括送信ではなく、候補者をチェック選択して送信キューに追加し、管理者が1件ずつ内容を確認して送信操作を行う「チェック選択式・送信キュー型の個別DM送信支援機能」とする。

詳細設計は以下を正とする。

- `docs/DETAIL_firestore_design.md`
- `docs/DETAIL_cloud_functions_design.md`
- `docs/DETAIL_flutter_screen_design.md`
- `docs/DETAIL_x_api_verification.md`
- `docs/MVP_implementation_plan.md`

---

## 2. システム全体構成

```text
[管理者]
   ↓
[Flutter Web 管理画面]
   ↓
[Firebase Authentication]
   ↓
[Firestore]
   ↓
[Cloud Functions for Firebase]
   ↓
[X API]
```

## 3. 構成要素

| 区分 | 技術 | 役割 |
|---|---|---|
| 管理画面 | Flutter Web | 候補一覧、詳細、送信キュー、履歴、設定などの画面を提供する |
| フロント言語 | Dart | Flutter Web の実装言語 |
| 認証 | Firebase Authentication | 管理者ログインを管理する |
| DB | Firestore | 候補、送信履歴、テンプレート、設定、成果証跡を保存する |
| サーバー処理 | Cloud Functions for Firebase | X API連携、候補抽出、送信履歴登録、DM送信処理を行う |
| Functions言語 | TypeScript | Cloud Functions の実装言語 |
| ホスティング | Firebase Hosting | Flutter Web を配信する |
| 外部API | X API | 投稿検索、ユーザー情報取得、DM送信を行う |

---

## 4. 基本方針

- X APIのアクセストークンやシークレットはFlutter側に保持しない
- X API連携はCloud Functions側に集約する
- Firestoreへの通常表示用データはFlutterから取得する
- 重要な更新処理はCloud Functions経由で行う
- 送信履歴、成果証跡は改ざんされにくい形で保存する
- DMは候補者ごとに管理者が確認し、1件ずつ送信操作を行う
- Google、Firebase、GitHub、X Developer関連資産は `docs/account_repository_handover_policy.md` に従い、クライアント所有または案件専用アカウントで管理する

---

## 5. 画面一覧

| No | 画面名 | パス案 | 概要 |
|---|---|---|---|
| 1 | ログイン画面 | /login | 管理者ログインを行う |
| 2 | ダッシュボード | /dashboard | 候補数、送信済み数、除外数などを表示する |
| 3 | タグ設定画面 | /settings/tags | 検索対象タグを設定する |
| 4 | 除外キーワード設定画面 | /settings/exclusions | 除外判定用キーワードを設定する |
| 5 | 候補一覧画面 | /candidates | 抽出された候補を一覧表示する |
| 6 | 候補詳細画面 | /candidates/:id | 候補の詳細情報を表示する |
| 7 | 送信キュー画面 | /send-queue | チェック選択された候補を1件ずつ確認・送信する |
| 8 | 送信履歴画面 | /send-histories | DM送信履歴を表示する |
| 9 | 除外リスト画面 | /excluded-accounts | 除外対象アカウントを表示する |
| 10 | テンプレート画面 | /templates | DMテンプレートを管理する |
| 11 | 成果記録画面 | /conversions | 初期運用では非表示。必要時に成約記録/成果メモとして再設計する |
| 12 | システム設定画面 | /settings | 基本設定を管理する |

---

## 6. 候補一覧画面設計

### 目的

抽出された候補アカウントを一覧で確認し、送信対象を選択する。

### 表示項目

| 項目 | 内容 |
|---|---|
| チェック | 送信キュー追加対象を選択する |
| 表示名 | Xの表示名 |
| ユーザー名 | @username |
| プロフィール文 | 一部を省略表示 |
| 抽出元タグ | 候補抽出に使われたタグ |
| ステータス | candidate / excluded / sent |
| 除外判定 | 除外キーワード該当有無 |
| 既送信 | 送信履歴有無 |
| 初回抽出日時 | firstFoundAt |
| 最終確認日時 | lastCheckedAt |

### 操作

| 操作 | 内容 |
|---|---|
| 候補詳細表示 | 候補詳細画面へ遷移する |
| 送信対象チェック | 送信キューに追加する候補を選択する |
| 送信キューに追加 | チェック済み候補を送信キューへ追加する |
| 除外にする | 候補を除外ステータスに変更する |
| 候補抽出実行 | Cloud Functionsで候補抽出を実行する |

---

## 7. 送信キュー画面設計

### 目的

候補一覧で選択された候補者を、管理者が1件ずつ確認してDM送信する。

### 画面構成

| 項目 | 内容 |
|---|---|
| 進捗表示 | 例：1 / 20件目 |
| 候補情報 | 表示名、ユーザー名、プロフィール文 |
| 除外判定 | 除外キーワード該当有無 |
| 既送信確認 | send_historiesの有無 |
| テンプレート選択 | 使用するDMテンプレートを選択する |
| DM本文 | 送信予定本文を表示する |
| 操作ボタン | 送信、スキップ、コピー、除外 |

### 操作

| 操作 | 内容 |
|---|---|
| この候補者にDM送信 | X APIでDM送信する |
| 本文をコピー | DM本文をクリップボードへコピーする |
| 送信済みにする | 手動送信後に履歴登録する |
| スキップ | 現在候補をスキップして次へ進む |
| 除外にする | 現在候補を除外する |
| 前へ | 前の候補に戻る |
| 次へ | 次の候補へ進む |

---

## 8. Firestore設計

### 8.1 コレクション一覧

| コレクション | 用途 |
|---|---|
| users | 管理ユーザー情報 |
| settings | システム設定 |
| templates | DMテンプレート |
| candidates | 候補アカウント |
| send_queues | 送信キュー |
| send_histories | 送信履歴 |
| excluded_accounts | 除外対象アカウント |
| conversions | 成果報酬算定情報 |
| function_logs | Cloud Functions実行ログ |

---

## 9. candidates

### パス

```text
candidates/{candidateId}
```

### candidateId方針

```text
candidateId = xUserId
```

同一アカウントを複数タグから抽出した場合も、候補アカウントは1件に統合する。

### フィールド

| フィールド | 型 | 必須 | 内容 |
|---|---|---|---|
| candidateId | string | ○ | 候補ID |
| xUserId | string | ○ | XユーザーID |
| username | string | ○ | Xユーザー名 |
| displayName | string | - | 表示名 |
| profileText | string | - | プロフィール文 |
| sourceTags | array<string> | ○ | 抽出元タグ一覧 |
| sourcePostIds | array<string> | - | 抽出元投稿ID一覧 |
| status | string | ○ | candidate / excluded / sent |
| excludeMatchedKeywords | array<string> | - | 該当した除外キーワード |
| isExcluded | boolean | ○ | 除外対象か |
| isSent | boolean | ○ | 送信済みか |
| firstFoundAt | timestamp | ○ | 初回抽出日時 |
| lastFoundAt | timestamp | ○ | 最終抽出日時 |
| lastCheckedAt | timestamp | - | 最終確認日時 |
| firstContactedAt | timestamp | - | 初回接触日時 |
| createdAt | timestamp | ○ | 作成日時 |
| updatedAt | timestamp | ○ | 更新日時 |

---

## 10. send_queues

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
| status | string | ○ | active / completed / canceled |
| candidateIds | array<string> | ○ | 送信対象候補ID一覧 |
| currentIndex | number | ○ | 現在表示中の候補位置 |
| totalCount | number | ○ | キュー内候補数 |
| completedCount | number | ○ | 完了件数 |
| skippedCount | number | ○ | スキップ件数 |
| createdAt | timestamp | ○ | 作成日時 |
| updatedAt | timestamp | ○ | 更新日時 |
| createdBy | string | ○ | 作成者UID |

### items フィールド

| フィールド | 型 | 必須 | 内容 |
|---|---|---|---|
| itemId | string | ○ | キュー明細ID |
| candidateId | string | ○ | 候補ID |
| xUserId | string | ○ | XユーザーID |
| username | string | ○ | Xユーザー名 |
| status | string | ○ | pending / sent / skipped / excluded / failed |
| order | number | ○ | 送信順 |
| templateId | string | - | 使用テンプレートID |
| sentAt | timestamp | - | 送信日時 |
| errorMessage | string | - | エラー内容 |
| createdAt | timestamp | ○ | 作成日時 |
| updatedAt | timestamp | ○ | 更新日時 |

---

## 11. send_histories

### パス

```text
send_histories/{historyId}
```

### フィールド

| フィールド | 型 | 必須 | 内容 |
|---|---|---|---|
| historyId | string | ○ | 履歴ID |
| candidateId | string | ○ | 候補ID |
| xUserId | string | ○ | XユーザーID |
| username | string | ○ | Xユーザー名 |
| displayName | string | - | 表示名 |
| templateId | string | ○ | テンプレートID |
| templateName | string | ○ | テンプレート名 |
| messageBodySnapshot | string | ○ | 送信本文のスナップショット |
| sentAt | timestamp | ○ | 送信日時 |
| sentBy | string | ○ | 送信者UID |
| sendMethod | string | ○ | api / manual |
| xDmEventId | string | - | X API側のDMイベントID |
| createdAt | timestamp | ○ | 作成日時 |

---

## 12. Cloud Functions設計

### 12.1 関数一覧

| 関数名 | 種別 | 概要 |
|---|---|---|
| syncCandidates | callable | 指定タグをもとにX APIから候補を抽出する |
| revertCandidateSyncRun | callable | 抽出run単位で候補抽出を解除する |
| createSendQueue | callable | チェック選択された候補から送信キューを作成する |
| sendDirectMessage | callable | 候補者1名にDMを送信する |
| markAsManuallySent | callable | 手動送信済みとして履歴を保存する |
| excludeCandidate | callable | 候補を除外する |
| restoreCandidate | callable | 除外候補を候補に戻す |
| createConversion | callable | 成果情報を登録する |

---

## 13. syncCandidates

### 概要

設定されたタグをもとにX APIで投稿検索を行い、投稿主アカウントを候補として保存する。

### 処理

1. 認証ユーザーを確認する
2. 管理者権限を確認する
3. settings/scoutを取得する
4. 対象タグとタグ検索条件を決定する
5. タグごと検索、OR検索、AND検索のいずれかでX API投稿検索を実行する
6. 投稿主ユーザー情報を取得する
7. 既存candidateを確認する
8. send_historiesを確認し既送信を判定する
9. excluded_accountsを確認し除外対象を判定する
10. プロフィール文に除外キーワードが含まれるか判定する
11. candidatesへ保存または更新する
12. function_logsへ実行結果を保存する

抽出実行ごとに `candidate_sync_runs/{runId}` と配下changesへ差分を保存し、誤抽出時にrun単位で解除できるようにする。
送信履歴または送信キューに関わった候補、後続抽出で更新済みの候補は解除対象からスキップする。

---

## 14. createSendQueue

### 概要

候補一覧でチェック選択された候補者から送信キューを作成する。

### 処理

1. 認証ユーザーを確認する
2. 管理者権限を確認する
3. candidateIdsの候補を取得する
4. status = candidate のみ対象にする
5. 既送信、除外対象を除外する
6. send_queuesを作成する
7. send_queues/{queueId}/itemsを作成する
8. queueIdを返却する

---

## 15. sendDirectMessage

### 概要

送信キュー内の候補者1名に対して、X APIを利用してDMを送信する。

本関数は、複数人への自動連続送信を行わない。1回の呼び出しにつき、1候補者への送信のみ実行する。

### 処理

1. 認証ユーザーを確認する
2. 管理者権限を確認する
3. candidateを取得する
4. queue itemを取得する
5. templateを取得する
6. candidate.status = candidate であることを確認する
7. excluded_accountsに存在しないことを確認する
8. send_historiesに既送信履歴がないことを確認する
9. X APIでDMを送信する
10. send_historiesを作成する
11. candidates.statusをsentに更新する
12. candidates.firstContactedAtを設定する
13. queue item.statusをsentに更新する
14. send_queues.completedCountを更新する
15. 結果を返却する

---

## 16. Flutterアプリ設計

### 16.1 ディレクトリ構成

```text
lib/
  main.dart
  app/
    app.dart
    router/
      app_router.dart
      route_paths.dart
    theme/
      app_theme.dart
  core/
    constants/
    errors/
    ui/
      app_scaffold.dart
      loading_view.dart
      error_view.dart
      confirm_dialog.dart
    utils/
      date_format_utils.dart
  features/
    auth/
    dashboard/
    candidates/
    send_queue/
    templates/
    histories/
    exclusions/
    conversions/
    settings/
```

### 16.2 状態管理

状態管理は Riverpod を想定する。

| 種別 | 用途 |
|---|---|
| StreamProvider | Firestoreのリアルタイム一覧取得 |
| FutureProvider | 初期読み込み、単発取得 |
| Notifier / AsyncNotifier | 画面操作、登録更新処理 |
| Provider | Repository、UseCase、FirebaseインスタンスDI |

### 16.3 ルーティング

GoRouterを想定する。

| パス | 画面 |
|---|---|
| /login | LoginPage |
| /dashboard | DashboardPage |
| /candidates | CandidateListPage |
| /candidates/:id | CandidateDetailPage |
| /send-queue/:queueId | SendQueuePage |
| /send-histories | SendHistoryPage |
| /excluded-accounts | ExcludedAccountPage |
| /templates | TemplateListPage |
| /conversions | ConversionListPage |
| /settings/tags | TagSettingPage |
| /settings/exclusions | ExclusionKeywordSettingPage |

---

## 17. 主要処理フロー

### 17.1 候補抽出フロー

```text
管理者
 ↓
候補一覧画面で「候補抽出」を押す
 ↓
必要に応じてタグ検索モードを切り替える
 ↓
FlutterからsyncCandidatesを呼び出す
 ↓
Cloud FunctionsがX APIで投稿検索
 ↓
投稿主アカウントを取得
 ↓
除外キーワード判定
 ↓
既送信・除外リスト確認
 ↓
Firestore candidatesへ保存
 ↓
候補一覧画面に反映
```

### 17.2 送信キュー作成フロー

```text
管理者
 ↓
候補一覧で送信対象にチェック
 ↓
「送信キューに追加」を押す
 ↓
FlutterからcreateSendQueueを呼び出す
 ↓
Cloud Functionsが送信可能候補を検証
 ↓
send_queuesとitemsを作成
 ↓
送信キュー画面へ遷移
```

### 17.3 個別DM送信フロー

```text
管理者
 ↓
送信キュー画面で候補者を確認
 ↓
テンプレートを選択
 ↓
DM本文を確認
 ↓
「この候補者にDM送信」を押す
 ↓
確認ダイアログを表示
 ↓
FlutterからsendDirectMessageを呼び出す
 ↓
Cloud Functionsが既送信・除外・状態を再確認
 ↓
X APIでDM送信
 ↓
send_histories作成
 ↓
candidates.status = sent
 ↓
queue item.status = sent
 ↓
次の候補へ進む
```

---

## 18. エラーハンドリング設計

| 種別 | 内容 | 表示方針 |
|---|---|---|
| 認証エラー | 未ログイン、セッション切れ | ログイン画面へ誘導 |
| 権限エラー | admin権限なし | 権限がない旨を表示 |
| 入力エラー | 必須項目不足 | 該当項目の近くに表示 |
| 既送信エラー | 対象が既に送信済み | 送信済みとして警告表示 |
| 除外エラー | 対象が除外済み | 除外対象として警告表示 |
| X APIエラー | API制限、送信失敗 | 内容を簡潔に表示し再試行案内 |
| 通信エラー | ネットワーク不良 | 再試行ボタンを表示 |

---

## 19. セキュリティ設計

- 未ログインユーザーは全データにアクセスできない
- 管理者以外は更新処理を行えない
- X APIトークンはCloud Functions側で管理する
- Flutter Web側に秘密情報を保持しない
- 送信履歴はクライアントから直接作成させず、原則Cloud Functions経由とする

---

## 20. テスト観点

| 区分 | 内容 |
|---|---|
| 認証 | 未ログイン時にアクセスできないこと |
| 候補抽出 | 指定タグから候補が保存されること |
| 除外判定 | 除外キーワードに一致した候補が除外されること |
| 重複防止 | 同一XユーザーIDが重複登録されないこと |
| 送信キュー | チェック選択した候補のみキュー化されること |
| 送信前チェック | 既送信、除外対象に送信できないこと |
| DM送信 | 1件ずつ送信できること |
| 送信履歴 | 送信成功時に履歴が保存されること |
| 手動送信記録 | manualとして履歴保存されること |
| 成約記録登録 | 成果対象者、対象売上、補足メモが保存されること |

---

## 21. MVP開発順序

### フェーズ1：基盤構築

1. Firebaseプロジェクト作成
2. Flutter Webプロジェクト作成
3. Firebase Authentication連携
4. Firestore接続
5. Hosting設定
6. Cloud Functions TypeScript環境構築

### フェーズ2：管理画面基礎

1. ログイン画面
2. AppScaffold
3. ダッシュボード
4. タグ設定画面
5. 除外キーワード設定画面
6. テンプレート画面

### フェーズ3：候補抽出

1. syncCandidates実装
2. X API疎通確認
3. 候補保存
4. 除外判定
5. 候補一覧画面
6. 候補詳細画面

### フェーズ4：送信キュー・DM送信支援

1. 候補一覧のチェック選択
2. createSendQueue実装
3. 送信キュー画面
4. sendDirectMessage実装
5. markAsManuallySent実装
6. 送信履歴画面

---

## 22. 対象外事項

- DMの確認なし自動一括送信
- 一定時間間隔による自動連続DM送信
- 複数担当者の詳細権限管理
- 返信管理
- NG管理
- 高度な分析機能
- AIスコアリング
- Googleスプレッドシート連携
- 運用代行
- X API審査通過保証
- Xアカウント凍結回避保証

---

## 23. 結論

本システムは、Flutter Web、Firebase、Cloud Functions TypeScriptを中心とした小規模かつ拡張可能な構成で実装する。

初期MVPでは、候補抽出、プロフィール除外、候補一覧、送信キュー、個別DM送信支援、送信履歴に絞って実装する。
成果記録UIは初期運用ではメイン導線から外し、必要時に成約記録/成果メモとして再設計する。

DM送信は、候補者ごとに管理者が内容を確認し、1件ずつ送信操作を行う方式とする。

確認なしの自動一括送信、一定時間間隔による自動連続送信は初期MVPの対象外とする。

---

## 24. 実装補強設計

本章は、要件精査で確認した実装リスクをもとに、初期実装で必ず反映する設計方針を定義する。

### 24.1 X API検証フェーズ

MVP開発では、管理画面の全実装に先行してX API検証を行う。

検証対象は以下とする。

| 検証項目 | 内容 |
|---|---|
| OAuth | OAuth 2.0 PKCEでアクセストークンを取得できること |
| スコープ | DM送信に必要な `dm.write`、DM参照に必要な `dm.read` が利用できること |
| 投稿検索 | 指定タグの投稿検索が実行できること |
| ユーザー取得 | 投稿主のユーザーID、ユーザー名、プロフィール文を取得できること |
| DM送信 | 1ユーザーに対してDM送信APIを実行できること |
| レート制限 | 想定運用件数で制限に抵触しないこと |

DM送信APIを基本送信手段とし、API失敗時や運用停止時の代替として手動送信支援モードを残す。

### 24.2 送信方式

送信方式は以下の2種類を持つ。

| 方式 | sendMethod | 内容 |
|---|---|---|
| API送信 | api | Cloud FunctionsからX APIを呼び出してDM送信する |
| 手動送信 | manual | 管理画面で本文をコピーし、X上で手動送信後に送信済み登録する |

初期MVPでは `manual` を必須機能、`api` をX API検証完了後に有効化する機能として扱う。

### 24.3 sendDirectMessageの二重送信防止

`sendDirectMessage` は、1回の呼び出しにつき1候補者のみを対象とする。

さらに、Firestore transactionにより以下の状態遷移を保証する。

```text
pending/candidate
  ↓ transactionでロック
sending
  ↓ X API送信成功
sent

sending
  ↓ X API送信失敗
failed
```

処理開始時に以下のいずれかに該当する場合、DM送信処理を実行しない。

- candidate.status が `sent`
- candidate.status が `excluded`
- queue item.status が `sending`
- queue item.status が `sent`
- send_histories に既存履歴がある
- excluded_accounts に存在する

### 24.4 markAsManuallySentの二重登録防止

`markAsManuallySent` も `sendDirectMessage` と同様に、Firestore transactionで既存履歴と候補状態を確認する。

手動送信済み登録時は、以下を同時に更新する。

- `send_histories` 作成
- `candidates.status = sent`
- `candidates.isSent = true`
- `candidates.firstContactedAt` 設定
- `send_queues/{queueId}/items/{itemId}.status = sent`
- `send_queues.completedCount` 更新

### 24.5 conversions

### パス

```text
conversions/{conversionId}
```

### フィールド

| フィールド | 型 | 必須 | 内容 |
|---|---|---|---|
| conversionId | string | ○ | 成果ID |
| candidateId | string | ○ | 候補ID |
| xUserId | string | ○ | XユーザーID |
| username | string | ○ | Xユーザー名 |
| displayName | string | - | 表示名 |
| sendHistoryId | string | - | 関連する送信履歴ID |
| sourceTags | array<string> | ○ | 抽出元タグ |
| firstFoundAt | timestamp | - | 初回抽出日時 |
| firstContactedAt | timestamp | - | 初回接触日時 |
| salesAmount | number | ○ | 対象売上 |
| rewardRate | number | - | 旧仕様互換用。現行UIでは使用しない |
| rewardAmount | number | - | 旧仕様互換用。現行UIでは使用しない |
| evidenceNote | string | - | 補足メモ |
| status | string | ○ | draft / reported / paid / canceled |
| createdBy | string | ○ | 登録者UID |
| createdAt | timestamp | ○ | 作成日時 |
| updatedAt | timestamp | ○ | 更新日時 |

成果報酬率と成果報酬額は本システムでは計算せず、クライアント側で別途算定する。

### 24.6 管理者権限設計

初期MVPでは、以下の方式で管理者権限を判定する。

```text
users/{uid}
```

| フィールド | 型 | 必須 | 内容 |
|---|---|---|---|
| uid | string | ○ | Firebase Auth UID |
| email | string | - | メールアドレス |
| displayName | string | - | 表示名 |
| role | string | ○ | admin |
| isActive | boolean | ○ | 有効ユーザーか |
| createdAt | timestamp | ○ | 作成日時 |
| updatedAt | timestamp | ○ | 更新日時 |

Cloud Functionsでは、認証済みユーザーの `users/{uid}` を取得し、`role = admin` かつ `isActive = true` の場合のみ重要処理を許可する。

### 24.7 Firestore Security Rules方針

初期MVPのFirestoreアクセス方針は以下とする。

- 未ログインユーザーは全データへアクセスできない
- 認証済み管理者のみ参照できる
- `send_histories`、`conversions`、`excluded_accounts` の作成・更新は原則Cloud Functions経由とする
- X APIトークン、シークレット、アクセストークンはFirestoreのクライアント読み取り可能領域に保存しない

### 24.8 除外状態の正本

除外対象の正本は `excluded_accounts` とする。

`candidates.status` と `candidates.isExcluded` は表示・検索・操作制御のためのスナップショットとして扱い、Cloud Functions経由の更新で同期する。

### 24.9 X APIトークン管理

X APIに関する秘密情報はCloud Functions側でのみ扱う。

保存先は以下のいずれかとする。

- Firebase Functions config
- Google Cloud Secret Manager

Flutter Web、Firestoreの通常ドキュメント、Firebase Hosting上の静的ファイルには秘密情報を保持しない。
