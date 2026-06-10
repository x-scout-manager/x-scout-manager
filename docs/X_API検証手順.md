# X API検証手順

## この手順で確認すること

014では、X APIをこのプロジェクトで使えるかを実際に確認する。

確認する順番:

1. ローカルに秘密情報ファイルを作る
2. Bearer Tokenで投稿検索できるか確認する
3. OAuth 2.0でXアカウントのUser Access Tokenを取得する
4. User Access Tokenでユーザー情報を取得する
5. 検証用アカウントへDM送信できるか確認する
6. 015/016へ進めるか判断する

## 重要な注意

- APIキーやTokenはチャット、GitHub、ドキュメントに貼らない
- `.env.x-api.local` はGit管理しない
- DM送信テストは実際に相手へDMが届く
- DM送信先は必ず検証用Xアカウントにする
- 失敗してもよい。014の目的は「使える/使えない」を判断すること

## いま完了していること

- X Developer App作成済み
- App name: `x-scout-manager-dev`
- App permission: 読み書きおよびダイレクトメッセージ
- App type: ウェブアプリ、自動化アプリまたはボット
- Callback URL: `https://x-scout-manager-prod.web.app/auth/x/callback`
- Website URL: `https://x-scout-manager-prod.web.app`
- Terms / Privacy URL: 未設定で保存済み
- API Key / API Key Secret / Bearer Token / Client ID / Client Secret は取得済み

## 事前準備

この手順はプロジェクト直下で実行する。

プロジェクト直下とは、以下のファイルやディレクトリが見える場所。

```text
AGENTS.md
docs/
functions/
lib/
tools/
pubspec.yaml
```

ターミナルで場所を確認する。

```bash
pwd
```

以下のように表示されればOK。

```text
/Users/rugmiya/x-scout-manager
```

違う場所にいる場合は移動する。

```bash
cd /Users/rugmiya/x-scout-manager
```

## 1. 秘密情報ファイルを作る

まず、サンプルファイルをコピーして、ローカル専用の秘密情報ファイルを作る。

```bash
cp .env.x-api.example .env.x-api.local
```

作成されたか確認する。

```bash
ls .env.x-api.local
```

以下のように表示されればOK。

```text
.env.x-api.local
```

## 2. `.env.x-api.local` を編集する

VS Codeなどで `.env.x-api.local` を開く。

中身は最初こうなっている。

```env
X_CLIENT_ID=
X_CLIENT_SECRET=
X_BEARER_TOKEN=
X_USER_ACCESS_TOKEN=
X_REDIRECT_URI=https://x-scout-manager-prod.web.app/auth/x/callback
X_LOCAL_REDIRECT_URI=http://127.0.0.1:8765/callback
X_SCOPES=tweet.read users.read dm.read dm.write offline.access
X_TOKEN_AUTH_METHOD=basic
```

X Developer Portalでメモした値を入れる。

```env
X_CLIENT_ID=ここにClient ID
X_CLIENT_SECRET=ここにClient Secret
X_BEARER_TOKEN=ここにBearer Token
X_USER_ACCESS_TOKEN=
X_REDIRECT_URI=https://x-scout-manager-prod.web.app/auth/x/callback
X_LOCAL_REDIRECT_URI=http://127.0.0.1:8765/callback
X_SCOPES=tweet.read users.read dm.read dm.write offline.access
X_TOKEN_AUTH_METHOD=basic
```

この時点では `X_USER_ACCESS_TOKEN` は空でよい。

悪い例:

```env
X_CLIENT_ID=
X_CLIENT_SECRET=
X_BEARER_TOKEN=
```

この状態だと検証できない。

## 3. 検証スクリプトが動くか確認する

```bash
node tools/x_api_probe.mjs help
```

以下のような使い方が表示されればOK。

```text
X API probe

Usage:
  node tools/x_api_probe.mjs oauth-url
  node tools/x_api_probe.mjs token <authorization_code> <code_verifier>
  node tools/x_api_probe.mjs search "#keyword -is:retweet"
```

ここでエラーになる場合は、Node.jsが使えるか確認する。

```bash
node -v
```

## 4. まず投稿検索を試す

投稿検索は `X_BEARER_TOKEN` だけで確認できる。

まずはテストしやすいキーワードで実行する。

```bash
node tools/x_api_probe.mjs search "from:XDevelopers -is:retweet"
```

成功例:

```text
status=200
x-rate-limit-limit=...
x-rate-limit-remaining=...
x-rate-limit-reset=...

{
  "data": [
    {
      "id": "...",
      "text": "...",
      "author_id": "..."
    }
  ],
  "includes": {
    "users": [...]
  }
}
```

見るポイント:

- `status=200` なら成功
- `data` があれば投稿が取得できている
- `includes.users` があれば投稿者情報も取れている
- `x-rate-limit-remaining` は残り回数

よくある失敗:

```text
status=401
```

Bearer Tokenが間違っている可能性が高い。

```text
status=403
```

APIプランまたはApp権限で、そのAPIが使えない可能性がある。

```text
status=429
```

レート制限。しばらく待つ。

## 5. OAuth認可URLを作る

DM送信など、Xアカウント本人の権限が必要なAPIでは、User Access Tokenが必要。

authorization codeの有効期限は約30秒。
手でURLから `code` をコピーしていると期限切れになりやすい。

そのため、まずはローカルcallback方式を使う。

X Developer PortalのCallback URLに以下を追加して保存する。

```text
http://127.0.0.1:8765/callback
```

保存後、以下を実行する。

```bash
node tools/x_api_probe.mjs oauth-local
```

ターミナルに認可URLが表示されるので、ブラウザで開いて許可する。

成功すると、ローカルサーバーがcallbackを受け取り、その場でtoken交換まで行う。

`access_token` が出たら、`.env.x-api.local` の `X_USER_ACCESS_TOKEN=` に設定する。

### 手動方式

ローカルcallback方式が使えない場合だけ、手動方式を使う。

まず認可URLを作る。

```bash
node tools/x_api_probe.mjs oauth-url
```

出力例:

```text
Open this URL in the X account that will authorize the app:
https://x.com/i/oauth2/authorize?response_type=code&client_id=...

Save these values until token exchange is complete:
state=...
code_verifier=...
```

この画面でやること:

- `https://x.com/i/oauth2/authorize?...` から始まる長いURLをコピーする
- `code_verifier=...` の値もコピーして一時的にメモする

`code_verifier` は後で1回だけ使う。

## 6. ブラウザでX認可を行う

手順:

1. 先ほどコピーしたURLをブラウザで開く
2. Xの認可画面が出る
3. `x-scout-manager-dev` のアクセスを許可する
4. Callback URLへリダイレクトされる

現在、Callback画面は未実装なので、画面自体はエラー表示や空白になる可能性がある。

重要なのはブラウザのアドレスバー。

アドレスバーが以下のようになっていればOK。

```text
https://x-scout-manager-prod.web.app/auth/x/callback?state=...&code=...
```

この中の `code=` の後ろをコピーする。

例:

```text
code=abc123xyz
```

この場合、コピーするのは `abc123xyz` の部分。

注意:

- `state=` ではなく `code=` を使う
- `code=` の値に `&` が続く場合、`&` より前までをコピーする
- 認可コードは短時間で期限切れになるため、すぐ次の手順へ進む

手でコピーするのが不安な場合は、Callback URL全体を以下のコマンドに渡す。

```bash
node tools/x_api_probe.mjs callback-code '<Callback URL全体>'
```

例:

```bash
node tools/x_api_probe.mjs callback-code 'https://x-scout-manager-prod.web.app/auth/x/callback?state=...&code=...#/dashboard'
```

出力された `code=` の値を次のtoken交換で使う。

## 7. User Access Tokenに交換する

さきほど取得した2つを使う。

- ブラウザURLから取った `code`
- `oauth-url` 実行時に出た `code_verifier`

コマンド:

```bash
node tools/x_api_probe.mjs token "<authorization_code>" "<code_verifier>"
```

例:

```bash
node tools/x_api_probe.mjs token "abc123xyz" "def456verifier"
```

成功例:

```json
{
  "token_type": "bearer",
  "expires_in": 7200,
  "access_token": "...",
  "scope": "tweet.read users.read dm.read dm.write offline.access",
  "refresh_token": "..."
}
```

ここでやること:

1. `access_token` の値をコピー
2. `.env.x-api.local` の `X_USER_ACCESS_TOKEN=` に貼る
3. `refresh_token` の値を `.env.x-api.local` の `X_USER_REFRESH_TOKEN=` に貼る

例:

```env
X_USER_ACCESS_TOKEN=ここにaccess_token
X_USER_REFRESH_TOKEN=ここにrefresh_token
```

`access_token` は期限切れするため、Cloud Functions本番運用では `refresh_token` もSecret Managerへ設定する。

### `authorization code was invalid` が出る場合

このエラーは、同じ `code` では再試行できない。

よくある原因:

- 古い `code` を使っている
- 一度使った `code` を再利用している
- `code` と `code_verifier` が別々の `oauth-url` 実行回のもの
- `code_challenge` を `code_verifier` と間違えている
- Callback URLから `code` をコピーするときに余計な文字が混ざっている
- `.env.x-api.local` の `X_CLIENT_SECRET` にOAuth 2.0 Client Secretではなく、OAuth 1.0aのAPI Key Secretを入れている
- Developer Portal側のApp typeとtoken交換方式が合っていない

対処:

1. `node tools/x_api_probe.mjs oauth-url` をもう一度実行する
2. 新しい認可URLを開く
3. 新しいCallback URL全体をコピーする
4. `node tools/x_api_probe.mjs callback-code '<Callback URL全体>'` で `code` を抜き出す
5. 同じ回で出た新しい `code_verifier` と組み合わせてtoken交換する

`X_CLIENT_SECRET` は、Keys & TokensのOAuth 2.0欄にあるClient Secretを使う。
OAuth 1.0aのAPI Key Secretとは別物。

それでも失敗する場合は、`X_TOKEN_AUTH_METHOD` を一時的に切り替えて確認する。

通常は以下。

```env
X_TOKEN_AUTH_METHOD=basic
```

`basic` では、Client ID / Client SecretをURLエンコードしてからBasic認証ヘッダーを作る。
XのClient IDには `:` が含まれることがあるため、この処理が必要。

もしDeveloper Portal側が公開クライアント扱いの場合は以下にする。

```env
X_TOKEN_AUTH_METHOD=public
X_CLIENT_SECRET=
```

一部環境でBasic認証が通らない場合の確認用。

```env
X_TOKEN_AUTH_METHOD=body
```

切り替えた後は、古い `code` は使えないため、必ず `oauth-url` からやり直す。

## 8. ユーザー情報取得を試す

まず公式アカウントで確認する。

```bash
node tools/x_api_probe.mjs user XDevelopers
```

成功例:

```text
status=200

{
  "data": {
    "id": "2244994945",
    "username": "XDevelopers",
    "name": "Developers"
  }
}
```

見るポイント:

- `status=200` なら成功
- `id` がXユーザーID
- `username` が画面上のID
- `description` がプロフィール文

## 9. DM送信を試す

DM送信は実際に送られる。

必ず検証用の受信アカウントで確認する。

必要なもの:

- 受信側XアカウントのUser ID
- `.env.x-api.local` の `X_USER_ACCESS_TOKEN`

送信コマンド:

```bash
node tools/x_api_probe.mjs dm "<受信側のUser ID>" "X API DM送信検証です。"
```

例:

```bash
node tools/x_api_probe.mjs dm "1234567890" "X API DM送信検証です。"
```

成功時は、DMイベントIDのような値が返る。

見るポイント:

- `status=201` または成功系ならDM送信成功
- DMイベントIDが返るか
- 受信側アカウントでDMが届いているか

失敗しても、その内容が重要。

よくある失敗:

```text
status=401
```

User Access Tokenがない、期限切れ、または間違っている可能性。

```text
status=403
```

DM権限、APIプラン、相手のDM設定、アカウント制限のどれかが原因の可能性。

```text
status=429
```

レート制限。

## 10. 結果を記録する

以下を `tasks/active/014_X_API検証.md` または別途レビュー欄に記録する。

```text
検証日:
利用Xアカウント:
Developer App:
X APIプラン:
App permissions:
App type:
Callback URL:

投稿検索:
- 結果:
- HTTP status:
- rate limit:
- レスポンス概要:
- エラー:

ユーザー取得:
- 結果:
- HTTP status:
- rate limit:
- レスポンス概要:
- エラー:

DM送信:
- 結果:
- HTTP status:
- rate limit:
- レスポンス概要:
- エラー:

MVP判断:
- 候補抽出:
- API DM送信:
- 手動送信支援:

次アクション:
```

## 11. 判断基準

### 投稿検索が成功した場合

015 X API候補抽出に進める。

### 投稿検索が失敗した場合

候補抽出をAPIで行えない可能性がある。

確認するもの:

- X APIプラン
- Bearer Token
- App権限
- Recent Search APIの利用可否

### ユーザー取得が成功した場合

候補者のusername、displayName、profileTextを取得できる可能性が高い。

### DM送信が成功した場合

016 API DM送信に進める。

ただし、レート制限と運用リスクを確認してから有効化する。

### DM送信が失敗した場合

API送信を一時停止し、手動送信フォールバックで進める。

この場合でも、投稿検索とユーザー取得が成功していれば、候補抽出は実装できる。

## 12. Cloud Functionsで使うSecret

015の候補抽出Functionは、X API Bearer TokenをFirebase Secret Managerから読む。

Secret名:

```text
X_BEARER_TOKEN
```

ローカル検証で使う `.env.x-api.local` はGit管理しない。
本番Functionsへdeployする前に、Firebase側で同じ値をSecretとして設定する。

```bash
firebase functions:secrets:set X_BEARER_TOKEN --project x-scout-manager-prod
```

このコマンドは値の入力を求めるので、X Developer PortalのBearer Tokenを貼り付ける。
Secret値はチャットやGitHubへ貼らない。
