# 014 X API検証

## 現状の動作

X Developer Appは作成済み。

- App name: `x-scout-manager-dev`
- App permission: 読み書きおよびダイレクトメッセージ
- App type: ウェブアプリ、自動化アプリまたはボット
- Terms / Privacy URL: 未設定で保存済み

APIキー、Bearer Token、Client ID、Client Secretはユーザー側で取得済み。
秘密情報はGit管理せず、ローカル `.env.x-api.local` で扱う。

## 期待する動作

投稿検索、ユーザー取得、DM送信可否を判断できる。

## 操作フロー

1. X Developer Appを準備（完了）
2. `.env.x-api.local` に検証用秘密情報を設定
3. OAuth 2.0 PKCEを検証
4. 投稿検索を検証
5. ユーザー取得を検証
6. DM送信を検証
7. API送信有効化可否を判断

## UI参考（既存画面）

なし。

## 技術方針

`docs/DETAIL_x_api_verification.md` に従う。

ローカル検証は `tools/x_api_probe.mjs` を使用する。

## 対象ファイル（推定）

- `docs/DETAIL_x_api_verification.md`
- `docs/X_API検証手順.md`
- `.env.x-api.example`
- `tools/x_api_probe.mjs`
- `functions/src/**`
- 検証用スクリプト

## 完了条件

- [x] 検証結果が記録されている
- [x] `apiDmEnabled` の判断ができる
- [x] 失敗時のMVP分岐が明確

## レビュー指摘

- 2026-05-14: X Developer App作成とOAuth設定は完了。次はローカル検証スクリプトで投稿検索、ユーザー取得、DM送信の可否を確認する。
- 2026-05-14: `node tools/x_api_probe.mjs search "from:XDevelopers -is:retweet"` は `status=402` / `CreditsDepleted`。Bearer Token自体はAPIへ到達しているが、X APIクレジット不足によりRecent Searchを実行できない。
- 2026-05-14: クレジット反映後、同コマンドは `status=200`。`result_count=0` のためRecent Search API疎通は成功、ただしデータ取得確認には別クエリで `data` / `includes.users` の取得確認が必要。
- 2026-05-14: 別クエリで `data` / `includes.users` の取得成功。Recent Search APIは015候補抽出に利用可能と判断できる。
- 2026-05-14: `oauth-local` によりOAuth 2.0 User Access Token取得成功。authorization codeの30秒期限回避のため、ローカルcallback方式を採用。
- 2026-05-14: `node tools/x_api_probe.mjs user XDevelopers` は `status=200`。`id`, `username`, `name`, `description`, `receives_your_dm`, `public_metrics` を取得できることを確認。
- 2026-05-14: DM送信APIは `status=403` / `You do not have permission to DM one or more participants.`。API endpoint到達とレート制限ヘッダー取得は確認済みだが、対象ユーザーへのDM権限またはアカウント設定により送信不可。
- 2026-05-14: 受信側条件調整後、DM送信APIは `status=201`。`dm_conversation_id` と `dm_event_id` を取得できることを確認。ただし受信側X UIでの着信は未確認のため、016ではAPI受理後の実着確認を追加する。

## 備考

API DM送信はAPI上は受理される。ただし受信側X UIでの着信確認、受信側DM設定、相互フォロー、レート制限、X APIクレジットに依存するため、MVPでは手動送信支援モードを残したまま任意有効化する。
