# X API検証設計

## 1. 目的

X APIを利用した投稿検索、ユーザー情報取得、DM送信が本プロジェクトのMVPで利用可能かを検証する。

X APIの仕様、プラン、審査、レート制限、アカウント制限により機能提供可否が変わるため、UIやCloud Functions本実装より前に検証する。

## 2. 基本方針

- X Developer Appはクライアント所有または案件専用Xアカウントで作成する
- 開発者個人のX Developer Appを本番用に使用しない
- X API秘密情報はCloud Functions側でのみ扱う
- Flutter Web側にClient Secret、Access Token、Refresh Tokenを保持しない
- DM APIが利用できない場合でも、手動送信支援モードでMVPを成立させる

## 3. 検証前提

### 必要なもの

- Xアカウント（作成済み）
- X Developer Portalへのアクセス（確認済み）
- X Developer App（`x-scout-manager-dev` 作成済み）
- OAuth 2.0 Client ID（取得済み）
- Client Secret（取得済み）
- Bearer Token（取得済み）
- 必要スコープ（読み書きおよびダイレクトメッセージを選択済み）
- Firebase / Cloud Functions検証環境

### 想定スコープ

| スコープ | 用途 |
|---|---|
| `tweet.read` | 投稿検索・投稿参照 |
| `users.read` | ユーザー情報取得 |
| `dm.read` | DM関連情報参照 |
| `dm.write` | DM送信 |
| `offline.access` | Refresh Token利用が必要な場合 |

実際に利用可能なスコープはDeveloper Appの設定とX APIプランに依存する。

## 4. 検証項目

### 4.1 Developer App

| 項目 | 判定 |
|---|---|
| Developer Portalへログインできる | 必須 |
| Project / Appを作成できる | 必須 |
| OAuth 2.0を有効化できる | 必須 |
| Callback URLを設定できる | 必須 |
| 必要スコープを設定できる | 必須 |

### 4.2 OAuth 2.0 PKCE

| 項目 | 判定 |
|---|---|
| 認可URLを生成できる | 必須 |
| Xログイン後にcallbackを受け取れる | 必須 |
| Authorization Codeを取得できる | 必須 |
| Access Tokenを取得できる | 必須 |
| Refresh Tokenを取得できる | 必要に応じて |

### 4.3 投稿検索

検証内容:

- 指定タグで検索できる
- 取得件数を制御できる
- ページングできる
- 投稿ID、投稿者IDを取得できる
- レート制限時のレスポンスを確認できる

検証例:

```text
query = "#対象タグ -is:retweet"
max_results = 10
```

### 4.4 ユーザー情報取得

検証内容:

- 投稿者IDからユーザー情報を取得できる
- usernameを取得できる
- displayNameを取得できる
- profileTextを取得できる

### 4.5 DM送信

検証内容:

- 対象ユーザーへDM送信APIを呼べる
- 送信成功時にDMイベントIDを取得できる
- 送信不可ユーザーの場合のエラーを確認できる
- レート制限時のエラーを確認できる
- アカウント制限や権限不足時のエラーを確認できる

### 4.6 レート制限

確認項目:

- 投稿検索の制限
- ユーザー取得の制限
- DM送信の制限
- 日次/月次上限
- 429発生時のレスポンス

## 5. 成功条件

### 手動送信支援MVPの成功条件

以下が満たされれば、MVPは手動送信支援として成立する。

- 投稿検索が利用できる
- 投稿主ユーザー情報を取得できる
- Firestoreへ候補保存できる
- テンプレートコピーと手動送信済み登録ができる

### API DM送信有効化の成功条件

以下をすべて満たす場合のみ、`apiDmEnabled = true` を検討する。

- `dm.write` スコープが利用できる
- 実テストで1件のDM送信に成功する
- 送信成功レスポンスから証跡に必要なIDを保存できる
- 送信不可・権限不足・レート制限のエラーを分類できる
- クライアントがX API利用リスクを理解している

## 6. 失敗時の分岐

| 失敗内容 | 対応 |
|---|---|
| 投稿検索不可 | X APIプラン変更または候補抽出方式の再検討 |
| ユーザー情報取得不可 | 取得可能な情報だけで候補管理するか再検討 |
| DM送信不可 | API送信を無効化し、手動送信支援に限定 |
| レート制限が厳しい | 取得件数、実行頻度、運用手順を制限 |
| Developer審査不通過 | 外部要因として別見積・別対応 |

## 7. 検証実装方針

初期検証はCloud FunctionsまたはローカルNode.jsスクリプトで行う。

2026-05-14時点では、秘密情報を本番環境へ入れる前に `tools/x_api_probe.mjs` によるローカル検証を優先する。
手順は `docs/X_API検証手順.md` に記録する。

推奨順序:

1. OAuth 2.0 PKCE認可
2. Access Token取得
3. 投稿検索
4. ユーザー情報取得
5. DM送信
6. エラー分類

## 8. 検証結果記録

検証結果は以下の形式で記録する。

```text
検証日:
利用アカウント:
Developer App:
X APIプラン:
検証API:
結果:
レスポンス概要:
エラー:
MVPへの影響:
判断:
```

## 9. 未確定事項

- 本番運用での検索キーワード、取得件数、実行頻度
- 本番運用での送信上限

## 10. 2026-05-14 検証結果

### Developer App

- App name: `x-scout-manager-dev`
- App permission: 読み書きおよびダイレクトメッセージ
- App type: ウェブアプリ、自動化アプリまたはボット
- Callback URL:
  - `https://x-scout-manager-prod.web.app/auth/x/callback`
  - `http://127.0.0.1:8765/callback`

### 投稿検索

- 初回: `status=402` / `CreditsDepleted`
- クレジット反映後: `status=200`
- 別クエリで `data[]` と `includes.users[]` の取得成功
- 判定: 015 X API候補抽出に利用可能

### OAuth 2.0

- 手動コピー方式ではauthorization codeの30秒期限により失敗しやすい
- `oauth-local` によるローカルcallback方式でUser Access Token取得成功
- 判定: OAuth 2.0 User Access Token取得可能

### ユーザー取得

- `node tools/x_api_probe.mjs user XDevelopers`
- `status=200`
- `id`, `username`, `name`, `description`, `receives_your_dm`, `public_metrics` の取得成功
- 判定: 候補者プロフィール取得に利用可能

### DM送信

- 初回: `status=403` / `You do not have permission to DM one or more participants.`
- 受信側条件調整後: `status=201`
- `dm_conversation_id` と `dm_event_id` の取得成功
- 受信側X UIではメッセージリクエストの非表示領域に入ることを確認
- X公式ヘルプ上、品質フィルターで低品質リクエスト扱いになったDMは通知されず、Requests下部のフィルター内に表示される
- 判定: 016 API DM送信に進めるが、API受理と実着確認を分けて扱う

### MVP判断

- 候補抽出: API利用可能
- API DM送信: API上は受理されるが、受信側UIではメッセージリクエスト/非表示に入る可能性がある
- 手動送信支援: 受信側条件、レート制限、クレジット制約の回避策として継続
