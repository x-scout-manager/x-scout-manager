# Flutter画面詳細設計

## 1. 目的

Flutter Web管理画面の画面構成、表示項目、操作、状態、ViewModel責務を定義する。

アーキテクチャは `docs/ARCHITECTURE_flutter_core_features_mvvm.md` に従う。

## 2. 共通UI方針

### 2.1 レイアウト

- 業務ツールとして、情報量を整理した管理画面にする
- 過度な装飾やランディングページ風の構成は避ける
- PC利用を主対象としつつ、狭幅でも主要操作が破綻しないようにする
- 共通Scaffold、共通エラー、ローディング、空状態を `core/ui` に集約する

### 2.2 状態

各画面は以下の状態を持つ。

| 状態 | 表示 |
|---|---|
| loading | ローディング |
| data | 通常表示 |
| empty | 空状態 |
| error | エラー表示、再試行 |
| submitting | ボタン無効化、処理中表示 |

### 2.3 エラー表示

Cloud Functionsのエラーコードをユーザー向け文言に変換して表示する。

例:

| エラー | 表示 |
|---|---|
| unauthenticated | ログインしてください |
| permission-denied | 権限がありません |
| already-exists | 既に処理済みです |
| failed-precondition | 対象の状態が変わったため再読み込みしてください |
| resource-exhausted | API制限に達しました。時間をおいて再試行してください |

## 3. ルーティング

初期実装ではFlutter標準 `MaterialApp.routes` を使用している。認証ガード、パスパラメータ、リダイレクトが必要になった段階でGoRouterへ移行する。

| パス | 画面 | feature |
|---|---|---|
| `/login` | LoginPage | auth |
| `/dashboard` | DashboardPage | dashboard |
| `/candidates` | CandidateListPage | candidates |
| `/candidates/:id` | CandidateDetailPage | candidates |
| `/send-queue/:queueId` | SendQueuePage | send_queue |
| `/send-histories` | SendHistoryPage | histories |
| `/excluded-accounts` | ExcludedAccountPage | exclusions |
| `/templates` | TemplateListPage | templates |
| `/conversions` | ConversionListPage | conversions |
| `/settings/tags` | TagSettingPage | settings |
| `/settings/exclusions` | ExclusionKeywordSettingPage | exclusions |
| `/settings` | SystemSettingPage | settings |

## 4. ログイン画面

### 表示項目

- メールアドレス
- パスワード
- ログインボタン
- エラーメッセージ

### 操作

| 操作 | 処理 |
|---|---|
| ログイン | Firebase Authenticationでログインし、`users/{uid}` の管理者権限を確認する |

### ViewModel状態

```dart
email
password
isLoading
errorMessage
```

## 5. ダッシュボード

### 表示項目

- 候補数
- 送信済み数
- 除外数
- 未処理キュー数
- 直近候補抽出日時
- 直近送信日時

### 操作

| 操作 | 遷移先 |
|---|---|
| 候補を見る | 候補一覧 |
| 送信履歴を見る | 送信履歴 |
| 設定を見る | 設定 |

### ViewModel状態

```dart
summary
isLoading
errorMessage
```

## 6. タグ設定画面

### 表示項目

- 登録済みタグ一覧
- タグ追加入力
- 検索取得件数
- 最大ページ数

### 操作

| 操作 | 処理 |
|---|---|
| タグ追加 | 入力タグを追加 |
| タグ削除 | 対象タグを削除 |
| 保存 | `settings/scout` を更新 |

### バリデーション

- 空タグ不可
- 同一タグ重複不可
- `#` は入力されても内部では正規化する

## 7. 除外キーワード設定画面

### 表示項目

- 除外キーワード一覧
- キーワード追加入力

### 操作

| 操作 | 処理 |
|---|---|
| キーワード追加 | 除外キーワードを追加 |
| キーワード削除 | 除外キーワードを削除 |
| 保存 | `settings/scout.exclusionKeywords` を更新 |

## 8. テンプレート画面

### 表示項目

- テンプレート一覧
- テンプレート名
- 本文
- 有効/無効

### 操作

| 操作 | 処理 |
|---|---|
| 新規作成 | テンプレート作成 |
| 編集 | テンプレート更新 |
| 無効化 | `isActive = false` |

### 初期MVP

最低1件のテンプレートを登録できればよい。高度なテンプレート管理は対象外。

## 9. 候補一覧画面

### 表示項目

| 項目 | 内容 |
|---|---|
| チェック | 送信キュー追加対象 |
| 表示名 | X表示名 |
| ユーザー名 | @username |
| プロフィール文 | 省略表示 |
| 抽出元タグ | sourceTags |
| ステータス | candidate / sent / excluded / failed |
| 除外判定 | excludeMatchedKeywords |
| 既送信 | isSent |
| 初回抽出日時 | firstFoundAt |
| 最終抽出日時 | lastFoundAt |

### 操作

| 操作 | 処理 |
|---|---|
| 候補抽出 | `syncCandidates` 呼び出し |
| チェック | 送信対象選択 |
| 送信キューに追加 | `createSendQueue` 呼び出し |
| 詳細 | 候補詳細へ遷移 |
| 除外 | `excludeCandidate` 呼び出し |

### フィルタ

初期MVPでは以下のみ。

- ステータス
- タグ
- キーワード検索

## 10. 候補詳細画面

### 表示項目

- 表示名
- ユーザー名
- XプロフィールURL
- プロフィール文
- 抽出元タグ
- 抽出元投稿ID
- 除外判定
- 送信履歴
- 成果情報

### 操作

| 操作 | 処理 |
|---|---|
| 除外にする | `excludeCandidate` |
| 除外解除 | `restoreCandidate` |
| 送信キューに追加 | 単体キュー作成 |

## 11. 送信キュー画面

### 表示項目

- 進捗 `current / total`
- 候補情報
- プロフィール文
- 除外判定
- 既送信確認
- テンプレート選択
- DM本文プレビュー
- 送信方式
- エラー表示

### 操作

| 操作 | 処理 |
|---|---|
| 本文コピー | クリップボードへコピー |
| 手動送信済みにする | `markAsManuallySent` |
| APIでDM送信 | `sendDirectMessage`。`apiDmEnabled = true` の場合のみ表示 |
| スキップ | `skipQueueItem` |
| 除外にする | `excludeCandidate` |
| 前へ/次へ | キュー内移動 |

### 重要

初期MVPでは手動送信支援を必須とし、API送信はX API検証後に有効化する。

## 12. 送信履歴画面

### 表示項目

- 送信日時
- ユーザー名
- 表示名
- 送信方法 `api / manual`
- テンプレート名
- 本文スナップショット
- 送信者

### 操作

- 詳細確認
- 候補詳細へ遷移

履歴の編集・削除は初期MVPでは行わない。

## 13. 除外リスト画面

### 表示項目

- ユーザー名
- 表示名
- 除外理由
- 一致キーワード
- 除外日時

### 操作

| 操作 | 処理 |
|---|---|
| 除外解除 | `restoreCandidate` |
| 候補詳細 | 候補詳細へ遷移 |

## 14. 成果報告管理画面

### 表示項目

- 候補者
- Xユーザー名
- 送信履歴
- 対象売上
- 成果報酬率
- 成果報酬額
- ステータス
- 登録日時

### 操作

| 操作 | 処理 |
|---|---|
| 成果登録 | `createConversion` |
| 報酬額計算 | `calculateReward` |
| ステータス更新 | MVPでは任意。初期は登録のみでも可 |

## 15. システム設定画面

### 表示項目

- API DM送信有効/無効
- 手動送信有効/無効
- 標準成果報酬率
- 検索取得件数
- 最大ページ数

### 操作

- 保存

## 16. MVP画面実装順序

1. AppScaffoldとナビゲーション
2. ログイン画面
3. ダッシュボード
4. タグ設定
5. 除外キーワード設定
6. テンプレート画面
7. 候補一覧
8. 候補詳細
9. 送信キュー
10. 送信履歴
11. 除外リスト
12. 成果報告管理

## 17. 未確定事項

- GoRouter導入タイミング
- 管理画面のサイドナビ有無
- テンプレート本文の差し込み変数範囲
- 成果ステータス運用の詳細
