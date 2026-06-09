# 014 X API検証レビュー

## 2026-05-14 投稿検索検証

実行コマンド:

```bash
node tools/x_api_probe.mjs search "from:XDevelopers -is:retweet"
```

結果:

```text
status=402
title=CreditsDepleted
detail=Your enrolled account does not have any credits to fulfill this request.
```

判断:

- Bearer TokenはX APIへ到達している
- `401 Unauthorized` ではないため、Token未設定やToken形式ミスではない
- `429 Too Many Requests` ではないため、通常のレート制限ではない
- X APIアカウント側のクレジット不足によりRecent Searchを実行できない

次アクション:

- X Developer Portalで現在のPlan、Credits、Billing状態を確認する
- 必要であればクレジット追加、プラン変更、または課金設定を行う
- Creditsが有効になった後、同じ投稿検索コマンドを再実行する

MVP影響:

- この状態では015 X API候補抽出には進めない
- 手動送信支援MVPは継続可能

## 2026-05-14 投稿検索再検証

実行コマンド:

```bash
node tools/x_api_probe.mjs search "from:XDevelopers -is:retweet"
```

結果:

```text
status=200
x-rate-limit-limit=450
x-rate-limit-remaining=449
x-rate-limit-reset=1778741860
result_count=0
```

判断:

- CreditsDepletedは解消済み
- Recent Search APIは疎通成功
- 今回のクエリでは該当投稿が0件
- 候補抽出実装前に、別クエリで `data[]` と `includes.users[]` が返ることを確認する

次アクション:

- よりヒットしやすいクエリで投稿検索を再実行する
- 例: `node tools/x_api_probe.mjs search "X API lang:en -is:retweet"`

## 2026-05-14 投稿データ取得確認

結果:

```text
status=200
data[] 取得成功
includes.users[] 取得成功
```

判断:

- Recent Search APIで投稿ID、本文、投稿者IDを取得できる
- `includes.users[]` で候補者のX user ID、username、displayName相当を取得できる
- 015 X API候補抽出に進める

残確認:

- 実運用で使う検索キーワード、ハッシュタグ、除外条件
- 月間/日次のクレジット消費見込み
- 取得対象を直近投稿に限定するか、ページングするか

## 2026-05-14 OAuth 2.0検証

結果:

```text
oauth-local でUser Access Token取得成功
```

判断:

- OAuth 2.0認可は成功
- 手動コピー方式ではauthorization codeの30秒期限により失敗しやすい
- 検証ではローカルcallback方式を標準手順にする

次アクション:

- `X_USER_ACCESS_TOKEN` を使ってユーザー取得を確認する
- その後、検証用受信アカウントに対してDM送信可否を確認する

## 2026-05-14 ユーザー取得検証

実行コマンド:

```bash
node tools/x_api_probe.mjs user XDevelopers
```

結果:

```text
status=200
x-rate-limit-limit=900
x-rate-limit-remaining=899
id=2244994945
username=XDevelopers
name=Developers
receives_your_dm=true
```

判断:

- ユーザー情報取得APIは利用可能
- 候補者保存に必要なX user ID、username、displayName相当、profileText相当を取得できる
- `receives_your_dm` も取得できるため、DM可否判定の補助情報として利用可能

次アクション:

- 検証用受信アカウントのUser IDを取得する
- DM送信APIを検証する

## 2026-05-14 DM送信検証

実行コマンド:

```bash
node tools/x_api_probe.mjs dm "<recipient_user_id>" "X API DM送信検証です。"
```

結果:

```text
status=403
x-rate-limit-limit=99
x-rate-limit-remaining=98
detail=You do not have permission to DM one or more participants.
```

判断:

- DM送信API endpointには到達している
- User Access TokenでDM送信APIを呼び出せている
- ただし、対象ユーザーへのDM権限がないため送信不可
- 原因候補は、相手側DM設定、相互フォロー条件、対象アカウント制限、X API側のDM許可条件

次アクション:

- 受信側アカウントで「誰からでもDMを受け取る」設定を有効化する
- 送信元/受信先を相互フォロー状態にする
- 受信側ユーザー取得結果の `receives_your_dm` を確認する
- 条件変更後にDM送信を再検証する

MVP影響:

- 現時点ではAPI DM送信をMVP標準にする判断は保留
- 手動送信支援モードは継続可能

## 2026-05-14 DM送信再検証

実行コマンド:

```bash
node tools/x_api_probe.mjs dm "<recipient_user_id>" "X API DM送信検証です。"
```

結果:

```text
status=201
x-rate-limit-limit=99
x-rate-limit-remaining=96
dm_conversation_id=取得成功
dm_event_id=取得成功
```

判断:

- DM送信APIは `status=201` で受理される
- 成功時に `dm_conversation_id` と `dm_event_id` を取得できる
- ただし、受信側X UIでの着信は未確認
- 016 API DM送信では、API受理と実着確認を分けて扱う
- 020 成果記録UIの再設計判断で、必要な場合のみ `dm_event_id` を保存対象にできる

運用注意:

- `status=201` でも受信側UIで通常受信箱に表示されない可能性がある
- メッセージリクエスト、スパム、通知未表示、アカウント切替、UI反映遅延を確認する
- X公式ヘルプ上、未フォロー相手からのDMはRequestsに分離され、品質フィルター有効時は低品質リクエストとしてRequests下部のフィルター内に隠れることがある
- 品質フィルターで非表示になったリクエストは通知されない
- 宛先User IDが想定アカウントか再確認する
- 受信側DM設定または相互フォロー条件により403になる
- `receives_your_dm` を候補詳細や送信前判定で使う
- レート制限は検証時点で `99` 枠
- X APIクレジット消費を運用上監視する
